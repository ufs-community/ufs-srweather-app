#!/bin/bash -l

#----------------------------------------------------------------------
#  Wrapper for the automation of UFS Short Range Weather App Workflow
#  End to End Tests.
#
#  The wrapper loads the appropriate workflow environment for the
#  machine, and sets the machine test suite file before invoking the
#  run_WE2E_tests.sh.
#
#  The script is dependent on a successful build of this repo using the
#  test/build.sh script in the ufs-srweather-app repository.  The UFS
#  build must be completed in a particular manner for this script to
#  function properly, notably the location of the build and bin
#  directories: 
#    BUILD_DIR=${APP_DIR}/build_${compiler}
#    BIN_DIR=${APP_DIR}/bin_${compiler}
#
#  Example: ./end_to_end_tests.sh hera zrtrr
#----------------------------------------------------------------------

#-----------------------------------------------------------------------
#  Set variables
#-----------------------------------------------------------------------

function usage {
  echo
  echo "Usage: $0 machine slurm_account  | -h"
  echo
  echo "       machine       [required] is one of: ${machines[@]}"
  echo "       slurm_account [required] case sensitive name of the user-specific slurm account"
  echo "       -h            display this help"
  echo
  exit 1

}

machines=( hera jet )

if [ "$1" = "-h" ] ; then usage ; fi
[[ $# -le 1 ]] && usage

machine=$1
machine=$(echo "${machine}" | tr '[A-Z]' '[a-z]')  # scripts in sorc need lower case machine name

account=$2

#-----------------------------------------------------------------------
# Set directories
#-----------------------------------------------------------------------
scrfunc_fp=$( readlink -f "${BASH_SOURCE[0]}" )
scrfunc_fn=$( basename "${scrfunc_fp}" )
scrfunc_dir=$( dirname "${scrfunc_fp}" )

TESTS_DIR=$( dirname "${scrfunc_dir}" )
REGIONAL_WORKFLOW_DIR=$( dirname "${TESTS_DIR}" )
SRW_APP_DIR=$( dirname "${REGIONAL_WORKFLOW_DIR}" )
TOP_DIR=$( dirname "${SRW_APP_DIR}" )

EXPTS_DIR=${TOP_DIR}/expt_dirs

#-----------------------------------------------------------------------
# Set the path to the machine-specific test suite file.
#-----------------------------------------------------------------------

auto_file=${scrfunc_dir}/machine_suites/${machine}.txt

#----------------------------------------------------------------------
# Use exec_subdir consistent with the automated build.
#----------------------------------------------------------------------

exec_subdir='bin_intel/bin'

#-----------------------------------------------------------------------
# Run E2E Tests
#-----------------------------------------------------------------------

# Load Python Modules
env_path="${SRW_APP_DIR}/modulefiles"
env_file="wflow_${machine}"
echo "-- Load environment =>" $env_file
source ${SRW_APP_DIR}/etc/lmod-setup.sh ${machine}
module use ${env_path}
module load ${env_file}
conda activate regional_workflow

module list

# Run the E2E Workflow tests
./run_WE2E_tests.sh \
  tests_file=${auto_file} \
  machine=${machine} \
  account=${account} \
  exec_subdir=${exec_subdir}

