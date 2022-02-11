#!/bin/bash

set -eu

if [[ $(uname -s) == Darwin ]]; then
  readonly MYDIR=$(cd "$(dirname "$(greadlink -f -n "${BASH_SOURCE[0]}" )" )" && pwd -P)
else
  readonly MYDIR=$(cd "$(dirname "$(readlink -f -n "${BASH_SOURCE[0]}" )" )" && pwd -P)
fi

SRW_APP_DIR="${MYDIR}/../../.."
COMP_DIR="${SRW_APP_DIR}/comp_conf"
SRC_DIR="${SRW_APP_DIR}/src/JEDI"
BUILD_DIR="${SRW_APP_DIR}/build/JEDI"
BIN_DIR="${SRW_APP_DIR}/bin/"

# Detect MACHINE
source ${COMP_DIR}/detect_machine.sh

echo "MACHINE:" ${MACHINE}
if [[ ${MACHINE} != "hera" ]]; then
  echo "This machine is not supported!"
  exit
fi

cp -r ${SRC_DIR} ${BUILD_DIR}
mkdir -p ${BIN_DIR}

cd ${BUILD_DIR}
mkdir -p build
cd build

module purge
source ${COMP_DIR}/RRFS-CMAQ-DA/env/modulefile.build.hera.JEDI
module list

ecbuild -DMPIEXEC_EXECUTABLE=‘which srun‘ -DMPIEXEC_NUMPROC_FLAG="-n" ../ 
make -j 8

cd ${BIN_DIR}
ln -sf ${BUILD_DIR}/build/bin/fv3jedi* .

echo "The JEDI executables have been linked to bin."
