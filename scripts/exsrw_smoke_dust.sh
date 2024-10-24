#!/usr/bin/env bash

set -xue
#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. ${PARMsrw}/source_util_funcs.sh
task_global_vars=( "EBB_DCYCLE" "FIXsmoke" "INCR_CYCL_FREQ" \
  "PERSISTENCE" "PRE_TASK_CMDS" "PREDEF_GRID_NAME" "RESTART_INTERVAL" \
  "SMOKE_DUST_FILE_PREFIX" )
for var in ${task_global_vars[@]}; do
  source_config_for_task ${var} ${GLOBAL_VAR_DEFNS_FP}
done
#
#-----------------------------------------------------------------------
#
# Save current shell options (in a global array).  Then set new options
# for this script/function.
#
#-----------------------------------------------------------------------
#
#{ save_shell_opts; set -xue; } > /dev/null 2>&1
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

This is the ex-script for the task that runs Smoke and Dust.
========================================================================"
#
# Set CDATE used in the fire emission generation python script
#
export CDATE="${PDY}${cyc}"
#
# Check if the fire file exists in the designated directory
#
smokeFile="${SMOKE_DUST_FILE_PREFIX}_${CDATE}00.nc"
if [ -e "${COMINsmoke}/${smokeFile}" ]; then
  cp -p "${COMINsmoke}/${smokeFile}" ${COMOUT}
else
  eval ${PRE_TASK_CMDS}
  #
  # Link restart directory of the previous cycle in COMIN/COMOUT
  #
  CDATEprev=$($NDATE -${INCR_CYCL_FREQ} ${PDY}${cyc})
  PDYprev=${CDATEprev:0:8}
  cycprev=${CDATEprev:8:2}
  path_restart=${COMIN}/${RUN}.${PDYprev}/${cycprev}${SLASH_ENSMEM_SUBDIR}/RESTART
  ln -nsf ${path_restart} .

  # Check whether the RAVE files need to be split into hourly files
  if [ "${EBB_DCYCLE}" -eq 1 ]; then
    ddhh_to_use="${PDY}${cyc}"
  else
    ddhh_to_use="${PDYm1}${cyc}"
  fi
  for hour in {00..23}; do
    fire_hr_cdate=$($NDATE +${hour} ${ddhh_to_use})
    fire_hr_pdy="${fire_hr_cdate:0:8}"
    fire_hr_fn="Hourly_Emissions_3km_${fire_hr_cdate}00_${fire_hr_cdate}00.nc"
    if [ -f "${COMINrave}/${fire_hr_fn}" ]; then
      echo "Hourly emission file for $hour was found: ${fire_hr_fn}"
      ln -nsf ${COMINrave}/${fire_hr_fn} .
    else
      # Check various version of RAVE raw data files (new and old)
      rave_raw_fn1="RAVE-HrlyEmiss-3km_v2r0_blend_s${fire_hr_cdate}00000_e${fire_hr_pdy}23*"
      rave_raw_fn2="Hourly_Emissions_3km_${fire_hr_cdate}00_${fire_hr_pdy}23*"
      # Find files matching the specified patterns
      files_found=$(find "${COMINrave}" -type f \( -name "${rave_raw_fn1##*/}" -o -name "${rave_raw_fn2##*/}" \))
      # Splitting 24-hour RAVE raw data into houly data
      for file_to_use in $files_found; do
        echo "Using file: $file_to_use"
        echo "Splitting data for hour $hour..."
        ncks -d time,$hour,$hour "${COMINrave}/${file_to_use}" "${DATA}/${fire_hr_fn}"
        if [ -f "${DATA}/${fire_hr_fn}" ]; then
          break
        else
          echo "WARNING: Hourly emission file for $hour was NOT created from ${file_to_use}."
        fi
      done
    fi
  done
  #
  #-----------------------------------------------------------------------
  #
  # Call python script to generate fire emission files.
  #
  #-----------------------------------------------------------------------
  #
  ${USHsrw}/generate_fire_emissions.py \
    "${FIXsmoke}/${PREDEF_GRID_NAME}" \
    "${DATA}" \
    "${DATA_SHARE}" \
    "${PREDEF_GRID_NAME}" \
    "${EBB_DCYCLE}" \
    "${RESTART_INTERVAL}"\
    "${PERSISTENCE}"
  export err=$?
  if [ $err -ne 0 ]; then
    message_txt="generate_fire_emissions.py failed with return code $err"
    err_exit "${message_txt}"
    print_err_msg_exit "${message_txt}"
  fi

  # Copy Smoke file to COMOUT
  cp -p ${DATA}/${smokeFile} ${COMOUT}
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
Smoke and Dust has successfully generated output files !!!!

Exiting script:  \"${scrfunc_fn}\"
In directory:    \"${scrfunc_dir}\"
========================================================================"
#
#-----------------------------------------------------------------------
#
#{ restore_shell_opts; } > /dev/null 2>&1
