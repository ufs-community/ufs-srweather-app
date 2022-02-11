#!/bin/bash

set -eu

if [[ $(uname -s) == Darwin ]]; then
  readonly MYDIR=$(cd "$(dirname "$(greadlink -f -n "${BASH_SOURCE[0]}" )" )" && pwd -P)
else
  readonly MYDIR=$(cd "$(dirname "$(readlink -f -n "${BASH_SOURCE[0]}" )" )" && pwd -P)
fi

SRW_APP_DIR="${MYDIR}/../../.."
COMP_DIR="${SRW_APP_DIR}/comp_conf"
SRC_DIR="${SRW_APP_DIR}/src/gefs2clbcs_para"
BUILD_DIR="${SRW_APP_DIR}/build/gefs2clbcs_para"
BIN_DIR="${SRW_APP_DIR}/bin/"

# Detect MACHINE
source ${COMP_DIR}/detect_machine.sh

# Module file name
MODULE_FN="setup_${MACHINE}.sh"

echo "Moduel file name:" ${MODULE_FN}

# Load modules
module purge
. ${SRC_DIR}/${MODULE_FN}
module list

# Copy module file to env
cp "${SRC_DIR}/${MODULE_FN}" "${COMP_DIR}/RRFS-CMAQ/env/modulefile.gefs2clbc"

cp -r "${SRC_DIR}" "${BUILD_DIR}"

cd ${BUILD_DIR}

mkdir -p ${BIN_DIR}

make

mkdir -p ${BIN_DIR}

cp "${BUILD_DIR}/gefs2lbc_para" "${BIN_DIR}/gefs2lbc_para"

echo "gefs2lbc_para has been copied to bin"
