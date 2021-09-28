#!/bin/bash

set -eu

##### User's choice ##########

FCST_MODEL="fv3gfs_aqm"
MACHINE="hera"
COMPILER="intel"

DA_opt="YES"
##############################

### ========================================================================

# cd to location of script
MYDIR=$(cd "$(dirname "$(readlink -f -n "${BASH_SOURCE[0]}" )" )" && pwd -P)
SCRIPT_DIR="${MYDIR}/${FCST_MODEL}"
ORG_DIR="${MYDIR}/.."

# Suffix for DA 
if ["${DA_opt}"="YES"] || ["${DA_opt}"="yes"]; then
  DA_add="_DA"
  echo "... ## !!! for DA !!! ## ..."
else
  DA_add=""
  echo "... ## !!! for free-forecast (non-DA) !!! ## ..."
fi 

echo "... update config and env ..."
# External components
cp ${SCRIPT_DIR}/${FCST_MODEL}_Externals${DA_add}.cfg ${ORG_DIR}/Externals.cfg
# CMakeLists in src
cp ${SCRIPT_DIR}/${FCST_MODEL}_src_CMakeLists${DA_add}.txt ${ORG_DIR}/src/CMakeLists.txt
# Build environment file for components
cp ${SCRIPT_DIR}/${FCST_MODEL}_build_${MACHINE}_${COMPILER}.env ${ORG_DIR}/env/build_${MACHINE}_${COMPILER}.env


exit 0
