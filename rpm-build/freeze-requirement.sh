#!/usr/bin/env bash

# Example usage:
#     ./freeze-requirement.sh <package_name> <target-spec-file>

set -e

# Check arg count
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <package_name> <target-spec-file>"
  exit 1
fi

PACKAGE_NAME=$1
TARGET_SPEC_FILE=$2

# Query the latest RPM version number of the specified package
LATEST_VERSION_NOARCH=$(curl https://rpm.palette-software.com/centos/dev/noarch/ | grep ${PACKAGE_NAME} | sed -e"s/.*${PACKAGE_NAME}-[v]*\([0-9.-]*\)\.noarch.*/\1/g")
LATEST_VERSION_X86_64=$(curl https://rpm.palette-software.com/centos/dev/x86_64/ | grep ${PACKAGE_NAME} | sed -e"s/.*${PACKAGE_NAME}-[v]*\([0-9.-]*\)\.x86_64.*/\1/g")
echo -e "Latest noarch:"
echo "${LATEST_VERSION_NOARCH}"
echo -e "Latest x86_64:"
echo "${LATEST_VERSION_X86_64}"
echo -e "\n\nSummarized:"
LATEST_VERSION=$(echo -e "${LATEST_VERSION_NOARCH}\n${LATEST_VERSION_X86_64}" | sort -V | tail -1)
# Replace the requirement line in the specified spec file
# For example this script would turn a line like this
#   Requires: palette-insight-agent
# into
#   Requires: palette-insight-agent = 2.0.11
sed -i "s/Requires: ${PACKAGE_NAME}/Requires: ${PACKAGE_NAME} = ${LATEST_VERSION}/g" ${TARGET_SPEC_FILE}
