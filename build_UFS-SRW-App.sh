#!/bin/bash

###########################################################################
## Script to build UFS Short-Range Weather Application (UFS SRW App)     ##
##                                                                       ##
## Usage:                                                                ##
##  1. Non-coupled (FV3 stand-alone) regional modeling:                  ##
##    (1) non-DA:                                                        ##
##               ./build_UFS-SRW-App.sh                                  ##
##            or ./build_UFS-SRW-App.sh "RRFS"                           ##
##            or ./build_UFS-SRW-App.sh "RRFS" "NO"                      ##
##                                                                       ##
##    Components:                                                        ##
##      - COMMON : regional workflow, UFS_UTILS, UPP                     ##
##      - RRFS   : ufs-weather-model                                     ##
##                                                                       ##
##  2. Coupled regional air quality modeling (RRFS-CMAQ):                ##
##    (1) non-DA:                                                        ##
##               ./build_RRFS-CMAQ.sh "RRFS-CMAQ"                        ##
##            or ./build_RRFS-CMAQ.sh "RRFS-CMAQ" "NO"                   ## 
##    (2) DA:                                                            ##
##               ./build_RRFS-CMAQ.sh "RRFS-CMAQ" "YES"                  ##
##                                                                       ##
##    Components:                                                        ##
##      - COMMON       : regional workflow, UFS_UTILS, UPP               ##
##      - RRFS-CMAQ    : arl_nexus, fv3gfs_aqm, AQM-utils                ##
##      - RRFS-CMAQ-DA : GSI, JEDI                                       ##
###########################################################################

set -eu

if [[ $(uname -s) == Darwin ]]; then
  readonly MYDIR=$(cd "$(dirname "$(greadlink -f -n "${BASH_SOURCE[0]}" )" )" && pwd -P)
else
  readonly MYDIR=$(cd "$(dirname "$(readlink -f -n "${BASH_SOURCE[0]}" )" )" && pwd -P)
fi

SRW_APP_DIR="${MYDIR}"
COMP_DIR="${SRW_APP_DIR}/components"

###########################################################################
## User specific parameters                                              ##
###########################################################################
##
## RRFS system option ("RRFS" or "RRFS-CMAQ")
##    RRFS      : FV3 stand-alone
##    RRFS-CMAQ : FV3 + AQM
##
RRFS_opt="${1:-RRFS}"
##
## DA option ("NO" or "YES")
##    NO  : hera, wcoss_dell_p3
##    YES : hera
##
DA_opt="${2:-NO}"
##
## Clean option ("YES" or not)
##    YES : clean build-related directories (bin,build,include,lib,share,src)
##
clean_opt="YES"
##
## CCPP_SUITES: for ufs-weather-model
##
export CCPP_SUITES="FV3_CPT_v0,FV3_GFS_2017_gfdlmp,FV3_GFS_2017_gfdlmp_regional,FV3_GSD_SAR,FV3_GSD_v0,FV3_GFS_v15p2,FV3_GFS_v16,FV3_RRFS_v1beta,FV3_HRRR,FV3_RRFS_v1alpha,FV3_GFS_v15_thompson_mynn_lam3km"
##
## Compiler
##
export COMPILER="intel"
##
###########################################################################
echo "RRFS system:" ${RRFS_opt}
echo "DA option:" ${DA_opt}
echo "Clean option:" ${clean_opt}

if [[ "${clean_opt}" == "YES" ]]; then
  rm -rf ${SRW_APP_DIR}/bin
  rm -rf ${SRW_APP_DIR}/build
  rm -rf ${SRW_APP_DIR}/include
  rm -rf ${SRW_APP_DIR}/lib
  rm -rf ${SRW_APP_DIR}/share
  rm -rf ${SRW_APP_DIR}/src
fi

# Check out the external components
echo "... Checking out the COMMON external components: regional workflow, UFS_UTILS, UPP ..."
./manage_externals/checkout_externals -e ${COMP_DIR}/COMMON/Externals.cfg
if [[ "${RRFS_opt}" == "RRFS" ]]; then
  echo "... Checking out the forecast model: ufs-weather-model ..."
  ./manage_externals/checkout_externals -e ${COMP_DIR}/RRFS/Externals.cfg
elif [[ "${RRFS_opt}" == "RRFS-CMAQ" ]]; then
  echo "... Checking out the RRFS-CMAQ components: arl_nexus,fv3gfs_aqm, gefs2clbcs, upp_post_stat ..."
  ./manage_externals/checkout_externals -e ${COMP_DIR}/RRFS-CMAQ/Externals.cfg
  if [[ "${DA_opt}" == "YES" ]]; then
    echo "... Checking out the DA components: GSI, JEDI ..."
    ./manage_externals/checkout_externals -e ${COMP_DIR}/RRFS-CMAQ-DA/Externals.cfg
  fi
fi

# Build the external components
echo "... Building UFS_UTILS ..."
cd ${COMP_DIR}/COMMON/build_scripts/
./build_UFS_UTILS.sh
echo "... Building UPP ..."
./build_UPP.sh
if [[ "${RRFS_opt}" == "RRFS" ]]; then
  echo "... Building ufs-weather-model ..."
  cd ${COMP_DIR}/RRFS/build_scripts/
  ./build_ufs-weather-model.sh
elif [[ "${RRFS_opt}" == "RRFS-CMAQ" ]]; then
  echo "... Building arl_nexus ..."
  cd ${COMP_DIR}/RRFS-CMAQ/build_scripts/
  ./build_arl_nexus.sh
  echo "... Building fv3gfs_aqm ..."
  ./build_fv3gfs_aqm.sh
  echo "... Building gefs2clbc ..."
  ./build_gefs2clbc.sh
  if [[ "${DA_opt}" == "YES" ]]; then
    echo "... Building GSI ..."
    cd ${COMP_DIR}/RRFS-CMAQ-DA/build_scripts/
    ./build_GSI.sh
    echo "... Building JEDI ..."
    ./build_JEDI.sh
  fi
fi
