#!/bin/bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. $USHdir/source_util_funcs.sh
source_config_for_task "task_run_prepstart|task_get_extrn_lbcs" ${GLOBAL_VAR_DEFNS_FP}
#
#-----------------------------------------------------------------------
#
# Save current shell options (in a global array).  Then set new options
# for this script/function.
#
#-----------------------------------------------------------------------
#
{ save_shell_opts; . $USHdir/preamble.sh; } > /dev/null 2>&1
#
#-----------------------------------------------------------------------
#
# Get the full path to the file in which this script/function is located 
# (scrfunc_fp), the name of that file (scrfunc_fn), and the directory in
# which the file is located (scrfunc_dir).
#
#-----------------------------------------------------------------------
#
scrfunc_fp=$( readlink -f "${BASH_SOURCE[0]}" )
scrfunc_fn=$( basename "${scrfunc_fp}" )
scrfunc_dir=$( dirname "${scrfunc_fp}" )
#
#-----------------------------------------------------------------------
#
# Print message indicating entry into script.
#
#-----------------------------------------------------------------------
#
print_info_msg "
========================================================================
Entering script:  \"${scrfunc_fn}\"
In directory:     \"${scrfunc_dir}\"
This is the ex-script for the task that runs a analysis with FV3 for the
specified cycle.
========================================================================"
#
#-----------------------------------------------------------------------
#
# Load modules.
#
#-----------------------------------------------------------------------
#
eval ${PRE_TASK_CMDS}

nprocs=$((NNODES_RUN_PREPSTART*PPN_RUN_PREPSTART))

gridspec_dir=${NWGES_BASEDIR}/grid_spec
#
#-----------------------------------------------------------------------
#
# Extract from CDATE the starting year, month, day, and hour of the
# forecast.  These are needed below for various operations.
#
#-----------------------------------------------------------------------
#
START_DATE=$(echo "${CDATE}" | sed 's/\([[:digit:]]\{2\}\)$/ \1/')
YYYYMMDDHH=$(date +%Y%m%d%H -d "${START_DATE}")
JJJ=$(date +%j -d "${START_DATE}")

YYYY=${YYYYMMDDHH:0:4}
MM=${YYYYMMDDHH:4:2}
DD=${YYYYMMDDHH:6:2}
HH=${YYYYMMDDHH:8:2}
YYYYMMDD=${YYYYMMDDHH:0:8}
YYYYJJJHH=${YYYY}${JJJ}${HH}

current_time=$(date "+%T")
YYYYMMDDm1=$(date +%Y%m%d -d "${START_DATE} 1 days ago")
YYYYMMDDm2=$(date +%Y%m%d -d "${START_DATE} 2 days ago")
#
#-----------------------------------------------------------------------
#
# Compute date & time components for the SST analysis time relative to current analysis time
YYJJJ00000000=`date +"%y%j00000000" -d "${START_DATE} 1 day ago"`
YYJJJ1200=`date +"%y%j1200" -d "${START_DATE} 1 day ago"`
YYJJJ2200000000=`date +"%y%j2200000000" -d "${START_DATE} 1 day ago"`

#
#-----------------------------------------------------------------------
#
# go to INPUT directory.
# prepare initial conditions for ensemble free forecast after ensemble DA
#
#-----------------------------------------------------------------------
if [ ${DO_ENSFCST} = "TRUE" ] &&  [ ${DO_ENKFUPDATE} = "TRUE" ]; then
  cd_vrfy ${DATA}
  bkpath=${FG_ROOT}/${YYYYMMDDHH}${SLASH_ENSMEM_SUBDIR}/fcst_fv3lam/DA_OUTPUT  # use DA analysis from DA_OUTPUT
  filelistn="fv_core.res.tile1.nc fv_srf_wnd.res.tile1.nc fv_tracer.res.tile1.nc phy_data.nc sfc_data.nc"
  checkfile=${bkpath}/coupler.res
  n_iolayouty=$(($IO_LAYOUT_Y-1))
  list_iolayout=$(seq 0 $n_iolayouty)
  if [ -r "${checkfile}" ] ; then
    cp_vrfy ${bkpath}/coupler.res                coupler.res
    cp_vrfy ${bkpath}/gfs_ctrl.nc  gfs_ctrl.nc
    cp_vrfy ${bkpath}/fv_core.res.nc             fv_core.res.nc
    if [ "${IO_LAYOUT_Y}" == "1" ]; then
      for file in ${filelistn}; do
        cp_vrfy ${bkpath}/${file}     ${file}
      done
    else
      for file in ${filelistn}; do
         for ii in $list_iolayout
         do
           iii=$(printf %4.4i $ii)
           cp_vrfy ${bkpath}/${file}.${iii}     ${file}.${iii}
         done
      done
    fi
  else
    print_err_msg_exit "Error: can not find ensemble DA analysis output for running ensemble free forecast, \
  check ${bkpath} for needed files."
  fi
#
#-----------------------------------------------------------------------
#
else
#
# go to INPUT directory.
# prepare initial conditions for 
#     cold start if BKTYPE=1 
#     warm start if BKTYPE=0
#     spinupcyc + warm start if BKTYPE=2
#       the previous 6 cycles are searched to find the restart files
#       valid at this time from the closet previous cycle.
#
#-----------------------------------------------------------------------

BKTYPE=0
if [ ${CYCLE_TYPE} == "spinup" ]; then
  echo "spin up cycle"
  for cyc_start in "${CYCL_HRS_SPINSTART[@]}"; do
    if [ ${HH} -eq ${cyc_start} ]; then
      BKTYPE=1
    fi
  done
  if [ ${CYCLE_SUBTYPE} == "spinup" ]; then
    echo "ensinit cycle - warm start from 1 timestep restart files"
    BKTYPE=0
  fi
else
  echo " product cycle"
  for cyc_start in "${CYCL_HRS_PRODSTART[@]}"; do
    if [ ${HH} -eq ${cyc_start} ]; then
      if [ ${DO_SPINUP} == "TRUE" ]; then
        BKTYPE=2   # using 1-h forecast from spinup cycle
      else
        BKTYPE=1
      fi
    fi
  done
