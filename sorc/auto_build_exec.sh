#!/bin/bash

./manage_externals/checkout_externals

cd ../parm
 rm -rf aqm_utils nexus_config ufs_utils upp
 cp -rp ../sorc/AQM-utils/parm  aqm_utils
 cp -rp ../sorc/arl_nexus/config nexus_config
 cp -rp ../sorc/UFS_UTILS/parm  ufs_utils
 cp -rp ../sorc/UPP/parm upp	
 
cd ../ush
 rm -rf aqm_utils_python nexus_utils
 cp -rp ../sorc/AQM-utils/python_utils  aqm_utils_python	
 cp -rp ../sorc/arl_nexus/utils  nexus_utils

cd ../sorc

#./app_build.sh -p=wcoss2 --clean

./app_build.sh -p=wcoss2 -a=ATMAQ  |& tee buildup.log

#./app_build.sh -p=wcoss2 -a=ATMAQ --build-type=DEBUG |& tee build_debug.log
