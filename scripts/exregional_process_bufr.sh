#!/bin/bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. $USHdir/source_util_funcs.sh
source_config_for_task "task_process_bufr" ${GLOBAL_VAR_DEFNS_FP}
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

This is the ex-script for the task that runs bufr (cloud, metar, lightning) preprocess
with FV3 for the specified cycle.
========================================================================"
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

YYJJJHH=$(date +"%y%j%H" -d "${START_DATE}")
PREYYJJJHH=$(date +"%y%j%H" -d "${START_DATE} 1 hours ago")

#
#-----------------------------------------------------------------------
#
# Get into working directory
#
#-----------------------------------------------------------------------
#
print_info_msg "$VERBOSE" "
Getting into working directory for BUFR obseration process ..."

cd_vrfy ${DATA}

fixgriddir=$FIX_GSI/${PREDEF_GRID_NAME}

print_info_msg "$VERBOSE" "fixgriddir is $fixgriddir"

#
#-----------------------------------------------------------------------
#
# link or copy background files
#
#-----------------------------------------------------------------------

cp_vrfy ${fixgriddir}/fv3_grid_spec          fv3sar_grid_spec.nc

#-----------------------------------------------------------------------
#
#   copy bufr table
#
#-----------------------------------------------------------------------
BUFR_TABLE=${FIX_GSI}/prepobs_prep_RAP.bufrtable
cp_vrfy $BUFR_TABLE prepobs_prep.bufrtable

#-----------------------------------------------------------------------
#
#   set observation soruce 
#
#-----------------------------------------------------------------------
if [[ "${NET}" = "RTMA"* ]]; then
  SUBH=$(date +%M -d "${START_DATE}")
  obs_source="rtma_ru"
  obsfileprefix=${obs_source}
  obspath_tmp=${OBSPATH}/${obs_source}.${YYYYMMDD}

else
  SUBH=""
  obs_source=rap
  if [[ ${HH} -eq '00' || ${HH} -eq '12' ]]; then
    obs_source=rap_e
  fi

  case $MACHINE in

  "WCOSS2")

    obsfileprefix=${obs_source}
    obspath_tmp=${OBSPATH}/${obs_source}.${YYYYMMDD}

    ;;
  *)

    obsfileprefix=${YYYYMMDDHH}.${obs_source}
    obspath_tmp=${OBSPATH}

  esac
fi

#
#-----------------------------------------------------------------------
#-----------------------------------------------------------------------
#
# Link to the observation lightning bufr files
#
#-----------------------------------------------------------------------

run_lightning=false
obs_file=${obspath_tmp}/${obsfileprefix}.t${HH}${SUBH}z.lghtng.tm00.bufr_d
print_info_msg "$VERBOSE" "obsfile is $obs_file"
if [ -r "${obs_file}" ]; then
   cp_vrfy "${obs_file}" "lghtngbufr"
   run_lightning=true
else
   print_info_msg "$VERBOSE" "Warning: ${obs_file} does not exist!"
fi


#-----------------------------------------------------------------------
#
# Build namelist and run executable for lightning
#
#   analysis_time : process obs used for this analysis date (YYYYMMDDHH)
#   minute        : process obs used for this analysis minute (integer)
#   trange_start  : obs time window start (minutes before analysis time)
#   trange_end    : obs time window end (minutes after analysis time)
#   bkversion     : grid type (background will be used in the analysis)
#                   0 for ARW  (default)
#                   1 for FV3LAM
#-----------------------------------------------------------------------

cat << EOF > namelist.lightning
 &setup
  analysis_time = ${YYYYMMDDHH},
  minute=00,
  trange_start=-10,
  trange_end=10,
  grid_type = "${PREDEF_GRID_NAME}",
  obs_type = "bufr"
 /

EOF

#
#-----------------------------------------------------------------------
#
# link/copy executable file to working directory 
#
#-----------------------------------------------------------------------
#
exec_fn="process_Lightning.exe"
exec_fp="$EXECdir/${exec_fn}"

if [ ! -f "${exec_fp}" ]; then
  print_err_msg_exit "\
The executable specified in exec_fp does not exist:
  exec_fp = \"${exec_fp}\"
Build lightning process and rerun."
fi
#
#
#-----------------------------------------------------------------------
#
# Run the process for lightning bufr file 
#
#-----------------------------------------------------------------------
#
if [[ "$run_lightning" == true ]]; then
   PREP_STEP
   eval $RUN_CMD_UTILS ${exec_fp} ${REDIRECT_OUT_ERR} || print_err_msg "\
        Call to executable to run lightning process returned with nonzero exit code."
   POST_STEP
fi

#
#-----------------------------------------------------------------------
#-----------------------------------------------------------------------
#
# Link to the observation NASA LaRC cloud bufr file
#
#-----------------------------------------------------------------------

