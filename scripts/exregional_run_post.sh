#!/bin/bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. $USHdir/source_util_funcs.sh
source_config_for_task "task_run_post" ${GLOBAL_VAR_DEFNS_FP}
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
scrfunc_fp=$( $READLINK -f "${BASH_SOURCE[0]}" )
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

This is the ex-script for the task that runs the post-processor (UPP) on
the output files corresponding to a specified forecast hour.
========================================================================"
#
#-----------------------------------------------------------------------
#
# Set OpenMP variables.
#
#-----------------------------------------------------------------------
#
export KMP_AFFINITY=${KMP_AFFINITY_RUN_POST}
export OMP_NUM_THREADS=${OMP_NUM_THREADS_RUN_POST}
export OMP_STACKSIZE=${OMP_STACKSIZE_RUN_POST}
#
#-----------------------------------------------------------------------
#
# Load modules.
#
#-----------------------------------------------------------------------
#
eval ${PRE_TASK_CMDS}

nprocs=$(( NNODES_RUN_POST*PPN_RUN_POST ))
if [ -z "${RUN_CMD_POST:-}" ] ; then
  print_err_msg_exit "\
  Run command was not set in machine file. \
  Please set RUN_CMD_POST for your platform"
else
  print_info_msg "$VERBOSE" "
  All executables will be submitted with command \'${RUN_CMD_POST}\'."
fi
#
#-----------------------------------------------------------------------
#
# Remove any files from previous runs and stage necessary files in the 
# temporary work directory specified by DATA_FHR.
#
#-----------------------------------------------------------------------
#
rm_vrfy -f fort.*
cp_vrfy ${PARMdir}/upp/nam_micro_lookup.dat ./eta_micro_lookup.dat
if [ ${USE_CUSTOM_POST_CONFIG_FILE} = "TRUE" ]; then
  post_config_fp="${CUSTOM_POST_CONFIG_FP}"
  post_params_fp="${CUSTOM_POST_PARAMS_FP}"
  print_info_msg "
====================================================================
Copying the user-defined post flat file specified by CUSTOM_POST_CONFIG_FP
to the temporary work directory (DATA_FHR):
  CUSTOM_POST_CONFIG_FP = \"${CUSTOM_POST_CONFIG_FP}\"
  CUSTOM_POST_PARAMS_FP = \"${CUSTOM_POST_PARAMS_FP}\"
  DATA_FHR = \"${DATA_FHR}\"
===================================================================="
else
  if [ ${FCST_MODEL} = "fv3gfs_aqm" ]; then
    post_config_fp="${PARMdir}/upp/postxconfig-NT-fv3lam_cmaq.txt"
    post_params_fp="${PARMdir}/upp/params_grib2_tbl_new_cmaq"
  else
    post_config_fp="${PARMdir}/upp/postxconfig-NT-fv3lam.txt"
    post_params_fp="${PARMdir}/upp/params_grib2_tbl_new"
  fi
  print_info_msg "
====================================================================
Copying the default post flat file specified by post_config_fp to the 
temporary work directory (DATA_FHR):
  post_config_fp = \"${post_config_fp}\"
  post_params_fp = \"${post_params_fp}\"
  DATA_FHR = \"${DATA_FHR}\"
