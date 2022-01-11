#!/bin/bash

set -eu

MYDIR=$(cd "$(dirname "$(readlink -f -n "${BASH_SOURCE[0]}" )" )" && pwd -P)
cd ${MYDIR}

SRC_DIR="${MYDIR}/../../src/fv3gfs_aqm/NEMS"
BIN_DIR="${MYDIR}/../../bin"

cd ${SRC_DIR}

gmake -j app=coupledFV3_AQM build 2>&1 | tee log.build.fv3gfs_aqm

mkdir -p ${BIN_DIR}

cp exe/NEMS.x "${BIN_DIR}/"

echo "fv3gfs_aqm executable NEMS.x has been copied to bin"

exit 0
