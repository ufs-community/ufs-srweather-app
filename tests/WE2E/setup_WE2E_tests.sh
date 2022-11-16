#!/usr/bin/env bash
[ -n "$HOME" ] && exec -c "$0" "$@"

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
  echo "Usage: $0 machine account [compiler] [test_type] [others] | -h"
  echo
  echo "       machine       [required] is one of: ${machines[@]}"
  echo "       account       [required] case sensitive name of the user-specific slurm account"
  echo "       compiler      [optional] compiler used to build binaries (intel or gnu)"
  echo "       test_type     [optional] test type: fundamental or comprehensive or all or any other name"
  echo "       others        [optional] All other arguments are forwarded to run_WE2E_tests.sh"
  echo "       -h            display this help"
  echo
  exit 1

}

machines=( hera jet cheyenne orion wcoss2 gaea odin singularity macos noaacloud )

if [ "$1" = "-h" ] ; then usage ; fi
[[ $# -le 1 ]] && usage

machine=${1,,}
account=$2
compiler=${3:-intel}
test_type=${4:-fundamental}

#----------------------------------------------------------------------
# Set some default options, if user did not pass them
#----------------------------------------------------------------------
opts=
if [[ "$*" != *"debug"* ]]; then
   opts="${opts} debug=TRUE"
fi
if [[ "$*" != *"verbose"* ]]; then
   opts="${opts} verbose=TRUE"
fi
if [[ "$*" != *"cron_relaunch_intvl_mnts"* ]]; then
   opts="${opts} cron_relaunch_intvl_mnts=4"
fi
if [[ "$*" != *"exec_subdir"* ]]; then
   opts="${opts} exec_subdir=install_${compiler}/exec"
fi

#-----------------------------------------------------------------------
# Run E2E Tests
#-----------------------------------------------------------------------

# Load Python Modules
source ../../ush/load_modules_wflow.sh ${machine}

# Run the E2E Workflow tests
./run_WE2E_tests.sh \
  machine=${machine} \
  account=${account} \
  compiler=${compiler} \
  test_type=${test_type} \
  ${opts} \
  "${@:5}"

