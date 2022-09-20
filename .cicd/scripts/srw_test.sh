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

declare we2e_experiment_base_dir
if [[ -n "${SRW_WE2E_EXPERIMENT_BASE_DIR}" ]]; then
    we2e_experiment_base_dir="${SRW_WE2E_EXPERIMENT_BASE_DIR}"
else
    we2e_experiment_base_dir="${workspace}/experiments"
fi

we2e_test_dir="${workspace}/tests/WE2E"

we2e_test_file="${we2e_test_dir}/experiments.txt"

# The fundamental set of end-to-end tests to run.
declare -a we2e_fundamental_tests
we2e_fundamental_tests=('grid_RRFS_CONUS_25km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v16'
    'grid_RRFS_CONUS_25km_ics_FV3GFS_lbcs_FV3GFS_suite_RRFS_v1beta'
    'grid_RRFS_CONUS_25km_ics_FV3GFS_lbcs_RAP_suite_HRRR'
    'grid_RRFS_CONUS_25km_ics_NAM_lbcs_NAM_suite_HRRR'
    'grid_RRFS_CONUS_25km_ics_NAM_lbcs_NAM_suite_RRFS_v1beta'
    'grid_RRFS_CONUScompact_25km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v16'
    'grid_RRFS_CONUScompact_25km_ics_HRRR_lbcs_HRRR_suite_HRRR'
    'grid_RRFS_CONUScompact_25km_ics_HRRR_lbcs_RAP_suite_HRRR'
    'grid_RRFS_CONUScompact_25km_ics_HRRR_lbcs_RAP_suite_RRFS_v1beta'
    'grid_SUBCONUS_Ind_3km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v16'
    'grid_SUBCONUS_Ind_3km_ics_HRRR_lbcs_RAP_suite_HRRR'
    'grid_SUBCONUS_Ind_3km_ics_HRRR_lbcs_RAP_suite_RRFS_v1beta'
    'nco_grid_RRFS_CONUScompact_25km_ics_HRRR_lbcs_RAP_suite_HRRR'
    'community_ensemble_2mems'
    'custom_ESGgrid'
    'deactivate_tasks'
    'inline_post'
    'nco_ensemble'
    'specify_DOT_OR_USCORE'
    'specify_DT_ATMOS_LAYOUT_XY_BLOCKSIZE'
    'specify_RESTART_INTERVAL'
    'specify_template_filenames')

if [[ "${platform}" != 'gaea' && "${platform}" != 'noaacloud' ]]; then
    we2e_fundamental_tests+=('MET_ensemble_verification'
        'MET_verification'
        'pregen_grid_orog_sfc_climo')
fi

