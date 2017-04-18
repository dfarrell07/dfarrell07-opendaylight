require 'spec_helper'

describe 'opendaylight' do
  # All tests that check OS support/not-support
  describe 'OS support tests' do
    # All tests for OSs in the Red Hat family (CentOS, Fedora)
    describe 'OS family Red Hat ' do
      osfamily = 'RedHat'
      # All tests for Fedora
      describe 'Fedora' do
        operatingsystem = 'Fedora'

        # All tests for supported versions of Fedora
        ['24', '25'].each do |operatingsystemmajrelease|
          context "#{operatingsystemmajrelease}" do
            let(:facts) {{
              :osfamily => osfamily,
              :operatingsystem => operatingsystem,
              :operatingsystemmajrelease => operatingsystemmajrelease,
            }}
            # Run shared tests applicable to all supported OSs
            # Note that this function is defined in spec_helper
            generic_tests

            # Run tests that specialize in checking rpm-based installs
            # NB: Only testing defaults here, specialized rpm tests elsewhere
            # Note that this function is defined in spec_helper
            rpm_install_tests(operatingsystem: operatingsystem)

            # Run tests that specialize in checking Karaf feature installs
            # NB: Only testing defaults here, specialized Karaf tests elsewhere
            # Note that this function is defined in spec_helper
            karaf_feature_tests

            # Run tests that specialize in checking ODL's REST port config
            # NB: Only testing defaults here, specialized log level tests elsewhere
            # Note that this function is defined in spec_helper
            odl_rest_port_tests

            # Run tests that specialize in checking custom log level config
            # NB: Only testing defaults here, specialized log level tests elsewhere
            # Note that this function is defined in spec_helper
            log_level_tests

            # Run tests that specialize in checking ODL OVSDB HA config
            # NB: Only testing defaults here, specialized enabling HA tests elsewhere
            # Note that this function is defined in spec_helper
            enable_ha_tests
          end
        end

        # All tests for unsupported versions of Fedora
        ['23'].each do |operatingsystemmajrelease|
          context "#{operatingsystemmajrelease}" do
            let(:facts) {{
              :osfamily => osfamily,
              :operatingsystem => operatingsystem,
              :operatingsystemmajrelease => operatingsystemmajrelease,
            }}
            # Run shared tests applicable to all unsupported OSs
            # Note that this function is defined in spec_helper
            expected_msg = "Unsupported OS: #{operatingsystem} #{operatingsystemmajrelease}"
            unsupported_os_tests(expected_msg: expected_msg)
          end
        end
      end

      # All tests for CentOS
      describe 'CentOS' do
        operatingsystem = 'CentOS'

        # All tests for supported versions of CentOS
        ['7'].each do |operatingsystemmajrelease|
          context "#{operatingsystemmajrelease}" do
            let(:facts) {{
              :osfamily => osfamily,
              :operatingsystem => operatingsystem,
              :operatingsystemmajrelease => operatingsystemmajrelease,
            }}
            # Run shared tests applicable to all supported OSs
            # Note that this function is defined in spec_helper
            generic_tests

            # Run test that specialize in checking rpm-based installs
            # NB: Only testing defaults here, specialized rpm tests elsewhere
            # Note that this function is defined in spec_helper
            rpm_install_tests

            # Run test that specialize in checking Karaf feature installs
            # NB: Only testing defaults here, specialized Karaf tests elsewhere
            # Note that this function is defined in spec_helper
            karaf_feature_tests

            # Run tests that specialize in checking ODL's REST port config
            # NB: Only testing defaults here, specialized log level tests elsewhere
            # Note that this function is defined in spec_helper
            odl_rest_port_tests

            # Run test that specialize in checking custom log level config
            # NB: Only testing defaults here, specialized log level tests elsewhere
            # Note that this function is defined in spec_helper
            log_level_tests

            # Run tests that specialize in checking ODL OVSDB HA config
            # NB: Only testing defaults here, specialized enabling HA tests elsewhere
            # Note that this function is defined in spec_helper
            enable_ha_tests
          end
        end

        # All tests for unsupported versions of CentOS
        ['6'].each do |operatingsystemmajrelease|
          context "#{operatingsystemmajrelease}" do
            let(:facts) {{
              :osfamily => osfamily,
              :operatingsystem => operatingsystem,
              :operatingsystemmajrelease => operatingsystemmajrelease,
            }}
            # Run shared tests applicable to all unsupported OSs
            # Note that this function is defined in spec_helper
            expected_msg = "Unsupported OS: #{operatingsystem} #{operatingsystemmajrelease}"
            unsupported_os_tests(expected_msg: expected_msg)
          end
        end
      end
    end

    # All tests for OSs in the Debian family (Ubuntu)
    describe 'OS family Debian' do
      osfamily = 'Debian'

      # All tests for Ubuntu 16.04
      describe 'Ubuntu' do
        operatingsystem = 'Ubuntu'

        # All tests for supported versions of Ubuntu
        ['16.04'].each do |operatingsystemrelease|
          context "#{operatingsystemrelease}" do
            let(:facts) {{
              :osfamily => osfamily,
              :operatingsystem => operatingsystem,
              :operatingsystemrelease => operatingsystemrelease,
              :lsbdistid => operatingsystem,
              :lsbdistrelease => operatingsystemrelease,
              :lsbdistcodename => 'xenial',
              :puppetversion => '4.9.0',
              :path => ['/usr/local/bin', '/usr/bin', '/bin'],
            }}

            # Run shared tests applicable to all supported OSs
            # Note that this function is defined in spec_helper
            generic_tests

            # Run test that specialize in checking deb-based installs
            # Note that this function is defined in spec_helper
            deb_install_tests

            # Run test that specialize in checking Karaf feature installs
            # NB: Only testing defaults here, specialized Karaf tests elsewhere
            # Note that this function is defined in spec_helper
            karaf_feature_tests

            # Run tests that specialize in checking ODL's REST port config
            # NB: Only testing defaults here, specialized log level tests elsewhere
            # Note that this function is defined in spec_helper
            odl_rest_port_tests

            # Run test that specialize in checking custom log level config
            # NB: Only testing defaults here, specialized log level tests elsewhere
            # Note that this function is defined in spec_helper
            log_level_tests

            # Run tests that specialize in checking ODL OVSDB HA config
            # NB: Only testing defaults here, specialized enabling HA tests elsewhere
            # Note that this function is defined in spec_helper
            enable_ha_tests
          end
        end

        # All tests for unsupported versions of Ubuntu
        ['12.04', '14.04', '15.10'].each do |operatingsystemrelease|
          context "#{operatingsystemrelease}" do
            let(:facts) {{
              :osfamily => osfamily,
              :operatingsystem => operatingsystem,
              :operatingsystemrelease => operatingsystemrelease,
              :lsbdistid => operatingsystem,
              :lsbdistrelease => operatingsystemrelease,
              :lsbdistcodename => 'xenial',
              :puppetversion => '4.9.0',
            }}
            # Run shared tests applicable to all unsupported OSs
            # Note that this function is defined in spec_helper
            expected_msg = "Unsupported OS: #{operatingsystem} #{operatingsystemrelease}"
            unsupported_os_tests(expected_msg: expected_msg)
          end
        end
      end
    end

    # All tests for unsupported OS families
    ['Suse', 'Solaris'].each do |osfamily|
      context "OS family #{osfamily}" do
        let(:facts) {{
          :osfamily => osfamily,
        }}

        # Run shared tests applicable to all unsupported OSs
        # Note that this function is defined in spec_helper
        expected_msg = "Unsupported OS family: #{osfamily}"
        unsupported_os_tests(expected_msg: expected_msg)
      end
    end
  end

  # All Karaf feature tests
  describe 'Karaf feature tests' do
    # Non-OS-type tests assume CentOS 7
    #   See issue #43 for reasoning:
    #   https://github.com/dfarrell07/puppet-opendaylight/issues/43#issue-57343159
    osfamily = 'RedHat'
    operatingsystem = 'CentOS'
    operatingsystemmajrelease = '7'
    describe 'using default features' do
      context 'and not passing extra features' do
        let(:facts) {{
          :osfamily => osfamily,
          :operatingsystem => operatingsystem,
          :operatingsystemmajrelease => operatingsystemmajrelease,
        }}

        let(:params) {{ }}

        # Run shared tests applicable to all supported OSs
        # Note that this function is defined in spec_helper
        generic_tests

        # Run test that specialize in checking Karaf feature installs
        # Note that this function is defined in spec_helper
        karaf_feature_tests
      end

      context 'and passing extra features' do
        let(:facts) {{
          :osfamily => osfamily,
          :operatingsystem => operatingsystem,
          :operatingsystemmajrelease => operatingsystemmajrelease,
        }}

        # These are real but arbitrarily chosen features
        extra_features = ['odl-base-all', 'odl-ovsdb-all']
        let(:params) {{
          :extra_features => extra_features,
        }}

        # Run shared tests applicable to all supported OSs
        # Note that this function is defined in spec_helper
        generic_tests

        # Run test that specialize in checking Karaf feature installs
        # Note that this function is defined in spec_helper
        karaf_feature_tests(extra_features: extra_features)
      end
    end

    describe 'overriding default features' do
      default_features = ['standard', 'ssh']
      context 'and not passing extra features' do
        let(:facts) {{
          :osfamily => osfamily,
          :operatingsystem => operatingsystem,
          :operatingsystemmajrelease => operatingsystemmajrelease,
        }}

        let(:params) {{
          :default_features => default_features,
        }}

        # Run shared tests applicable to all supported OSs
        # Note that this function is defined in spec_helper
        generic_tests

        # Run test that specialize in checking Karaf feature installs
        # Note that this function is defined in spec_helper
        karaf_feature_tests(default_features: default_features)
      end

      context 'and passing extra features' do
        let(:facts) {{
          :osfamily => osfamily,
          :operatingsystem => operatingsystem,
          :operatingsystemmajrelease => operatingsystemmajrelease,
        }}

        # These are real but arbitrarily chosen features
        extra_features = ['odl-base-all', 'odl-ovsdb-all']
        let(:params) {{
          :default_features => default_features,
          :extra_features => extra_features,
        }}

        # Run shared tests applicable to all supported OSs
        # Note that this function is defined in spec_helper
        generic_tests

        # Run test that specialize in checking Karaf feature installs
        # Note that this function is defined in spec_helper
        karaf_feature_tests(default_features: default_features, extra_features: extra_features)
      end
    end
  end

  # All ODL REST port tests
  describe 'REST port tests' do
    # Non-OS-type tests assume CentOS 7
    #   See issue #43 for reasoning:
    #   https://github.com/dfarrell07/puppet-opendaylight/issues/43#issue-57343159
    osfamily = 'RedHat'
    operatingsystem = 'CentOS'
    operatingsystemmajrelease = '7'
    context 'using default REST port' do
      let(:facts) {{
        :osfamily => osfamily,
        :operatingsystem => operatingsystem,
        :operatingsystemmajrelease => operatingsystemmajrelease,
      }}

      let(:params) {{ }}

      # Run shared tests applicable to all supported OSs
      # Note that this function is defined in spec_helper
      generic_tests

      # Run test that specialize in checking ODL REST port config
      # Note that this function is defined in spec_helper
      odl_rest_port_tests
    end

    context 'overriding default REST port' do
      let(:facts) {{
        :osfamily => osfamily,
        :operatingsystem => operatingsystem,
        :operatingsystemmajrelease => operatingsystemmajrelease,
      }}

      let(:params) {{
        :odl_rest_port => 7777,
      }}

      # Run shared tests applicable to all supported OSs
      # Note that this function is defined in spec_helper
      generic_tests

      # Run test that specialize in checking ODL REST port config
      # Note that this function is defined in spec_helper
      odl_rest_port_tests(odl_rest_port: 7777)
    end
  end

  # All custom log level tests
  describe 'custom log level tests' do
    # Non-OS-type tests assume CentOS 7
    #   See issue #43 for reasoning:
    #   https://github.com/dfarrell07/puppet-opendaylight/issues/43#issue-57343159
    osfamily = 'RedHat'
    operatingsystem = 'CentOS'
    operatingsystemmajrelease = '7'
    context 'using default log levels' do
      let(:facts) {{
        :osfamily => osfamily,
        :operatingsystem => operatingsystem,
        :operatingsystemmajrelease => operatingsystemmajrelease,
      }}

      let(:params) {{ }}

      # Run shared tests applicable to all supported OSs
      # Note that this function is defined in spec_helper
      generic_tests

      # Run test that specialize in checking custom log level config
      # Note that this function is defined in spec_helper
      log_level_tests
    end

    context 'adding one custom log level' do
      let(:facts) {{
        :osfamily => osfamily,
        :operatingsystem => operatingsystem,
        :operatingsystemmajrelease => operatingsystemmajrelease,
      }}

      custom_log_levels = { 'org.opendaylight.ovsdb' => 'TRACE' }

      let(:params) {{
        :log_levels => custom_log_levels,
      }}

      # Run shared tests applicable to all supported OSs
      # Note that this function is defined in spec_helper
      generic_tests

      # Run test that specialize in checking log level config
      # Note that this function is defined in spec_helper
      log_level_tests(log_levels: custom_log_levels)
    end

    context 'adding two custom log levels' do
      let(:facts) {{
        :osfamily => osfamily,
        :operatingsystem => operatingsystem,
        :operatingsystemmajrelease => operatingsystemmajrelease,
      }}

      custom_log_levels = { 'org.opendaylight.ovsdb' => 'TRACE',
                         'org.opendaylight.ovsdb.lib' => 'INFO' }

      let(:params) {{
        :log_levels => custom_log_levels,
      }}

      # Run shared tests applicable to all supported OSs
      # Note that this function is defined in spec_helper
      generic_tests

      # Run test that specialize in checking log level config
      # Note that this function is defined in spec_helper
      log_level_tests(log_levels: custom_log_levels)
    end
  end

  # All OVSDB HA enable/disable tests
  describe 'OVSDB HA enable/disable tests' do
    # Non-OS-type tests assume CentOS 7
    #   See issue #43 for reasoning:
    #   https://github.com/dfarrell07/puppet-opendaylight/issues/43#issue-57343159
    osfamily = 'RedHat'
    operatingsystem = 'CentOS'
    operatingsystemmajrelease = '7'
    context 'using enable_ha default' do
      let(:facts) {{
        :osfamily => osfamily,
        :operatingsystem => operatingsystem,
        :operatingsystemmajrelease => operatingsystemmajrelease,
      }}

      let(:params) {{ }}

      # Run shared tests applicable to all supported OSs
      # Note that this function is defined in spec_helper
      generic_tests

      # Run test that specialize in checking ODL OVSDB HA config
      # Note that this function is defined in spec_helper
      enable_ha_tests
    end

    context 'using false for enable_ha' do
      let(:facts) {{
        :osfamily => osfamily,
        :operatingsystem => operatingsystem,
        :operatingsystemmajrelease => operatingsystemmajrelease,
      }}

      let(:params) {{
        :enable_ha => false,
      }}

      # Run shared tests applicable to all supported OSs
      # Note that this function is defined in spec_helper
      generic_tests

      # Run test that specialize in checking ODL OVSDB HA config
      # Note that this function is defined in spec_helper
      enable_ha_tests(enable_ha: false)
    end

    context 'using true for enable_ha' do
      context 'using ha_node_count >=2' do
        let(:facts) {{
          :osfamily => osfamily,
          :operatingsystem => operatingsystem,
          :operatingsystemmajrelease => operatingsystemmajrelease,
        }}

        let(:params) {{
          :enable_ha => true,
          :ha_node_ips => ['0.0.0.0', '127.0.0.1']
        }}

        # Run shared tests applicable to all supported OSs
        # Note that this function is defined in spec_helper
        generic_tests

        # Run test that specialize in checking ODL OVSDB HA config
        # Note that this function is defined in spec_helper
        enable_ha_tests(enable_ha: true, ha_node_ips: ['0.0.0.0', '127.0.0.1'])
      end
    end
  end


  # All install method tests
  describe 'install method tests' do

    # All tests for RPM install method
    describe 'RPM' do
      # Non-OS-type tests assume CentOS 7
      #   See issue #43 for reasoning:
      #   https://github.com/dfarrell07/puppet-opendaylight/issues/43#issue-57343159
      osfamily = 'RedHat'
      operatingsystem = 'CentOS'
      operatingsystemrelease = '7.0'
      operatingsystemmajrelease = '7'

      context 'installing default RPM' do
        let(:facts) {{
          :osfamily => osfamily,
          :operatingsystem => operatingsystem,
          :operatingsystemmajrelease => operatingsystemmajrelease,
        }}

        # Run shared tests applicable to all supported OSs
        # Note that this function is defined in spec_helper
        generic_tests

        # Run test that specialize in checking RPM-based installs
        # Note that this function is defined in spec_helper
        rpm_install_tests
      end

      context 'installing Beryllium RPM' do
        rpm_repo = 'opendaylight-40-release'
        let(:facts) {{
          :osfamily => osfamily,
          :operatingsystem => operatingsystem,
          :operatingsystemmajrelease => operatingsystemmajrelease,
        }}

        let(:params) {{
          :rpm_repo => rpm_repo,
        }}

        # Run shared tests applicable to all supported OSs
        # Note that this function is defined in spec_helper
        generic_tests

        # Run test that specialize in checking RPM-based installs
        # Note that this function is defined in spec_helper
        rpm_install_tests(rpm_repo: rpm_repo)
      end
    end

    # All tests for Deb install method
    describe 'Deb' do
      osfamily = 'Debian'
      operatingsystem = 'Ubuntu'
      operatingsystemrelease = '16.04'
      operatingsystemmajrelease = '16'
      lsbdistcodename = 'xenial'

      context 'installing Deb' do
        let(:facts) {{
          :osfamily => osfamily,
          :operatingsystem => operatingsystem,
          :operatingsystemrelease => operatingsystemrelease,
          :operatingsystemmajrelease => operatingsystemmajrelease,
          :lsbdistid => operatingsystem,
          :lsbdistrelease => operatingsystemrelease,
          :lsbmajdistrelease => operatingsystemmajrelease,
          :lsbdistcodename => lsbdistcodename,
          :puppetversion => Puppet.version,
        }}

        # Run shared tests applicable to all supported OSs
        # Note that this function is defined in spec_helper
        generic_tests

        # Run test that specialize in checking RPM-based installs
        # Note that this function is defined in spec_helper
        deb_install_tests
      end

      context 'installing Boron Deb' do
        deb_repo = 'ppa:odl-team/boron'
        let(:facts) {{
          :osfamily => osfamily,
          :operatingsystem => operatingsystem,
          :operatingsystemrelease => operatingsystemrelease,
          :operatingsystemmajrelease => operatingsystemmajrelease,
          :lsbdistid => operatingsystem,
          :lsbdistrelease => operatingsystemrelease,
          :lsbmajdistrelease => operatingsystemmajrelease,
          :lsbdistcodename => lsbdistcodename,
          :puppetversion => Puppet.version,
        }}

        let(:params) {{
          :deb_repo => deb_repo,
        }}

        # Run shared tests applicable to all supported OSs
        # Note that this function is defined in spec_helper
        generic_tests

        # Run test that specialize in checking RPM-based installs
        # Note that this function is defined in spec_helper
        deb_install_tests(deb_repo: deb_repo)
      end
    end

  end

  # Security Group Tests
  describe 'security group tests' do
    # Non-OS-type tests assume CentOS 7
    #   See issue #43 for reasoning:
    #   https://github.com/dfarrell07/puppet-opendaylight/issues/43#issue-57343159
    osfamily = 'RedHat'
    operatingsystem = 'CentOS'
    operatingsystemmajrelease = '7'
    context 'using supported stateful' do
      let(:facts) {{
        :osfamily => osfamily,
        :operatingsystem => operatingsystem,
        :operatingsystemmajrelease => operatingsystemmajrelease,
        :operatingsystemrelease => '7.3',
      }}

      let(:params) {{
        :security_group_mode => 'stateful',
        :extra_features      => ['odl-netvirt-openstack'],
      }}

      # Run shared tests applicable to all supported OSs
      # Note that this function is defined in spec_helper
      generic_tests

      # Run test that specialize in checking security groups
      # Note that this function is defined in spec_helper
      enable_sg_tests('stateful', '7.3')
    end

    context 'using unsupported stateful' do
      let(:facts) {{
        :osfamily => osfamily,
        :operatingsystem => operatingsystem,
        :operatingsystemmajrelease => operatingsystemmajrelease,
        :operatingsystemrelease => '7.2.1511',
      }}

      let(:params) {{
        :security_group_mode => 'stateful',
        :extra_features      => ['odl-netvirt-openstack'],
      }}

      # Run shared tests applicable to all supported OSs
      # Note that this function is defined in spec_helper
      generic_tests

      # Run test that specialize in checking security groups
      # Note that this function is defined in spec_helper
      enable_sg_tests('stateful', '7.2.1511')
    end

    context 'using transparent with unsupported stateful' do
      let(:facts) {{
        :osfamily => osfamily,
        :operatingsystem => operatingsystem,
        :operatingsystemmajrelease => operatingsystemmajrelease,
        :operatingsystemrelease => '7.2.1511',
      }}

      let(:params) {{
        :security_group_mode => 'transparent',
        :extra_features      => ['odl-netvirt-openstack'],
      }}

      # Run shared tests applicable to all supported OSs
      # Note that this function is defined in spec_helper
      generic_tests

      # Run test that specialize in checking security groups
      # Note that this function is defined in spec_helper
      enable_sg_tests('transparent', '7.2.1511')
    end
  end

  # VPP routing node config tests
  describe 'VPP routing node tests' do
    # Non-OS-type tests assume CentOS 7
    #   See issue #43 for reasoning:
    #   https://github.com/dfarrell07/puppet-opendaylight/issues/43#issue-57343159
    osfamily = 'RedHat'
    operatingsystem = 'CentOS'
    operatingsystemmajrelease = '7'
    context 'using default - no routing node' do
      let(:facts) {{
        :osfamily => osfamily,
        :operatingsystem => operatingsystem,
        :operatingsystemmajrelease => operatingsystemmajrelease,
      }}

      let(:params) {{ }}

      # Run shared tests applicable to all supported OSs
      # Note that this function is defined in spec_helper
      generic_tests

      # Run test that specialize in checking routing-node config
      # Note that this function is defined in spec_helper
      vpp_routing_node_tests
    end

    context 'using node name for routing node' do
      let(:facts) {{
        :osfamily => osfamily,
        :operatingsystem => operatingsystem,
        :operatingsystemmajrelease => operatingsystemmajrelease,
      }}

      let(:params) {{
        :vpp_routing_node => 'test-node-1',
      }}

      # Run shared tests applicable to all supported OSs
      # Note that this function is defined in spec_helper
      generic_tests

      # Run test that specialize in checking routing-node config
      # Note that this function is defined in spec_helper
      vpp_routing_node_tests(routing_node: 'test-node-1')
    end
  end

  # ODL username/password tests
  describe 'ODL username/password tests' do
    # Non-OS-type tests assume CentOS 7
    #   See issue #43 for reasoning:
    #   https://github.com/dfarrell07/puppet-opendaylight/issues/43#issue-57343159
    osfamily = 'RedHat'
    operatingsystem = 'CentOS'
    operatingsystemmajrelease = '7'
    context 'using default username/password' do
      let(:facts) {{
        :osfamily => osfamily,
        :operatingsystem => operatingsystem,
        :operatingsystemmajrelease => operatingsystemmajrelease,
      }}

      let(:params) {{ }}

      # Run shared tests applicable to all supported OSs
      # Note that this function is defined in spec_helper
      generic_tests

      # Run test that specialize in checking username/password config
      # Note that this function is defined in spec_helper
      username_password_tests('admin','admin')
    end

    context 'specifying non-default username/password' do
      let(:facts) {{
        :osfamily => osfamily,
        :operatingsystem => operatingsystem,
        :operatingsystemmajrelease => operatingsystemmajrelease,
      }}

      let(:params) {{
        :username => 'test',
        :password => 'test'
      }}

      # Run shared tests applicable to all supported OSs
      # Note that this function is defined in spec_helper
      generic_tests

      # Run test that specialize in checking routing-node config
      # Note that this function is defined in spec_helper
      username_password_tests('test', 'test')
    end
  end

end
