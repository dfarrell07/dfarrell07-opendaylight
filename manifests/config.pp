# == Class opendaylight::config
#
# This class handles ODL config changes.
# It's called from the opendaylight class.
#
# === Parameters
# [*odl_rest_port *]
#   Port for ODL northbound REST interface to listen on.
#
class opendaylight::config (
  $odl_rest_port = $::opendaylight::params::odl_rest_port
) inherits ::opendaylight::params {
  # Ideally, ODL's version wouldn't be in the path, to make this more robust
  file { 'org.apache.karaf.features.cfg':
    ensure  => file,
    path    => "/opt/${opendaylight::odl_target_name}/etc/org.apache.karaf.features.cfg",
    content => template('opendaylight/org.apache.karaf.features.cfg.erb'),
  }

  # TODO: Is this include needed?
  include stdlib
  # TODO: Better var name (this is from PR #35)
  # TODO: Consider moving to a template, for consistency
  $myline= "    <Connector port=\"${odl_rest_port}\" protocol=\"HTTP/1.1\""
  file_line { 'tomcatport':
    ensure => present,
    # Ideally, ODL's version wouldn't be in the path, to make this more robust
    path   => "/opt/${opendaylight::odl_target_name}/configuration/tomcat-server.xml",
    line   => $myline,
    match  => '^\s*<Connector\s*port=\"[0-9]+\"\s*protocol=\"HTTP\/1.1\"$',
  }
}
