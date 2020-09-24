#! /usr/bin/env bash
#==========================================================================
#
# Description: Builds the UFS Weather Model and puts the executable in
#              ufs_weather_model/test.  This script is usually called
#              from ./build_all.sh.
#
# Note:  Only the CCPP static build of the UFS MR Weather Model is supported.
#
# Usage: ./build_forecast.sh
#
#==========================================================================
set -eux

source ./machine-setup.sh > /dev/null 2>&1
cwd=`pwd`

USE_PREINST_LIBS=${USE_PREINST_LIBS:-"true"}
if [ $USE_PREINST_LIBS = true ]; then
  export MOD_PATH=/scratch3/NCEPDEV/nwprod/lib/modulefiles
else
  export MOD_PATH=${cwd}/lib/modulefiles
fi

export COMPILER=intel
export CMAKE_Platform=${target}
if [ $target = 'wcoss_cray' -o $target = 'wcoss_dell_p3' ]; then
  target=${target}
else
  target=${target}.${COMPILER}
fi

cd ufs_weather_model
model_top_dir=`pwd`

cd modulefiles/${target}
module use $(pwd)
module load fv3
cd ${model_top_dir}

# CMake 3.15 or higher is required.
if [ "$platform" == "cheyenne" ] ; then
  module load cmake/3.16.4
fi

#---------------------------------------------------------------------------------
# Build static executable using cmake for all valid suites in workflow
# defined in regional_workflow/ush/valid_param_vals.sh
#---------------------------------------------------------------------------------

# Read in the array of valid physics suite from the file in the workflow
# that specifies valid values for various parameters.  In this case, it
# is the valid values for CCPP_PHYS_SUITE.  Note that the result (stored
# in CCPP_SUITES) is a string consisting of a comma-separated list of all
# the valid (allowed) CCPP physics suites.
CCPP_SUITES=$( 
  . ../../regional_workflow/ush/valid_param_vals.sh 
  printf "%s," "${valid_vals_CCPP_PHYS_SUITE[@]}"
)
export CCPP_SUITES="${CCPP_SUITES:0: -1}"  # Remove comma after last suite.

./build.sh || echo "FAIL:  build_forecast.sh failed, see ${cwd}/logs/build_forecast.log"

#---------------------------------------------------------------------------------
# Copy executable (named ufs_weather_model) to tests dir so workflow can find it
#---------------------------------------------------------------------------------
cp ${model_top_dir}/ufs_weather_model ${model_top_dir}/tests/fv3.exe
