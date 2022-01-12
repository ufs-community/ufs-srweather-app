#!/bin/bash

set -eu

MYDIR=$(cd "$(dirname "$(readlink -f -n "${BASH_SOURCE[0]}" )" )" && pwd -P)
cd ${MYDIR}

SRC_DIR="${MYDIR}/../../src/JEDI"
BIN_DIR="${SRC_DIR}/../../bin"

cd ${SRC_DIR}
mkdir -p build
cd build

module purge
source ${MYDIR}/JEDI_build_hera.env 
module list
ecbuild -DMPIEXEC_EXECUTABLE=‘which srun‘ -DMPIEXEC_NUMPROC_FLAG="-n" ../ 
make -j 8

cd ${BIN_DIR}
ln -sf ${SRC_DIR}/build/bin/fv3jedi* .

