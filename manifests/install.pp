# == Class opendaylight::install
#
# Manages the installation of OpenDaylight.
#
# There are two install methods: RPM-based and tarball-based. The resulting
# system state should be functionally equivalent, but we have to do more
# work here for the tarball method (would normally be handled by the RPM).
#
class opendaylight::install {
  if $opendaylight::install_method == 'rpm' {
    # Add OpenDaylight's Yum repository
    yumrepo { $opendaylight::rpm_repo:
      # 'ensure' isn't supported with Puppet <3.5
      # Seems to default to present, but docs don't say
      # https://docs.puppetlabs.com/references/3.4.0/type.html#yumrepo
      # https://docs.puppetlabs.com/references/3.5.0/type.html#yumrepo
      baseurl  => "http://cbs.centos.org/repos/nfv7-${opendaylight::rpm_repo}/\$basearch/os/",
      descr    => 'OpenDaylight SDN Controller',
      enabled  => 1,
      # NB: RPM signing is an active TODO, but is not done. We will enable
      #     this gpgcheck once the RPM supports it.
      gpgcheck => 0,
      before   => Package['opendaylight'],
    }

    # Install the OpenDaylight RPM
    package { 'opendaylight':
      ensure  => present,
      require => Yumrepo[$opendaylight::rpm_repo],
    }
    ->
    # Configure the systemd file to force ipv4 binds (instead of ipv6)
    file_line { 'odl_start_ipv4 ':
      ensure => present,
      path   => '/usr/lib/systemd/system/opendaylight.service',
      line   => 'Environment=_JAVA_OPTIONS=\'-Djava.net.preferIPv4Stack=true\'',
      after  => 'ExecStart=/opt/opendaylight/bin/start',
    }
    ->
    exec {'reload_systemd_units':
      command => 'systemctl daemon-reload',
      path    => '/bin'
    }
  }
  elsif $opendaylight::install_method == 'tarball' {
    # Install Java 7
    $package = $::osfamily ? {
      'RedHat' => 'java-1.7.0-openjdk',
      'Debian' => 'openjdk-7-jdk',
    }
    class { 'java':
      # NB: ODL is currently in the process of moving to Java 8
      package => $package,
    }

    # Create and configure the odl user
    user { 'odl':
      ensure     => present,
      # Must be a valid dir for the auto-creation of some files
      home       => '/opt/opendaylight/',
      # The odl user should, at the minimum, be a member of the odl group
      membership => 'minimum',
      groups     => 'odl',
      # The odl user's home dir should exist before the user is created
      # The odl group, to which the odl user will belong, should exist
      require    => [Archive['opendaylight'], Group['odl']],
      # The odl user will own this dir, user should exist before we set owner
      before     => File['/opt/opendaylight/'],
    }

    # Create and configure the odl group
    group { 'odl':
      ensure => present,
      # The odl user will be a member of this group, create it first
      # The odl user will own ODL's dir, so should exist before owner set 
      before => [File['/opt/opendaylight/'], User['odl']],
    }

    # Download and extract the ODL tarball
    archive { 'opendaylight':
      ensure           => present,
      # URL from which ODL's tarball can be downloaded
      url              => $opendaylight::tarball_url,
      # Will end up installing /opt/opendaylight/
      target           => '/opt/opendaylight/',
      # ODL doesn't provide a checksum in the expected path, would fail
      checksum         => false,
      # This discards top-level dir of extracted tarball
      # Required to get proper /opt/opendaylight/ path
      strip_components => 1,
      root_dir         => '.',
      # Default timeout is 120s, which may not be enough. See Issue #53:
      # https://github.com/dfarrell07/puppet-opendaylight/issues/53
      timeout          => 600,
      # ODL's archive should be dl'd/extracted before we config mode/user/group
      # The odl user will set this to their home dir, should exist before user
      before           => [File['/opt/opendaylight/'], User['odl']],
    }

    # Set the user:group owners and mode of ODL dir
    file { '/opt/opendaylight/':
      # ensure=>dir and recurse=>true are required for managing recursively
      ensure  => 'directory',
      recurse => true,
      # Set user:group owners of ODL dir
      owner   => 'odl',
      group   => 'odl',
      # The ODL archive we're modifying should exist
      # Since ODL's dir is owned by odl:odl, that user:group should exist
      require => [Archive['opendaylight'], Group['odl'], User['odl']],
    }

    # Systemd vs upstart config depends on OS family
    if ( $::osfamily == 'RedHat' ) {
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
    }
    elsif ( $::osfamily == 'Debian' ) {
      file { '/etc/init/opendaylight.conf':
        # It should be a normal file
        ensure => 'file',
        # Set user:group owners of ODL upstart file
        # NB: Unverfied, not sure if this is correct for upstart
        owner  => 'root',
        group  => 'root',
        # Set mode of ODL upstart file
        # NB: Unverfied, not sure if this is correct for upstart
        mode   => '0644',
        # Use Puppet URL for Travis. File stored in <mod name>/files/
        source => 'puppet:///modules/opendaylight/upstart.odl.conf'
      }
    }
    else {
      fail("Unsupported OS family: ${::osfamily}")
    }
  }
  else {
    fail("Unknown install method: ${opendaylight::install_method}")
  }
}
