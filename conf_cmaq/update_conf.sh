#!/bin/bash

set -eu

##### User's choice ##########

FCST_MODEL="fv3gfs_aqm"
MACHINE="hera"
COMPILER="intel"

##############################

### ========================================================================

#cd to location of script
MYDIR=$(cd "$(dirname "$(readlink -f -n "${BASH_SOURCE[0]}" )" )" && pwd -P)

echo "... update config and env ..."
# External components
cp ${MYDIR}/${FCST_MODEL}_Externals.cfg ${MYDIR}/../Externals.cfg
# CMakeLists in src
cp ${MYDIR}/${FCST_MODEL}_src_CMakeLists.txt ${MYDIR}/../src/CMakeLists.txt
# Build environment file for UFS_UTILS, arl_nexus, emc_post
cp ${MYDIR}/${FCST_MODEL}_build_${MACHINE}_${COMPILER}.env ${MYDIR}/../env/build_${MACHINE}_${COMPILER}.env


exit 0
