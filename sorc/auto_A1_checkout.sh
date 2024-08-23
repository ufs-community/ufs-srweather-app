#!/bin/bash

#-------------------------------------------------------------------
#=====  Step 1: check out source code and  external compoments  ====
#-------------------------------------------------------------------

./manage_externals/checkout_externals

#-------------------------------------------------------------------
#=====  Step 2: create symbolic links for parm and ush  ============
#-------------------------------------------------------------------

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


#-------------------------------------------------------------------
#=====  Step 3: create symbolic links for source codes  ============
#-------------------------------------------------------------------
cd ../sorc

for src in aqm_bias_correct aqm_bias_interpolate aqm_post_bias_cor_grib2 aqm_post_grib2 aqm_post_maxi_bias_cor_grib2 aqm_post_maxi_grib2  convert_airnow_csv gefs2lbcs_para 
do
 ln -s AQM-utils/sorc/${src}.fd .
 done

 ln -s UFS_UTILS/sorc/chgres_cube.fd .

 ln -s ufs-weather-model ufs-model.fd

 ln -s UPP/sorc/ncep_post.fd upp.fd

 ln -s arl_nexus nexus.fd

