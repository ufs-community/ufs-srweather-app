#!/bin/bash

#
#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. ${GLOBAL_VAR_DEFNS_FP}
. $USHdir/source_util_funcs.sh
#
#-----------------------------------------------------------------------
#
# Save current shell options (in a global array).  Then set new options
# for this script/function.
#
#-----------------------------------------------------------------------
#
{ save_shell_opts; set -u -x; } > /dev/null 2>&1
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

This is the script for the task that runs smoke emissions preprocessing.
========================================================================"
#
#-----------------------------------------------------------------------
#
# Set the name of and create the directory in which the output from this
# script will be saved for long time (if that directory doesn't already exist).
#
#-----------------------------------------------------------------------
#
export rave_nwges_dir=${NWGES_DIR}/RAVE_INTP
mkdir -p "${rave_nwges_dir}"
export hourly_hwpdir=${NWGES_BASEDIR}/HOURLY_HWP
mkdir -p "${hourly_hwpdir}"
#
#-----------------------------------------------------------------------
#
# Link the the hourly, interpolated RAVE data from $rave_nwges_dir so it
# is reused
#
#-----------------------------------------------------------------------
ECHO=/bin/echo
SED=/bin/sed
DATE=/bin/date
LN=/bin/ln
ebb_dc=${EBB_DCYCLE}

# Start date manipulation
START_DATE=$(${ECHO} "${CDATE}" | ${SED} 's/\([[:digit:]]\{2\}\)$/ \1/')
YYYYMMDDHH=$(${DATE} +%Y%m%d%H -d "${START_DATE}")
YYYYMMDD=${YYYYMMDDHH:0:8}
HH=${YYYYMMDDHH:8:2}
${ECHO} ${YYYYMMDD}
${ECHO} ${HH}

# Current and previous day calculation
current_day=`${DATE} -d "${YYYYMMDD}"`
current_hh=`${DATE} -d ${HH} +"%H"`

prev_hh=`${DATE} -d "$current_hh -24 hour" +"%H"`
previous_day=`${DATE} '+%C%y%m%d' -d "$current_day-1 days"`
previous_day="${previous_day} ${prev_hh}"

# Number of files to process
nfiles=24
smokeFile=SMOKE_RRFS_data_${YYYYMMDDHH}00.nc

for i in $(seq 0 $(($nfiles - 1)) )
do 
   if [ "$ebb_dc" -eq 2 ]; then	

      # For ebb_dc == 2	   
      timestr=`date +%Y%m%d%H -d "$previous_day + $i hours"`
      intp_fname=${PREDEF_GRID_NAME}_intp_${timestr}00_${timestr}59.nc
   else
       # For ebb_dc == 1	   
      timestr=`date +%Y%m%d%H -d "$current_day $current_hh + $i hours"`
      intp_fname=${PREDEF_GRID_NAME}_intp_${timestr}00_${timestr}59.nc
   fi

   if  [ -f ${rave_nwges_dir}/${intp_fname} ]; then
      ${LN} -sf ${rave_nwges_dir}/${intp_fname} ${workdir}/${intp_fname}
      echo "${rave_nwges_dir}/${intp_fname} interoplated file available to reuse"
   else
      echo "${rave_nwges_dir}/${intp_fname} interoplated file non available to reuse"  
   fi
done

#-----------------------------------------------------------------------
#
#  link RAVE data to work directory  $workdir
#
#-----------------------------------------------------------------------

previous_2day=`${DATE} '+%C%y%m%d' -d "$current_day-2 days"`
YYYYMMDDm1=${previous_day:0:8}
YYYYMMDDm2=${previous_2day:0:8}
if [ -d ${FIRE_RAVE_DIR}/${YYYYMMDDm1}/rave ]; then
   fire_rave_dir_work=${workdir}
   ln -snf ${FIRE_RAVE_DIR}/${YYYYMMDD}/rave/RAVE-HrlyEmiss-3km_* ${fire_rave_dir_work}/.
   ln -snf ${FIRE_RAVE_DIR}/${YYYYMMDDm1}/rave/RAVE-HrlyEmiss-3km_* ${fire_rave_dir_work}/.
   ln -snf ${FIRE_RAVE_DIR}/${YYYYMMDDm2}/rave/RAVE-HrlyEmiss-3km_* ${fire_rave_dir_work}/.
else
   fire_rave_dir_work=${FIRE_RAVE_DIR}
fi

# Check whether the RAVE files need to be split into hourly files
# Format the current day and hour properly for UTC
if [ "$ebb_dc" -eq 1 ]; then
    ddhh_to_use="${current_day}${current_hh}"
    dd_to_use="${current_day}"
else
    ddhh_to_use="${previous_day}${prev_hh}"
    dd_to_use="${previous_day}"
fi

# Construct file names and check their existence
intp_fname="${fire_rave_dir_work}/RAVE-HrlyEmiss-3km_v2r0_blend_s${ddhh_to_use}00000_e${dd_to_use}23*"
intp_fname_beta="${fire_rave_dir_work}/Hourly_Emissions_3km_${ddhh_to_use}00_${dd_to_use}23*"

echo "Checking for files in directory: $fire_rave_dir_work"

# Find files matching the specified patterns
files_found=$(find "$fire_rave_dir_work" -type f \( -name "${intp_fname##*/}" -o -name "${intp_fname_beta##*/}" \))

if [ -z "$files_found" ]; then
    echo "No files found matching patterns."
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
# Call the ex-script for this J-job.
#
#-----------------------------------------------------------------------
#
python -u  ${USHdir}/generate_fire_emissions.py \
  "${FIX_SMOKE_DUST}/${PREDEF_GRID_NAME}" \
  "${fire_rave_dir_work}" \
  "${workdir}" \
  "${PREDEF_GRID_NAME}" \
  "${EBB_DCYCLE}" \
  "${RESTART_INTERVAL}" \

# Capture the return code from the previous command
err=$?
echo "Return code from generate_fire_emissions.py: $err"
export err

# Check the return code before calling err_chk
if [ $err -ne 0 ]; then
    echo "Error: generate_fire_emissions.py failed with return code $err"
    err_chk
fi

#Copy the the hourly, interpolated RAVE data to $rave_nwges_dir so it
# is maintained there for future cycles.
# Function to check if all files in the directory are older than 15 days

are_all_files_older_than_15_days() {
    find "$1" -type f -mtime -15 | read
    return $?
}

# Check if all files in the rave_nwges_dir are older than 5 days
if are_all_files_older_than_15_days "${rave_nwges_dir}"; then
    echo "All files are older than 5 days. Replacing all files."

    # Loop through all files in the work directory and replace them in rave_nwges_dir
    for file in ${workdir}/*; do
        filename=$(basename "$file")
        target_file="${rave_nwges_dir}/${filename}"
        
        cp "${file}" "${target_file}"
        echo "Copied file: $filename"
    done
else
    echo "Not all files are older than 5 days. Checking individual files."

    # Loop through all files in the work directory
    for file in ${workdir}/*; do
        filename=$(basename "$file")
        target_file="${rave_nwges_dir}/${filename}"

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
# Print exit message.
#
#-----------------------------------------------------------------------
#
print_info_msg "
========================================================================
Exiting script:  \"${scrfunc_fn}\"
In directory:    \"${scrfunc_dir}\"
========================================================================"
#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script/function.
#
#-----------------------------------------------------------------------
#
{ restore_shell_opts; } > /dev/null 2>&1


