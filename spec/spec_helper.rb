require 'puppetlabs_spec_helper/module_spec_helper'
require 'rspec-puppet-facts'
include RspecPuppetFacts

# Customize filters to ignore 3rd-party code
# If the coverage report shows not-our-code results, add it here
custom_filters = [
  'Anchor[java::end]',
  'Stage[setup]',
  'Anchor[java::begin:]',
  'Archive::Download[opendaylight.tar.gz]',
  'Archive::Download[opendaylight-systemd.tar.gz]',
  'Archive::Extract[opendaylight]',
  'Archive::Extract[opendaylight-systemd]',
  'Class[Java::Config]',
  'Class[Java::Params]',
  'Class[Stdlib::Stages]',
  'Class[Stdlib]',
  'Exec[Configure ODL OVSDB Clustering]',
  'Exec[download archive opendaylight.tar.gz and check sum]',
  'Exec[download archive opendaylight-systemd.tar.gz and check sum]',
  'Exec[opendaylight unpack]',
  'Exec[opendaylight-systemd unpack]',
  'Exec[rm-on-error-opendaylight.tar.gz]',
  'Exec[rm-on-error-opendaylight-systemd.tar.gz]',
  'Exec[reload_systemd_units]',
  'Exec[update-java-alternatives]',
  'Package[curl]',
  'Stage[deploy]',
  'Stage[deploy_app]',
  'Stage[deploy_infra]',
  'Stage[runtime]',
  'Stage[setup_app]',
  'Stage[setup_infra]',
]
RSpec::Puppet::Coverage.filters.push(*custom_filters)

#
# NB: This is a library of helper fns used by the rspec-puppet tests
#

# Tests that are common to all possible configurations
def generic_tests()
  # Confirm that module compiles
  it { should compile }
  it { should compile.with_all_deps }

  # Confirm presence of classes
  it { should contain_class('opendaylight') }
  it { should contain_class('opendaylight::params') }
  it { should contain_class('opendaylight::install') }
  it { should contain_class('opendaylight::config') }
  it { should contain_class('opendaylight::service') }

  # Confirm relationships between classes
  it { should contain_class('opendaylight::install').that_comes_before('Class[opendaylight::config]') }
  it { should contain_class('opendaylight::config').that_requires('Class[opendaylight::install]') }
  it { should contain_class('opendaylight::config').that_notifies('Class[opendaylight::service]') }
  it { should contain_class('opendaylight::service').that_subscribes_to('Class[opendaylight::config]') }
  it { should contain_class('opendaylight::service').that_comes_before('Class[opendaylight]') }
  it { should contain_class('opendaylight').that_requires('Class[opendaylight::service]') }

  # Confirm presence of generic resources
  it { should contain_service('opendaylight') }
  it { should contain_file('org.apache.karaf.features.cfg') }

  # Confirm properties of generic resources
  # NB: These hashes don't work with Ruby 1.8.7, but we
  #   don't support 1.8.7 so that's okay. See issue #36.
  it {
    should contain_service('opendaylight').with(
      'ensure'      => 'running',
      'enable'      => 'true',
      'hasstatus'   => 'true',
      'hasrestart'  => 'true',
    )
  }
  it {
    should contain_file('org.apache.karaf.features.cfg').with(
      'ensure'      => 'file',
      'path'        => '/opt/opendaylight/etc/org.apache.karaf.features.cfg',
      'owner'   => 'odl',
      'group'   => 'odl',
    )
  }
end

# Shared tests that specialize in testing Karaf feature installs
def karaf_feature_tests(options = {})
  # Extract params
  # NB: This default list should be the same as the one in opendaylight::params
  # TODO: Remove this possible source of bugs^^
  default_features = options.fetch(:default_features, ['config', 'standard', 'region', 'package', 'kar', 'ssh', 'management'])
  extra_features = options.fetch(:extra_features, [])

  # The order of this list concat matters
  features = default_features + extra_features
  features_csv = features.join(',')

  # Confirm properties of Karaf features config file
  # NB: These hashes don't work with Ruby 1.8.7, but we
  #   don't support 1.8.7 so that's okay. See issue #36.
  it {
    should contain_file('org.apache.karaf.features.cfg').with(
      'ensure'      => 'file',
      'path'        => '/opt/opendaylight/etc/org.apache.karaf.features.cfg',
      'owner'   => 'odl',
      'group'   => 'odl',
    )
  }
  it {
    should contain_file_line('featuresBoot').with(
      'path'  => '/opt/opendaylight/etc/org.apache.karaf.features.cfg',
      'line'  => "featuresBoot=#{features_csv}",
      'match' => '^featuresBoot=.*$',
    )
  }
end