fi

# cycle surface 
SFC_CYC=0
if [ ${DO_SURFACE_CYCLE} == "TRUE" ]; then  # cycle surface fields
  if [ ${DO_SPINUP} == "TRUE" ]; then
    if [ ${CYCLE_TYPE} == "spinup" ]; then
      for cyc_start in "${CYCL_HRS_SPINSTART[@]}"; do
        SFC_CYCL_HH=$(( ${cyc_start} + ${SURFACE_CYCLE_DELAY_HRS} ))
        if [ ${HH} -eq ${SFC_CYCL_HH} ]; then
          if [ ${SURFACE_CYCLE_DELAY_HRS} == "0" ]; then
            SFC_CYC=1  # cold start
          else
            SFC_CYC=2  # delayed surface cycle
          fi
        fi
      done
    fi
  else
    for cyc_start in "${CYCL_HRS_PRODSTART[@]}"; do
       if [ ${HH} -eq ${cyc_start} ]; then
          SFC_CYC=1  # cold start
       fi
    done
  fi
fi

cd_vrfy ${DATA}

if [ ${BKTYPE} -eq 1 ] ; then  # cold start, use prepare cold strat initial files from ics
    bkpath=${LBCS_ROOT}/$YYYYMMDD$HH${SLASH_ENSMEM_SUBDIR}/ics
    if [ -r "${bkpath}/gfs_data.tile7.halo0.nc" ]; then
      cp_vrfy ${bkpath}/gfs_bndy.tile7.000.nc gfs_bndy.tile7.000.nc        
      cp_vrfy ${bkpath}/gfs_ctrl.nc gfs_ctrl.nc        
      cp_vrfy ${bkpath}/gfs_data.tile7.halo0.nc gfs_data.tile7.halo0.nc        
      cp_vrfy ${bkpath}/sfc_data.tile7.halo0.nc sfc_data.tile7.halo0.nc        
      ln_vrfy -s ${bkpath}/gfs_bndy.tile7.000.nc bk_gfs_bndy.tile7.000.nc
      ln_vrfy -s ${bkpath}/gfs_data.tile7.halo0.nc bk_gfs_data.tile7.halo0.nc
      ln_vrfy -s ${bkpath}/sfc_data.tile7.halo0.nc bk_sfc_data.tile7.halo0.nc
      print_info_msg "$VERBOSE" "cold start from $bkpath"
      if [ ${SAVE_CYCLE_LOG} == "TRUE" ] ; then
        echo "${YYYYMMDDHH}(${CYCLE_TYPE}): cold start at ${current_time} from $bkpath " >> ${EXPTDIR}/log.cycles
      fi
    else
      print_err_msg_exit "Error: cannot find cold start initial condition from : ${bkpath}"
    fi

else

# Setup the INPUT directory for warm start cycles, which can be spin-up cycle or product cycle.
#
# First decide the source of the first guess (fg_restart_dirname) depending on CYCLE_TYPE and BKTYPE:
#  1. If cycle is spinup cycle (CYCLE_TYPE == spinup) or it is the product start cycle (BKTYPE==2),
#             looking for the first guess from spinup forecast (fcst_fv3lam_spinup)
#  2. Others, looking for the first guess from product forecast (fcst_fv3lam)
#
  if [ ${CYCLE_TYPE} == "spinup" ] || [ ${BKTYPE} -eq 2 ]; then
     fg_restart_dirname=fcst_fv3lam_spinup
  else
     fg_restart_dirname=fcst_fv3lam
  fi
#
#   let us figure out which backgound is available
#
#   the restart file from FV3 has a name like: ${YYYYMMDD}.${HH}0000.fv_core.res.tile1.nc
#   But the restart files for the forecast length has a name like: fv_core.res.tile1.nc
#   So the defination of restart_prefix needs a "." at the end.
#
  restart_prefix="${YYYYMMDD}.${HH}0000."

  if [ ${CYCLE_SUBTYPE} == "spinup" ] ; then
# point to the 0-h cycle for the warm start from the 1 timestep restart files
    fg_restart_dirname=fcst_fv3lam_ensinit
    bkpath=${FG_ROOT}/${YYYYMMDDHH}${SLASH_ENSMEM_SUBDIR}/${fg_restart_dirname}/RESTART  # cycling, use background from RESTART
  else
    YYYYMMDDHHmInterv=$( date +%Y%m%d%H -d "${START_DATE} ${DA_CYCLE_INTERV} hours ago" )
    bkpath=${FG_ROOT}/${YYYYMMDDHHmInterv}${SLASH_ENSMEM_SUBDIR}/${fg_restart_dirname}/RESTART  # cycling, use background from RESTART

  n=${DA_CYCLE_INTERV}
  while [[ $n -le 6 ]] ; do
    checkfile=${bkpath}/${restart_prefix}coupler.res
    if [ -r "${checkfile}" ] ; then
      print_info_msg "$VERBOSE" "Found ${checkfile}; Use it as background for analysis "
      break
    else
      n=$((n + ${DA_CYCLE_INTERV}))
      YYYYMMDDHHmInterv=$( date +%Y%m%d%H -d "${START_DATE} ${n} hours ago" )
      bkpath=${FG_ROOT}/${YYYYMMDDHHmInterv}${SLASH_ENSMEM_SUBDIR}/${fg_restart_dirname}/RESTART  # cycling, use background from RESTART
      print_info_msg "$VERBOSE" "Trying this path: ${bkpath}"
    fi
  done
#
  checkfile=${bkpath}/${restart_prefix}coupler.res
# spin-up cycle is not success, try to find background from full cycle
  if [ ! -r "${checkfile}" ] && [ ${BKTYPE} -eq 2 ]; then
     print_info_msg "$VERBOSE" "cannot find background from spin-up cycle, try product cycle"
     fg_restart_dirname=fcst_fv3lam
     YYYYMMDDHHmInterv=$( date +%Y%m%d%H -d "${START_DATE} ${DA_CYCLE_INTERV} hours ago" )
     bkpath=${FG_ROOT}/${YYYYMMDDHHmInterv}${SLASH_ENSMEM_SUBDIR}/${fg_restart_dirname}/RESTART  # cycling, use background from RESTART