obs_file=${obspath_tmp}/${obsfileprefix}.t${HH}${SUBH}z.lgycld.tm00.bufr_d
print_info_msg "$VERBOSE" "obsfile is $obs_file"
run_cloud=false
if [ -r "${obs_file}" ]; then
   cp_vrfy "${obs_file}" "lgycld.bufr_d"
   run_cloud=true
else
   print_info_msg "$VERBOSE" "Warning: ${obs_file} does not exist!"
fi

#-----------------------------------------------------------------------
#
# Build namelist and run executable for NASA LaRC cloud
#
#   analysis_time : process obs used for this analysis date (YYYYMMDDHH)
#   bufrfile      : result BUFR file name
#   npts_rad      : number of grid point to build search box (integer)
#   ioption       : interpolation options
#                   = 1 is nearest neighrhood
#                   = 2 is median of cloudy fov
#   bkversion     : grid type (background will be used in the analysis)
#                   = 0 for ARW  (default)
#                   = 1 for FV3LAM
#-----------------------------------------------------------------------

if [ ${PREDEF_GRID_NAME} == "GSD_RAP13km" ]; then
   npts_rad_number=1
   metar_impact_radius_number=9
else
   npts_rad_number=3
   metar_impact_radius_number=15
fi

cat << EOF > namelist.nasalarc
 &setup
  analysis_time = ${YYYYMMDDHH},
  bufrfile='NASALaRCCloudInGSI_bufr.bufr',
  npts_rad=$npts_rad_number,
  ioption = 2,
  grid_type = "${PREDEF_GRID_NAME}",
 /
EOF

#
#-----------------------------------------------------------------------
#
# Copy the executable to the run directory.
#
#-----------------------------------------------------------------------
#
exec_fn="process_larccld.exe"
exec_fp="$EXECdir/${exec_fn}"

if [ ! -f "${exec_fp}" ]; then
  print_err_msg_exit "\
The executable specified in exec_fp does not exist:
  exec_fp = \"${exec_fp}\"
Build lightning process and rerun."
fi
#
#
#-----------------------------------------------------------------------
#
# Run the process for NASA LaRc cloud  bufr file 
#
#-----------------------------------------------------------------------
#
if [[ "$run_cloud" == true ]]; then
  PREP_STEP
  eval ${RUN_CMD_UTILS} ${exec_fp} ${REDIRECT_OUT_ERR} || print_err_msg "\
       Call to executable to run NASA LaRC Cloud process returned with nonzero exit code."
  POST_STEP
fi

#
#-----------------------------------------------------------------------
#-----------------------------------------------------------------------
#
# Link to the observation prepbufr bufr file for METAR cloud
#
#-----------------------------------------------------------------------

obs_file=${obspath_tmp}/${obsfileprefix}.t${HH}${SUBH}z.prepbufr.tm00 
print_info_msg "$VERBOSE" "obsfile is $obs_file"
run_metar=false
if [ -r "${obs_file}" ]; then
   cp_vrfy "${obs_file}" "prepbufr"
   run_metar=true
else
   print_info_msg "$VERBOSE" "Warning: ${obs_file} does not exist!"
fi

#-----------------------------------------------------------------------
#
# Build namelist for METAR cloud
#
#   analysis_time   : process obs used for this analysis date (YYYYMMDDHH)
#   analysis_minute : process obs used for this analysis minute (integer)
#   prepbufrfile    : input prepbufr file name
#   twindin         : observation time window (real: hours before and after analysis time)
#
#-----------------------------------------------------------------------

cat << EOF > namelist.metarcld
 &setup
  analysis_time = ${YYYYMMDDHH},
  prepbufrfile='prepbufr',
  twindin=0.5,
  metar_impact_radius=$metar_impact_radius_number,
  grid_type = "${PREDEF_GRID_NAME}",
 /
EOF

#
#-----------------------------------------------------------------------
#
# Copy the executable to the run directory.
#
#-----------------------------------------------------------------------
#
exec_fn="process_metarcld.exe"
exec_fp="$EXECdir/${exec_fn}"

if [ ! -f "${exec_fp}" ]; then
  print_err_msg_exit "\
The executable specified in exec_fp does not exist:
  exec_fp = \"$exec_fp\"
Build lightning process and rerun."
fi
#
#
#-----------------------------------------------------------------------
#
# Run the process for METAR cloud bufr file 
#
#-----------------------------------------------------------------------
#
if [[ "$run_metar" == true ]]; then
  PREP_STEP
  eval $RUN_CMD_UTILS ${exec_fp} ${REDIRECT_OUT_ERR} || print_err_msg "\
    Call to executable to run METAR cloud process returned with nonzero exit code."
  POST_STEP
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
BUFR PROCESS completed successfully!!!

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

