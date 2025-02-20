#!/usr/bin/env bash

#
#-----------------------------------------------------------------------
#
# The ex-script that runs UPP.
#
# Run-time environment variables:
#
#    CDATE
#    COMOUT
#    DATA_FHR
#    DBNROOT
#    ENSMEM_INDX
#    GLOBAL_VAR_DEFNS_FP
#    NET
#    PDY
#    REDIRECT_OUT_ERR
#    SENDDBN
#
# Experiment variables
#
#   user:
#     EXECdir
#     MACHINE
#     PARMdir
#     RUN_ENVIR
#     USHdir
#
#   platform:
#     PRE_TASK_CMDS
#     RUN_CMD_POST
#
#   workflow:
#     VERBOSE
#
#   task_run_fcst:
#     DT_ATMOS
#
#   task_run_post:
#     CUSTOM_POST_CONFIG_FP
#     KMP_AFFINITY_RUN_POST
#     OMP_NUM_THREADS_RUN_POST
#     OMP_STACKSIZE_RUN_POST
#     NUMX
#     POST_OUTPUT_DOMAIN_NAME
#     SUB_HOURLY_POST
#     USE_CUSTOM_POST_CONFIG_FILE
#
#   global:
#     CRTM_DIR
#     USE_CRTM
#
#   cpl_aqm_parm:
#     CPL_AQM
#
#-----------------------------------------------------------------------
#

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. $USHdir/source_util_funcs.sh
for sect in user nco platform workflow global cpl_aqm_parm smoke_dust_parm \
  task_run_fcst task_run_post ; do
  source_yaml ${GLOBAL_VAR_DEFNS_FP} ${sect}
done
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
rm -f fort.*
cp ${HOMEdir}/fix/upp/nam_micro_lookup.dat ./eta_micro_lookup.dat
if [ $(boolify ${USE_CUSTOM_POST_CONFIG_FILE}) = "TRUE" ]; then
  post_config_fp="${CUSTOM_POST_CONFIG_FP}"
  print_info_msg "
====================================================================
Copying the user-defined post flat file specified by CUSTOM_POST_CONFIG_FP
to the temporary work directory (DATA_FHR):
  CUSTOM_POST_CONFIG_FP = \"${CUSTOM_POST_CONFIG_FP}\"
  DATA_FHR = \"${DATA_FHR}\"
===================================================================="
else
  if [ $(boolify "${CPL_AQM}") = "TRUE" ]; then
    post_config_fp="${PARMdir}/upp/postxconfig-NT-AQM.txt"
  else
    post_config_fp="${PARMdir}/upp/postxconfig-NT-rrfs.txt"
  fi
  print_info_msg "
====================================================================
Copying the default post flat file specified by post_config_fp to the 
temporary work directory (DATA_FHR):
  post_config_fp = \"${post_config_fp}\"
  DATA_FHR = \"${DATA_FHR}\"
