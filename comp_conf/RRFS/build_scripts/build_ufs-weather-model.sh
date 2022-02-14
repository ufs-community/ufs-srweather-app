#!/bin/bash

set -eu

if [[ $(uname -s) == Darwin ]]; then
  readonly MYDIR=$(cd "$(dirname "$(greadlink -f -n "${BASH_SOURCE[0]}" )" )" && pwd -P)
else
  readonly MYDIR=$(cd "$(dirname "$(readlink -f -n "${BASH_SOURCE[0]}" )" )" && pwd -P)
fi

SRW_APP_DIR="${MYDIR}/../../.."
COMP_DIR="${SRW_APP_DIR}/comp_conf"
SRC_DIR="${SRW_APP_DIR}/src/ufs-weather-model"
BUILD_DIR="${SRW_APP_DIR}/build/ufs-weather-model"
BIN_DIR="${SRW_APP_DIR}/bin/"

# Detect MACHINE
source ${COMP_DIR}/detect_machine.sh

###########################################################
## User specific parameters                              ##
###########################################################
##
COMPILER="${COMPILER:-intel}"
##
CCPP_SUITES="${CCPP_SUITES:-FV3_GFS_v15_thompson_mynn_lam3km}"
##
CMAKE_FLAGS="-DAPP=ATM -D32BIT=ON -DINLINE_POST=ON"
##
###########################################################

echo "MACHINE:" ${MACHINE}
echo "COMPILER:" ${COMPILER}

# Module file
if [[ "${MACHINE}" == "wcoss_cray" || "${MACHINE}" == "wcoss_dell_p3" || 
      "${MACHINE}" == "wcoss2" ]]; then
  MODULE_FN="ufs_${MACHINE}"
else
  MODULE_FN="ufs_${MACHINE}.${COMPILER}"
fi

echo "Moduel file name:" ${MODULE_FN}

# Load modules
module purge
module use ${SRC_DIR}/modulefiles
module load ${MODULE_FN}
module list

# Copy module file to env
cp "${SRC_DIR}/modulefiles/${MODULE_FN}" "${COMP_DIR}/env/modulefile.ufs-weather-model"
cp "${SRC_DIR}/modulefiles/ufs_common" "${COMP_DIR}/env/ufs_common"

# Set cmake environment
source ../../cmake_env_machine.sh

export ESMFMKFILE=${ESMFMKFILE:?"Please set ESMFMKFILE environment variable"}

CMAKE_FLAGS+=" -DCCPP_SUITES=${CCPP_SUITES}"
[[ -n "${MAPL_ROOT:-""}" ]] && CMAKE_FLAGS+=" -DCMAKE_MODULE_PATH=${MAPL_ROOT}/share/MAPL/cmake"

echo "CMAKE_C_COMPILER:" ${CMAKE_C_COMPILER}
echo "CMAKE_CXX_COMPILER:" ${CMAKE_CXX_COMPILER}
echo "CMAKE_Fortran_COMPILER:" ${CMAKE_Fortran_COMPILER}
echo "CMAKE_Platform:" ${CMAKE_Platform}
echo "ESMFMKFILE:" ${ESMFMKFILE}
echo "CMAKE_FLAGS:" ${CMAKE_FLAGS}

mkdir -p ${BUILD_DIR}
mkdir -p ${BIN_DIR}

cd ${BUILD_DIR}
cmake -DCMAKE_INSTALL_PREFIX=${SRW_APP_DIR} ${SRC_DIR} ${CMAKE_FLAGS}
# Turn off OpenMP threading for parallel builds
# to avoid exhausting the number of user processes
OMP_NUM_THREADS=1 make -j8 VERBOSE=${BUILD_VERBOSE:-}

cp "${BUILD_DIR}/ufs_model" "${BIN_DIR}/ufs_model"
