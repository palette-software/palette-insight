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

# Palette Insight Architecture

![GitHub Logo](https://github.com/palette-software/palette-insight/blob/master/insight-system-diagram.png?raw=true)
