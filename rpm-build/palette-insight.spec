# Enable bash specific commands (eg. pushd)
%define _buildshell /bin/bash

# As we are not adding any file to this package, it would attempt to
# package the contents of the rpm-build directory, and would complain
# about "installed, but unpackaged" files. Overcome that by disabling
# the following macro.
%define _unpackaged_files_terminate_build 0

Name: palette-insight
Version: %{version}
Release: %{buildrelease}
Summary: Installer of the Palette Insight product
Group: default
License: Proprietary
Vendor: Palette Software
URL: http://www.palette-software.com
Packager: Palette Developers <developers@palette-software.com>
BuildArch: x86_64
# Disable Automatic Dependency Processing
AutoReqProv: no
# Add prefix, must not end with / except for root (/)
Prefix: /
# Seems specifying BuildRoot is required on older rpmbuild (like on CentOS 5)
# fpm passes '--define buildroot ...' on the commandline, so just reuse that.
# BuildRoot: %buildroot

# Travis is going to freeze the versions of these requirements by adding
# a specific version to the end of each line
Requires: palette-insight-toolkit
Requires: palette-insight-website
Requires: palette-insight-agent
Requires: palette-insight-server
Requires: palette-insight-gp-import
Requires: palette-insight-reporting

%description
Installer of the Palette Insight product

%clean
# noop

# Empty files otherwise package is not built
%files
