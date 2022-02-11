#!/bin/bash

set -eu

if [[ $(uname -s) == Darwin ]]; then
  readonly MYDIR=$(cd "$(dirname "$(greadlink -f -n "${BASH_SOURCE[0]}" )" )" && pwd -P)
else
  readonly MYDIR=$(cd "$(dirname "$(readlink -f -n "${BASH_SOURCE[0]}" )" )" && pwd -P)
fi

SRW_APP_DIR="${MYDIR}/../../.."
COMP_DIR="${SRW_APP_DIR}/comp_conf"
SRC_DIR="${SRW_APP_DIR}/src/fv3gfs_aqm"
BUILD_DIR="${SRW_APP_DIR}/build/fv3gfs_aqm"
BIN_DIR="${SRW_APP_DIR}/bin/"

# Detect MACHINE
source ${COMP_DIR}/detect_machine.sh

###########################################################
## User specific parameters                              ##
###########################################################
##
COMPILER="${COMPILER:-intel}"
##
###########################################################

echo "MACHINE:" ${MACHINE}
echo "COMPILER:" ${COMPILER}

# Module file name
if [[ "${MACHINE}" == "wcoss_cray" || "${MACHINE}" == "wcoss_dell_p3" ]]; then
  MODULE_FN="${MACHINE}/fv3"
else
  MODULE_FN="${MACHINE}.${COMPILER}/fv3"
fi

echo "Moduel file name:" ${MODULE_FN}

# Load modules
module purge
module use ${SRC_DIR}/modulefiles
module load ${MODULE_FN}
module list

# Copy module file to env
cp "${SRC_DIR}/modulefiles/${MODULE_FN}" "${COMP_DIR}/RRFS-CMAQ/env/modulefile.fv3gfs_aqm"

cp -r "${SRC_DIR}" "${BUILD_DIR}"

cd "${BUILD_DIR}/NEMS"

mkdir -p ${BIN_DIR}

gmake -j app=coupledFV3_AQM build 2>&1 | tee log.build.fv3gfs_aqm

cp "${BUILD_DIR}/NEMS/exe/NEMS.x" "${BIN_DIR}/NEMS.x"

echo "fv3gfs_aqm executable NEMS.x has been copied to bin"

