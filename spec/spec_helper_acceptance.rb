require 'beaker-rspec/spec_helper'
require 'beaker-rspec/helpers/serverspec'

# Install Puppet on all Beaker hosts
unless ENV['BEAKER_provision'] == 'no'
  hosts.each do |host|
    # Install Puppet
    if host.is_pe?
      install_pe
    elsif host.name == "ubuntu-16-docker" || host.name == "ubuntu-16"
      install_puppet_agent_on(host, puppet_collection: "pc1")
    else
      install_puppet
    end
  end
end

RSpec.configure do |c|
  # Project root
  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  # Readable test descriptions
  c.formatter = :documentation

  # Configure all nodes in nodeset
  c.before :suite do
    # Install opendaylight module on any/all Beaker hosts
    # TODO: Should this be done in host.each loop?
    puppet_module_install(:source => proj_root, :module_name => 'opendaylight')
    hosts.each do |host|
      # Install stdlib, a dependency of the odl mod
      on host, puppet('module', 'install', 'puppetlabs-stdlib'), { :acceptable_exit_codes => [0] }
      # Install apt, a dependency of the deb install method
      on host, puppet('module', 'install', 'puppetlabs-apt'), { :acceptable_exit_codes => [0] }
    end
  end
end

#
# NB: These are a library of helper fns used by the Beaker tests
#

# NB: There are a large number of helper functions used in these tests.
# They make this code much more friendly, but may need to be referenced.
# The serverspec helpers (`should`, `be_running`...) are documented here:
#   http://serverspec.org/resource_types.html

def install_odl(options = {})
  # Install params are passed via environment var, set in Rakefile
  # Changing the installed version of ODL via `puppet apply` is not supported
  # by puppet-odl, so it's not possible to vary these params in the same
  # Beaker test run. Do a different run passing different env vars.
  rpm_repo = ENV['RPM_REPO']
  deb_repo = ENV['DEB_REPO']

  if rpm_repo == ''
    rpm_repo = 'none'
  elsif deb_repo == ''
    deb_repo = 'none'
  end

  # NB: These param defaults should match the ones used by the opendaylight
  #   class, which are defined in opendaylight::params
  # TODO: Remove this possible source of bugs^^
  # Extract params if given, defaulting to odl class defaults if not
  extra_features = options.fetch(:extra_features, [])
  default_features = options.fetch(:default_features,
    ['config', 'standard', 'region', 'package', 'kar', 'ssh', 'management'])
  odl_rest_port = options.fetch(:odl_rest_port, 8080)
  log_levels = options.fetch(:log_levels, {})
  enable_ha = options.fetch(:enable_ha, false)
  ha_node_ips = options.fetch(:ha_node_ips, [])
  ha_node_index = options.fetch(:ha_node_index, 0)
  username = options.fetch(:username, 'admin')
  password = options.fetch(:password, 'admin')

  # Build script for consumption by Puppet apply
  it 'should work idempotently with no errors' do
    pp = <<-EOS
    class { 'opendaylight':
      rpm_repo => '#{rpm_repo}',
      deb_repo => '#{deb_repo}',
      default_features => #{default_features},
      extra_features => #{extra_features},
      odl_rest_port=> #{odl_rest_port},
      enable_ha=> #{enable_ha},
      ha_node_ips=> #{ha_node_ips},
      ha_node_index=> #{ha_node_index},
      log_levels=> #{log_levels},
      username=> #{username},
      password=> #{password},
    }
    EOS

    # Apply our Puppet manifest on the Beaker host
    apply_manifest(pp, :catch_failures => true)

    # Not checking for idempotence because of false failures
    # related to package manager cache updates outputting to
    # stdout and different IDs for the puppet manifest apply.
    # I think this is a limitation in how Beaker can check
    # for changes, not a problem with the Puppet module.
    end
end