#
     restart_prefix="${YYYYMMDD}.${HH}0000."
     n=${DA_CYCLE_INTERV}
     while [[ $n -le 6 ]] ; do
       checkfile=${bkpath}/${restart_prefix}coupler.res
       if [ -r "${checkfile}" ] ; then
         print_info_msg "$VERBOSE" "Found ${checkfile}; Use it as background for analysis "
         break
       else
         n=$((n + ${DA_CYCLE_INTERV}))
         YYYYMMDDHHmInterv=$( date +%Y%m%d%H -d "${START_DATE} ${n} hours ago" )
         bkpath=${FG_ROOT}/${YYYYMMDDHHmInterv}${SLASH_ENSMEM_SUBDIR}/${fg_restart_dirname}/RESTART  # cycling, use background from RESTART
         print_info_msg "$VERBOSE" "Trying this path: ${bkpath}"
       fi
     done
  fi
#
  fi

  filelistn="fv_core.res.tile1.nc fv_srf_wnd.res.tile1.nc fv_tracer.res.tile1.nc phy_data.nc sfc_data.nc"
  checkfile=${bkpath}/${restart_prefix}coupler.res
  n_iolayouty=$(($IO_LAYOUT_Y-1))
  list_iolayout=$(seq 0 $n_iolayouty)
  if [ -r "${checkfile}" ] ; then
    cp_vrfy ${bkpath}/${restart_prefix}coupler.res                bk_coupler.res
    cp_vrfy ${bkpath}/${restart_prefix}fv_core.res.nc             fv_core.res.nc
    if [ "${IO_LAYOUT_Y}" == "1" ]; then
      for file in ${filelistn}; do
        cp_vrfy ${bkpath}/${restart_prefix}${file}     ${file}
        ln_vrfy -s ${bkpath}/${restart_prefix}${file}     bk_${file}
      done
    else
      for file in ${filelistn}; do
        for ii in $list_iolayout
        do
          iii=$(printf %4.4i $ii)
          cp_vrfy ${bkpath}/${restart_prefix}${file}.${iii}     ${file}.${iii}
          ln_vrfy -s ${bkpath}/${restart_prefix}${file}.${iii}     bk_${file}.${iii}
        done
      done
    fi
    if [ ${CYCLE_SUBTYPE} == "spinup" ] ; then
      cp_vrfy ${FG_ROOT}/${YYYYMMDDHH}${SLASH_ENSMEM_SUBDIR}/${fg_restart_dirname}/INPUT/gfs_ctrl.nc  gfs_ctrl.nc
    else
      cp_vrfy ${FG_ROOT}/${YYYYMMDDHHmInterv}${SLASH_ENSMEM_SUBDIR}/${fg_restart_dirname}/INPUT/gfs_ctrl.nc  gfs_ctrl.nc
    fi
    if [ ${SAVE_CYCLE_LOG} == "TRUE" ] ; then
      echo "${YYYYMMDDHH}(${CYCLE_TYPE}): warm start at ${current_time} from ${checkfile} " >> ${EXPTDIR}/log.cycles
    fi
#
# remove checksum from restart files. Checksum will cause trouble if model initializes from analysis
#
    if [ "${IO_LAYOUT_Y}" == "1" ]; then
      for file in ${filelistn}; do
        ncatted -a checksum,,d,, ${file}
      done
      ncatted -O -a source,global,c,c,'FV3GFS GAUSSIAN NETCDF FILE' fv_core.res.tile1.nc
    else
      for file in ${filelistn}; do
        for ii in $list_iolayout
        do
          iii=$(printf %4.4i $ii)
          ncatted -a checksum,,d,, ${file}.${iii}
        done
      done
      for ii in $list_iolayout
      do
        iii=$(printf %4.4i $ii)
        ncatted -O -a source,global,c,c,'FV3GFS GAUSSIAN NETCDF FILE' fv_core.res.tile1.nc.${iii}
      done
    fi
    ncatted -a checksum,,d,, fv_core.res.nc

# generate coupler.res with right date
    if [ ${CYCLE_SUBTYPE} == "spinup" ]; then
# from the 1 timestep restart files
      head -2 bk_coupler.res > coupler.res
      head -2 bk_coupler.res | tail -1 >> coupler.res
    else
      head -1 bk_coupler.res > coupler.res
      tail -1 bk_coupler.res >> coupler.res
      tail -1 bk_coupler.res >> coupler.res
    fi
  else
    print_err_msg_exit "Error: cannot find background: ${checkfile}"
  fi
fi

#-----------------------------------------------------------------------
#
# do snow/ice update at ${SNOWICE_update_hour}z for the restart sfc_data.nc
#
#-----------------------------------------------------------------------

if [ ${HH} -eq ${SNOWICE_update_hour} ] && [ ${CYCLE_TYPE} == "prod" ] ; then
   echo "Update snow cover based on imssnow  at ${SNOWICE_update_hour}z"
   if [ -r "${IMSSNOW_ROOT}/latest.SNOW_IMS" ]; then
      cp ${IMSSNOW_ROOT}/latest.SNOW_IMS .
   elif [ -r "${IMSSNOW_ROOT}/${YYJJJ2200000000}" ]; then
      cp ${IMSSNOW_ROOT}/${YYJJJ2200000000} latest.SNOW_IMS
   elif [ -r "${IMSSNOW_ROOT}/rap.${YYYYMMDD}/rap.t${HH}z.imssnow.grib2" ]; then
      cp ${IMSSNOW_ROOT}/rap.${YYYYMMDD}/rap.t${HH}z.imssnow.grib2  latest.SNOW_IMS
   elif [ -r "${IMSSNOW_ROOT}/rap.${YYYYMMDD}/rap_e.t${HH}z.imssnow.grib2" ]; then
      cp ${IMSSNOW_ROOT}/rap_e.${YYYYMMDD}/rap_e.t${HH}z.imssnow.grib2  latest.SNOW_IMS
   else
     echo "${IMSSNOW_ROOT} data does not exist!!"
     echo "ERROR: No snow update at ${HH}!!!!"
   fi
   if [ -r "latest.SNOW_IMS" ]; then
     ln_vrfy -sf ./latest.SNOW_IMS                imssnow2

     if [ "${IO_LAYOUT_Y}" == "1" ]; then
       ln_vrfy -sf ${FIX_GSI}/${PREDEF_GRID_NAME}/fv3_grid_spec  fv3_grid_spec
     else
       for ii in ${list_iolayout}
       do
         iii=$(printf %4.4i $ii)
         ln_vrfy -sf ${gridspec_dir}/fv3_grid_spec.${iii}  fv3_grid_spec.${iii}
       done
     fi
