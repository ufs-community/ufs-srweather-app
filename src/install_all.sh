#!/bin/sh
set -xeu

build_dir=`pwd`

CP='cp -rp'

# Check final bin folder exists
if [ ! -d "../bin" ]; then
  echo "Creating ../bin folder"
  mkdir ../bin
fi

#------------------------------------
# INCLUDE PARTIAL BUILD 
#------------------------------------

. ./partial_build.sh

#------------------------------------
# install forecast
#------------------------------------
#${CP} NEMSfv3gfs/fv3.exe                               ../bin/regional_forecast.x

#------------------------------------
# install post
#------------------------------------
$Build_post && {
 ${CP} EMC_post/exec/*                                 ../bin/nceppost.x
}

#------------------------------------
# install needed utilities from UFS_UTILS.
#------------------------------------
$Build_UFS_UTILS && {
# ${CP} regional_utils.fd/exec/global_chgres            ../bin/regional_chgres.x
 ${CP} UFS_UTILS/exec/chgres_cube                      ../bin/chgres_cube
 ${CP} UFS_UTILS/exec/orog                             ../bin/orog
 ${CP} UFS_UTILS/exec/sfc_climo_gen                    ../bin/sfc_climo_gen
 ${CP} UFS_UTILS/exec/regional_esg_grid                ../bin/regional_esg_grid
 ${CP} UFS_UTILS/exec/make_hgrid                       ../bin/make_hgrid
 ${CP} UFS_UTILS/exec/make_solo_mosaic                 ../bin/make_solo_mosaic
 ${CP} UFS_UTILS/exec/fregrid                          ../bin/fregrid
 ${CP} UFS_UTILS/exec/filter_topo                      ../bin/filter_topo
 ${CP} UFS_UTILS/exec/shave                            ../bin/shave
 ${CP} UFS_UTILS/exec/global_equiv_resol               ../bin/global_equiv_resol
}

#------------------------------------
# install gsi
#------------------------------------
$Build_gsi && {
 ${CP} regional_gsi.fd/exec/global_gsi.x               ../exec/regional_gsi.x
 ${CP} regional_gsi.fd/exec/global_enkf.x              ../exec/regional_enkf.x
 ${CP} regional_gsi.fd/exec/adderrspec.x               ../exec/regional_adderrspec.x
 ${CP} regional_gsi.fd/exec/adjustps.x                 ../exec/regional_adjustps.x
 ${CP} regional_gsi.fd/exec/calc_increment_ens.x       ../exec/regional_calc_increment_ens.x
 ${CP} regional_gsi.fd/exec/calc_increment_serial.x    ../exec/regional_calc_increment_serial.x
 ${CP} regional_gsi.fd/exec/getnstensmeanp.x           ../exec/regional_getnstensmeanp.x
 ${CP} regional_gsi.fd/exec/getsfcensmeanp.x           ../exec/regional_getsfcensmeanp.x
 ${CP} regional_gsi.fd/exec/getsfcnstensupdp.x         ../exec/regional_getsfcnstensupdp.x
 ${CP} regional_gsi.fd/exec/getsigensmeanp_smooth.x    ../exec/regional_getsigensmeanp_smooth.x
 ${CP} regional_gsi.fd/exec/getsigensstatp.x           ../exec/regional_getsigensstatp.x
 ${CP} regional_gsi.fd/exec/gribmean.x                 ../exec/regional_gribmean.x
 ${CP} regional_gsi.fd/exec/nc_diag_cat.x              ../exec/regional_nc_diag_cat.x
 ${CP} regional_gsi.fd/exec/nc_diag_cat_serial.x       ../exec/regional_nc_diag_cat_serial.x
 ${CP} regional_gsi.fd/exec/oznmon_horiz.x             ../exec/regional_oznmon_horiz.x
 ${CP} regional_gsi.fd/exec/oznmon_time.x              ../exec/regional_oznmon_time.x
 ${CP} regional_gsi.fd/exec/radmon_angle.x             ../exec/regional_radmon_angle.x
 ${CP} regional_gsi.fd/exec/radmon_bcoef.x             ../exec/regional_radmon_bcoef.x
 ${CP} regional_gsi.fd/exec/radmon_bcor.x              ../exec/regional_radmon_bcor.x
 ${CP} regional_gsi.fd/exec/radmon_time.x              ../exec/regional_radmon_time.x
 ${CP} regional_gsi.fd/exec/recenternemsiop_hybgain.x  ../exec/regional_recenternemsiop_hybgain.x
 ${CP} regional_gsi.fd/exec/recentersigp.x             ../exec/regional_recentersigp.x
 ${CP} regional_gsi.fd/exec/test_nc_unlimdims.x        ../exec/regional_test_nc_unlimdims.x
}

echo;echo " .... Install system finished .... "

exit 0
