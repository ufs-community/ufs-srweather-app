#!/usr/bin/env bash
#
# The goal of this script is to provide an example of performing Indy-Severe-Weather test run and compare results to reference with
# Skill score index that is calculated by MET Stat-Analysis Tools
#
# Required:
#    WORKSPACE=</full/path/to/ufs-srweather-app>
#    SRW_PLATFORM=<supported_platform_host>
#    SRW_COMPILER=<intel|gnu>
#
# Optional:
[[ -n ${SRW_PROJECT} ]] || SRW_PROJECT="no_account"
[[ -n ${FORGIVE_CONDA} ]] || FORGIVE_CONDA=true
set -e -u -x

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)"

# Get repository root from Jenkins WORKSPACE variable if set, otherwise, set
# relative to script directory.
declare workspace
if [[ -n "${WORKSPACE}/${SRW_PLATFORM}" ]]; then
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

# Activate the workflow environment ...
source etc/lmod-setup.sh ${platform,,}
module use modulefiles
module load build_${platform,,}_${SRW_COMPILER}
module load wflow_${platform,,}

[[ ${FORGIVE_CONDA} == true ]] && set +e +u    # Some platforms have incomplete python3 or conda support, but wouldn't necessarily block workflow tests
conda activate workflow_tools
set -e -u

# build srw
cd ${workspace}/tests
./build.sh ${platform,,} ${SRW_COMPILER}
cd ${workspace}

# run test
[[ -d ${we2e_experiment_base_dir} ]] && rm -rf ${we2e_experiment_base_dir}
cd ${workspace}/tests/WE2E
./run_WE2E_tests.py -t ${we2e_test_name} -m ${platform,,} -a ${SRW_PROJECT} --expt_basedir "metric_test" --exec_subdir=install_intel/exec -q
cd ${workspace}

# run skill-score check
[[ ! -f Indy-Severe-Weather.tgz ]] && wget https://noaa-ufs-srw-pds.s3.amazonaws.com/experiment-user-cases/release-public-v2.1.0/METplus-vx-sample/Indy-Severe-Weather.tgz
[[ ! -d Indy-Severe-Weather ]] && tar xvfz Indy-Severe-Weather.tgz
[[ -f skill-score.out ]] && rm skill-score.out
# Skill score index is computed over several terms that are defined in parm/metplus/STATAnalysisConfig_skill_score. 
# It is computed by aggregating the output from earlier runs of the Point-Stat and/or Grid-Stat tools over one or more cases.
# In this example, skill score index is a weighted average of 4 skill scores of RMSE statistics for wind speed, dew point temperature, 
# temperature, and pressure at lowest level in the atmosphere over 6 hour lead time.
cp ${we2e_experiment_base_dir}/${we2e_test_name}/2019061500/metprd/PointStat/*.stat ${workspace}/Indy-Severe-Weather/metprd/point_stat/
# load met and metplus
module use modulefiles/tasks/${platform,,}
module load run_vx.local 
stat_analysis -config parm/metplus/STATAnalysisConfig_skill_score -lookin ${workspace}/Indy-Severe-Weather/metprd/point_stat -v 2 -out skill-score.out

# check skill-score.out
cat skill-score.out

# get skill-score (SS_INDEX) and check if it is significantly smaller than 1.0
# A value greater than 1.0 indicates that the forecast model outperforms the reference, 
# while a value less than 1.0 indicates that the reference outperforms the forecast.
tmp_string=$( tail -2 skill-score.out | head -1 )
SS_INDEX=$(echo $tmp_string | awk -F " " '{print $NF}')
echo "Skill Score: ${SS_INDEX}"
if [[ ${SS_INDEX} < "0.700" ]]; then
    echo "Your Skill Score is way smaller than 1.00, better check before merging"
    exit 1
else
    echo "Congrats! You pass check!"
fi
