#!/bin/sh
set -xeu

build_dir=`pwd`

CP='cp -rp'

#------------------------------------
# INCLUDE PARTIAL BUILD 
#------------------------------------

. ./partial_build.sh

#------------------------------------
# install forecast
#------------------------------------
#${CP} NEMSfv3gfs/fv3.exe                               ${BIN_DIR}/regional_forecast.x

#------------------------------------
# install post
#------------------------------------
$Build_post && {
 ${CP} EMC_post/exec/*                                 ${BIN_DIR}/ncep_post
}

#------------------------------------
# install needed utilities from UFS_UTILS.
#------------------------------------
$Build_UFS_UTILS && {
# ${CP} regional_utils.fd/exec/global_chgres            ${BIN_DIR}/regional_chgres.x
 ${CP} UFS_UTILS/exec/chgres_cube                      ${BIN_DIR}/chgres_cube
 ${CP} UFS_UTILS/exec/orog                             ${BIN_DIR}/orog
 ${CP} UFS_UTILS/exec/sfc_climo_gen                    ${BIN_DIR}/sfc_climo_gen
 ${CP} UFS_UTILS/exec/regional_esg_grid                ${BIN_DIR}/regional_esg_grid
 ${CP} UFS_UTILS/exec/make_hgrid                       ${BIN_DIR}/make_hgrid
 ${CP} UFS_UTILS/exec/make_solo_mosaic                 ${BIN_DIR}/make_solo_mosaic
 ${CP} UFS_UTILS/exec/fregrid                          ${BIN_DIR}/fregrid
 ${CP} UFS_UTILS/exec/filter_topo                      ${BIN_DIR}/filter_topo
 ${CP} UFS_UTILS/exec/shave                            ${BIN_DIR}/shave
 ${CP} UFS_UTILS/exec/global_equiv_resol               ${BIN_DIR}/global_equiv_resol
}

#------------------------------------
# install gsi
#------------------------------------
$Build_gsi && {
 ${CP} regional_gsi.fd/exec/global_gsi.x               ${BIN_DIR}/regional_gsi.x
 ${CP} regional_gsi.fd/exec/global_enkf.x              ${BIN_DIR}/regional_enkf.x
 ${CP} regional_gsi.fd/exec/adderrspec.x               ${BIN_DIR}/regional_adderrspec.x
 ${CP} regional_gsi.fd/exec/adjustps.x                 ${BIN_DIR}/regional_adjustps.x
 ${CP} regional_gsi.fd/exec/calc_increment_ens.x       ${BIN_DIR}/regional_calc_increment_ens.x
 ${CP} regional_gsi.fd/exec/calc_increment_serial.x    ${BIN_DIR}/regional_calc_increment_serial.x
 ${CP} regional_gsi.fd/exec/getnstensmeanp.x           ${BIN_DIR}/regional_getnstensmeanp.x
 ${CP} regional_gsi.fd/exec/getsfcensmeanp.x           ${BIN_DIR}/regional_getsfcensmeanp.x
 ${CP} regional_gsi.fd/exec/getsfcnstensupdp.x         ${BIN_DIR}/regional_getsfcnstensupdp.x
 ${CP} regional_gsi.fd/exec/getsigensmeanp_smooth.x    ${BIN_DIR}/regional_getsigensmeanp_smooth.x
 ${CP} regional_gsi.fd/exec/getsigensstatp.x           ${BIN_DIR}/regional_getsigensstatp.x
 ${CP} regional_gsi.fd/exec/gribmean.x                 ${BIN_DIR}/regional_gribmean.x
 ${CP} regional_gsi.fd/exec/nc_diag_cat.x              ${BIN_DIR}/regional_nc_diag_cat.x
 ${CP} regional_gsi.fd/exec/nc_diag_cat_serial.x       ${BIN_DIR}/regional_nc_diag_cat_serial.x
 ${CP} regional_gsi.fd/exec/oznmon_horiz.x             ${BIN_DIR}/regional_oznmon_horiz.x
 ${CP} regional_gsi.fd/exec/oznmon_time.x              ${BIN_DIR}/regional_oznmon_time.x
 ${CP} regional_gsi.fd/exec/radmon_angle.x             ${BIN_DIR}/regional_radmon_angle.x
 ${CP} regional_gsi.fd/exec/radmon_bcoef.x             ${BIN_DIR}/regional_radmon_bcoef.x
 ${CP} regional_gsi.fd/exec/radmon_bcor.x              ${BIN_DIR}/regional_radmon_bcor.x
 ${CP} regional_gsi.fd/exec/radmon_time.x              ${BIN_DIR}/regional_radmon_time.x
 ${CP} regional_gsi.fd/exec/recenternemsiop_hybgain.x  ${BIN_DIR}/regional_recenternemsiop_hybgain.x
 ${CP} regional_gsi.fd/exec/recentersigp.x             ${BIN_DIR}/regional_recentersigp.x
 ${CP} regional_gsi.fd/exec/test_nc_unlimdims.x        ${BIN_DIR}/regional_test_nc_unlimdims.x
}

echo;echo " .... Install system finished .... "

exit 0
