#!/bin/bash

set -x

msg="JOB $job HAS BEGUN"
postmsg "$msg"
   
export pgm=aqm_post

#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. $USHaqm/source_util_funcs.sh
source_config_for_task "task_run_post" ${GLOBAL_VAR_DEFNS_FP}
#
#-----------------------------------------------------------------------
#
# Save current shell options (in a global array).  Then set new options
# for this script/function.
#
#-----------------------------------------------------------------------
#
{ save_shell_opts; . $USHaqm/preamble.sh; } > /dev/null 2>&1
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
# temporary work directory specified by DATA.
#
#-----------------------------------------------------------------------
#
rm -f fort.*
cpreq ${PARMdir}/upp/nam_micro_lookup.dat ./eta_micro_lookup.dat
if [ ${USE_CUSTOM_POST_CONFIG_FILE} = "TRUE" ]; then
  post_config_fp="${CUSTOM_POST_CONFIG_FP}"
  print_info_msg "
====================================================================
Copying the user-defined post flat file specified by CUSTOM_POST_CONFIG_FP
to the temporary work directory (DATA):
  CUSTOM_POST_CONFIG_FP = \"${CUSTOM_POST_CONFIG_FP}\"
  DATA = \"${DATA}\"
===================================================================="
else
  if [ "${CPL_AQM}" = "TRUE" ]; then
    post_config_fp="${PARMdir}/upp/postxconfig-NT-AQM.txt"
  else
    post_config_fp="${PARMdir}/upp/postxconfig-NT-fv3lam.txt"
  fi
  print_info_msg "
====================================================================
Copying the default post flat file specified by post_config_fp to the 
temporary work directory (DATA):
  post_config_fp = \"${post_config_fp}\"
  DATA = \"${DATA}\"
===================================================================="
fi
cpreq ${post_config_fp} ./postxconfig-NT.txt
cpreq ${PARMdir}/upp/params_grib2_tbl_new .
if [ ${USE_CRTM} = "TRUE" ]; then
  cpreq ${CRTM_DIR}/fix/EmisCoeff/IR_Water/Big_Endian/Nalli.IRwater.EmisCoeff.bin ./
  cpreq ${CRTM_DIR}/fix/EmisCoeff/MW_Water/Big_Endian/FAST*.bin ./
  cpreq ${CRTM_DIR}/fix/EmisCoeff/IR_Land/SEcategory/Big_Endian/NPOESS.IRland.EmisCoeff.bin ./
  cpreq ${CRTM_DIR}/fix/EmisCoeff/IR_Snow/SEcategory/Big_Endian/NPOESS.IRsnow.EmisCoeff.bin ./
  cpreq ${CRTM_DIR}/fix/EmisCoeff/IR_Ice/SEcategory/Big_Endian/NPOESS.IRice.EmisCoeff.bin ./
  cpreq ${CRTM_DIR}/fix/AerosolCoeff/Big_Endian/AerosolCoeff.bin ./
  cpreq ${CRTM_DIR}/fix/CloudCoeff/Big_Endian/CloudCoeff.bin ./
  cpreq ${CRTM_DIR}/fix/SpcCoeff/Big_Endian/*.bin ./
  cpreq ${CRTM_DIR}/fix/TauCoeff/ODPS/Big_Endian/*.bin ./
  print_info_msg "
====================================================================
Copying the external CRTM fix files from CRTM_DIR to the temporary
work directory (DATA):
  CRTM_DIR = \"${CRTM_DIR}\"
  DATA = \"${DATA}\"
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

dyn_file="${COMIN}/${cyc}/${NET}.${cycle}${dot_ensmem}.dyn.f${fhr}${mnts_secs_str}.nc"
phy_file="${COMIN}/${cyc}/${NET}.${cycle}${dot_ensmem}.phy.f${fhr}${mnts_secs_str}.nc"

#
# Set parameters that specify the actual time (not forecast time) of the
# output.
#
fmn='00'
post_time=`$NDATE +${fhr} ${yyyymmdd}${hh}`$fmn
post_yyyy=${post_time:0:4}
post_mm=${post_time:4:2}
post_dd=${post_time:6:2}
post_hh=${post_time:8:2}
post_mn=${post_time:10:2}

#
# Create the input namelist file to the post-processor executable.
#
if [ "${CPL_AQM}" = "TRUE" ]; then
  post_itag_add="aqf_on=.true.,"
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
 KPO=47,PO=1000.,975.,950.,925.,900.,875.,850.,825.,800.,775.,750.,725.,700.,675.,650.,625.,600.,575.,550.,525.,500.,475.,450.,425.,400.,375.,350.,325.,300.,275.,250.,225.,200.,175.,150.,125.,100.,70.,50.,30.,20.,10.,7.,5.,3.,2.,1.,${post_itag_add}
 /
EOF
#
#-----------------------------------------------------------------------
#
# Run the UPP executable in the temporary directory (DATA) for this
# output time.
#
#-----------------------------------------------------------------------
#
print_info_msg "$VERBOSE" "
Starting post-processing for fhr = $fhr hr..."

startmsg
eval ${RUN_CMD_POST} ${EXECaqm}/upp.x < itag ${REDIRECT_OUT_ERR} >> $pgmout 2>errfile
export err=$?; err_chk
if [ -e "${pgmout}" ]; then
   cat ${pgmout}
fi
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
if [ "${CPL_AQM}" = "TRUE" ]; then
  fids=( "cmaq" )
else
  fids=( "prslev" "natlev" )
fi
for fid in "${fids[@]}"; do
  FID=$(echo_uppercase $fid)
  post_orig_fn="${FID}.${post_fn_suffix}"
  post_renamed_fn="${NET}.${cycle}${dot_ensmem}.${fid}.${post_renamed_fn_suffix}"
  mv ${DATA}/${post_orig_fn} ${post_renamed_fn}
  
done

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

