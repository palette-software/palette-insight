#!/bin/bash

# /data must be at least 200GB
export PALETTE_REQUIRED_DATA_PARTITION_SIZE=209612596

INSTALL_ROOT_DIR=$(dirname $0)

if [ ! -d ${INSTALL_ROOT_DIR}/rpm ]; then
    echo "${INSTALL_ROOT_DIR}/rpm does not exist"
    exit 1
fi

if [ ! -d ${INSTALL_ROOT_DIR}/pip ]; then
    echo "${INSTALL_ROOT_DIR}/pip does not exist"
    exit 1
fi

pushd ${INSTALL_ROOT_DIR}/rpm
INSTALL_RPM_DIR=$(pwd)
popd

pushd ${INSTALL_ROOT_DIR}/pip
INSTALL_PIP_DIR=$(pwd)
popd

pushd ${INSTALL_RPM_DIR}
CREATEREPO_PACKAGES="createrepo-0.9.9-28.el7.noarch.rpm deltarpm-3.6-3.el7.x86_64.rpm python-deltarpm-3.6-3.el7.x86_64.rpm"
yum localinstall -y --disablerepo="*" ${CREATEREPO_PACKAGES}
createrepo .
popd

cat > /etc/yum.repos.d/palettelocal.repo << EOF
[palettelocal]
name=Palette Local
baseurl=file://${INSTALL_RPM_DIR}
enabled=1
gpgcheck=0
EOF

YUM_PALETTE='yum install -y --enablerepo=palettelocal'

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



# Install Palette Insight
${YUM_PALETTE} palette-insight