# Shared function that handles generic validations
# These should be common for all odl class param combos
def generic_validations()
  # Verify ODL's directory
  describe file('/opt/opendaylight/') do
    it { should be_directory }
    it { should be_owned_by 'odl' }
    it { should be_grouped_into 'odl' }
  end

  # Verify ODL's systemd service
  describe service('opendaylight') do
    it { should be_enabled }
    it { should be_enabled.with_level(3) }
    it { should be_running.under('systemd') }
  end

  # Creation handled by RPM or Deb
  describe user('odl') do
    it { should exist }
    it { should belong_to_group 'odl' }
    # NB: This really shouldn't have a slash at the end!
    #     The home dir set by the RPM is `/opt/opendaylight`.
    #     Since we use the trailing slash elsewhere else, this
    #     may look like a style issue. It isn't! It will make
    #     Beaker tests fail if it ends with a `/`. A future
    #     version of the ODL RPM may change this.
    it { should have_home_directory '/opt/opendaylight' }
  end

  # Creation handled by RPM or Deb
  describe group('odl') do
    it { should exist }
  end

  # This should not be the odl user's home dir
  describe file('/home/odl') do
    # Home dir shouldn't be created for odl user
    it { should_not be_directory }
  end

  # OpenDaylight will appear as a Java process
  describe process('java') do
    it { should be_running }
  end

  # Should contain Karaf features config file
  describe file('/opt/opendaylight/etc/org.apache.karaf.features.cfg') do
    it { should be_file }
    it { should be_owned_by 'odl' }
    it { should be_grouped_into 'odl' }
  end

  # Should contain ODL NB port config file
  describe file('/opt/opendaylight/etc/jetty.xml') do
    it { should be_file }
    it { should be_owned_by 'odl' }
    it { should be_grouped_into 'odl' }
  end

  # Should contain log level config file
  describe file('/opt/opendaylight/etc/org.ops4j.pax.logging.cfg') do
    it { should be_file }
    it { should be_owned_by 'odl' }
    it { should be_grouped_into 'odl' }
  end

  if ['centos-7', 'centos-7-docker'].include? ENV['RS_SET']
    # Validations for modern Red Hat family OSs

    # Verify ODL systemd .service file
    describe file('/usr/lib/systemd/system/opendaylight.service') do
      it { should be_file }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'root' }
      it { should be_mode '644' }
    end

    # Java 8 should be installed
    describe package('java-1.8.0-openjdk') do
      it { should be_installed }
    end

  # Ubuntu 16.04 specific validation
  elsif ['ubuntu-16', 'ubuntu-16-docker'].include? ENV['RS_SET']

    # Verify ODL systemd .service file
    describe file('/lib/systemd/system/opendaylight.service') do
      it { should be_file }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'root' }
      it { should be_mode '644' }
    end

    # Java 8 should be installed
    describe package('openjdk-8-jre-headless') do
      it { should be_installed }
    end

  else
    fail("Unexpected RS_SET (host OS): #{ENV['RS_SET']}")
  end
end

