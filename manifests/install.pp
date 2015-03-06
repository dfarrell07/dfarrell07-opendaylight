# == Class opendaylight::install
#
# Manages the installation of OpenDaylight.
#
class opendaylight::install {
  if $opendaylight::install_method == 'rpm' {
    # Choose Yum URL based on OS (CentOS vs Fedora)
    $base_url = $::operatingsystem ? {
      'CentOS' => 'https://copr-be.cloud.fedoraproject.org/results/dfarrell07/OpenDaylight/epel-7-$basearch/',
      'Fedora' => 'https://copr-be.cloud.fedoraproject.org/results/dfarrell07/OpenDaylight/fedora-$releasever-$basearch/',
    }

    # Add OpenDaylight's Yum repository
    yumrepo { 'opendaylight':
      # 'ensure' isn't supported with Puppet <3.5
      # Seems to default to present, but docs don't say
      # https://docs.puppetlabs.com/references/3.4.0/type.html#yumrepo
      # https://docs.puppetlabs.com/references/3.5.0/type.html#yumrepo
      baseurl  => $base_url,
      descr    => 'OpenDaylight SDN controller',
      gpgcheck => 0,
      enabled  => 1,
      before   => Package['opendaylight'],
    }

    # Install the OpenDaylight RPM
    package { 'opendaylight':
      ensure  => present,
      require => Yumrepo['opendaylight'],
    }
  }
  elsif $opendaylight::install_method == 'tarball' {
    
    # Install Java 7
    $package = $::osfamily ? {
      'RedHat' => 'java-1.7.0-openjdk',
      'Debian' => 'java7-jdk',
    }
    class { 'java':
      # NB: ODL is currently in the process of moving to Java 8
      package => $package,
    }

    # Create and configure the `odl` user
    user { 'odl':
      ensure     => present,
      # Must be a valid dir for the auto-creation of some files
      home       => "/opt/${opendaylight::odl_target_name}",
      # The odl user should, at the minimum, be a member of the odl group
      membership => 'minimum',
      groups     => 'odl',
      # The odl user's home dir should exist before it's created
      # The odl group, to which the odl user will below, should exist
      require    => [Archive[$opendaylight::odl_target_name], Group['odl']],
      before     => File["/opt/${opendaylight::odl_target_name}"],
    }

    # Create and configure the `odl` group
    group { 'odl':
      ensure => present,
      # The `odl` user will be a member of this group, create it first
      before => [File["/opt/${opendaylight::odl_target_name}"], User['odl']],
    }

    # Download and extract the ODL tarball
    archive { $opendaylight::odl_target_name:
      ensure           => present,
      url              => $opendaylight::tarball_url,
      # Will end up installing /opt/opendaylight-0.2.2
      target           => "/opt/${opendaylight::odl_target_name}",
      # ODL doesn't provide a checksum in the expected path, would fail
      checksum         => false,
      # This discards top-level dir of extracted tarball
      # Required to get proper /opt/opendaylight-<version> path
      strip_components => 1,
      # Default timeout is 120s, which may not be enough. See Issue #53:
      # https://github.com/dfarrell07/puppet-opendaylight/issues/53
      timeout          => 600,
      # The odl user will set this to their home dir, should exist
      before              => [File["/opt/${opendaylight::odl_target_name}"], User['odl']],
    }
    
    # Set the user:group owners and mode of ODL dir
    file { "/opt/${opendaylight::odl_target_name}":
      # ensure=>dir and recurse=>true are required for managing recursively
      ensure  => 'directory',
      recurse => true,
      # Set user:group owners of ODL dir
      owner   => 'odl',
      group   => 'odl',
      # Set mode of ODL dir
      mode    => '0775',
      # Should happen after archive extracted and user/group created
      require => [Archive[$opendaylight::odl_target_name], Group['odl'], User['odl']],
    }
    
    if ( $::osfamily == 'redhat' ){
        # Download ODL systemd .service file and put in right location
        archive { 'opendaylight-systemd':
          ensure           => present,
          url              => $opendaylight::unitfile_url,
          # Will end up installing /usr/lib/systemd/system/opendaylight.service
          target           => '/usr/lib/systemd/system/',
          # Required by archive mod for correct exec `creates` param
          root_dir         => 'opendaylight.service',
          # ODL doesn't provide a checksum in the expected path, would fail
          checksum         => false,
          # This discards top-level dir of extracted tarball
          # Required to get proper /opt/opendaylight-<version> path
          strip_components => 1,
          # May end up with an HTML redirect output in a text file without this
          # Note that the curl'd down file would still have a .tar.gz name
          follow_redirects => true,
          # Should exist before we try to set its user/group/mode
          before           => File['/usr/lib/systemd/system/opendaylight.service'],
        }  

        # Set the user:group owners and mode of ODL's systemd .service file
        file { '/usr/lib/systemd/system/opendaylight.service':
          # It should be a normal file
          ensure  => 'file',
          # Set user:group owners of ODL systemd .service file
          owner   => 'root',
          group   => 'root',
          # Set mode of ODL systemd .service file
          mode    => '0644',
          # Should happen after the ODL systemd .service file has been extracted
          require => Archive['opendaylight-systemd'],
        }
    }else{
        
    }
    
  }
  else {
    fail("Unknown install method: ${opendaylight::install_method}")
  }
}
