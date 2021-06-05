#!/bin/bash

set -eu

##### User's choice ##########

FCST_MODEL="fv3gfs_aqm"
MACHINE="wcoss_dell_p3"
COMPILER="intel"

##############################

### ========================================================================

#cd to location of script
MYDIR=$(cd "$(dirname "$(readlink -f -n "${BASH_SOURCE[0]}" )" )" && pwd -P)
SCRIPT_DIR="${MYDIR}/${FCST_MODEL}"
ORG_DIR="${MYDIR}/.."

echo "... update config and env ..."
# External components
cp ${SCRIPT_DIR}/${FCST_MODEL}_Externals.cfg ${ORG_DIR}/Externals.cfg
# CMakeLists in src
cp ${SCRIPT_DIR}/${FCST_MODEL}_src_CMakeLists.txt ${ORG_DIR}/src/CMakeLists.txt
# Build environment file for UFS_UTILS, arl_nexus, emc_post
cp ${SCRIPT_DIR}/${FCST_MODEL}_build_${MACHINE}_${COMPILER}.env ${ORG_DIR}/env/build_${MACHINE}_${COMPILER}.env


exit 0
