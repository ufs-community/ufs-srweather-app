#!/bin/bash

set -eu

FCST_MODEL="fv3gfs_aqm"

cp conf_cmaq/${FCST_MODEL}_Externals.cfg Externals.cfg
cp conf_cmaq/${FCST_MODEL}_src_CMakeLists.txt src/CMakeLists.txt
cp conf_cmaq/${FCST_MODEL}_build_hera_intel.env env/build_hera_intel.env
