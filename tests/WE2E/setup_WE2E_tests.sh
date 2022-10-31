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
#  tests/build.sh script in the ufs-srweather-app repository.  The UFS
#  build must be completed in a particular manner for this script to
#  function properly, notably the location of the build and install
#  directories: 
#    BUILD_DIR=${APP_DIR}/build_${compiler}
#    INSTALL_DIR=${APP_DIR}/install_${compiler}
#
#  Example: ./setup_WE2E_tests.sh hera zrtrr
#----------------------------------------------------------------------

#-----------------------------------------------------------------------
#  Set variables
#-----------------------------------------------------------------------

function usage {
  echo
  echo "Usage: $0 machine slurm_account [compiler] [test_type] [expts_dir] [nco_dirs] [run_envir] | -h"
  echo
  echo "       machine       [required] is one of: ${machines[@]}"
  echo "       slurm_account [required] case sensitive name of the user-specific slurm account"
  echo "       compiler      [optional] compiler used for build"
  echo "       test_type     [optional] test type: fundamental or comprehensive or all or any other name"
  echo "       expts_dir     [optional] Experiment base directory"
  echo "       nco_dirs      [optional] NCO operations root directory"
  echo "       run_envir     [optional] either 'community' or 'nco' "
  echo "       -h            display this help"
  echo
  exit 1

}

machines=( hera jet cheyenne orion wcoss2 gaea odin singularity macos noaacloud )

if [ "$1" = "-h" ] ; then usage ; fi
[[ $# -le 1 ]] && usage

machine=$1
machine=$(echo "${machine}" | tr '[A-Z]' '[a-z]')  # scripts in sorc need lower case machine name
account=$2
compiler=${3:-intel}
test_type=${4:-fundamental}

#-----------------------------------------------------------------------
# Set directories
#-----------------------------------------------------------------------
scrfunc_fp=$( readlink -f "${BASH_SOURCE[0]}" )
scrfunc_fn=$( basename "${scrfunc_fp}" )
scrfunc_dir=$( dirname "${scrfunc_fp}" )

TESTS_DIR=$( dirname "${scrfunc_dir}" )
SRW_APP_DIR=$( dirname "${TESTS_DIR}" )
TOP_DIR=$( dirname "${SRW_APP_DIR}" )

EXPTS_DIR=${5:-"${TOP_DIR}/expt_dirs"}
NCO_DIR=${6:-"${TOP_DIR}/nco_dirs"}

RUN_ENVIR=${7:-""}

#----------------------------------------------------------------------
# Use exec_subdir consistent with the automated build.
#----------------------------------------------------------------------

exec_subdir="install_${compiler}/exec"

#-----------------------------------------------------------------------
# Run E2E Tests
#-----------------------------------------------------------------------

# Load Python Modules
source ${SRW_APP_DIR}/ush/load_modules_wflow.sh ${machine}

# Run the E2E Workflow tests
./run_WE2E_tests.sh \
  test_type=${test_type} \
  machine=${machine} \
  account=${account} \
  exec_subdir=${exec_subdir} \
  compiler=${compiler} \
  expt_basedir=${EXPTS_DIR} \
  opsroot=${NCO_DIR} \
  debug="TRUE" \
  verbose="TRUE" \
  cron_relaunch_intvl_mnts=4 \
  run_envir=${RUN_ENVIR}