===================================================================="
fi
cp ${post_config_fp} ./postxconfig-NT.txt
cp ${PARMdir}/upp/params_grib2_tbl_new .
if [ $(boolify ${DO_SMOKE_DUST}) = "TRUE" ] || [ $(boolify ${USE_CRTM}) = "TRUE" ]; then
  if [ $(boolify ${DO_SMOKE_DUST}) = "TRUE" ]; then
    CRTM_DIR="${FIXcrtm}"
  fi
  ln -nsf ${CRTM_DIR}/Nalli.IRwater.EmisCoeff.bin .
  ln -nsf ${CRTM_DIR}/FAST*.bin .
  ln -nsf ${CRTM_DIR}/NPOESS.IRland.EmisCoeff.bin .
  ln -nsf ${CRTM_DIR}/NPOESS.IRsnow.EmisCoeff.bin .
  ln -nsf ${CRTM_DIR}/NPOESS.IRice.EmisCoeff.bin .
  ln -nsf ${CRTM_DIR}/AerosolCoeff.bin .
  ln -nsf ${CRTM_DIR}/CloudCoeff.bin .
  ln -nsf ${CRTM_DIR}/*.SpcCoeff.bin .
  ln -nsf ${CRTM_DIR}/*.TauCoeff.bin .
  print_info_msg "
====================================================================
Copying the external CRTM fix files from CRTM_DIR to the temporary
work directory (DATA_FHR):
  CRTM_DIR = \"${CRTM_DIR}\"
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
if [ $(boolify "${SUB_HOURLY_POST}") = "TRUE" ]; then
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
    DATAFCST=$DATAROOT/run_fcst_mem${ENSMEM_INDX}.${share_pid}
else
    DATAFCST=$DATA
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
if [ $(boolify "${CPL_AQM}") = "TRUE" ] && [ $(boolify "${DO_SMOKE_DUST}") = "FALSE" ]; then
  post_itag_add="aqf_on=.true.,"
elif [ $(boolify "${DO_SMOKE_DUST}") = "TRUE" ]; then
  post_itag_add="slrutah_on=.true.,gtg_on=.true."
else
  post_itag_add=""
fi
cat > itag <<EOF
&model_inputs
fileName='${dyn_file}'
IOFORM='netcdf'
grib='grib2'
DateStr='${post_yyyy}-${post_mm}-${post_dd}_${post_hh}:${post_mn}:00'
MODELNAME='FV3R'
fileNameFlux='${phy_file}'
/

 &NAMPGB
 KPO=47,PO=1000.,975.,950.,925.,900.,875.,850.,825.,800.,775.,750.,725.,700.,675.,650.,625.,600.,575.,550.,525.,500.,475.,450.,425.,400.,375.,350.,325.,300.,275.,250.,225.,200.,175.,150.,125.,100.,70.,50.,30.,20.,10.,7.,5.,3.,2.,1.,${post_itag_add},numx=${NUMX}
 /
EOF

if [ $(boolify "${DO_SMOKE_DUST}") = "TRUE" ]; then
  if [ ${PREDEF_GRID_NAME} = "RRFS_CONUS_3km" ]; then
    grid_specs_rrfs="lambert:-97.5:38.500000 237.280472:1799:3000 21.138115:1059:3000"
  elif [ ${PREDEF_GRID_NAME} = "RRFS_NA_3km" ]; then
    grid_specs_rrfs="rot-ll:247.000000:-35.000000:0.000000 299.000000:4881:0.025000 -37.0000000:2961:0.025000"
  fi
  if [ ${PREDEF_GRID_NAME} = "RRFS_CONUS_3km" ] || [ ${PREDEF_GRID_NAME} = "RRFS_NA_3km" ]; then
    for ayear in 100y 10y 5y 2y ; do
      for ahour in 01h 03h 06h 12h 24h; do
        if [ -f ${FIXupp}/${PREDEF_GRID_NAME}/ari${ayear}_${ahour}.grib2 ]; then
          ln -snf ${FIXupp}/${PREDEF_GRID_NAME}/ari${ayear}_${ahour}.grib2 ari${ayear}_${ahour}.grib2
        fi
      done
    done
  fi
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
eval ${RUN_CMD_POST} ${EXECdir}/upp.x < itag ${REDIRECT_OUT_ERR}
export err=$?
if [ "${RUN_ENVIR}" = "nco" ] && [ "${MACHINE}" = "WCOSS2" ]; then
  err_chk
else
  if [ $err -ne 0 ]; then
    print_err_msg_exit "Call to executable to run post for forecast hour $fhr 
returned with non-zero exit code."
  fi
fi
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
# Set variables needed in constructing the names of the grib2 files
# generated by UPP.
#
len_fhr=${#fhr}
if [ ${len_fhr} -eq 2 ]; then
  post_fhr=${fhr}
elif [ ${len_fhr} -eq 3 ]; then
  if [ "${fhr:0:1}" = "0" ]; then
    post_fhr="${fhr:1}"
  else
    post_fhr="${fhr}"
  fi
else
  print_err_msg_exit "\
The \${fhr} variable contains too few or too many characters:
  fhr = \"$fhr\""
fi

if [ $(boolify "${DO_SMOKE_DUST}") = "TRUE" ]; then
  bgdawp=${NET}.${cycle}.prslev.f${fhr}.${POST_OUTPUT_DOMAIN_NAME}.grib2
  bgrd3d=${NET}.${cycle}.natlev.f${fhr}.${POST_OUTPUT_DOMAIN_NAME}.grib2
  bgifi=${NET}.${cycle}.ififip.f${fhr}.${POST_OUTPUT_DOMAIN_NAME}.grib2
  bgavi=${NET}.${cycle}.aviation.f${fhr}.${POST_OUTPUT_DOMAIN_NAME}.grib2

  if [ -f "PRSLEV.GrbF${post_fhr}" ]; then
    wgrib2 PRSLEV.GrbF${post_fhr} -set center 7 -grib ${bgdawp}
    mv ${bgdawp} ${COMOUT}
  fi
  if [ -f "NATLEV.GrbF${post_fhr}" ]; then
    wgrib2 NATLEV.GrbF${post_fhr} -set center 7 -grib ${bgrd3d}
    mv ${bgrd3d} ${COMOUT}
  fi
  if [ -f "IFIFIP.GrbF${post_fhr}" ]; then
    wgrib2 IFIFIP.GrbF${post_fhr} -set center 7 -grib ${bgifi}
    mv ${bgifi} ${COMOUT}
  fi
  if [ -f "AVIATION.GrbF${post_fhr}" ]; then
    wgrib2 AVIATION.GrbF${post_fhr} -set center 7 -grib ${bgavi}
    mv ${bgavi} ${COMOUT}
  fi

else
  post_mn_or_null=""
  dot_post_mn_or_null=""
  if [ "${post_mn}" != "00" ]; then
    post_mn_or_null="${post_mn}"
    dot_post_mn_or_null=".${post_mn}"
  fi

  post_fn_suffix="GrbF${post_fhr}${dot_post_mn_or_null}"
  post_renamed_fn_suffix="f${fhr}${post_mn_or_null}.${POST_OUTPUT_DOMAIN_NAME}.grib2"
  #
  # For convenience, change location to COMOUT (where the final output
  # from UPP will be located).  Then loop through the two files that UPP
  # generates (i.e. "...prslev..." and "...natlev..." files) and move, 
  # rename, and create symlinks to them.
  #
  cd "${COMOUT}"
  basetime=$( $DATE_UTIL --date "$yyyymmdd $hh" +%y%j%H%M )
  symlink_suffix="${dot_ensmem}.${basetime}f${fhr}${post_mn}"
  if [ $(boolify "${CPL_AQM}") = "TRUE" ]; then
    fids=( "cmaq" )
  else
    fids=( "prslev" "natlev" )
  fi
  for fid in "${fids[@]}"; do
    FID=$(echo_uppercase $fid)
    post_orig_fn="${FID}.${post_fn_suffix}"
    post_renamed_fn="${NET}.${cycle}${dot_ensmem}.${fid}.${post_renamed_fn_suffix}"
    mv ${DATA_FHR}/${post_orig_fn} ${post_renamed_fn}
    if [ $RUN_ENVIR != "nco" ]; then
      create_symlink_to_file ${post_renamed_fn} ${FID}${symlink_suffix} TRUE
    fi
    # DBN alert
    if [ "$SENDDBN" = "TRUE" ]; then
      $DBNROOT/bin/dbn_alert MODEL rrfs_post ${job} ${COMOUT}/${post_renamed_fn}
    fi
  done
fi
rm -rf ${DATA_FHR}
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

