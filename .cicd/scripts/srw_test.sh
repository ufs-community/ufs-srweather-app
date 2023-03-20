#!/usr/bin/env bash
#
# A unified test script for the SRW application. This script is expected to
# test the SRW application for all supported platforms. NOTE: At this time,
# this script is a placeholder for a more robust test framework.
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

# Test directories
we2e_experiment_base_dir="${workspace}/expt_dirs"
we2e_test_dir="${workspace}/tests/WE2E"
nco_dir="${workspace}/nco_dirs"

# Run the end-to-end tests.
if "${SRW_WE2E_COMPREHENSIVE_TESTS}"; then
    test_type="comprehensive"
else
    test_type="fundamental"
fi

cd ${we2e_test_dir}
# Progress file
progress_file="${workspace}/we2e_test_results-${platform}-${SRW_COMPILER}.txt"
./setup_WE2E_tests.sh ${platform} ${SRW_PROJECT} ${SRW_COMPILER} ${test_type} \
    --expt_basedir=${we2e_experiment_base_dir} \
    --opsroot=${nco_dir} | tee ${progress_file}

# Set exit code to number of failures
set +e
failures=$(grep " DEAD    " ${progress_file} | wc -l)
if [[ $failures -ne 0 ]]; then
    failures=1
fi
set -e
exit ${failures}
