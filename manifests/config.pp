# == Class opendaylight::config
#
# This class handles ODL config changes.
# It's called from the opendaylight class.
#
class opendaylight::config {
  # Configuration of Karaf features to install
  file { 'org.apache.karaf.features.cfg':
    ensure => file,
    path   => '/opt/opendaylight/etc/org.apache.karaf.features.cfg',
    # Set user:group owners
    owner  => 'odl',
    group  => 'odl',
  }
  $features_csv = join($opendaylight::features, ',')
  file_line { 'featuresBoot':
    path  => '/opt/opendaylight/etc/org.apache.karaf.features.cfg',
    line  => "featuresBoot=${features_csv}",
    match => '^featuresBoot=.*$',
  }

  # Configuration of ODL NB REST port to listen on
  file { 'jetty.xml':
    ensure  => file,
    path    => '/opt/opendaylight/etc/jetty.xml',
    # Set user:group owners
    owner   => 'odl',
    group   => 'odl',
    # Use a template to populate the content
    content => template('opendaylight/jetty.xml.erb'),
  }

  # Set any custom log levels
  file { 'org.ops4j.pax.logging.cfg':
    ensure  => file,
    path    => '/opt/opendaylight/etc/org.ops4j.pax.logging.cfg',
    # Set user:group owners
    owner   => 'odl',
    group   => 'odl',
    # Use a template to populate the content
    content => template('opendaylight/org.ops4j.pax.logging.cfg.erb'),
  }

  # Configure ODL HA if enabled
  $ha_node_count = count($::opendaylight::ha_node_ips)
  if $::opendaylight::enable_ha {
    if $ha_node_count >= 2 {
      # Configure ODL OSVDB Clustering
      $ha_node_ip_str = join($::opendaylight::ha_node_ips, ' ')
      exec { 'Configure ODL OVSDB Clustering':
        command => "configure_cluster.sh ${::opendaylight::ha_node_index} ${ha_node_ip_str}",
        path    => '/opt/opendaylight/bin/:/usr/sbin:/usr/bin:/sbin:/bin',
        creates => '/opt/opendaylight/configuration/initial/akka.conf'
      }
    } else {
      fail("Number of HA nodes less than 2: ${ha_node_count} and HA Enabled")
    }
  }

  # Configure ACL security group
  # Requires at least CentOS 7.3 for RHEL/CentOS systems
  if ('odl-netvirt-openstack' in $opendaylight::features) {
    if $opendaylight::security_group_mode == 'stateful' {
      if defined('$opendaylight::stateful_unsupported') and $opendaylight::stateful_unsupported {
          warning("Stateful is unsupported in ${::operatingsystemrelease} setting to 'learn'")
          $sg_mode = 'learn'
      } else {
        $sg_mode = 'stateful'
      }
    } else {
      $sg_mode = $opendaylight::security_group_mode
    }

    $odl_datastore = [
      '/opt/opendaylight/etc/opendaylight',
      '/opt/opendaylight/etc/opendaylight/datastore',
      '/opt/opendaylight/etc/opendaylight/datastore/initial',
      '/opt/opendaylight/etc/opendaylight/datastore/initial/config',
    ]

    file { $odl_datastore:
      ensure => directory,
      mode   => '0755',
      owner  => 'odl',
      group  => 'odl',
    }
    -> file { 'netvirt-aclservice-config.xml':
      ensure  => file,
      path    => '/opt/opendaylight/etc/opendaylight/datastore/initial/config/netvirt-aclservice-config.xml',
      owner   => 'odl',
      group   => 'odl',
      content => template('opendaylight/netvirt-aclservice-config.xml.erb'),
    }
  }

  #configure VPP routing node
  if ! empty($::opendaylight::vpp_routing_node) {
    file { 'org.opendaylight.groupbasedpolicy.neutron.vpp.mapper.cfg':
      ensure => file,
      path   => '/opt/opendaylight/etc/org.opendaylight.groupbasedpolicy.neutron.vpp.mapper.cfg',
      owner  => 'odl',
      group  => 'odl',
    }
    file_line { 'routing-node':
      path  => '/opt/opendaylight/etc/org.opendaylight.groupbasedpolicy.neutron.vpp.mapper.cfg',
      line  => "routing-node=${::opendaylight::vpp_routing_node}",
      match => '^routing-node=.*$',
    }
  }

  # Configure username/password
  odl_user { $::opendaylight::username:
    password => $::opendaylight::password,
    before   => Service['opendaylight'],
  }
}
