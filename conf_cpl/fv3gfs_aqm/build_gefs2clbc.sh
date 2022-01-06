#!/bin/bash

set -eu

MYDIR=$(cd "$(dirname "$(readlink -f -n "${BASH_SOURCE[0]}" )" )" && pwd -P)
cd ${MYDIR}

# Detect MACHINE
source ${MYDIR}/../detect_machine.sh
echo "MACHINE:" $MACHINE

if [ "${MACHINE}" = "wcoss_dell_p3" ]; then
  MACHINE="wcoss_dell"
  echo "MACHINE (SHORT):" $MACHINE
fi

SRC_DIR="${MYDIR}/../../src/gefs2clbcs_para"
BIN_DIR="${SRC_DIR}/../../bin"

cd ${SRC_DIR}

. ./setup_${MACHINE}.sh

make

mkdir -p ${BIN_DIR}

cp gefs2lbc_para ${BIN_DIR}/gefs2lbc_para

echo "gefs2lbc_para has been copied to bin"

exit 0
