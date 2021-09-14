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
SCRIPT_DIR="${MYDIR}/${FCST_MODEL}"
ORG_DIR="${MYDIR}/.."

echo "... update config and env ..."
echo "... ## !!! for DA !!! ## ..."
# External components
cp ${SCRIPT_DIR}/${FCST_MODEL}_Externals_DA.cfg ${ORG_DIR}/Externals.cfg
# CMakeLists in src
cp ${SCRIPT_DIR}/${FCST_MODEL}_src_CMakeLists_DA.txt ${ORG_DIR}/src/CMakeLists.txt
# Build environment file for components
cp ${SCRIPT_DIR}/${FCST_MODEL}_build_${MACHINE}_${COMPILER}.env ${ORG_DIR}/env/build_${MACHINE}_${COMPILER}.env


exit 0
