#   Disable any prep shell actions. replace them with simply 'true'
# %define __spec_prep_post true
# %define __spec_prep_pre true
#   Disable any build shell actions. replace them with simply 'true'
# %define __spec_build_post true
# %define __spec_build_pre true
#   Disable any install shell actions. replace them with simply 'true'
# %define __spec_install_post true
# %define __spec_install_pre true
#   Disable any clean shell actions. replace them with simply 'true'
# %define __spec_clean_post true
# %define __spec_clean_pre true
# Disable checking for unpackaged files ?
#%undefine __check_files

# # Use md5 file digest method.
# # The first macro is the one used in RPM v4.9.1.1
# %define _binary_filedigest_algorithm 1
# # This is the macro I find on OSX when Homebrew provides rpmbuild (rpm v5.4.14)
# %define _build_binary_file_digest_algo 1
# 
# # Use bzip2 payload compression
# %define _binary_payload w9.bzdio

# Enable bash specific commands (eg. pushd)
%define _buildshell /bin/bash
Name: palette-insight
Version: %{version}
Release: %{buildrelease}
Summary: Installer of the Palette Insight product
Group: default
License: Proprietary
Vendor: Palette Software
URL: http://www.palette-software.com
Packager: Palette Developers <developers@palette-software.com>
BuildArch: noarch
# Disable Automatic Dependency Processing
AutoReqProv: no
# Add prefix, must not end with / except for root (/)
Prefix: /
# Seems specifying BuildRoot is required on older rpmbuild (like on CentOS 5)
# fpm passes '--define buildroot ...' on the commandline, so just reuse that.
# BuildRoot: %buildroot


Requires: palette-insight-toolkit palette-insight-website
Requires: palette-insight-agent palette-insight-server
Requires: palette-greenplum-installer palette-insight-gp-import palette-insight-reporting-framework

%description
Installer of the Palette Insight product

# Empty files otherwise package is not built
%files
