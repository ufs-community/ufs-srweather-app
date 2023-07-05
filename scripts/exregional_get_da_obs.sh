#!/bin/bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. $USHdir/source_util_funcs.sh
. $USHdir/get_mrms_files.sh
source_config_for_task "task_get_da_obs|task_process_radarref" ${GLOBAL_VAR_DEFNS_FP}
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

This is the ex-script for the task that retrieves observation data for
RRFS data assimilation tasks. 
========================================================================"
#
#-----------------------------------------------------------------------
#
# Enter working directory; set up variables for call to retrieve_data.py
#
#-----------------------------------------------------------------------
#
print_info_msg "$VERBOSE" "
Entering working directory for observation files ..."

cd_vrfy ${DATA}

if [ $RUN_ENVIR = "nco" ]; then
    EXTRN_DEFNS="${NET}.${cycle}.${EXTRN_MDL_NAME}.${ICS_OR_LBCS}.${EXTRN_MDL_VAR_DEFNS_FN}.sh"
else
    EXTRN_DEFNS="${EXTRN_MDL_VAR_DEFNS_FN}.sh"
fi

#
#-----------------------------------------------------------------------
#
# retrieve RAP obs bufr files
#
#-----------------------------------------------------------------------
#

# Start array for templates for files we will retrieve
template_arr=()

# Obs from different filenames depending on hour
set -x
if [[ ${cyc} -eq '00' || ${cyc} -eq '12' ]]; then
  RAP=rap_e
else
  RAP=rap
fi
# Bufr lightning obs
template_arr+=("${YYYYMMDDHH}.${RAP}.t${cyc}z.lghtng.tm00.bufr_d")
# NASA LaRC cloud bufr file
template_arr+=("${YYYYMMDDHH}.${RAP}.t${cyc}z.lgycld.tm00.bufr_d")
# Prepbufr obs file
template_arr+=("${YYYYMMDDHH}.${RAP}.t${cyc}z.prepbufr.tm00")

additional_flags=""
if [ $SYMLINK_FIX_FILES = "TRUE" ]; then
  additional_flags="$additional_flags \
  --symlink"
fi

if [ -n "${RAP_OBS_BUFR:-}" ] ; then
  data_stores="disk ${EXTRN_MDL_DATA_STORES}"
  additional_flags="$additional_flags \
  --input_file_path ${RAP_OBS_BUFR}"
fi

cmd="
python3 -u ${USHdir}/retrieve_data.py \
  --debug \
  --file_set obs \
  --config ${PARMdir}/data_locations.yml \
  --cycle_date ${PDY}${cyc} \
  --data_stores ${data_stores} \
  --data_type RAP_obs \
  --output_path ${DATA} \
  --summary_file ${EXTRN_DEFNS} \
  --file_templates ${template_arr[@]} \
  $additional_flags"

$cmd || print_err_msg_exit "\
Call to retrieve_data.py failed with a non-zero exit status.

The command was:
${cmd}
"
# Link to GSI-expected filenames
ln_vrfy "${DATA}/${template_arr[0]}" "${DATA}/lghtngbufr"
ln_vrfy "${DATA}/${template_arr[1]}" "${DATA}/lgycld.bufr_d"
ln_vrfy "${DATA}/${template_arr[2]}" "${DATA}/prepbufr"

#
#-----------------------------------------------------------------------
#
# retrieve NLDN NetCDF lightning obs
#
#-----------------------------------------------------------------------
#

if [ "${NLDN_NEEDED:-}" = "TRUE" ]; then
  template_arr=()
  for incr in $(seq -25 5 5) ; do
    filedate=$(date +"%y%j%H%M" -d "${START_DATE} ${incr} minutes ")
    template_arr+=("${filedate}0005r")
  done

  additional_flags=""
  if [ $SYMLINK_FIX_FILES = "TRUE" ]; then
    additional_flags="$additional_flags \
    --symlink"
  fi

  if [ -n "${NLDN_LIGHTNING:-}" ] ; then
    data_stores="disk ${EXTRN_MDL_DATA_STORES}"
    additional_flags="$additional_flags \
    --input_file_path ${NLDN_LIGHTNING}"
  fi

  cmd="
  python3 -u ${USHdir}/retrieve_data.py \
    --debug \
    --file_set obs \
    --config ${PARMdir}/data_locations.yml \
    --cycle_date ${PDY}${cyc} \
    --data_stores ${data_stores} \
    --data_type RAP_obs \
    --output_path ${DATA} \
    --summary_file ${EXTRN_DEFNS} \
    --file_templates ${template_arr[@]} \
    $additional_flags"

  $cmd || print_err_msg_exit "\
  Call to retrieve_data.py failed with a non-zero exit status.

  The command was:
  ${cmd}
  "
  # Link to GSI-expected filenames
  filenum=0
  for incr in $(seq -25 5 5) ; do
    filedate=$(date +"%y%j%H%M" -d "${START_DATE} ${incr} minutes ")
    filename="${filedate}0005r"
    if [ -r ${filename} ]; then
      ((filenum += 1 ))
      mv_vrfy ${filename} ./NLDN_lightning_${filenum}
    else
      print_info_msg "WARNING: ${filename} does not exist"
    fi
  done

fi
#
#-----------------------------------------------------------------------
#
# retrieve NSSL Mosaic Reflectivity observations
#
#-----------------------------------------------------------------------
#


# If files are available on disk, copy them here in the code. This
# approach is used here because of its efficiency compared to repeated
# calls to retrieve_data.py for this observation file type.

#
#-----------------------------------------------------------------------
#
# Check for files on disk first
#
#-----------------------------------------------------------------------
#
mrms="MergedReflectivityQC"

  for timelevel in ${RADARREFL_TIMELEVEL[@]}; do
    echo "timelevel = ${timelevel}"
    timelevel=$( printf %2.2i $timelevel )
    radar_output_path=${RADAR_DATA}/${timelevel}
    mkdir -p $radar_output_path

    #-----------------------------------------------------------------------
    # copy observation files to staging location
    #-----------------------------------------------------------------------
    if [ -n "${NSSLMOSAIC:-}" ] ; then
        get_mrms_files $timelevel $radar_output_path $mrms
    fi

    # Check to see if files were retrieved from disk
    # Try other resources, if not
    if [ ! -s ${radar_output_path}/filelist_mrms ]; then

      cmd="
      python3 -u ${USHdir}/retrieve_data.py \
        --debug \
        --file_set obs \
        --config ${PARMdir}/data_locations.yml \
        --cycle_date ${PDY}${cyc}${timelevel} \
        --data_stores ${EXTRN_MDL_DATA_STORES} \
        --data_type NSSL_mrms \
        --output_path ${radar_output_path}
      "

      $cmd || print_err_msg_exit "\
      Call to retrieve_data.py failed with a non-zero exit status.

      The command was:
      ${cmd}
      "
      ls $radar_output_path/*${mrms}* > $radar_output_path/filelist_mrms
    fi
  done


#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script/function.
#
#-----------------------------------------------------------------------
#
{ restore_shell_opts; } > /dev/null 2>&1