# Shared tests that specialize in testing ODL's REST port config
def odl_rest_port_tests(options = {})
  # Extract params
  # NB: This default value should be the same as one in opendaylight::params
  # TODO: Remove this possible source of bugs^^
  odl_rest_port = options.fetch(:odl_rest_port, 8080)

  # Confirm properties of ODL REST port config file
  # NB: These hashes don't work with Ruby 1.8.7, but we
  #   don't support 1.8.7 so that's okay. See issue #36.
  it {
    should contain_file('jetty.xml').with(
      'ensure'      => 'file',
      'path'        => '/opt/opendaylight/etc/jetty.xml',
      'owner'   => 'odl',
      'group'   => 'odl',
      'content'     => /Property name="jetty.port" default="#{odl_rest_port}"/
    )
  }
end

def log_level_tests(options = {})
  # Extract params
  # NB: This default value should be the same as one in opendaylight::params
  # TODO: Remove this possible source of bugs^^
  log_levels = options.fetch(:log_levels, {})

  if log_levels.empty?
    # Should contain log level config file
    it {
      should contain_file('org.ops4j.pax.logging.cfg').with(
        'ensure'      => 'file',
        'path'        => '/opt/opendaylight/etc/org.ops4j.pax.logging.cfg',
        'owner'   => 'odl',
        'group'   => 'odl',
      )
    }
    # Should not contain custom log level config
    it {
      should_not contain_file('org.ops4j.pax.logging.cfg').with(
        'ensure'      => 'file',
        'path'        => '/opt/opendaylight/etc/org.ops4j.pax.logging.cfg',
        'owner'   => 'odl',
        'group'   => 'odl',
        'content'     => /# Log level config added by puppet-opendaylight/
      )
    }
  else
    # Should contain log level config file
    it {
      should contain_file('org.ops4j.pax.logging.cfg').with(
        'ensure'      => 'file',
        'path'        => '/opt/opendaylight/etc/org.ops4j.pax.logging.cfg',
        'owner'   => 'odl',
        'group'   => 'odl',
      )
    }
    # Should contain custom log level config
    it {
      should contain_file('org.ops4j.pax.logging.cfg').with(
        'ensure'      => 'file',
        'path'        => '/opt/opendaylight/etc/org.ops4j.pax.logging.cfg',
        'owner'   => 'odl',
        'group'   => 'odl',
        'content'     => /# Log level config added by puppet-opendaylight/
      )
    }
    # Verify each custom log level config entry
    log_levels.each_pair do |logger, level|
      it {
        should contain_file('org.ops4j.pax.logging.cfg').with(
          'ensure'      => 'file',
          'path'        => '/opt/opendaylight/etc/org.ops4j.pax.logging.cfg',
          'owner'   => 'odl',
          'group'   => 'odl',
          'content'     => /^log4j.logger.#{logger} = #{level}/
        )
      }
    end
  end
end

def enable_ha_tests(options = {})
  # Extract params
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

def rpm_install_tests(options = {})
  # Extract params
  rpm_repo = options.fetch(:rpm_repo, 'opendaylight-5-testing')
  java_opts = options.fetch(:java_opts, '-Djava.net.preferIPv4Stack=true')
  baseurl = options.fetch(:baseurl, "http://cbs.centos.org/repos/nfv7-#{rpm_repo}/$basearch/os/")
  enable_repo = options.fetch(:enable_repo, '1')

  # Default to CentOS 7 Yum repo URL

  # Confirm presence of RPM-related resources
  it { should contain_yumrepo(rpm_repo) }
  it { should contain_package('opendaylight') }

  # Confirm relationships between RPM-related resources
  it { should contain_package('opendaylight').that_requires("Yumrepo[#{rpm_repo}]") }
  it { should contain_yumrepo(rpm_repo).that_comes_before('Package[opendaylight]') }

  # Confirm properties of RPM-related resources
  # NB: These hashes don't work with Ruby 1.8.7, but we
  #   don't support 1.8.7 so that's okay. See issue #36.
  it {
    should contain_yumrepo(rpm_repo).with(
      'enabled'     => "#{enable_repo}",
      'gpgcheck'    => '0',
      'descr'       => 'OpenDaylight SDN Controller',
      'baseurl'     => "#{baseurl}",
    )
  }
  it {
    should contain_package('opendaylight').with(
      'ensure'   => 'present',
    )
  }

  it {
    should contain_file_line('java_options_systemd').with(
      'ensure' => 'present',
      'path' => '/usr/lib/systemd/system/opendaylight.service',
      'line' => "Environment=_JAVA_OPTIONS=\'#{java_opts}\'",
      'after' => 'ExecStart=/opt/opendaylight/bin/start',
    )
  }
end