#
# copy executable
#
     snowice_exec_fn="process_imssnow_fv3lam.exe"
     snowice_exec_fp="$EXECdir/${snowice_exec_fn}"
     if [ ! -f "${snowice_exec_fp}" ]; then
      print_err_msg_exit "\
The executable (snowice_exec_fn) for processing snow/ice data onto FV3-LAM
native grid does not exist:
  snowice_exec_fp= \"${snowice_exec_fp}\"
Please ensure that you have built this executable."
     fi

     PREP_STEP
     eval $RUN_CMD_UTILS ${snowice_exec_fp}  ${IO_LAYOUT_Y} ${REDIRECT_OUT_ERR} || \
     print_err_msg_exit "\
 Call to executable (fvcom_exe) to modify sfc fields for FV3-LAM failed:
   snowice_exe = \"${snowice_exec_fp}\"
 The following variables were being used:
   list_iolayout = \"${list_iolayout}\""
     POST_STEP

     snowice_reference_time=$(wgrib2 -t latest.SNOW_IMS | tail -1) 
     if [ ${SAVE_CYCLE_LOG} == "TRUE" ] ; then
       echo "${YYYYMMDDHH}(${CYCLE_TYPE}): update snow/ice using ${snowice_reference_time}" >> ${EXPTDIR}/log.cycles
     fi
   else
     echo "ERROR: No latest IMS SNOW file for update at ${YYYYMMDDHH}!!!!"
   fi
else
   echo "NOTE: No update for IMS SNOW/ICE at ${YYYYMMDDHH}!"
fi
#-----------------------------------------------------------------------
#
# do SST update at ${SST_update_hour}z for the restart sfc_data.nc
#
#-----------------------------------------------------------------------
if [ ${HH} -eq ${SST_update_hour} ] && [ ${CYCLE_TYPE} == "prod" ] ; then
   echo "Update SST at ${SST_update_hour}z"
   if [ -r "${SST_ROOT}/latest.SST" ]; then
      cp ${SST_ROOT}/latest.SST .
   elif [ -r "${SST_ROOT}/${YYJJJ00000000}" ]; then
      cp ${SST_ROOT}/${YYJJJ00000000} latest.SST
   elif [ -r "${SST_ROOT}/sst.$YYYYMMDD/rtgssthr_grb_0.083.grib2" ]; then 
      cp ${SST_ROOT}/sst.$YYYYMMDD/rtgssthr_grb_0.083.grib2 latest.SST
   elif [ -r "${SST_ROOT}/sst.$YYYYMMDDm1/rtgssthr_grb_0.083.grib2" ]; then 
      cp ${SST_ROOT}/sst.$YYYYMMDDm1/rtgssthr_grb_0.083.grib2 latest.SST
   else
     echo "${SST_ROOT} data does not exist!!"
     echo "ERROR: No SST update at ${HH}!!!!"
   fi
   if [ -r "latest.SST" ]; then
     cp_vrfy ${FIXgsm}/RTG_SST_landmask.dat                RTG_SST_landmask.dat
     ln_vrfy -sf ./latest.SST                                  SSTRTG
     cp_vrfy ${FIX_GSI}/${PREDEF_GRID_NAME}/fv3_akbk       fv3_akbk

cat << EOF > sst.namelist
&setup
  bkversion=1,
  iyear=${YYYY}
  imonth=${MM}
  iday=${DD}
  ihr=${HH}
/
EOF
     if [ "${IO_LAYOUT_Y}" == "1" ]; then
       ln_vrfy -sf ${FIX_GSI}/${PREDEF_GRID_NAME}/fv3_grid_spec  fv3_grid_spec
       ${EXECdir}/process_updatesst.exe > stdout_sstupdate 2>&1
     else
       for ii in ${list_iolayout}
       do
         iii=$(printf %4.4i $ii)
         ln_vrfy -sf ${gridspec_dir}/fv3_grid_spec.${iii}  fv3_grid_spec
         ln_vrfy -sf sfc_data.nc.${iii} sfc_data.nc
         ${EXECdir}/process_updatesst.exe > stdout_sstupdate.${iii} 2>&1
         ls -l > list_sstupdate.${iii}
       done
       rm -f sfc_data.nc
     fi

     sst_reference_time=$(wgrib2 -t latest.SST) 
     if [ ${SAVE_CYCLE_LOG} == "TRUE" ] ; then
       echo "${YYYYMMDDHH}(${CYCLE_TYPE}): update SST using ${sst_reference_time}" >> ${EXPTDIR}/log.cycles
     fi
   else
     echo "ERROR: No latest SST file for update at ${YYYYMMDDHH}!!!!"
   fi
else
   echo "NOTE: No update for SST at ${YYYYMMDDHH}!"
fi

#-----------------------------------------------------------------------
#
#  smoke/dust cycling
#
#-----------------------------------------------------------------------
if [ "${DO_SMOKE_DUST}" = "TRUE" ] && [ ${CYCLE_TYPE} == "spinup" ] ; then  # cycle smoke/dust fields
  if [ ${HH} -eq 4 ] || [ ${HH} -eq 16 ] ; then

