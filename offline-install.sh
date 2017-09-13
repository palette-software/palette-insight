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

# Prevent pip to look for newer pip version online
export PIP_DISABLE_PIP_VERSION_CHECK=1

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

install_suitable_psycopg2() {
    PIP_COMMAND=$1
    SUCCESS=0
    INSTALL_LOG=psycopg2_install.log
    echo "Installing psycopg2 from local packages with ${PIP_COMMAND}"
    for PSYCOPG2_PACKAGE in ${INSTALL_PIP_DIR}/psycopg2/*; do
        ${PIP_COMMAND} install ${PSYCOPG2_PACKAGE} >> ${INSTALL_LOG} 2>&1
	if [ $? -eq 0 ]; then
            SUCCESS=1;
            break;
        fi
    done

    if [ ${SUCCESS} -eq 1 ]; then
        echo "Successfully ${PIP_COMMAND} installed psycopg2"
        rm -f ${INSTALL_LOG}
    else
        >&2 echo "Failed to ${PIP_COMMAND} install psycopg2!"
        cat ${INSTALL_LOG}
        rm -f ${INSTALL_LOG}
        exit 1
    fi
}

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
pip install ${INSTALL_PIP_DIR}/argparse*
pip install ${INSTALL_PIP_DIR}/Jinja2*
pip install ${INSTALL_PIP_DIR}/Mako*
pip install ${INSTALL_PIP_DIR}/meld3*
pip install ${INSTALL_PIP_DIR}/six*
pip install ${INSTALL_PIP_DIR}/pyjade*
pip install ${INSTALL_PIP_DIR}/PyYAML*
pip install ${INSTALL_PIP_DIR}/supervisor*

# Install psycopg2 package supported on this platform
install_suitable_psycopg2 pip

# Because of Supervisorctl
pip3 install ${INSTALL_PIP_DIR}/MarkupSafe*
pip3 install ${INSTALL_PIP_DIR}/Jinja2*
pip3 install ${INSTALL_PIP_DIR}/Mako*
pip3 install ${INSTALL_PIP_DIR}/six*
pip3 install ${INSTALL_PIP_DIR}/pyjade*
pip3 install ${INSTALL_PIP_DIR}/PyYAML*

# Install psycopg2 package supported on this platform
install_suitable_psycopg2 pip3

# Install Palette Insight
${YUM_PALETTE} palette-insight
