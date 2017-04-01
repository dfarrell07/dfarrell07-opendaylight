[![CI Status][4]][1]
[![Dependency Status][5]][2]

# OpenDaylight

#### Table of Contents

1. [Overview](#overview)
2. [Module Description](#module-description)
3. [Setup](#setup)

- [What `opendaylight` affects](#what-opendaylight-affects)
- [Beginning with `opendaylight`](#beginning-with-opendaylight)

4. [Usage](#usage)

- [Karaf Features](#karaf-features)
- [RPM Repo](#rpm-repo)
- [Deb Repo](#deb-repo)
- [Ports](#ports)
- [Log Verbosity](#log-verbosity)
- [Enabling ODL HA](#enabling-odl-ha)

5. [Reference ](#reference)
6. [Limitations](#limitations)
7. [Development](#development)
8. [Release Notes/Contributors](#release-notescontributors)

## Overview

Puppet module that installs and configures the [OpenDaylight Software Defined
Networking (SDN) controller][7].

## Module Description

Deploys OpenDaylight to various OSs either via an RPM or a Deb.

All OpenDaylight configuration should be handled through the ODL Puppet
module's [params](#parameters). If you need a new knob, [please raise an
Issue][8].

By default, the master branch installs OpenDaylight from the latest testing RPM repository
or from the latest stable Deb repository depending on the OS. There are stable/<release>
branches that install OpenDaylight releases and service releases, like Beryllium or Beryllium SR3.

## Setup

### What `opendaylight` affects

- Installs Java, which is required by ODL.
- Creates `odl:odl` user:group if they don't already exist.
- Installs [OpenDaylight][7].
- Installs a [systemd unitfile][9] for OpenDaylight.
- Manipulates OpenDaylight's configuration files according to the params
  passed to the `::opendaylight` class.
- Starts the `opendaylight` systemd service.

### Beginning with `opendaylight`

Getting started with the OpenDaylight Puppet module is as simple as declaring
the `::opendaylight` class.

The [vagrant-opendaylight][11] project provides an easy way to experiment with
[applying the ODL Puppet module][12] to VMs.

```
# Provision a CentOS VM using puppet-opendaylight
$ vagrant up cent7_pup_rpm
$ vagrant ssh cent7_pup_rpm
$ sudo systemctl is-active opendaylight
active
```

## Usage

The most basic usage, passing no parameters to the OpenDaylight class, will
install and start OpenDaylight with a default configuration.

```puppet
class { 'opendaylight':
}
```

### Karaf Features

To set extra Karaf features to be installed at OpenDaylight start time, pass
them in a list to the `extra_features` param. The extra features you pass will
typically be driven by the requirements of your ODL install. You'll almost
certainly need to pass some.

```puppet
class { 'opendaylight':
  extra_features => ['odl-netvirt-openstack'],
}
```

OpenDaylight normally installs a default set of Karaf features at boot. They
are recommended, so the ODL Puppet mod defaults to installing them. This can
be customized by overriding the `default_features` param. You shouldn't
normally need to do so.

```puppet
class { 'opendaylight':
  default_features => ['config', 'standard', 'region', 'package', 'kar', 'ssh', 'management'],
}
```

### RPM Repo

The `rpm_repo` param can be used to configure which RPM repository
OpenDaylight is installed from.

```puppet
class { 'opendaylight':
  rpm_repo => 'opendaylight-40-release',
}
```

The naming convention follows the naming convention of the CentOS Community
Build System, which is where upstream ODL hosts its RPMs. The
`opendaylight-40-release` example above would install OpenDaylight Beryllium
4.0.0 from the [nfv7-opendaylight-40-release][18] repo. Repo names ending in
`-release` will always contain well-tested, officially released versions of
OpenDaylight. Repos ending in `-testing` contain frequent, but unstable and
unofficial, releases. The ODL version given in repo names shows which major
and minor version it is pinned to. The `opendaylight-40-release` repo will
always provide OpenDaylight Beryllium 4.0, whereas `opendaylight-4-release`
will provide the latest release with major version 4 (which could include
Service Releases, like SR2 4.2).

For a full list of OpenDaylight releases and their CBS repos, see the
[OpenDaylight Deployment wiki][19].

This is only read for RedHat based operating systems. For Debian based OSs,
this values is `none`.

It's also possible to use the baseurl parameter to have a custom repository.

```puppet
class { 'opendaylight':
  rpm_repo => 'opendaylight-5-testing',
  baseurl => 'http://cbs.centos.org/repos/nfv7-opendaylight-5-testing/$basearch/os/'
}
```
To disable the repository (For example when a repository for OpenDaylight already exists) use:

```puppet
class { 'opendaylight':
  manage_repositories => false,
}
```

### Deb Repo

The `deb_repo` param can be used to configure which Deb repository
OpenDaylight is installed from.

```puppet
class { 'opendaylight':
  deb_repo => 'ppa:odl-team/boron',
}
```

The naming convention is same as the naming convention of Launchpad PPA's,
which is where ODL .debs are hosted. The `ppa:odl-team/boron` example above
would install OpenDaylight Boron realease from the [odl-team's boron][20] repo.

This is only read for Debian based operating systems. For RedHat based OSs,
this values is `none`.

### Ports

To change the port on which OpenDaylight's northbound listens for REST API
calls, use the `odl_rest_port` param.

```puppet
class { 'opendaylight':
  odl_rest_port => '8080',
}
```

### Log Verbosity

It's possible to define custom logger verbosity levels via the `log_levels`
param.

```puppet
class { 'opendaylight':
  log_levels => { 'org.opendaylight.ovsdb' => 'TRACE', 'org.opendaylight.ovsdb.lib' => 'INFO' },
}
```

### Enabling ODL HA

To enable ODL HA, use the `enable_ha` flag. It's disabled by default.

When `enable_ha` is set to true the `ha_node_ips` should be populated with the
IP addresses that ODL will listen on for each node in the HA cluster and
`ha_node_index` should be set with the index of the IP address from
`ha_node_ips` for the particular node that puppet is configuring as part of the
HA cluster.

```puppet
class { 'opendaylight':
  enable_ha     => true,
  ha_node_ips   => ['10.10.10.1', '10.10.10.1', '10.10.10.3'],
  ha_node_index => 0,
}
```

## Reference

### Classes

#### Public classes

- `::opendaylight`: Main entry point to the module. All ODL knobs should be
  managed through its params.

#### Private classes

- `::opendaylight::params`: Contains default `opendaylight` class param values.
- `::opendaylight::install`: Installs ODL from an RPM or a Deb.
- `::opendaylight::config`: Manages ODL config, including Karaf features and
  REST port.
- `::opendaylight::service`: Starts the OpenDaylight service.

### `::opendaylight`

#### Parameters

##### `default_features`

Sets the Karaf features to install by default. These should not normally need
to be overridden.

Default: `['config', 'standard', 'region', 'package', 'kar', 'ssh', 'management']`

Valid options: A list of Karaf feature names as strings.

##### `extra_features`

Specifies Karaf features to install in addition to the defaults listed in
`default_features`.

You will likely need to customize this to your use-case.

Default: `[]`

Valid options: A list of Karaf feature names as strings.

##### `odl_rest_port`

Specifies the port for the ODL northbound REST interface to listen on.

Default: `'8080'`

Valid options: A valid port number as a string or integer.

##### `rpm_repo`

OpenDaylight CentOS CBS repo to install RPM from (opendaylight-4-testing,
opendaylight-40-release, ...).

##### `deb_repo`

OpenDaylight Launchpad PPA repo to install .deb from (ppa:odl-team/boron,
ppa:odl-team/carbon, ...).

##### `log_levels`

Custom OpenDaylight logger verbosity configuration.

Default: `{}`

Valid options: A hash of loggers to log levels.

```
{ 'org.opendaylight.ovsdb' => 'TRACE', 'org.opendaylight.ovsdb.lib' => 'INFO' }
```

Valid log levels are TRACE, DEBUG, INFO, WARN, and ERROR.

The above example would add the following logging configuration to
`/opt/opendaylight/etc/org.ops4j.pax.logging.cfg`.

```
# Log level config added by puppet-opendaylight
log4j.logger.org.opendaylight.ovsdb = TRACE

# Log level config added by puppet-opendaylight
log4j.logger.org.opendaylight.ovsdb.lib = INFO
```

To view loggers and their verbosity levels, use `log:list` at the ODL Karaf shell.

```
opendaylight-user@root>log:list
Logger                     | Level
----------------------------------
ROOT                       | INFO
org.opendaylight.ovsdb     | TRACE
org.opendaylight.ovsdb.lib | INFO
```

The main log output file is `/opt/opendaylight/data/log/karaf.log`.

##### `enable_ha`

Enable or disable ODL High Availablity.

Default: `false`

Valid options: The boolean values `true` and `false`.

Requires: `ha_node_ips`, `ha_node_index`

The ODL Clustering XML for HA are configured and enabled.

##### `ha_node_ips`

Specifies the IPs that are part of the HA cluster enabled by `enable_ha`.

Default: \[]

Valid options: An array of IP addresses `['10.10.10.1', '10.10.10.1', '10.10.10.3']`.

Required by: `enable_ha`

##### `ha_node_index`

Specifies the index of the IP for the node being configured from the array `ha_node_ips`.

Default: ''

Valid options: Index of a member of the array `ha_node_ips`: `0`.

Required by: `enable_ha`, `ha_node_ips`

##### `security_group_mode`

Specifies the mode to use for security groups.

Default: `stateful`

Valid options: `transparent`, `learn`, `stateless`

##### `vpp_routing_node`

Specifies the routing node for VPP deployment. A non-empty string will create config file
org.opendaylight.groupbasedpolicy.neutron.vpp.mapper.cfg with routing-node set.

Default: `''`

Valid options: A valid host name to a VPP node handling routing.

##### `java_opts`

Specifies the Java options to run ODL with as a string.

Default: `'-Djava.net.preferIPv4Stack=true'`

Valid options: A string of valid Java options.

## Limitations

- Tested on CentOS 7 and Ubuntu 16.04.
- Fedora is allowed but not well-tested, no Beaker coverage.

## Development

We welcome contributions and work to make them easy!

See [CONTRIBUTING.markdown][14] for details about how to contribute to the
OpenDaylight Puppet module.

## Release Notes/Contributors

See the [CHANGELOG][15] or our [git tags][16] for information about releases.
See our [git commit history][17] for contributor information.

[1]: https://travis-ci.org/dfarrell07/puppet-opendaylight

[2]: https://gemnasium.com/dfarrell07/puppet-opendaylight

[4]: https://travis-ci.org/dfarrell07/puppet-opendaylight.svg?branch=master

[5]: https://gemnasium.com/dfarrell07/puppet-opendaylight.svg?branch=master

[7]: http://www.opendaylight.org/

[8]: https://github.com/dfarrell07/puppet-opendaylight/blob/master/CONTRIBUTING.markdown#issues

[9]: https://github.com/dfarrell07/opendaylight-systemd/

[11]: https://github.com/dfarrell07/vagrant-opendaylight/

[12]: https://github.com/dfarrell07/vagrant-opendaylight/tree/master/manifests

[13]: https://github.com/dfarrell07/puppet-opendaylight/issues/63

[14]: https://github.com/dfarrell07/puppet-opendaylight/blob/master/CONTRIBUTING.markdown

[15]: https://github.com/dfarrell07/puppet-opendaylight/blob/master/CHANGELOG

[16]: https://github.com/dfarrell07/puppet-opendaylight/releases

[17]: https://github.com/dfarrell07/puppet-opendaylight/commits/master

[18]: http://cbs.centos.org/repos/nfv7-opendaylight-40-release/x86_64/os/Packages/ "OpenDaylight Beryllium CentOS CBS repo"

[18]: https://wiki.opendaylight.org/view/Deployment#RPM "OpenDaylight RPMs and their repos"

[20]: https://launchpad.net/~odl-team/+archive/ubuntu/boron