def deb_install_tests(options = {})
  # Extract params
  deb_repo = options.fetch(:deb_repo, 'ppa:odl-team/boron')

  # Confirm the presence of Deb-related resources
  it { should contain_apt__ppa(deb_repo) }
  it { should contain_package('opendaylight') }

  # Confirm relationships between Deb-related resources
  it { should contain_package('opendaylight').that_requires("Apt::Ppa[#{deb_repo}]") }
  it { should contain_apt__ppa(deb_repo).that_comes_before('Package[opendaylight]') }

  # Confirm presence of Deb-related resources
  it {
    should contain_package('opendaylight').with(
      'ensure'   => 'present',
    )
  }
end

# Shared tests for unsupported OSs
def unsupported_os_tests(options = {})
  # Extract params
  expected_msg = options.fetch(:expected_msg)
  rpm_repo = options.fetch(:rpm_repo, 'opendaylight-5-testing')

  # Confirm that classes fail on unsupported OSs
  it { expect { should contain_class('opendaylight') }.to raise_error(Puppet::Error, /#{expected_msg}/) }
  it { expect { should contain_class('opendaylight::install') }.to raise_error(Puppet::Error, /#{expected_msg}/) }
  it { expect { should contain_class('opendaylight::config') }.to raise_error(Puppet::Error, /#{expected_msg}/) }
  it { expect { should contain_class('opendaylight::service') }.to raise_error(Puppet::Error, /#{expected_msg}/) }

  # Confirm that other resources fail on unsupported OSs
  it { expect { should contain_yumrepo(rpm_repo) }.to raise_error(Puppet::Error, /#{expected_msg}/) }
  it { expect { should contain_package('opendaylight') }.to raise_error(Puppet::Error, /#{expected_msg}/) }
  it { expect { should contain_service('opendaylight') }.to raise_error(Puppet::Error, /#{expected_msg}/) }
  it { expect { should contain_file('org.apache.karaf.features.cfg') }.to raise_error(Puppet::Error, /#{expected_msg}/) }
end

# Shared tests that specialize in testing security group mode
def enable_sg_tests(sg_mode='stateful', os_release)
  # Extract params
  # NB: This default value should be the same as one in opendaylight::params
  # TODO: Remove this possible source of bugs^^

  it { should contain_file('/opt/opendaylight/etc/opendaylight') }
  it { should contain_file('/opt/opendaylight/etc/opendaylight/datastore')}
  it { should contain_file('/opt/opendaylight/etc/opendaylight/datastore/initial')}
  it { should contain_file('/opt/opendaylight/etc/opendaylight/datastore/initial/config')}

  if os_release != '7.3' and sg_mode == 'stateful'
    # Confirm sg_mode becomes learn
    it {
      should contain_file('netvirt-aclservice-config.xml').with(
        'ensure'      => 'file',
        'path'        => '/opt/opendaylight/etc/opendaylight/datastore/initial/config/netvirt-aclservice-config.xml',
        'owner'   => 'odl',
        'group'   => 'odl',
        'content'     => /learn/
      )
    }
  else
    # Confirm other sg_mode is passed correctly
    it {
      should contain_file('netvirt-aclservice-config.xml').with(
        'ensure'      => 'file',
        'path'        => '/opt/opendaylight/etc/opendaylight/datastore/initial/config/netvirt-aclservice-config.xml',
        'owner'   => 'odl',
        'group'   => 'odl',
        'content'     => /#{sg_mode}/
      )
    }
  end
end

# Shared tests that specialize in testing VPP routing node config
def vpp_routing_node_tests(options = {})
  # Extract params
  # NB: This default list should be the same as the one in opendaylight::params
  # TODO: Remove this possible source of bugs^^
  routing_node = options.fetch(:routing_node, '')

  if routing_node.empty?
    it { should_not contain_file('org.opendaylight.groupbasedpolicy.neutron.vpp.mapper.cfg') }
    it { should_not contain_file_line('routing-node') }
  else
    # Confirm properties of Karaf config file
    # NB: These hashes don't work with Ruby 1.8.7, but we
    #   don't support 1.8.7 so that's okay. See issue #36.
    it {
      should contain_file('org.opendaylight.groupbasedpolicy.neutron.vpp.mapper.cfg').with(
        'ensure'      => 'file',
        'path'        => '/opt/opendaylight/etc/org.opendaylight.groupbasedpolicy.neutron.vpp.mapper.cfg',
        'owner'   => 'odl',
        'group'   => 'odl',
      )
    }
    it {
      should contain_file_line('routing-node').with(
        'path'  => '/opt/opendaylight/etc/org.opendaylight.groupbasedpolicy.neutron.vpp.mapper.cfg',
        'line'  => "routing-node=#{routing_node}",
        'match' => '^routing-node=.*$',
      )
    }
  end
end
