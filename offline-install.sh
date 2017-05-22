#!/bin/bash

# /data must be at least 200GB
export PALETTE_REQUIRED_DATA_PARTITION_SIZE=209612596

INSTALL_ROOT_DIR=$(dirname $0)

pushd ${INSTALL_ROOT_DIR}/rpm
INSTALL_RPM_DIR=$(pwd)
popd

pushd ${INSTALL_ROOT_DIR}/pip
INSTALL_PIP_DIR=$(pwd)
popd

pushd ${INSTALL_RPM_DIR}
yum localinstall -y --disablerepo="*" createrepo-0.9.9-26.el6.noarch.rpm python-deltarpm-3.5-0.5.20090913git.el6.x86_64.rpm deltarpm-3.5-0.5.20090913git.el6.x86_64.rpm libxml2-python-2.7.6-21.el6_8.1.x86_64.rpm libxml2-2.7.6-21.el6_8.1.x86_64.rpm
createrepo .
popd

cat > /etc/yum.repos.d/palettelocal.repo << EOF
[palettelocal]
name=Palette Local
baseurl=file://${INSTALL_RPM_DIR}
enabled=1
gpgcheck=0
EOF

YUM_PALETTE='yum install -y --disablerepo=* --enablerepo=palettelocal'

# For pip install
${YUM_PALETTE} python-pip python35u-pip
${YUM_PALETTE} postgresql-devel postgresql-libs gcc python-devel python35u-devel

${YUM_PALETTE} palette-insight-toolkit # Insight user and pip3

pip install ${INSTALL_PIP_DIR}/MarkupSafe* # for Mako
pip install ${INSTALL_PIP_DIR}/*

# Because of Supervisorctl
pip3 install ${INSTALL_PIP_DIR}/MarkupSafe*
pip3 install ${INSTALL_PIP_DIR}/Jinja2*
pip3 install ${INSTALL_PIP_DIR}/Mako*
pip3 install ${INSTALL_PIP_DIR}/six*
pip3 install ${INSTALL_PIP_DIR}/pyjade*
pip3 install ${INSTALL_PIP_DIR}/PyYAML*
pip3 install ${INSTALL_PIP_DIR}/psycopg2*

# Workaround the updated packages issue

${YUM_PALETTE} libyaml

ln -s /usr/lib64/libyaml-0.so.2 /usr/lib64/libyaml-0.so.1

${YUM_PALETTE} openssl098e-0.9.8e

ln -s /usr/lib64/libcrypto.so.0.9.8e /usr/lib64/libcrypto.so.0.9.8
ln -s /usr/lib64/libssl.so.0.9.8e /usr/lib64/libssl.so.0.9.8

# Install Palette Insight
${YUM_PALETTE} palette-insight
