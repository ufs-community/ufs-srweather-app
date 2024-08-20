#!/usr/bin/env bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. ${USHsrw}/source_util_funcs.sh
for sect in user nco platform workflow nco global smoke_dust_parm \
  constants fixed_files grid_params task_run_fcst ; do
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
{ save_shell_opts; set -xue; } > /dev/null 2>&1
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
#-----------------------------------------------------------------------
#
# Path to Smoke and Dust input files
#
#-----------------------------------------------------------------------
#
rave_intp_dir=${COMINsmoke}/RAVE_INTP
hourly_hwpdir=${COMINsmoke}/HOURLY_HWP
#
#-----------------------------------------------------------------------
#
# Link the the hourly, interpolated RAVE data
#
#-----------------------------------------------------------------------
#
# Current and previous day calculation
export CDATE=${PDY}${cyc}
export CDATEm1="${PDYm1}${cyc}"

# Number of files to process
nfiles=24
smokeFile="${SMOKE_DUST_FILE_PREFIX}_${CDATE}00.nc"

for i in $(seq 0 $(($nfiles - 1)) )
do 
  if [ "${EBB_DCYCLE}" -eq 2 ]; then	
    # For ebb_dc == 2	   
    timestr=$($NDATE +$i ${CDATEm1})
    intp_fname=${PREDEF_GRID_NAME}_intp_${timestr}00_${timestr}59.nc
  else
    # For ebb_dc == 1	   
    timestr=$($NDATE +$i ${CDATE})
    intp_fname=${PREDEF_GRID_NAME}_intp_${timestr}00_${timestr}59.nc
  fi

  if [ -f ${rave_intp_dir}/${intp_fname} ]; then
    ln -nsf ${rave_intp_dir}/${intp_fname} ${DATA}/${intp_fname}
    echo "${rave_intp_dir}/${intp_fname} interoplated file available."
  else
    echo "WARNING: ${rave_intp_dir}/${intp_fname} interoplated file non available."
  fi
done
#
#-----------------------------------------------------------------------
#
# link RAVE fire data to working directory $DATA
#
#-----------------------------------------------------------------------
#
if [ -d ${COMINfire}/${PDYm1}/rave ]; then
  fire_rave_dir_work=${DATA}
  ln -snf ${COMINfire}/${PDY}/rave/${RAVE_FIRE_FILE_PREFIX}_* ${fire_rave_dir_work}/.
  ln -snf ${COMINfire}/${PDYm1}/rave/${RAVE_FIRE_FILE_PREFIX}_* ${fire_rave_dir_work}/.
  ln -snf ${COMINfire}/${PDYm2}/rave/${RAVE_FIRE_FILE_PREFIX}_* ${fire_rave_dir_work}/.
else
  fire_rave_dir_work=${COMINfire}
fi

# Check whether the RAVE files need to be split into hourly files
# Format the current day and hour properly for UTC
if [ "${EBB_DCYCLE}" -eq 1 ]; then
  ddhh_to_use="${PDY}${cyc}"
  dd_to_use="${PDY}"
else
  ddhh_to_use="${PDYm1}${cyc}"
  dd_to_use="${PDYm1}"
fi

# Construct file names and check their existence
intp_fname="${fire_rave_dir_work}/RAVE-HrlyEmiss-3km_v2r0_blend_s${ddhh_to_use}00000_e${dd_to_use}23*"
intp_fname_beta="${fire_rave_dir_work}/Hourly_Emissions_3km_${ddhh_to_use}00_${dd_to_use}23*"

echo "Checking for files in directory: $fire_rave_dir_work"

# Find files matching the specified patterns
files_found=$(find "$fire_rave_dir_work" -type f \( -name "${intp_fname##*/}" -o -name "${intp_fname_beta##*/}" \))

if [ -z "$files_found" ]; then
  echo "WARNING: No files found matching patterns."
else
  echo "Files found, proceeding with processing..."
  for file_to_use in $files_found; do
    echo "Using file: $file_to_use"
    for hour in {00..23}; do
      output_file="${fire_rave_dir_work}/Hourly_Emissions_3km_${dd_to_use}${hour}00_${dd_to_use}${hour}00.nc"
      if [ -f "$output_file" ]; then
        echo "Output file for hour $hour already exists: $output_file. Skipping..."
        continue
      fi
      echo "Splitting data for hour $hour..."
      ncks -d time,$hour,$hour "$file_to_use" "$output_file"
    done
    echo "Hourly files processing completed for: $file_to_use"
  done
fi
#
#-----------------------------------------------------------------------
#
# Call python script to generate fire emission files.
#
#-----------------------------------------------------------------------
#
${USHsrw}/generate_fire_emissions.py \
  "${FIXsmoke}/${PREDEF_GRID_NAME}" \
  "${fire_rave_dir_work}" \
  "${DATA}" \
  "${PREDEF_GRID_NAME}" \
  "${EBB_DCYCLE}" \
  "${RESTART_INTERVAL}"
# Capture the return code from the previous command
export err=$?
if [ $err -ne 0 ]; then
  message_txt="Generate_fire_emissions.py failed with return code $err"
  err_exit "${message_txt}"
  print_err_msg_exit "${message_txt}"
fi

#Copy the the hourly, interpolated RAVE data to $rave_nwges_dir so it
# is maintained there for future cycles.
# Function to check if all files in the directory are older than 15 days

are_all_files_older_than_15_days() {
    find "$1" -type f -mtime -15 | read
    return $?
}

# Check if all files in the rave_nwges_dir are older than 5 days
if are_all_files_older_than_15_days "${rave_intp_dir}"; then
  echo "All files are older than 5 days. Replacing all files."
  # Loop through all files in the work directory and replace them in rave_nwges_dir
  for file in ${DATA}/*; do
    filename=$(basename "$file")
    target_file="${COMINsmoke}/${filename}"
        
    cp "${file}" "${target_file}"
    echo "Copied file: $filename"
  done
else
  echo "Not all files are older than 5 days. Checking individual files."
  # Loop through all files in the work directory
  for file in ${DATA}/*; do
    filename=$(basename "$file")
    target_file="${COMINsmoke}/${filename}"

    # Check if the file matches the pattern or is missing in the target directory
    if [[ "$filename" =~ SMOKE_RRFS_data_.*\.nc ]]; then
      cp "${file}" "${target_file}"
      echo "Copied file: $filename"
    elif [ ! -f "${target_file}" ]; then
      cp "${file}" "${target_file}"
      echo "Copied missing file: $filename"
    fi
  done
fi

echo "Copy RAVE interpolated files completed"
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
{ restore_shell_opts; } > /dev/null 2>&1