===================================================================="
fi
cp_vrfy ${post_config_fp} ./postxconfig-NT.txt
cp_vrfy ${post_params_fp}  ./params_grib2_tbl_new
#
#-----------------------------------------------------------------------
#
# Symlink CRTM fix files
#
#-----------------------------------------------------------------------
#
if [ ${USE_CRTM} = "TRUE" ]; then
  ln_vrfy -snf ${FIXcrtmupp}/*bin ./
  print_info_msg "
====================================================================
Copying the external CRTM fix files from FIXcrtm to the temporary
work directory (DATA_FHR):
  FIXcrtmupp = \"${FIXcrtmupp}\"
  DATA_FHR = \"${DATA_FHR}\"
===================================================================="
fi
#
#-----------------------------------------------------------------------
#
# Get the cycle date and hour (in formats of yyyymmdd and hh, respectively)
# from CDATE.
#
#-----------------------------------------------------------------------
#
yyyymmdd=${PDY}
hh=${cyc}
#
#-----------------------------------------------------------------------
#
# Create the namelist file (itag) containing arguments to pass to the post-
# processor's executable.
#
#-----------------------------------------------------------------------
#
# Set the variable (mnts_secs_str) that determines the suffix in the names 
# of the forecast model's write-component output files that specifies the 
# minutes and seconds of the corresponding output forecast time.
#
# Note that if the forecast model is instructed to output at some hourly
# interval (via the output_fh parameter in the MODEL_CONFIG_FN file, 
# with nsout set to a non-positive value), then the write-component
# output file names will not contain any suffix for the minutes and seconds.
# For this reason, when SUB_HOURLY_POST is not set to "TRUE", mnts_sec_str
# must be set to a null string.
#
mnts_secs_str=""
if [ "${SUB_HOURLY_POST}" = "TRUE" ]; then
  if [ ${fhr}${fmn} = "00000" ]; then
    mnts_secs_str=":"$( $DATE_UTIL --utc --date "${yyyymmdd} ${hh} UTC + ${DT_ATMOS} seconds" "+%M:%S" )
  else
    mnts_secs_str=":${fmn}:00"
  fi
fi

#
# Set the names of the forecast model's write-component output files.
#
if [ "${RUN_ENVIR}" = "nco" ]; then
    DATAFCST=${DATAROOT}/${TAG}run_fcst_${CYCLE_TYPE}${dot_ensmem/./_}.${share_pid}
else
    DATAFCST=${COMIN}${SLASH_ENSMEM_SUBDIR}
fi

if [ ${CYCLE_TYPE} == "spinup" ]; then
  DATAFCST="${DATAFCST}/fcst_fv3lam_spinup"
else
  DATAFCST="${DATAFCST}/fcst_fv3lam"
fi

dyn_file="${DATAFCST}/dynf${fhr}${mnts_secs_str}.nc"
phy_file="${DATAFCST}/phyf${fhr}${mnts_secs_str}.nc"

#
# Set parameters that specify the actual time (not forecast time) of the
# output.
#
post_time=$( $DATE_UTIL --utc --date "${yyyymmdd} ${hh} UTC + ${fhr} hours + ${fmn} minutes" "+%Y%m%d%H%M" )
post_yyyy=${post_time:0:4}
post_mm=${post_time:4:2}
post_dd=${post_time:6:2}
post_hh=${post_time:8:2}
post_mn=${post_time:10:2}
#
# Create the input namelist file to the post-processor executable.
#
if [ ${FCST_MODEL} = "fv3gfs_aqm" ]; then
  post_itag_add="aqfcmaq_on=.true.,"
else
  post_itag_add=""
fi
cat > itag <<EOF
&model_inputs
fileName='${dyn_file}'
IOFORM='netcdf'
grib='grib2'
DateStr='${post_yyyy}-${post_mm}-${post_dd}_${post_hh}:${post_mn}:00'
MODELNAME='${POST_FULL_MODEL_NAME}'
SUBMODELNAME='${POST_SUB_MODEL_NAME}'
fileNameFlux='${phy_file}'
fileNameFlat='postxconfig-NT.txt'
/

 &NAMPGB
 KPO=47,PO=1000.,975.,950.,925.,900.,875.,850.,825.,800.,775.,750.,725.,700.,675.,650.,625.,600.,575.,550.,525.,500.,475.,450.,425.,400.,375.,350.,325.,300.,275.,250.,225.,200.,175.,150.,125.,100.,70.,50.,30.,20.,10.,7.,5.,3.,2.,1.,${post_itag_add}
 /
EOF
#
#-----------------------------------------------------------------------
#
# Run wgrib2
#
#-----------------------------------------------------------------------
#
if [ ${PREDEF_GRID_NAME} = "RRFS_CONUS_3km_HRRRIC" ]; then
  grid_specs_rrfs="lambert:-97.5:38.500000 237.826355:1746:3000 21.885885:1014:3000"
elif [ ${PREDEF_GRID_NAME} = "RRFS_CONUS_3km" ]; then
  grid_specs_rrfs="lambert:-97.5:38.500000 237.280472:1799:3000 21.138123:1059:3000"
elif [ ${PREDEF_GRID_NAME} = "RRFS_NA_3km" ]; then
  grid_specs_rrfs="rot-ll:247.000000:-35.000000:0.000000 299.000000:4881:0.025000 -37.0000000:2961:0.025000"
elif [ ${PREDEF_GRID_NAME} = "GSD_RAP13km" ]; then
  grid_specs_rrfs="rot-ll:254.000000:-36.000000:0.000000 304.174600:956:0.1169118 -48.5768500:831:0.1170527"
fi
if [ ${PREDEF_GRID_NAME} = "RRFS_CONUS_3km_HRRRIC" ] || \
   [ ${PREDEF_GRID_NAME} = "RRFS_CONUS_3km" ] || \
   [ ${PREDEF_GRID_NAME} = "RRFS_NA_3km" ] || \
   [ ${PREDEF_GRID_NAME} = "GSD_RAP13km" ]; then

  if [ -f ${FFG_DIR}/latest.FFG ]; then
    cp_vrfy ${FFG_DIR}/latest.FFG .
    wgrib2 latest.FFG -match "0-12 hour" -end -new_grid_interpolation bilinear -new_grid_winds grid -new_grid ${grid_specs_rrfs} ffg_12h.grib2
    wgrib2 latest.FFG -match "0-6 hour" -end -new_grid_interpolation bilinear -new_grid_winds grid -new_grid ${grid_specs_rrfs} ffg_06h.grib2
    wgrib2 latest.FFG -match "0-3 hour" -end -new_grid_interpolation bilinear -new_grid_winds grid -new_grid ${grid_specs_rrfs} ffg_03h.grib2
    wgrib2 latest.FFG -match "0-1 hour" -end -new_grid_interpolation bilinear -new_grid_winds grid -new_grid ${grid_specs_rrfs} ffg_01h.grib2
  fi
  for ayear in 100y 10y 5y 2y ; do
    for ahour in 01h 03h 06h 12h 24h; do
      if [ -f ${PARMdir}/upp/${PREDEF_GRID_NAME}/ari${ayear}_${ahour}.grib2 ]; then
        ln_vrfy -snf ${PARMdir}/upp/${PREDEF_GRID_NAME}/ari${ayear}_${ahour}.grib2 ari${ayear}_${ahour}.grib2
      fi
    done
  done
fi
#
#-----------------------------------------------------------------------
#
# Run the UPP executable in the temporary directory (DATA_FHR) for this
# output time.
#
#-----------------------------------------------------------------------
#
print_info_msg "$VERBOSE" "
Starting post-processing for fhr = $fhr hr..."

PREP_STEP
eval ${RUN_CMD_POST} ${EXECdir}/upp.x < itag ${REDIRECT_OUT_ERR} || print_err_msg_exit "\
Call to executable to run post for forecast hour $fhr returned with non-
zero exit code."
POST_STEP
#
#-----------------------------------------------------------------------
#
# Move and rename the output files from the work directory to their final 
# location in COMOUT.  Also, create symlinks in COMOUT to the
# grib2 files that are needed by the data services group.  Then delete 
# the work directory.
#
#-----------------------------------------------------------------------
#

#
# Set variables needed in constructing the names of the grib2 files
# generated by UPP.
#
len_fhr=${#fhr}
subh_fhr=${fhr}
if [ ${len_fhr} -eq 2 ]; then
  post_fhr=${fhr}
elif [ ${len_fhr} -eq 3 ]; then
  if [ "${fhr:0:1}" = "0" ]; then
    post_fhr="${fhr:1}"
  else
    post_fhr="${fhr}"
  fi
elif [ ${len_fhr} -eq 9 ]; then
  if [ "${fhr:0:1}" = "0" ]; then
    if [ ${post_min} -eq 00 ]; then
      post_fhr="${fhr:1:2}"
      subh_fhr="${fhr:0:3}"
    else
      post_fhr="${fhr:1:2}.${fhr:4:2}"
    fi
  else
    if [ ${post_min} -eq 00 ]; then
      post_fhr="${fhr:0:3}"
      subh_fhr="${fhr:0:3}"
    else
      post_fhr="${fhr:0:3}.${fhr:4:2}"
    fi
  fi
else
  print_err_msg_exit "\
The \${fhr} variable contains too few or too many characters:
  fhr = \"$fhr\""
fi

# set post minutes
post_mn_or_null=""
dot_post_mn_or_null=""
if [ "${post_mn}" != "00" ]; then
  post_mn_or_null="${post_mn}"
  dot_post_mn_or_null=".${post_mn}"
fi

post_fn_suffix="GrbF${post_fhr}${dot_post_mn_or_null}"
post_renamed_fn_suffix="f${fhr}${post_mn_or_null}.${POST_OUTPUT_DOMAIN_NAME}.grib2"
cd_vrfy "${COMOUT}"

#
# background files
#
bgdawp=${COMOUT}/${NET}.${cycle}.bgdawpf${subh_fhr}.${TMMARK}.grib2
bgrd3d=${COMOUT}/${NET}.${cycle}.bgrd3df${subh_fhr}.${TMMARK}.grib2
bgsfc=${COMOUT}/${NET}.${cycle}.bgsfcf${subh_fhr}.${TMMARK}.grib2
bgifi=${COMOUT}/${NET}.${cycle}.bgifif${subh_fhr}.${TMMARK}.grib2

wgrib2 ${NET}.${cycle}${dot_ensmem}.prslev.${post_renamed_fn_suffix} -set center 7 -grib ${bgdawp}
wgrib2 ${NET}.${cycle}${dot_ensmem}.natlev.${post_renamed_fn_suffix} -set center 7 -grib ${bgrd3d}
if [ -f ${NET}.${cycle}${dot_ensmem}.ififip.${post_renamed_fn_suffix} ]; then
  wgrib2 ${NET}.${cycle}${dot_ensmem}.ififip.${post_renamed_fn_suffix} -set center 7 -grib ${bgifi}
fi

#
# Loop through the two files that UPP
# generates (i.e. "...prslev..." and "...natlev..." files) and move, 
# rename, and create symlinks to them.
#
basetime=$( $DATE_UTIL --date "$yyyymmdd $hh" +%y%j%H%M )
symlink_suffix="${dot_ensmem}.${basetime}f${fhr}${post_mn}"
fids=( "prslev" "natlev" )
for fid in "${fids[@]}"; do
  FID=$(echo_uppercase $fid)
  post_orig_fn="${FID}.${post_fn_suffix}"
  post_renamed_fn="${NET}.${cycle}${dot_ensmem}.${fid}.${post_renamed_fn_suffix}"
  mv_vrfy ${DATA_FHR}/${post_orig_fn} ${post_renamed_fn}

  create_symlink_to_file target="${post_renamed_fn}" \
                       symlink="${FID}${symlink_suffix}" \
                       relative="TRUE"
  # DBN alert
  if [ $SENDDBN = "TRUE" ]; then
    $DBNROOT/bin/dbn_alert MODEL rrfs_post ${job} ${COMOUT}/${post_renamed_fn}
  fi
done

# remove DATA_FHR
rm_vrfy -rf ${DATA_FHR}

#
# Delete the forecast directory
#
if [ $CYCLE_TYPE = "spinup" ]; then
   fhr_l=$(printf "%03d" $FCST_LEN_HRS_SPINUP)
else
   fhr_l=$(printf "%03d" $FCST_LEN_HRS)
fi
if [ $RUN_ENVIR = "nco" ] && [ $KEEPDATA = "FALSE" ] && [ $fhr = $fhr_l ]; then
   rm -rf $DATAFCST
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
Post-processing for forecast hour $fhr completed successfully.

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

