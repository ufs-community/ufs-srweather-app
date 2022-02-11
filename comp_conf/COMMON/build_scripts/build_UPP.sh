#!/bin/bash

set -eu

if [[ $(uname -s) == Darwin ]]; then
  readonly MYDIR=$(cd "$(dirname "$(greadlink -f -n "${BASH_SOURCE[0]}" )" )" && pwd -P)
else
  readonly MYDIR=$(cd "$(dirname "$(readlink -f -n "${BASH_SOURCE[0]}" )" )" && pwd -P)
fi

SRW_APP_DIR="${MYDIR}/../../.."
COMP_DIR="${SRW_APP_DIR}/comp_conf"
SRC_DIR="${SRW_APP_DIR}/src/UPP"
BUILD_DIR="${SRW_APP_DIR}/build/UPP"
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

# File name suffix
if [[ "${MACHINE}" == "wcoss2" ]]; then
  FN_SFX=".lua"
else
  FN_SFX=""
fi

MODULE_FN="${MACHINE}${FN_SFX}"

echo "Moduel file name:" ${MODULE_FN}

# Load modules
module purge
module use ${SRC_DIR}/modulefiles
module load ${MODULE_FN}
module list

# Copy module file to env
cp "${SRC_DIR}/modulefiles/${MODULE_FN}" "${COMP_DIR}/COMMON/env/modulefile.UPP${FN_SFX}"

# Set cmake environment
source ../../cmake_env_machine.sh

echo "CMAKE_C_COMPILER:" ${CMAKE_C_COMPILER}
echo "CMAKE_CXX_COMPILER:" ${CMAKE_CXX_COMPILER}
echo "CMAKE_Fortran_COMPILER:" ${CMAKE_Fortran_COMPILER}
echo "CMAKE_Platform:" ${CMAKE_Platform}

mkdir -p ${BUILD_DIR}
mkdir -p ${BIN_DIR}

cd ${BUILD_DIR}
cmake -DCMAKE_INSTALL_PREFIX=${SRW_APP_DIR} ${SRC_DIR}
make -j4
make install
