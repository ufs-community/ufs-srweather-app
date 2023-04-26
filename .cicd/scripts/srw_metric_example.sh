#!/usr/bin/env bash
#
# The goal of this script is to provide an example to perform Indy-Severe-Weather run and compare with baseline using
# skill-score metric.
#
# Required:
#    WORKSPACE=</full/path/to/ufs-srweather-app>
#    SRW_PLATFORM=<supported_platform_host>
#    SRW_COMPILER=<intel|gnu>
#
# Optional:
[[ -n ${ACCOUNT} ]] || ACCOUNT="no_account"
[[ -n ${FORGIVE_CONDA} ]] || FORGIVE_CONDA=true
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
we2e_experiment_base_dir="${workspace}/../expt_dirs/metric_test"
we2e_test_dir="${workspace}/tests/WE2E"
we2e_test_name="grid_SUBCONUS_Ind_3km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v16"

pwd

# Activate the workflow environment ...
source etc/lmod-setup.sh ${platform,,}
module use modulefiles
module load build_${platform,,}_${SRW_COMPILER}
module load wflow_${platform,,}

[[ ${FORGIVE_CONDA} == true ]] && set +e +u    # Some platforms have incomplete python3 or conda support, but wouldn't necessarily block workflow tests
conda activate regional_workflow
set -e -u

# build srw
cd ${WORKSPACE}/tests
./build.sh ${platform,,} ${SRW_COMPILER}
cd ${WORKSPACE}

# run test
[[ -d ${we2e_experiment_base_dir} ]] && rm -rf ${we2e_experiment_base_dir}
cd ${WORKSPACE}/tests/WE2E
./run_WE2E_tests.py -t ${we2e_test_name} -m ${platform,,} -a ${ACCOUNT} --expt_basedir "metric_test" --exec_subdir=install_intel/exec -q
cd ${WORKSPACE}

# run metplus skill-score check
# first load MET env variables
source ${we2e_experiment_base_dir}/${we2e_test_name}/var_defns.sh
[[ ! -f Indy-Severe-Weather.tgz ]] && wget https://noaa-ufs-srw-pds.s3.amazonaws.com/sample_cases/release-public-v2.1.0/Indy-Severe-Weather.tgz
[[ ! -d Indy-Severe-Weather ]] && tar xvfz Indy-Severe-Weather.tgz
[[ -f skill-score.out ]] && rm skill-score.out
cp ${we2e_experiment_base_dir}/${we2e_test_name}/2019061500/mem000/metprd/PointStat/*.stat ${WORKSPACE}/Indy-Severe-Weather/metprd/point_stat/
${MET_INSTALL_DIR}/${MET_BIN_EXEC}/stat_analysis -config .cicd/scripts/STATAnalysisConfig_skill_score -lookin ${WORKSPACE}/Indy-Severe-Weather/metprd/point_stat -v 2 -out skill-score.out

# check skill-score.out
cat skill-score.out

 get skill-score (SS_INDEX) and check if it is significantly smaller than 1
# A value greater than 1.0 indicates that the forecast model outperforms the reference, 
# while a value less than 1.0 indicates that the reference outperforms the forecast.
tmp_string=$( tail -2 skill-score.out | head -1 )
SS_INDEX=${tmp_string:(-7)}
echo "Skill Score: ${SS_INDEX}"
if [[ ${SS_INDEX} < "0.700" ]]; then
    echo "Your Skill Score is way smaller than 1.00, better check before merging"
    exit 1
else
    echo "Congrats! You pass check!"
fi
