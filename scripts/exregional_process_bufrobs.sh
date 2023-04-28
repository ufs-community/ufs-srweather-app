#!/bin/bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. $USHdir/source_util_funcs.sh
source_config_for_task "task_process_bufrobs" ${GLOBAL_VAR_DEFNS_FP}
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

This is the ex-script for the task that runs bufr (cloud, metar, lightning) preprocessing
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
START_DATE=$(echo "${PDY} ${cyc}")
YYYYMMDDHH=$(date +%Y%m%d%H -d "${START_DATE}")
#
#-----------------------------------------------------------------------
#
# Get into working directory
#
#-----------------------------------------------------------------------
#
print_info_msg "$VERBOSE" "
Getting into working directory for BUFR observation process ..."

cd_vrfy ${DATA}

pregen_grid_dir=$DOMAIN_PREGEN_BASEDIR/${PREDEF_GRID_NAME}

print_info_msg "$VERBOSE" "pregen_grid_dir is $pregen_grid_dir"

#
#-----------------------------------------------------------------------
#
# link or copy background files
#
#-----------------------------------------------------------------------

cp_vrfy ${pregen_grid_dir}/fv3_grid_spec fv3sar_grid_spec.nc

#-----------------------------------------------------------------------
#
#   copy bufr table
#
#-----------------------------------------------------------------------
BUFR_TABLE=${FIXgsi}/prepobs_prep_RAP.bufrtable
cp_vrfy $BUFR_TABLE prepobs_prep.bufrtable

#
#-----------------------------------------------------------------------
#-----------------------------------------------------------------------
#
# Link to the observation lightning bufr files
#
#-----------------------------------------------------------------------

obs_file="${COMIN}/obs/lghtngbufr"
print_info_msg "$VERBOSE" "obsfile is $obs_file"
run_lightning=false
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
#   grid_type     : grid type (background will be used in the analysis)
#                   0 for ARW  (default)
#                   1 for FV3LAM
#-----------------------------------------------------------------------

if [[ "$run_lightning" == true ]]; then

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
  Build rrfs_utl and rerun."
  fi
  #
  #
  #-----------------------------------------------------------------------
  #
  # Run the process for lightning bufr file 
  #
  #-----------------------------------------------------------------------
  #
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

obs_file="${COMIN}/obs/lgycld.bufr_d"
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
#   grid_type     : grid type (background will be used in the analysis)
#                   = 0 for ARW  (default)
#                   = 1 for FV3LAM
#-----------------------------------------------------------------------

if [ ${PREDEF_GRID_NAME} == "RRFS_NA_13km" ]  || [ ${PREDEF_GRID_NAME} == "RRFS_CONUS_13km" ] ; then
   npts_rad_number=1
   metar_impact_radius_number=9
else
   npts_rad_number=3
   metar_impact_radius_number=15
fi

if [[ "$run_cloud" == true ]]; then

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
  Build rrfs_utl and rerun."
  fi
  #
  #
  #-----------------------------------------------------------------------
  #
  # Run the process for NASA LaRc cloud  bufr file 
  #
  #-----------------------------------------------------------------------
  #
  PREP_STEP
  eval ${RUN_CMD_UTILS} ${exec_fp} ${REDIRECT_OUT_ERR} || print_err_msg "\
       Call to executable to run NASA LaRC Cloud process returned with nonzero exit code."
  POST_STEP

fi

#
#-----------------------------------------------------------------------
#
# Link to the observation prepbufr bufr file for METAR cloud
#
#-----------------------------------------------------------------------

obs_file="${COMIN}/obs/prepbufr" 
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
#   prepbufrfile    : input prepbufr file name
#   twindin         : observation time window (real: hours before and after analysis time)
#
#-----------------------------------------------------------------------

if [[ "$run_metar" == true ]]; then

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
  Build rrfs_utl and rerun."
  fi
  #
  #
  #-----------------------------------------------------------------------
  #
  # Run the process for METAR cloud bufr file 
  #
  #-----------------------------------------------------------------------
  #
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