# Shared function for validations related to the Karaf config file
def karaf_config_validations(options = {})
  # NB: These param defaults should match the ones used by the opendaylight
  #   class, which are defined in opendaylight::params
  # TODO: Remove this possible source of bugs^^
  extra_features = options.fetch(:extra_features, [])
  default_features = options.fetch(:default_features, ['config', 'standard', 'region',
                                  'package', 'kar', 'ssh', 'management'])

  # Create one list of all of the features
  features = default_features + extra_features

  describe file('/opt/opendaylight/etc/org.apache.karaf.features.cfg') do
    it { should be_file }
    it { should be_owned_by 'odl' }
    it { should be_grouped_into 'odl' }
    its(:content) { should match /^featuresBoot=#{features.join(",")}/ }
  end
end

# Shared function for validations related to the ODL REST port config file
def port_config_validations(options = {})
  # NB: This param default should match the one used by the opendaylight
  #   class, which is defined in opendaylight::params
  # TODO: Remove this possible source of bugs^^
  odl_rest_port = options.fetch(:odl_rest_port, 8080)

  describe file('/opt/opendaylight/etc/jetty.xml') do
    it { should be_file }
    it { should be_owned_by 'odl' }
    it { should be_grouped_into 'odl' }
    its(:content) { should match /Property name="jetty.port" default="#{odl_rest_port}"/ }
  end
end

# Shared function for validations related to custom logging verbosity
def log_level_validations(options = {})
  # NB: This param default should match the one used by the opendaylight
  #   class, which is defined in opendaylight::params
  # TODO: Remove this possible source of bugs^^
  log_levels = options.fetch(:log_levels, {})

  if log_levels.empty?
    # Should contain log level config file
    describe file('/opt/opendaylight/etc/org.ops4j.pax.logging.cfg') do
      it { should be_file }
      it { should be_owned_by 'odl' }
      it { should be_grouped_into 'odl' }
    end
    # Should not contain custom log level config
    describe file('/opt/opendaylight/etc/org.ops4j.pax.logging.cfg') do
      it { should be_file }
      it { should be_owned_by 'odl' }
      it { should be_grouped_into 'odl' }
      its(:content) { should_not match /# Log level config added by puppet-opendaylight/ }
    end
  else
    # Should contain log level config file
    describe file('/opt/opendaylight/etc/org.ops4j.pax.logging.cfg') do
      it { should be_file }
      it { should be_owned_by 'odl' }
      it { should be_grouped_into 'odl' }
    end
    # Should not contain custom log level config
    describe file('/opt/opendaylight/etc/org.ops4j.pax.logging.cfg') do
      it { should be_file }
      it { should be_owned_by 'odl' }
      it { should be_grouped_into 'odl' }
      its(:content) { should match /# Log level config added by puppet-opendaylight/ }
    end
    # Verify each custom log level config entry
    log_levels.each_pair do |logger, level|
      describe file('/opt/opendaylight/etc/org.ops4j.pax.logging.cfg') do
        it { should be_file }
        it { should be_owned_by 'odl' }
        it { should be_grouped_into 'odl' }
        its(:content) { should match /^log4j.logger.#{logger} = #{level}/ }
      end
    end
  end
end

# Shared function for validations related to ODL OVSDB HA config
def enable_ha_validations(options = {})
  # NB: This param default should match the one used by the opendaylight
  #   class, which is defined in opendaylight::params
  # TODO: Remove this possible source of bugs^^
  enable_ha = options.fetch(:enable_ha, false)
  ha_node_ips = options.fetch(:ha_node_ips, [])
  ha_node_index = options.fetch(:ha_node_index, 0)
  # HA_NODE_IPS size
  ha_node_count = ha_node_ips.size

  if (enable_ha) && (ha_node_count < 2)
    # Check for HA_NODE_COUNT < 2
    fail("Number of HA nodes less than 2: #{ha_node_count} and HA Enabled")
  end
end

# Shared function that handles validations specific to RPM-type installs
def rpm_validations()
  rpm_repo = ENV['RPM_REPO']

  describe yumrepo(rpm_repo) do
    it { should exist }
    it { should be_enabled }
  end

  describe package('opendaylight') do
    it { should be_installed }
  end
end

# Shared function that handles validations specific to Deb-type installs
def deb_validations()
  deb_repo = ENV['DEB_REPO']
  # Check ppa
  # Docs: http://serverspec.org/resource_types.html#ppa
  describe ppa(deb_repo) do
    it { should exist }
    it { should be_enabled }
  end

  describe package('opendaylight') do
    it { should be_installed }
  end
end

# Shared function for validations related to username/password
def username_password_validations(options = {})
  # NB: This param default should match the one used by the opendaylight
  #   class, which is defined in opendaylight::params
  # TODO: Remove this possible source of bugs^^
  odl_username = options.fetch(:username, 'admin')
  odl_password = options.fetch(:password, 'admin')
  odl_check_url = 'http://127.0.0.1:8080/restconf'

  describe file('/opt/opendaylight/idmlight.db.mv.db') do
    it { should be_file }
  end

  describe command("sleep 60 && curl -o /dev/null --fail --silent --head -u #{odl_username}:#{odl_password} #{odl_check_url}") do
    its(:exit_status) { should eq 0 }
  end
end
