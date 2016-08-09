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

  # Enable or disable ODL OVSDB ML2 L3 forwarding
  file { 'custom.properties':
    ensure  => file,
    path    => '/opt/opendaylight/etc/custom.properties',
    # Set user:group owners
    owner   => 'odl',
    group   => 'odl',
    # Use a template to populate the content
    content => template('opendaylight/custom.properties.erb'),
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
      # Configuration Jolokia XML for HA
      file { 'opendaylight/jolokia.xml':
        ensure => file,
        path   => '/opt/opendaylight/deploy/jolokia.xml',
        # Set user:group owners
        owner  => 'odl',
        group  => 'odl',
        source => 'puppet:///modules/opendaylight/jolokia.xml',
      }

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

  # Configure DHCP service
  file { 'dhcpservice-impl-default-config.xml':
    ensure  => file,
    path    => '/opt/opendaylight/etc/opendaylight/karaf/dhcpservice-impl-default-config.xml',
    # Set user:group owners
    owner   => 'odl',
    group   => 'odl',
    # Use a template to populate the content
    content => template('opendaylight/dhcpservice-impl-default-config.xml.erb'),
  }
}
