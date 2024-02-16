#!/bin/bash
set -ex

# configure base directory
if [ -f app_build.sh ]; then
  base_dir=$(realpath $(pwd)/..)
else
  echo "This script is to be used before build for cleanup. Please ensure the path is correct"
  exit 7
fi

# clean up the development module ufs-weather-model/FV3/upp/modulefiles/wcoss2_a.lua
[[ -f ${base_dir}/sorc/ufs-weather-model/FV3/upp/modulefiles/wcoss2_a.lua ]] && rm -f ${base_dir}/sorc/ufs-weather-model/FV3/upp/modulefiles/wcoss2_a.lua

# clean up the development module UPP/modulefiles/wcoss2_a.lua
[[ -f ${base_dir}/sorc/UPP/modulefiles/wcoss2_a.lua ]] && rm -f ${base_dir}/sorc/UPP/modulefiles/wcoss2_a.lua

exit 0
