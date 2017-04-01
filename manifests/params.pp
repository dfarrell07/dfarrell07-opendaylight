# == Class opendaylight::params
#
# This class manages the default params for the ODL class.
#
class opendaylight::params {
  # NB: If you update the default values here, you'll also need to update:
  #   spec/spec_helper_acceptance.rb's install_odl helper fn
  #   spec/classes/opendaylight_spec.rb tests that use default Karaf features
  # Else, both the Beaker and RSpec tests will fail
  # TODO: Remove this possible source of bugs^^
  $default_features = ['config', 'standard', 'region', 'package', 'kar', 'ssh', 'management']
  $extra_features = []
  $odl_rest_port = '8080'
  $odl_bind_ip = '0.0.0.0'
  $rpm_repo = 'opendaylight-6-testing'
  $deb_repo = 'ppa:odl-team/boron'
  $rpm_repo_gpgcheck = 0
  $log_levels = {}
  $enable_ha = false
  $ha_node_ips = []
  $ha_node_index = 0
  $security_group_mode = 'stateful'
  $vpp_routing_node = ''
  $java_opts = '-Djava.net.preferIPv4Stack=true'
  $manage_repositories = true
}
