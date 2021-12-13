#!/bin/bash

set -eu

MYDIR=$(cd "$(dirname "$(readlink -f -n "${BASH_SOURCE[0]}" )" )" && pwd -P)
cd ${MYDIR}

##### User's choice ##########

FCST_MODEL="fv3gfs_aqm"
#MACHINE="hera"     # If set, the auto-detected MACHINE will be replaced with this value.
COMPILER="intel"

##############################

# Detect MACHINE
source detect_machine.sh
echo "MACHINE:" $MACHINE

SCRIPT_DIR="${MYDIR}/${FCST_MODEL}"
ORG_DIR="${MYDIR}/.."

echo "FCST_MODEL:" ${FCST_MODEL}
echo "COMPILER  :" ${COMPILER}
echo "... update config and env ..."
# External components
cp ${SCRIPT_DIR}/${FCST_MODEL}_Externals.cfg ${ORG_DIR}/Externals.cfg
# CMakeLists in src
cp ${SCRIPT_DIR}/${FCST_MODEL}_src_CMakeLists.txt ${ORG_DIR}/src/CMakeLists.txt
# Build environment file for UFS_UTILS, arl_nexus, emc_post
cp ${SCRIPT_DIR}/${FCST_MODEL}_build_${MACHINE}_${COMPILER}.env ${ORG_DIR}/env/build_${MACHINE}_${COMPILER}.env
echo "... updated ..."

exit 0