# figure out which surface is available
      surface_file_dir_name=fcst_fv3lam
      bkpath_find="missing"
      restart_prefix_find="missing"
      if [ "${bkpath_find}" == "missing" ]; then
          restart_prefix=$( date +%Y%m%d.%H0000. -d "${START_DATE}" )

          offset_hours=${DA_CYCLE_INTERV}
          YYYYMMDDHHmInterv=$( date +%Y%m%d%H -d "${START_DATE} ${offset_hours} hours ago" )
          bkpath=${FG_ROOT}/${YYYYMMDDHHmInterv}${SLASH_ENSMEM_SUBDIR}/${surface_file_dir_name}/RESTART  

          n=${DA_CYCLE_INTERV}
          while [[ $n -le 6 ]] ; do
             if [ "${IO_LAYOUT_Y}" == "1" ]; then
               checkfile=${bkpath}/${restart_prefix}fv_tracer.res.tile1.nc
             else
               checkfile=${bkpath}/${restart_prefix}fv_tracer.res.tile1.nc.0000
             fi
             if [ -r "${checkfile}" ] && [ "${bkpath_find}" == "missing" ]; then
               bkpath_find=${bkpath}
               restart_prefix_find=${restart_prefix}
               print_info_msg "$VERBOSE" "Found ${checkfile}; Use it for smoke/dust cycle "
               break
             fi
 
             n=$((n + ${DA_CYCLE_INTERV}))
             offset_hours=${n}
             YYYYMMDDHHmInterv=$( date +%Y%m%d%H -d "${START_DATE} ${offset_hours} hours ago" )
             bkpath=${FG_ROOT}/${YYYYMMDDHHmInterv}${SLASH_ENSMEM_SUBDIR}/${surface_file_dir_name}/RESTART  # cycling, use background from RESTART
             print_info_msg "$VERBOSE" "Trying this path: ${bkpath}"
          done
      fi

# cycle smoke/dust
      rm -f cycle_smoke_dust.done
      if [ "${bkpath_find}" == "missing" ]; then
        print_info_msg "Warning: cannot find smoke/dust files from previous cycle"
      else
        if [ "${IO_LAYOUT_Y}" == "1" ]; then
          checkfile=${bkpath_find}/${restart_prefix_find}fv_tracer.res.tile1.nc
          if [ -r "${checkfile}" ]; then
            ncks -A -v smoke,dust ${checkfile}  fv_tracer.res.tile1.nc
          fi
        else
          for ii in ${list_iolayout}
          do
            iii=$(printf %4.4i $ii)
            checkfile=${bkpath_find}/${restart_prefix_find}fv_tracer.res.tile1.nc.${iii}
            if [ -r "${checkfile}" ]; then
              ncks -A -v smoke,dust ${checkfile}  fv_tracer.res.tile1.nc.${iii}
            fi
          done
        fi
        echo "${YYYYMMDDHH}(${CYCLE_TYPE}): cycle smoke/dust from ${checkfile} " >> ${EXPTDIR}/log.cycles
      fi
  fi
fi
#-----------------------------------------------------------------------
#
#  surface cycling
#
#-----------------------------------------------------------------------
#SFC_CYC=2
if_update_ice="TRUE"
if [ ${SFC_CYC} -eq 1 ] || [ ${SFC_CYC} -eq 2 ] ; then  # cycle surface fields

# figure out which surface is available
      surface_file_dir_name=fcst_fv3lam
      bkpath_find="missing"
      restart_prefix_find="missing"
      for ndayinhour in 00 24 48 72
      do 
        if [ "${bkpath_find}" == "missing" ]; then
          restart_prefix=$( date +%Y%m%d.%H0000. -d "${START_DATE} ${ndayinhour} hours ago" )

          offset_hours=$(( ${DA_CYCLE_INTERV} + ${ndayinhour} ))
          YYYYMMDDHHmInterv=$( date +%Y%m%d%H -d "${START_DATE} ${offset_hours} hours ago" )
          bkpath=${FG_ROOT}/${YYYYMMDDHHmInterv}${SLASH_ENSMEM_SUBDIR}/${surface_file_dir_name}/RESTART  

          n=${DA_CYCLE_INTERV}
          while [[ $n -le 6 ]] ; do
             if [ "${IO_LAYOUT_Y}" == "1" ]; then
               checkfile=${bkpath}/${restart_prefix}sfc_data.nc
             else
               checkfile=${bkpath}/${restart_prefix}sfc_data.nc.0000
             fi
             if [ -r "${checkfile}" ] && [ "${bkpath_find}" == "missing" ]; then
               bkpath_find=${bkpath}
               restart_prefix_find=${restart_prefix}
               print_info_msg "$VERBOSE" "Found ${checkfile}; Use it as surface for analysis "
             fi
 
             n=$((n + ${DA_CYCLE_INTERV}))
             offset_hours=$(( ${n} + ${ndayinhour} ))
             YYYYMMDDHHmInterv=$( date +%Y%m%d%H -d "${START_DATE} ${offset_hours} hours ago" )
             bkpath=${FG_ROOT}/${YYYYMMDDHHmInterv}${SLASH_ENSMEM_SUBDIR}/${surface_file_dir_name}/RESTART  # cycling, use background from RESTART
             print_info_msg "$VERBOSE" "Trying this path: ${bkpath}"
          done
        fi

      done

