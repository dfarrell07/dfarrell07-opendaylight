# == Class: opendaylight::repos
#
# Manages the installation of the OpenDaylight repositories for RedHat and
# Debian
#
# === Parameters
#
# [*deb_repo*]
#  The name of the debppa repo to configure. Ignored if on a RHEL based system.
#  Defaults to $::opendaylight::deb_repo
#
# [*rpm_repo*]
#  The name of the rpm repo to configure. Ignored if on a Debian based system
#  Defaults to $::opendaylight::rpm_repo
#
# [*rpm_repo_enabled*]
#  Flag to indicate if the the rpm repo should be enabled or disabled.
#  Defualts to 1.
#
# [*rpm_repo_gpgcheck*]
#  Flag to indicate if the rpm repo should be configured with gpgcheck.
#  Defaults to 0.
#
class opendaylight::repos (
  $deb_repo          = $::opendaylight::deb_repo,
  $rpm_repo          = $::opendaylight::rpm_repo,
  $rpm_repo_enabled  = 1,
  $rpm_repo_gpgcheck = $::opendaylight::rpm_repo_gpgcheck,
  $baseurl = $::opendaylight::baseurl,
) inherits ::opendaylight {
  if $::osfamily == 'RedHat' {
    # Add OpenDaylight's Yum repository
    yumrepo { $rpm_repo:
      # 'ensure' isn't supported with Puppet <3.5
      # Seems to default to present, but docs don't say
      # https://docs.puppetlabs.com/references/3.4.0/type.html#yumrepo
      # https://docs.puppetlabs.com/references/3.5.0/type.html#yumrepo
      baseurl  => $baseurl,
      descr    => 'OpenDaylight SDN Controller',
      enabled  => $rpm_repo_enabled,
      # NB: RPM signing is an active TODO, but is not done. We will enable
      #     this gpgcheck once the RPM supports it.
      gpgcheck => $rpm_repo_gpgcheck,
    }
  } elsif ($::osfamily == 'Debian') {
    include ::apt

    # Add ODL ppa repository
    apt::ppa{ $deb_repo: }
  } else {
    fail("Unknown operating system method: ${::osfamily}")
  }
}
