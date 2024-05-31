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
if [[ -d "${WORKSPACE}/${SRW_PLATFORM}" ]]; then
    workspace="${WORKSPACE}/${SRW_PLATFORM}"
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
export we2e_experiment_base_dir="${workspace}/expt_dirs"
export we2e_test_dir="${workspace}/tests/WE2E"

# Clean any stale test logs
rm -f ${workspace}/tests/WE2E/log.*
rm -f ${we2e_experiment_base_dir}/*/log.generate_FV3LAM_wflow ${we2e_experiment_base_dir}/*/log/* WE2E_summary*txt

# Run the end-to-end tests.
if "${SRW_WE2E_COMPREHENSIVE_TESTS}"; then
    export test_type="comprehensive"
else
    export test_type=${SRW_WE2E_SINGLE_TEST:-"coverage"}
    if [[ "${test_type}" = skill-score ]]; then
        export test_type="grid_SUBCONUS_Ind_3km_ics_FV3GFS_lbcs_FV3GFS_suite_WoFS_v0"
    fi
fi

cd ${we2e_test_dir}
# Progress file
progress_file="${workspace}/we2e_test_results-${SRW_PLATFORM}-${SRW_COMPILER}.txt"
/usr/bin/time -p -f '{\n  "cpu": "%P"\n, "memMax": "%M"\n, "mem": {"text": "%X", "data": "%D", "swaps": "%W", "context": "%c", "waits": "%w"}\n, "pagefaults": {"major": "%F", "minor": "%R"}\n, "filesystem": {"inputs": "%I", "outputs": "%O"}\n, "time": {"real": "%e", "user": "%U", "sys": "%S"}\n}' -o ${WORKSPACE}/${SRW_PLATFORM}-${SRW_COMPILER}-time-srw_test.json \
    ./setup_WE2E_tests.sh ${platform} ${SRW_PROJECT} ${SRW_COMPILER} ${test_type} \
    --expt_basedir=${we2e_experiment_base_dir} | tee ${progress_file}; \
    [[ -f ${we2e_experiment_base_dir}/grid_SUBCONUS_Ind_3km_ics_FV3GFS_lbcs_FV3GFS_suite_WoFS_v0/log.generate_FV3LAM_wflow ]] && ${workspace}/.cicd/scripts/srw_metric.sh run_stat_anly

# Set exit code to number of failures
set +e
failures=$(grep " DEAD    " ${progress_file} | wc -l)
if [[ $failures -ne 0 ]]; then
    failures=1
fi
set -e
exit ${failures}
