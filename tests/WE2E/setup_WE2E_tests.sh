#!/usr/bin/env bash

# `exec -c` runs this script with clean environment; this avoids some problems
# with double-loading conda environments. Since we do need $HOME to be set for
# rocoto to run properly, pass it as an argument and export it later

[ -n "$HOME" ] && exec -c "$0" "$HOME" "$@"

#----------------------------------------------------------------------
#  Wrapper for the automation of UFS Short Range Weather App Workflow
#  End to End Tests.
#
#  The wrapper loads the appropriate workflow environment for the
#  machine, and sets the machine test suite file before invoking the
#  run_WE2E_tests.py script.
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
  echo "Usage: $0 machine account [compiler] [tests] [others] | -h"
  echo
  echo "   machine   [required] is one of: ${machines[@]}"
  echo "   account   [required] case sensitive name of the user-specific slurm account"
  echo "   compiler  [optional] compiler used to build binaries (intel or gnu)"
  echo "   tests     [optional] tests to run: can be suite (all|comprehensive|fundamental|coverage)
                        a filename, or a test name"
  echo "   others    [optional] All other arguments are forwarded to run_WE2E_tests.py"
  echo "   -h        display this help"
  echo
  exit 1

}

machines=( hera jet cheyenne derecho orion wcoss2 gaea odin singularity macos noaacloud )

if [ "$1" = "-h" ] ; then usage ; fi
[[ $# -le 2 ]] && usage

homedir=$1
machine=${2,,}
account=$3
compiler=${4:-intel}
tests=${5:-coverage}

#----------------------------------------------------------------------
# Set some default options, if user did not pass them
#----------------------------------------------------------------------
opts=
if [[ "$*" != *"debug"* ]]; then
   opts="${opts} --debug"
fi
if [[ "$*" != *"verbose"* ]]; then
   opts="${opts} --verbose"
fi
if [[ "$*" != *"exec_subdir"* ]]; then
   opts="${opts} --exec_subdir=install_${compiler}/exec"
fi

#-----------------------------------------------------------------------
# Run E2E Tests
#-----------------------------------------------------------------------
# Export HOME environment variable; needed for rocoto
export HOME=$homedir

# Load Python Modules
source ../../ush/load_modules_wflow.sh ${machine}

# Run the E2E Workflow tests
./run_WE2E_tests.py \
  --machine=${machine} \
  --account=${account} \
  --compiler=${compiler} \
  --tests=${tests} \
  ${opts} \
  "${@:6}"