# rename the soil mositure and temperature fields in restart file
      rm -f cycle_surface.done
      if [ "${bkpath_find}" == "missing" ]; then
        print_info_msg "Warning: cannot find surface from previous cycle"
      else
        if [ "${IO_LAYOUT_Y}" == "1" ]; then
          checkfile=${bkpath_find}/${restart_prefix_find}sfc_data.nc
        else
          checkfile=${bkpath_find}/${restart_prefix_find}sfc_data.nc.0000
        fi
        if [ -r "${checkfile}" ]; then
          if [ ${SFC_CYC} -eq 1 ]; then   # cycle surface at cold start cycle
            if [ "${IO_LAYOUT_Y}" == "1" ]; then 
              cp_vrfy ${checkfile}  ${restart_prefix_find}sfc_data.nc
              mv sfc_data.tile7.halo0.nc cold.sfc_data.tile7.halo0.nc
              ncks -v geolon,geolat cold.sfc_data.tile7.halo0.nc geolonlat.nc
              ln_vrfy -sf ${restart_prefix_find}sfc_data.nc sfc_data.tile7.halo0.nc
              ncks --append geolonlat.nc sfc_data.tile7.halo0.nc
              ncrename -v tslb,stc -v smois,smc -v sh2o,slc sfc_data.tile7.halo0.nc
            else
              print_info_msg "Warning: cannot do surface cycle in cold start with sudomain restart files"
            fi
          else
            if [ "${IO_LAYOUT_Y}" == "1" ]; then 
              cp_vrfy ${checkfile}  ${restart_prefix_find}sfc_data.nc
              mv sfc_data.nc gfsice.sfc_data.nc
              mv ${restart_prefix_find}sfc_data.nc sfc_data.nc
              ncatted -a checksum,,d,, sfc_data.nc
              if [ "${if_update_ice}" == "TRUE" ]; then
                ${EXECdir}/update_ice.exe > stdout_cycleICE 2>&1
              fi
            else
              checkfile=${bkpath_find}/${restart_prefix_find}sfc_data.nc
              for ii in ${list_iolayout}
              do
                iii=$(printf %4.4i $ii)
                cp_vrfy ${checkfile}.${iii}  ${restart_prefix_find}sfc_data.nc.${iii}
                mv sfc_data.nc.${iii} gfsice.sfc_data.nc.${iii}
                mv ${restart_prefix_find}sfc_data.nc.${iii} sfc_data.nc.${iii}
                ncatted -a checksum,,d,, sfc_data.nc.${iii}
              done
              ls -l > list_cycle_sfc
              for ii in ${list_iolayout}
              do
                iii=$(printf %4.4i $ii)
                ln_vrfy -sf sfc_data.nc.${iii} sfc_data.nc
                ln_vrfy -sf gfsice.sfc_data.nc.${iii} gfsice.sfc_data.nc
                if [ "${if_update_ice}" == "TRUE" ]; then
                  ${EXECdir}/update_ice.exe > stdout_cycleICE.${iii} 2>&1
                fi
              done
              rm -f sfc_data.nc gfsice.sfc_data.nc
            fi
          fi
          echo "cycle surface with ${checkfile}" > cycle_surface.done
          if [ ${SAVE_CYCLE_LOG} == "TRUE" ] ; then
            echo "${YYYYMMDDHH}(${CYCLE_TYPE}): cycle surface with ${checkfile} " >> ${EXPTDIR}/log.cycles
          fi
        else
          print_info_msg "Warning: cannot find surface from previous cycle"
        fi
      fi
fi

#-----------------------------------------------------------------------
#
# do update_GVF at ${GVF_update_hour}z for the restart sfc_data.nc
#
#-----------------------------------------------------------------------
if [ ${HH} -eq ${GVF_update_hour} ] && [ ${CYCLE_TYPE} == "spinup" ]; then
   latestGVF=$(ls ${GVF_ROOT}/GVF-WKL-GLB_v?r?_npp_s*_e${YYYYMMDDm1}_c${YYYYMMDD}*.grib2)
   latestGVF2=$(ls ${GVF_ROOT}/GVF-WKL-GLB_v?r?_npp_s*_e${YYYYMMDDm2}_c${YYYYMMDDm1}*.grib2)
   if [ ! -r "${latestGVF}" ]; then
     if [ -r "${latestGVF2}" ]; then
       latestGVF=${latestGVF2}
     else
       print_info_msg "Warning: cannot find GVF observation file"
     fi
   fi

   if [ -r "${latestGVF}" ]; then
      cp_vrfy ${latestGVF} ./GVF-WKL-GLB.grib2
      ln_vrfy -sf ${FIX_GSI}/gvf_VIIRS_4KM.MAX.1gd4r.new  gvf_VIIRS_4KM.MAX.1gd4r.new
      ln_vrfy -sf ${FIX_GSI}/gvf_VIIRS_4KM.MIN.1gd4r.new  gvf_VIIRS_4KM.MIN.1gd4r.new

      if [ "${IO_LAYOUT_Y}" == "1" ]; then
        ln_vrfy -sf ${FIX_GSI}/${PREDEF_GRID_NAME}/fv3_grid_spec  fv3_grid_spec
        ${EXECdir}/update_GVF.exe > stdout_updateGVF 2>&1
      else
        for ii in ${list_iolayout}
        do
          iii=$(printf %4.4i $ii)
          ln_vrfy -sf ${gridspec_dir}/fv3_grid_spec.${iii}  fv3_grid_spec
          ln_vrfy -sf sfc_data.nc.${iii} sfc_data.nc
          ${EXECdir}/update_GVF.exe > stdout_updateGVF.${iii} 2>&1
          ls -l > list_updateGVF.${iii}
        done
        rm -f sfc_data.nc
      fi

      if [ ${SAVE_CYCLE_LOG} == "TRUE" ] ; then
         echo "${YYYYMMDDHH}(${CYCLE_TYPE}): update GVF with ${latestGVF} " >> ${EXPTDIR}/log.cycles
      fi
   fi
fi

fi
#-----------------------------------------------------------------------
#
# go to INPUT directory.
# prepare boundary conditions:
#       the previous 12 cycles are searched to find the boundary files
#       that can cover the forecast length.
#       The 0-h boundary is copied and others are linked.
#
#-----------------------------------------------------------------------

if [[ "${NET}" = "RTMA"* ]]; then
    #find a bdry file, make sure it exists and was written out completely.
    for i in $(seq 0 24); do #track back up to 24 cycles to find bdry files
      lbcDIR="${LBCS_ROOT}/$(date -d "${START_DATE} ${i} hours ago" +"%Y%m%d%H")/lbcs"
      if [[  -f ${lbcDIR}/gfs_bndy.tile7.001.nc ]]; then
        age=$(( $(date +%s) - $(date -r ${lbcDIR}/gfs_bndy.tile7.001.nc +%s) ))
        [[ age -gt 300 ]] && break
      fi
    done
    ln_vrfy -snf ${lbcDIR}/gfs_bndy.tile7.000.nc .
    ln_vrfy -snf ${lbcDIR}/gfs_bndy.tile7.001.nc .

