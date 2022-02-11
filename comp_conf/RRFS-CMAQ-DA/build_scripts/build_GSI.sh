#!/bin/bash

set -eu

if [[ $(uname -s) == Darwin ]]; then
  readonly MYDIR=$(cd "$(dirname "$(greadlink -f -n "${BASH_SOURCE[0]}" )" )" && pwd -P)
else
  readonly MYDIR=$(cd "$(dirname "$(readlink -f -n "${BASH_SOURCE[0]}" )" )" && pwd -P)
fi

SRW_APP_DIR="${MYDIR}/../../.."
COMP_DIR="${SRW_APP_DIR}/comp_conf"
SRC_DIR="${SRW_APP_DIR}/src/gsi"
BUILD_DIR="${SRW_APP_DIR}/build/gsi"
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

./ush/build.comgsi

cp "${BUILD_DIR}/build/bin/gsi.x" ${BIN_DIR}

echo "The executable gsi.x has been copied to bin"
