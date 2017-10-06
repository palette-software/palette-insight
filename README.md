[![Build Status](https://travis-ci.org/palette-software/palette-insight.svg?branch=master)](https://travis-ci.org/palette-software/palette-insight)

# Palette Insight Installer
One RPM package above all Palette Insight related RPM packages.

This package is supposed to be the last one being installed during updates, so this package's post install steps can be used to perform custom commands during Palette Insight updates.

# Installation

### Open ports
Make sure that the following ports are allowed both for inbound and outbound connections by your firewall:
* 22 (SSH)
* 80, 443 (HTTP, HTTPS)
* 5432 (PostgreSql)

### Make sure Palette RPM repository is enabled

IUS and EPEL repositories are needed. Make sure you install the propriate packages from here:
https://ius.io/GettingStarted/

```
centos@ip-10-47-14-86:~$ sudo vi /etc/yum.repos.d/palette.repo
[palette-rpm]
name=Palette RPM
baseurl=https://palette-rpm.brilliant-data.net/centos/stable
enabled=1
gpgcheck=0
```

### Install

To install all Palette Insight server side components just execute the following:

`sudo yum install -y palette-insight`

Make sure that there is no error in the output of the `yum` command above, and make sure that `/var/log/palette-insight-reporting/install-data-model.log` file is created and it contains a line like this at the end:
```
-------------------- OK --------------------
```

The only thing that you need to do to have a fully functional Insight Server is to set a license key. Any GUID would do as a license key as of this project has been open sourced. Just run the following script as root and you are done:
```
/etc/palette-insight-server/set-license-key.sh <GUID>
```

# Palette Insight Architecture

![GitHub Logo](https://github.com/palette-software/palette-insight/blob/master/insight-system-diagram.png?raw=true)

# Log file locations
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
