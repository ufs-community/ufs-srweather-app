#!/bin/bash

set -eu

MYDIR=$(cd "$(dirname "$(readlink -f -n "${BASH_SOURCE[0]}" )" )" && pwd -P)
cd ${MYDIR}

SRC_DIR="${MYDIR}/../../src/gsi"
BIN_DIR="${SRC_DIR}/../../bin/"

cd ${SRC_DIR}

./ush/build.comgsi

cp build/bin/gsi.x ${BIN_DIR}
