#!/bin/bash
set -eu

if [[ $(uname -s) == Darwin ]]; then
  readonly ENV_DIR=$(cd "$(dirname "$(greadlink -f -n "${BASH_SOURCE[0]}" )" )" && pwd -P)
else
  readonly ENV_DIR=$(cd "$(dirname "$(readlink -f -n "${BASH_SOURCE[0]}" )" )" && pwd -P)
fi

cd ${ENV_DIR}

source detect_machine.sh
echo "MACHINE:" ${MACHINE}

####################
COMPILER="intel"
####################
echo "COMPILER:" ${COMPILER}

ENV_FILE="build_${MACHINE}_${COMPILER}.env"

echo "ENV FILE:" ${ENV_FILE}

module use ${ENV_DIR}

source ${ENV_FILE}

module list

BUILD_DIR=${ENV_DIR}/../build

mkdir -p ${BUILD_DIR}
cd ${BUILD_DIR}

cmake .. -DCMAKE_INSTALL_PREFIX=..

echo "================================================================================="
echo " App building begins, check ${BUILD_DIR}/build.out "
echo "================================================================================="

make -j 8 >& build.out &