# The comprehensive set of end-to-end tests to run.
declare -a we2e_comprehensive_tests
we2e_comprehensive_tests=('community_ensemble_008mems'
    'custom_GFDLgrid'
    'custom_GFDLgrid__GFDLgrid_USE_NUM_CELLS_IN_FILENAMES_eq_FALSE'
    'custom_GFDLgrid__GFDLgrid_USE_NUM_CELLS_IN_FILENAMES_eq_TRUE'
    'get_from_HPSS_ics_FV3GFS_lbcs_FV3GFS_fmt_grib2_2019061200'
    'get_from_HPSS_ics_FV3GFS_lbcs_FV3GFS_fmt_grib2_2019101818'
    'get_from_HPSS_ics_FV3GFS_lbcs_FV3GFS_fmt_grib2_2020022518'
    'get_from_HPSS_ics_FV3GFS_lbcs_FV3GFS_fmt_grib2_2020022600'
    'get_from_HPSS_ics_FV3GFS_lbcs_FV3GFS_fmt_grib2_2021010100'
    'get_from_HPSS_ics_FV3GFS_lbcs_FV3GFS_fmt_nemsio'
    'get_from_HPSS_ics_FV3GFS_lbcs_FV3GFS_fmt_nemsio_2019061200'
    'get_from_HPSS_ics_FV3GFS_lbcs_FV3GFS_fmt_nemsio_2019101818'
    'get_from_HPSS_ics_FV3GFS_lbcs_FV3GFS_fmt_nemsio_2020022518'
    'get_from_HPSS_ics_FV3GFS_lbcs_FV3GFS_fmt_nemsio_2020022600'
    'get_from_HPSS_ics_FV3GFS_lbcs_FV3GFS_fmt_nemsio_2021010100'
    'get_from_HPSS_ics_FV3GFS_lbcs_FV3GFS_fmt_netcdf_2021062000'
    'get_from_HPSS_ics_GSMGFS_lbcs_GSMGFS'
    'get_from_HPSS_ics_HRRR_lbcs_RAP'
    'get_from_HPSS_ics_RAP_lbcs_RAP'
    'get_from_NOMADS_ics_FV3GFS_lbcs_FV3GFS_fmt_nemsio'
    'grid_CONUS_25km_GFDLgrid_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v16'
    'grid_CONUS_3km_GFDLgrid_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v16'
    'grid_RRFS_AK_13km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v16'
    'grid_RRFS_AK_3km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v16'
    'grid_RRFS_CONUS_13km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v15p2'
    'grid_RRFS_CONUS_13km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v16'
    'grid_RRFS_CONUS_13km_ics_FV3GFS_lbcs_FV3GFS_suite_HRRR'
    'grid_RRFS_CONUS_13km_ics_FV3GFS_lbcs_FV3GFS_suite_RRFS_v1beta'
    'grid_RRFS_CONUS_25km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_2017_gfdlmp'
    'grid_RRFS_CONUS_25km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_2017_gfdlmp_regional'
    'grid_RRFS_CONUS_25km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v15p2'
    'grid_RRFS_CONUS_25km_ics_FV3GFS_lbcs_FV3GFS_suite_HRRR'
    'grid_RRFS_CONUS_25km_ics_GSMGFS_lbcs_GSMGFS_suite_GFS_2017_gfdlmp'
    'grid_RRFS_CONUS_25km_ics_GSMGFS_lbcs_GSMGFS_suite_GFS_v15p2'
    'grid_RRFS_CONUS_25km_ics_GSMGFS_lbcs_GSMGFS_suite_GFS_v16'
    'grid_RRFS_CONUS_3km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v15_thompson_mynn_lam3km'
    'grid_RRFS_CONUS_3km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v15p2'
    'grid_RRFS_CONUS_3km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v16'
    'grid_RRFS_CONUS_3km_ics_FV3GFS_lbcs_FV3GFS_suite_HRRR'
    'grid_RRFS_CONUS_3km_ics_FV3GFS_lbcs_FV3GFS_suite_RRFS_v1beta'
    'grid_RRFS_CONUScompact_13km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v16'
    'grid_RRFS_CONUScompact_13km_ics_HRRR_lbcs_RAP_suite_HRRR'
    'grid_RRFS_CONUScompact_13km_ics_HRRR_lbcs_RAP_suite_RRFS_v1beta'
    'grid_RRFS_CONUScompact_25km_ics_HRRR_lbcs_HRRR_suite_RRFS_v1beta'
    'grid_RRFS_CONUScompact_3km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v16'
    'grid_RRFS_CONUScompact_3km_ics_HRRR_lbcs_RAP_suite_GFS_v15p2'
    'grid_RRFS_CONUScompact_3km_ics_HRRR_lbcs_RAP_suite_HRRR'
    'grid_RRFS_CONUScompact_3km_ics_HRRR_lbcs_RAP_suite_RRFS_v1beta'
    'grid_RRFS_NA_13km_ics_FV3GFS_lbcs_FV3GFS_suite_RRFS_v1beta'
    'grid_RRFS_NA_3km_ics_FV3GFS_lbcs_FV3GFS_suite_RRFS_v1beta'
    'grid_RRFS_SUBCONUS_3km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v16'
    'grid_RRFS_SUBCONUS_3km_ics_HRRR_lbcs_RAP_suite_GFS_v15p2'
    'nco_grid_RRFS_CONUS_13km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v16'
    'nco_grid_RRFS_CONUS_3km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v15_thompson_mynn_lam3km')

