# == Class: opendaylight
#
# OpenDaylight SDN Controller
#
# === Parameters
# [*default_features*]
#   Features that should normally be installed by default, but can be overridden.
# [*extra_features*]
#   List of features to install in addition to the default ones.
# [*odl_rest_port *]
#   Port for ODL northbound REST interface to listen on.
# [*odl_bind_ip *]
#   IP for ODL northbound REST interface to bind to.
# [*install_method *]
#   How to install OpenDaylight. Current options are "rpm" and "tarball", default is RPM.
# [*rpm_repo*]
#   OpenDaylight CentOS CBS repo to install RPM from (opendaylight-4-testing, opendaylight-40-release, ...).
# [*tarball_url*]
#   If installing from a tarball, use this one. Defaults to latest ODL.
# [*unitfile_url*]
#   OpenDaylight .service file to use for tarball installs. Defaults to one used by ODL RPM.
# [*enable_l3*]
#   Enable or disable ODL OVSDB ML2 L3 forwarding. Valid: true, false, 'yes' and 'no'.
# [*log_levels*]
#   Custom OpenDaylight logger verbosity configuration (TRACE, DEBUG, INFO, WARN, ERROR).
# [*enable_ha*]
#   Enable or disable ODL OVSDB HA Clustering. Valid: true or false. Default: false.
# [*ha_node_ips*]
#   Array of IPs for each node in the HA cluster.
# [*ha_node_index*]
#   Index of ha_node_ips for this node.
# [*security_group_mode*]
#   Sets the mode to use for security groups (stateful, learn, stateless, transparent)
#
class opendaylight (
  $default_features    = $::opendaylight::params::default_features,
  $extra_features      = $::opendaylight::params::extra_features,
  $odl_rest_port       = $::opendaylight::params::odl_rest_port,
  $odl_bind_ip         = $::opendaylight::params::odl_bind_ip,
  $install_method      = $::opendaylight::params::install_method,
  $rpm_repo            = $::opendaylight::params::rpm_repo,
  $tarball_url         = $::opendaylight::params::tarball_url,
  $unitfile_url        = $::opendaylight::params::unitfile_url,
  $enable_l3           = $::opendaylight::params::enable_l3,
  $log_levels          = $::opendaylight::params::log_levels,
  $enable_ha           = $::opendaylight::params::enable_ha,
  $ha_node_ips         = $::opendaylight::params::ha_node_ips,
  $ha_node_index       = $::opendaylight::params::ha_node_index,
  $security_group_mode = $::opendaylight::params::security_group_mode,
) inherits ::opendaylight::params {

  # Validate OS family
  case $::osfamily {
    'RedHat': {}
    'Debian': {
        warning('Debian has limited support, is less stable, less tested.')
    }
    default: {
        fail("Unsupported OS family: ${::osfamily}")
    }
  }

  # Validate OS
  case $::operatingsystem {
    centos, redhat: {
      if $::operatingsystemmajrelease != '7' {
        # RHEL/CentOS versions < 7 not supported as they lack systemd
        fail("Unsupported OS: ${::operatingsystem} ${::operatingsystemmajrelease}")
      } elsif defined('$::operatingsystemrelease') {
          if (versioncmp($::operatingsystemrelease, '7.3') < 0) {
            # Versions < 7.3 do not support stateful security groups
            $stateful_unsupported = true
          }
        }
    }
    fedora: {
      # Fedora distros < 22 are EOL as of 2015-12-01
      # https://fedoraproject.org/wiki/End_of_life
      if $::operatingsystemmajrelease < '22' {
        fail("Unsupported OS: ${::operatingsystem} ${::operatingsystemmajrelease}")
      }
    }
    ubuntu: {
      if $::operatingsystemmajrelease != '14.04' {
        # Only tested on 14.04
        fail("Unsupported OS: ${::operatingsystem} ${::operatingsystemmajrelease}")
      }
    }
    default: {
      fail("Unsupported OS: ${::operatingsystem}")
    }
  }
  # Build full list of features to install
  $features = union($default_features, $extra_features)

  class { '::opendaylight::install': } ->
  class { '::opendaylight::config': } ~>
  class { '::opendaylight::service': } ->
  Class['::opendaylight']
}
