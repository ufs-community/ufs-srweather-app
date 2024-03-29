#!/usr/bin/env bash
#
# The goal of this script is to provide an example of performing Indy-Severe-Weather test run and compare results to reference with
# Skill score index that is calculated by MET Stat-Analysis Tools
#
# Required (these options are set in the Jenkins env):
#    WORKSPACE=</full/path/to/ufs-srweather-app>
#    SRW_PLATFORM=<supported_platform_host>
#    SRW_COMPILER=<intel|gnu>
#    SRW_PROJECT=<platform_account>
#
# Optional:
#[[ -n ${SRW_PROJECT} ]] || SRW_PROJECT="no_account"
[[ -n ${FORGIVE_CONDA} ]] || FORGIVE_CONDA=true
set -e -u -x

BUILD_OPT=false
RUN_WE2E_OPT=false
RUN_STAT_ANLY_OPT=false

if [[ $# -eq 0 ]]; then
    BUILD_OPT=true
    RUN_WE2E_OPT=true
    RUN_STAT_ANLY_OPT=true
elif [[ $# -ge 4 ]]; then 
    echo "Too many arguments, expecting three or less"
    exit 1
else 
    for opt in "$@"; do    
       case $opt in
            build) BUILD_OPT=true ;; 
            run_we2e) RUN_WE2E_OPT=true ;;
            run_stat_anly) RUN_STAT_ANLY_OPT=true ;;
            *) echo "Not valid option. Exiting!" ; exit 1 ;;
        esac
    done
fi

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
we2e_experiment_base_dir="${workspace}/../expt_dirs/metric_test"
we2e_test_dir="${workspace}/tests/WE2E"
we2e_test_name="grid_SUBCONUS_Ind_3km_ics_FV3GFS_lbcs_FV3GFS_suite_WoFS_v0"

pwd

# Setup the build environment
declare srw_compiler
srw_compiler=${SRW_COMPILER} 
source etc/lmod-setup.sh ${platform,,}
module use modulefiles
module load build_${platform,,}_${srw_compiler}

# Build srw
if [[ ${BUILD_OPT} == true ]]; then
    cd ${workspace}/tests
    ./build.sh ${platform,,} ${srw_compiler}
fi
cd ${workspace}

# Activate workflow environment
module load wflow_${platform,,}

[[ ${FORGIVE_CONDA} == true ]] && set +e +u    # Some platforms have incomplete python3 or conda support, but would not necessarily block workflow tests
conda activate srw_app
set -e -u

# Run test
declare srw_project
srw_project=${SRW_PROJECT}
if [[ ${RUN_WE2E_OPT} == true ]]; then
    [[ -d ${we2e_experiment_base_dir} ]] && rm -rf ${we2e_experiment_base_dir}
    cd ${workspace}/tests/WE2E
    ./run_WE2E_tests.py -t ${we2e_test_name} -m ${platform,,} -a ${srw_project} --expt_basedir "metric_test" --exec_subdir=install_intel/exec -q
fi
cd ${workspace}

# Run skill-score check
if [[ ${RUN_STAT_ANLY_OPT} == true ]]; then
    # Clear out data
    rm -rf ${workspace}/Indy-Severe-Weather/
    # Check if metprd data exists locally otherwise get it from S3
    TEST_EXTRN_MDL_SOURCE_BASEDIR=$(grep TEST_EXTRN_MDL_SOURCE_BASEDIR ${workspace}/ush/machine/${SRW_PLATFORM}.yaml | awk '{print $NF}')
    if [[ ! -d $(dirname ${TEST_EXTRN_MDL_SOURCE_BASEDIR})/metprd/point_stat ]] ; then
        mkdir -p Indy-Severe-Weather/metprd/point_stat
        cp -rp $(dirname ${TEST_EXTRN_MDL_SOURCE_BASEDIR})/metprd/point_stat Indy-Severe-Weather/metprd
    elif [[ -f Indy-Severe-Weather.tgz ]]; then
        tar xvfz Indy-Severe-Weather.tgz 
    else
        wget https://noaa-ufs-srw-pds.s3.amazonaws.com/sample_cases/release-public-v2.1.0/Indy-Severe-Weather.tgz
        tar xvfz Indy-Severe-Weather.tgz
    fi
    [[ -f skill-score.txt ]] && rm skill-score.txt
    # Skill score index is computed over several terms that are defined in parm/metplus/STATAnalysisConfig_skill_score. 
    # It is computed by aggregating the output from earlier runs of the Point-Stat and/or Grid-Stat tools over one or more cases.
    # In this example, skill score index is a weighted average of 4 skill scores of RMSE statistics for wind speed, dew point temperature, 
    # temperature, and pressure at lowest level in the atmosphere over 6 hour lead time.
    cp ${we2e_experiment_base_dir}/${we2e_test_name}/2019061500/metprd/PointStat/*.stat ${workspace}/Indy-Severe-Weather/metprd/point_stat/
    # Remove conda for Orion due to conda env conflicts
    if [[ ${platform} =~ "orion" ]]; then
        sed -i 's|load("conda")|--load("conda")|g' ${workspace}/modulefiles/tasks/${platform,,}/run_vx.local.lua
    fi
    # Load met and metplus
    module use modulefiles/tasks/${platform,,}
    module load run_vx.local 
    # Reset Orion run_vx.local file
    if [[ ${platform} =~ "orion" ]]; then
       sed -i 's|--load("conda")|load("conda")|g' ${workspace}/modulefiles/tasks/${platform,,}/run_vx.local.lua
    fi
    # Run stat_analysis
    stat_analysis -config parm/metplus/STATAnalysisConfig_skill_score -lookin ${workspace}/Indy-Severe-Weather/metprd/point_stat -v 2 -out skill-score.txt

    # check skill-score.txt
    cat skill-score.txt

    # get skill-score (SS_INDEX) and check if it is significantly smaller than 1.0
    # A value greater than 1.0 indicates that the forecast model outperforms the reference, 
    # while a value less than 1.0 indicates that the reference outperforms the forecast.
    tmp_string=$( tail -2 skill-score.txt | head -1 )
    SS_INDEX=$(echo $tmp_string | awk -F " " '{print $NF}')
    echo "Skill Score: ${SS_INDEX}"
    if [[ ${SS_INDEX} < "0.700" ]]; then
        echo "Your Skill Score is way smaller than 1.00, better check before merging"
        exit 1
    else
        echo "Congrats! You pass check!"
   fi
fi