declare -a we2e_tests
we2e_tests=("${we2e_fundamental_tests[@]}")
if "${SRW_WE2E_COMPREHENSIVE_TESTS}"; then
    we2e_tests+=("${we2e_comprehensive_tests[@]}")

    # Add additional tests for Hera.
    if [[ "${platform}" == 'hera' ]]; then
        we2e_tests+=('specify_EXTRN_MDL_SYSBASEDIR_ICS_LBCS')
    fi
fi

# Parses the test log for the status of a specific test.
function workflow_status() {
    local test="$1"

    local test_dir="${we2e_experiment_base_dir}/${test}"
    local log_file="${test_dir}/log.launch_FV3LAM_wflow"

    if [[ -f "${log_file}" ]]; then
        local status
        status="$(awk 'BEGIN {FS=":";} $1 ~ "^[[:space:]]+Workflow status" {print $2}' "${log_file}" |\
            tail -1 |\
            sed --regexp-extended --expression 's/^[[:space:]]*(.*)[[:space:]]*$/\1/')"
        if [[ "${status}" == 'IN PROGRESS' || "${status}" == 'SUCCESS' || "${status}" == 'FAILURE' ]]; then
            echo "${status}"
        else
            echo 'UNKNOWN'
        fi
    else
        echo 'NOT FOUND'
    fi
}

# Gets the status of all tests. Prints the number of tests that are running.
# Returns a non-zero code when all tests reach a final state.
function check_progress() {
    local in_progress=false
    local remaining=0

    for test in "${we2e_tests[@]}"; do
        local status
        status="$(workflow_status "${test}")"
        if [[ "${status}" == 'IN PROGRESS' ]]; then
            in_progress=true
            (( remaining++ ))
        fi
    done

    if "${in_progress}"; then
        echo "Tests remaining: ${remaining}"
    else
        return 1
    fi
}

# Prints the status of all tests.
function get_results() {
    for test in "${we2e_tests[@]}"; do
        local status
        status="$(workflow_status "${test}")"
        echo "${test} ${status}"
    done
}

# Verify that there is a non-zero sized weather model executable.
[[ -s "${workspace}/bin/ufs_model" ]] || [[ -s "${workspace}/bin/NEMS.exe" ]]

# Set test related environment variables and load required modules.
source "${workspace}/etc/lmod-setup.sh" "${platform}"
module use "${workspace}/modulefiles"
module load "build_${platform}_${SRW_COMPILER}"
module load "wflow_${platform}"

if [[ "${platform}" == 'cheyenne' ]]; then
    export PATH="/glade/p/ral/jntp/UFS_CAM/ncar_pylib_20200427/bin:${PATH}"
else
    if [[ "${platform}" == 'noaacloud' && -z "${PROJ_LIB-}" ]]; then
        PROJ_LIB=''
    fi

    conda activate regional_workflow
fi

# Create the experiments/tests base directory.
mkdir "${we2e_experiment_base_dir}"

# Generate the experiments/tests file.
for test in "${we2e_tests[@]}"; do
    echo "${test}" >> "${we2e_test_file}"
done

# Run the end-to-end tests.
"${we2e_test_dir}/run_WE2E_tests.sh" \
    tests_file="${we2e_test_file}" \
    machine="${platform}" \
    account="${SRW_PROJECT}" \
    expt_basedir="${we2e_experiment_base_dir}" \
    compiler="${SRW_COMPILER}"

# Allow the tests to start before checking for status.
# TODO: Create a parameter that sets the initial start delay.
sleep 180

# Wait for all tests to complete.
while check_progress; do
    # TODO: Create a paremeter that sets the poll frequency.
    sleep 60
done

# Get test results and write to a file.
results="$(get_results |\
    tee "${workspace}/we2e_test_results-${platform}-${SRW_COMPILER}.txt")"

# Check that the number of tests equals the number of successes, otherwise
# exit with a non-zero code that equals the difference.
successes="$(awk '$2 == "SUCCESS" {print $1}' <<< "${results}" | wc -l)"
exit "$(( ${#we2e_tests[@]} - ${successes} ))"