else
  num_fhrs=( "${#FCST_LEN_HRS_CYCLES[@]}" )
  ihh=$( expr ${HH} + 0 )
  if [ ${num_fhrs} -gt ${ihh} ]; then
     FCST_LEN_HRS_thiscycle=${FCST_LEN_HRS_CYCLES[${ihh}]}
  else
     FCST_LEN_HRS_thiscycle=${FCST_LEN_HRS}
  fi
  if [ ${CYCLE_TYPE} == "spinup" ]; then
     FCST_LEN_HRS_thiscycle=${FCST_LEN_HRS_SPINUP}
  fi 
  print_info_msg "$VERBOSE" " The forecast length for cycle (\"${HH}\") is
                 ( \"${FCST_LEN_HRS_thiscycle}\") "

#   let us figure out which boundary file is available
  bndy_prefix=gfs_bndy.tile7
  n=${EXTRN_MDL_LBCS_SEARCH_OFFSET_HRS}
  end_search_hr=$(( 12 + ${EXTRN_MDL_LBCS_SEARCH_OFFSET_HRS} ))
  YYYYMMDDHHmInterv=$(date +%Y%m%d%H -d "${START_DATE} ${n} hours ago")
  lbcs_path=${LBCS_ROOT}/${YYYYMMDDHHmInterv}${SLASH_ENSMEM_SUBDIR}/lbcs
  while [[ $n -le ${end_search_hr} ]] ; do
    last_bdy_time=$(( n + ${FCST_LEN_HRS_thiscycle} ))
    last_bdy=$(printf %3.3i $last_bdy_time)
    checkfile=${lbcs_path}/${bndy_prefix}.${last_bdy}.nc
    if [ -r "${checkfile}" ]; then
      print_info_msg "$VERBOSE" "Found ${checkfile}; Use it as boundary for forecast "
      break
    else
      n=$((n + 1))
      YYYYMMDDHHmInterv=$(date +%Y%m%d%H -d "${START_DATE} ${n} hours ago")
      lbcs_path=${LBCS_ROOT}/${YYYYMMDDHHmInterv}${SLASH_ENSMEM_SUBDIR}/lbcs
    fi
  done
#
  relative_or_null="--relative"
  nb=1
  if [ -r "${checkfile}" ]; then
    while [ $nb -le ${FCST_LEN_HRS_thiscycle} ]
    do
      bdy_time=$(( ${n} + ${nb} ))
      this_bdy=$(printf %3.3i $bdy_time)
      local_bdy=$(printf %3.3i $nb)

      if [ -f "${lbcs_path}/${bndy_prefix}.${this_bdy}.nc" ]; then
        ln_vrfy -sf ${relative_or_null} ${lbcs_path}/${bndy_prefix}.${this_bdy}.nc ${bndy_prefix}.${local_bdy}.nc
      fi

      nb=$((nb + 1))
    done
# check 0-h boundary condition
    if [ ! -f "${bndy_prefix}.000.nc" ]; then
      this_bdy=$(printf %3.3i ${n})
      cp_vrfy ${lbcs_path}/${bndy_prefix}.${this_bdy}.nc ${bndy_prefix}.000.nc 
    fi
  else
    print_err_msg_exit "Error: cannot find boundary file: ${checkfile}"
  fi

fi 

#
#-----------------------------------------------------------------------
#
# condut surface surgery to transfer RAP/HRRR surface fields into RRFS.
# 
# This surgery only needs to be done once to give RRFS a good start of the surfcase.
# Please consult Ming or Tanya first before turning on this surgery.
#
#-----------------------------------------------------------------------
# 
if [ ${YYYYMMDDHH} -eq ${SOIL_SURGERY_time} ] ; then
if [ ${CYCLE_TYPE} == "spinup" ]; then

#   raphrrr_com=/mnt/lfs4/BMC/rtwbl/mhu/wcoss/nco/com/
#   ln -s ${raphrrr_com}/rap/prod/rap.${YYYYMMDD}/rap.t${HH}z.wrf_inout_smoke    sfc_rap
#   ln -s ${raphrrr_com}/hrrr/prod/hrrr.${YYYYMMDD}/conus/hrrr.t${HH}z.wrf_inout sfc_hrrr
#   ln -s ${raphrrr_com}/hrrr/prod/hrrr.${YYYYMMDD}/alaska/hrrrak.t${HH}z.wrf_inout sfc_hrrrak
   raphrrr_com=${RAPHRR_SOIL_ROOT}
   rapfile='missing'
   hrrrfile='missing'
   hrrr_akfile='missing'
   if [ -r ${raphrrr_com}/${YYYYMMDD}/rap.t${HH}z.wrf_inout_smoke ]; then
     ln -s ${raphrrr_com}/${YYYYMMDD}/rap.t${HH}z.wrf_inout_smoke    sfc_rap
     rapfile='sfc_rap'
   fi
   if [ -r ${raphrrr_com}/${YYYYMMDD}/hrrr.t${HH}z.wrf_inout ]; then
     ln -s ${raphrrr_com}/${YYYYMMDD}/hrrr.t${HH}z.wrf_inout sfc_hrrr
     hrrrfile='sfc_hrrr'
   fi
   if [ -r ${raphrrr_com}/${YYYYMMDD}/hrrrak.t${HH}z.wrf_inout ]; then
     ln -s ${raphrrr_com}/${YYYYMMDD}/hrrr.t${HH}z.wrf_inout sfc_hrrrak
     hrrr_akfile='sfc_hrrrak'
   fi
 
cat << EOF > use_raphrrr_sfc.namelist
&setup
rapfile=${rapfile}
hrrrfile=${hrrrfile}
hrrr_akfile=${hrrr_akfile}
rrfsfile='sfc_data.nc'
/
EOF

   exect="use_raphrrr_sfc.exe"
   if [ -f ${EXECdir}/$exect ]; then
     print_info_msg "$VERBOSE" "
     Copying the surface surgery executable to the run directory..."
     cp_vrfy ${EXECdir}/${exect} ${exect}

     if [ "${IO_LAYOUT_Y}" == "1" ]; then
       ln_vrfy -sf ${FIX_GSI}/${PREDEF_GRID_NAME}/fv3_grid_spec  fv3_grid_spec
       ./${exect} > stdout_sfc_sugery 2>&1 || print_info_msg "\
       Call to executable to run surface surgery returned with nonzero exit code."
     else
       for ii in ${list_iolayout}
       do
         iii=$(printf %4.4i $ii)
         ln_vrfy -sf ${gridspec_dir}/fv3_grid_spec.${iii}  fv3_grid_spec
         ln_vrfy -sf sfc_data.nc.${iii} sfc_data.nc
         ./${exect} > stdout_sfc_sugery.${iii} 2>&1 || print_info_msg "\
         Call to executable to run surface surgery returned with nonzero exit code."
         ls -l > list_sfc_sugery.${iii}
       done
       rm -f sfc_data.nc
     fi

     if [ ${SAVE_CYCLE_LOG} == "TRUE" ] ; then
       echo "${YYYYMMDDHH}(${CYCLE_TYPE}): run surface surgery" >> ${EXPTDIR}/log.cycles
     fi
   else
     print_info_msg "\
     The executable specified in exect does not exist:
     exect = \"${EXECdir}/$exect\"
     Build executable and rerun."
   fi
fi
fi

#
#-----------------------------------------------------------------------
#
# Process FVCOM Data
#
#-----------------------------------------------------------------------
#
if [ "${USE_FVCOM}" = "TRUE" ] || [ ${SFC_CYC} -eq 2 ] ; then

# Remap the FVCOM output from the 5 lakes onto the RRFS grid
  if [ "${PREP_FVCOM}" = "TRUE" ]; then
    ${SCRIPTSDIR}/exregional_prep_fvcom.sh \
                  DATA="${DATA}" \
                  FIXLAM="${FIXLAM}" \
                  FVCOM_DIR="${FVCOM_DIR}" \
              YYYYJJJHH="${YYYYJJJHH}" \
                  YYYYMMDD="${YYYYMMDD}" \
                  YYYYMMDDm1="${YYYYMMDDm1}" \
                  HH="${HH}" || \
    print_err_msg_exit "\
    Call to ex-script failed."

    cd_vrfy ${DATA}
# FVCOM_DIR needs to be redefined here to find 
    FVCOM_DIR=${DATA}/fvcom_remap
  fi

  set -x
  latest_fvcom_file="${FVCOM_DIR}/${FVCOM_FILE}"
  if [ ${HH} -gt 12 ]; then 
    starttime_fvcom="$(date +%Y%m%d -d "${START_DATE}") 12"
  else
    starttime_fvcom="$(date +%Y%m%d -d "${START_DATE}") 00"
  fi
  for ii in $(seq 0 3)
  do
     jumphour=$((${ii} * 12))
     fvcomtime=$(date +%Y%j%H -d "${starttime_fvcom}  ${jumphour} hours ago")
     fvcom_data_fp="${latest_fvcom_file}_${fvcomtime}.nc"
     if [ -f "${fvcom_data_fp}" ]; then
       break 
     fi
  done

  if [ ! -f "${fvcom_data_fp}" ]; then
    print_info_msg "\
The file or path (fvcom_data_fp) does not exist:
  fvcom_data_fp = \"${fvcom_data_fp}\"
Please check the following user defined variables:
  FVCOM_DIR = \"${FVCOM_DIR}\"
  FVCOM_FILE= \"${FVCOM_FILE}\" "

  else
    cp_vrfy ${fvcom_data_fp} fvcom.nc

#Format for fvcom_time: YYYY-MM-DDTHH:00:00.000000
    fvcom_time="${YYYY}-${MM}-${DD}T${HH}:00:00.000000"
    fvcom_exec_fn="fvcom_to_FV3"
    fvcom_exec_fp="$EXECdir/${fvcom_exec_fn}"
    if [ ! -f "${fvcom_exec_fp}" ]; then
      print_err_msg_exit "\
The executable (fvcom_exec_fp) for processing FVCOM data onto FV3-LAM
native grid does not exist:
  fvcom_exec_fp = \"${fvcom_exec_fp}\"
Please ensure that you've built this executable."
    fi
    cp_vrfy ${fvcom_exec_fp} .

# decide surface
    if [ ${BKTYPE} -eq 1 ] ; then
      FVCOM_WCSTART='cold'
      surface_file='sfc_data.tile7.halo0.nc'
    else
      FVCOM_WCSTART='warm'
      surface_file='sfc_data.nc'
    fi

#
    PREP_STEP
    eval $RUN_CMD_UTILS ${fvcom_exec_fn} ${surface_file} fvcom.nc ${FVCOM_WCSTART} ${fvcom_time} ${IO_LAYOUT_Y} ${REDIRECT_OUT_ERR} || \
    print_err_msg_exit "\
Call to executable (fvcom_exe) to modify sfc fields for FV3-LAM failed:
  fvcom_exe = \"${fvcom_exec_fn}\"
The following variables were being used:
  FVCOM_DIR = \"${FVCOM_DIR}\"
  FVCOM_FILE = \"${FVCOM_FILE}\"
  fvcom_time = \"${fvcom_time}\"
  FVCOM_WCSTART = \"${FVCOM_WCSTART}\"
  "
    POST_STEP

  fi
fi

#
#-----------------------------------------------------------------------
#
# Print message indicating successful completion of script.
#
#-----------------------------------------------------------------------
#
print_info_msg "
========================================================================
Prepare start completed successfully!!!
Exiting script:  \"${scrfunc_fn}\"
In directory:    \"${scrfunc_dir}\"
========================================================================"
#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script/func-
# tion.
#
#-----------------------------------------------------------------------
#
{ restore_shell_opts; } > /dev/null 2>&1
