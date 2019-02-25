[![Build Status](https://travis-ci.org/palette-software/palette-insight.svg?branch=master)](https://travis-ci.org/palette-software/palette-insight)

# Palette Insight Installer
One RPM package above all Palette Insight related RPM packages.

This package is supposed to be the last one being installed during updates, so this package's post install steps can be used to perform custom commands during Palette Insight updates.

## Prerequisites

### Machine requirements
Red Hat Enterprise Linux or CentOS version 6 or 7.3+
* CPU: 8 vCPU
* Memory: 16 GB
* Volumes:
  * 10 GB system
  * 32GB Swap Memory
  * 1 TB data (3 TB recommended) mounted under `/data` and formatted as [XFS](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/storage_administration_guide/ch-xfs)
* Recommended network access to:
  * https://palette-rpm.brilliant-data.net
  * http://mirror.centos.org

### Open ports
Make sure that the following ports are allowed both for inbound and outbound connections by your firewall:
* 22 (SSH)
* 80, 443 (HTTP, HTTPS)
* 5432 (PostgreSql)

### Enable required RPM repositories

#### IUS and EPEL repositories

IUS and EPEL repositories are needed. Make sure you install the propriate packages from here:
https://ius.io/GettingStarted/

#### Palette RPM repository

```
$ sudo tee /etc/yum.repos.d/palette.repo << EOF
[palette-rpm]
name=Palette RPM
baseurl=https://palette-rpm.brilliant-data.net/centos/stable
enabled=1
gpgcheck=0
EOF
```

### Data folder

The Palette Insight and the [Greenplum Database](https://github.com/palette-software/greenplum-installer) store significant amount of data under the `/data` directory. Please make sure to set it up according to the [Machine requirements](#machine-requirements).

## Install

### Final check before install

1. The `/data` folder exists
1. IUS and EPEL repositories are added
1. Palette RPM repository added
1. Ports are open on firewall

### Install

To install all Palette Insight server side components just execute the following:

`sudo yum install -y palette-insight`

### Post install check

Make sure that there is no error in the output of the `yum` command above, and make sure that `/var/log/palette-insight-reporting/install-data-model.log` file is created and it contains a line like this at the end:

```
-------------------- OK --------------------
```

### Post install configuration

The only thing that you need to do to have a fully functional Insight Server is to set a license key. Any GUID would do as a license key as of this project has been open sourced. Just run the following script as root and you are done:

```
/etc/palette-insight-server/set-license-key.sh <GUID>
```

### Update
If there is an update available in our [Palette RPM](http://palette-rpm.brilliant-data.net/) repository, you can update Palette Insight 2 ways:
1. Click on the `Update` button on your Insight Server's control page (http://your-insight-server-url/control)
<img src="https://github.com/palette-software/PaletteInsightAgent/blob/master/docs/resources/insight-server-control-page.png" alt="Insight Server Control Page" width="400" >
2. Via command line:

```
su - insight
/opt/insight-toolkit/update.sh
```

## Palette Insight Architecture

![GitHub Logo](https://github.com/palette-software/palette-insight/blob/master/insight-system-diagram.png?raw=true)

## Log file locations
Here are the log file locations on the Insight Server for each Palette Insight components:
* palette-insight-server: `/var/log/palette-insight-server/palette-insight-server.log`
* palette-greenplum-installer: `/var/log/greenplum/service.log`
* palette-insight-gp-import:
  * `/var/log/insight-gp-import/loadtables.log`
  * `/var/log/insight-gpfdist/insight-gpfdist.log`
* palette-insight-reporting-framework:
  * `/var/log/insight-reporting-framework/reporting.log`
  * `/var/log/insight-reporting-framework/reporting_delta.log`
  * `/var/log/insight-reporting-framework/loadctrl.log`
  * `/var/log/insight-reporting-framework/db_maintenance.log`
* palette-insight-website: `/var/log/palette-insight-website/website.log`

And here are the log files that can be found on your Tableau Server machines:
* palette-insight-agent: `<PALETTE_INSIGHT_INSTALL_DIR>\Logs\PaletteInsightAgent.nlog.txt`
* palette-updater:
  * `<PALETTE_INSIGHT_INSTALL_DIR>\Logs\watchdog.log`
  * `<PALETTE_INSIGHT_INSTALL_DIR>\Logs\manager.log` (this file only exists if Palette Insight Agent was auto updated at least once)
  * `<PALETTE_INSIGHT_INSTALL_DIR>\Logs\installer.log` (this file only exists if Palette Insight Agent was auto updated at least once)
