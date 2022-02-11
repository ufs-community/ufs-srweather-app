#!/bin/bash

###########################################################
## Script to build RRFS                                  ##
## Components:                                           ##
## - regional workflow, UFS_UTILS, UPP                   ##
## - UFS Weather Model                                   ##
###########################################################

set -eu

if [[ $(uname -s) == Darwin ]]; then
  readonly MYDIR=$(cd "$(dirname "$(greadlink -f -n "${BASH_SOURCE[0]}" )" )" && pwd -P)
else
  readonly MYDIR=$(cd "$(dirname "$(readlink -f -n "${BASH_SOURCE[0]}" )" )" && pwd -P)
fi

# Check out the external components for RRFS
echo "... Checking out the common external components: regional workflow, UFS_UTILS, UPP ..."
./manage_externals/checkout_externals -e comp_conf/COMMON/Externals.cfg
echo "... Checking out the RRFS forecast model: ufs-weather-model ..."
./manage_externals/checkout_externals -e comp_conf/RRFS/Externals.cfg

###########################################################
## User specific parameters                              ##
###########################################################
##
export COMPILER="intel"
##
export CCPP_SUITES="FV3_CPT_v0,FV3_GFS_2017_gfdlmp,FV3_GFS_2017_gfdlmp_regional,FV3_GSD_SAR,FV3_GSD_v0,FV3_GFS_v15p2,FV3_GFS_v16,FV3_RRFS_v1beta,FV3_HRRR,FV3_RRFS_v1alpha,FV3_GFS_v15_thompson_mynn_lam3km"
##
###########################################################

# Build the external components for RRFS
echo "... Building UFS_UTILS ..."
cd ${MYDIR}/comp_conf/COMMON/build_scripts/
./build_UFS_UTILS.sh
echo "... Building UPP ..."
./build_UPP.sh
echo "... Building ufs-weather-model ..."
cd ${MYDIR}/comp_conf/RRFS/build_scripts/
./build_ufs-weather-model.sh
