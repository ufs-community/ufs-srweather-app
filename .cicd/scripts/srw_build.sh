#!/usr/bin/env bash
#
# A unified build script for the SRW application. This script is expected to
# build the SRW application for all supported platforms.
#
set -e -u -x

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)"

# Get repository root from Jenkins WORKSPACE variable if set, otherwise, set
# relative to script directory.
declare workspace
if [[ -n "${WORKSPACE}" ]]; then
    workspace="${WORKSPACE}"
else
    workspace="$(cd -- "${script_dir}/../.." && pwd)"
fi

build_dir="${workspace}/build"

# Set build related environment variables and load required modules.
source "${workspace}/etc/lmod-setup.sh" "${SRW_PLATFORM}"
module use "${workspace}/modulefiles"
module load "build_${SRW_PLATFORM}_${SRW_COMPILER}"

# Compile SRW application and install to repository root.
mkdir "${build_dir}"
pushd "${build_dir}"
    cmake -DCMAKE_INSTALL_PREFIX="${workspace}" -DENABLE_RRFS=on "${workspace}"
    make -j "${MAKE_JOBS}"
popd
