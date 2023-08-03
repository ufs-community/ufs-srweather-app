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

# Normalize Parallel Works cluster platform value.
declare platform
if [[ "${SRW_PLATFORM}" =~ ^(az|g|p)clusternoaa ]]; then
    platform='noaacloud'
else
    platform="${SRW_PLATFORM}"
fi

# Build and install
cd ${workspace}/tests
set +e
./build.sh ${platform} ${SRW_COMPILER}
build_exit=$?
set -e
cd -

# Create combined log file for upload to s3
build_dir="${workspace}/build_${SRW_COMPILER}"
cat ${build_dir}/log.cmake ${build_dir}/log.make \
    >${build_dir}/srw_build-${platform}-${SRW_COMPILER}.txt

exit $build_exit
