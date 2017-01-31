[![Build Status](https://travis-ci.com/palette-software/palette-insight.svg?token=qWG5FJDvsjLrsJpXgxSJ&branch=master)](https://travis-ci.com/palette-software/palette-insight)

# Palette Insight Installer
One RPM package above all Palette Insight related RPM packages.

This package is supposed to be the last one being installed during updates, so this package's post install steps can be used to perform custom commands during Palette Insight updates.

# Installation

### Make sure Palette RPM repository is enabled

IUS and EPEL repositories are needed. The proxies for them are only needed when they are not directly available.

```
centos@ip-10-47-14-86:~$ sudo vi /etc/yum.repos.d/palette.repo
[palette-epel-proxy]
name=Palette Epel Proxy
baseurl=https://rpm.palette-software.com/epel-6
enabled=1
gpgcheck=0

[palette-ius-proxy]
name=Palette IUS Proxy
baseurl=https://rpm.palette-software.com/ius-6
enabled=1
gpgcheck=0

[palette-rpm]
name=Palette RPM
baseurl=https://rpm.palette-software.com/centos/stable
enabled=1
gpgcheck=0
```

### Install

To install all Palette Insight server side components just execute the following:  

`sudo yum install -y palette-insight`

# Palette Insight Architecture

![GitHub Logo](https://github.com/palette-software/palette-insight/blob/master/insight-system-diagram.png?raw=true)
