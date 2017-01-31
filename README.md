[![Build Status](https://travis-ci.com/palette-software/palette-insight.svg?token=qWG5FJDvsjLrsJpXgxSJ&branch=master)](https://travis-ci.com/palette-software/palette-insight)

# Palette Insight Installer
One RPM package above all Palette Insight related RPM packages.

This package is supposed to be the last one being installed during updates, so this package's post install steps can be used to perform custom commands during Palette Insight updates.

# Installation

To install all Palette Insight server side components just execute the following:  

`sudo yum install -y palette-insight`

# Palette Insight Architecture

![GitHub Logo](https://github.com/palette-software/palette-insight/blob/master/insight-system-diagram.png?raw=true)
