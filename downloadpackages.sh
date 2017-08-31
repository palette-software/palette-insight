#!/bin/bash

BUNDLE_ROOT_DIR="palette"
BUNDLE_RPM_DIR="${BUNDLE_ROOT_DIR}/rpm"

yum install --downloadonly --downloaddir=${BUNDLE_RPM_DIR} createrepo
yum install --downloadonly --downloaddir=${BUNDLE_RPM_DIR} palette-insight

BUNDLE_PIP_DIR="${BUNDLE_ROOT_DIR}/pip"

pip download --dest ${BUNDLE_PIP_DIR} argparse
pip download --dest ${BUNDLE_PIP_DIR} jinja2 psycopg2 pyyaml
pip download --dest ${BUNDLE_PIP_DIR} Mako==1.0.4 pyjade==4.0.0
pip download --dest ${BUNDLE_PIP_DIR} meld3==1.0.1 supervisor==3.2.3
