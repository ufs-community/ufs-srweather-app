#!/bin/bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. $USHdir/source_util_funcs.sh
source_config_for_task "task_get_extrn_ics|task_get_extrn_lbcs" ${GLOBAL_VAR_DEFNS_FP}
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

This is the ex-script for the task that copies or fetches external model
input data from disk, HPSS, or a URL, and stages them to the
workflow-specified location so that they may be used to generate initial
or lateral boundary conditions for the FV3.
========================================================================"
#
#-----------------------------------------------------------------------
#
# Set up variables for call to retrieve_data.py
#
#-----------------------------------------------------------------------
#
set -x
if [ "${ICS_OR_LBCS}" = "ICS" ]; then
  if [ ${TIME_OFFSET_HRS} -eq 0 ] ; then
    anl_or_fcst="anl"
  else
    anl_or_fcst="fcst"
  fi
  fcst_hrs=${TIME_OFFSET_HRS}
  file_names=${EXTRN_MDL_FILES_ICS[@]}
  if [ ${EXTRN_MDL_NAME} = FV3GFS ] || [ "${EXTRN_MDL_NAME}" == "GDAS" ] ; then
    file_type=$FV3GFS_FILE_FMT_ICS
  fi
  input_file_path=${EXTRN_MDL_SOURCE_BASEDIR_ICS:-$EXTRN_MDL_SYSBASEDIR_ICS}

elif [ "${ICS_OR_LBCS}" = "LBCS" ]; then
  anl_or_fcst="fcst"
  first_time=$((TIME_OFFSET_HRS + LBC_SPEC_INTVL_HRS))
  last_time=$((TIME_OFFSET_HRS + FCST_LEN_HRS))
  fcst_hrs="${first_time} ${last_time} ${LBC_SPEC_INTVL_HRS}"
  file_names=${EXTRN_MDL_FILES_LBCS[@]}
  if [ ${EXTRN_MDL_NAME} = FV3GFS ] || [ "${EXTRN_MDL_NAME}" == "GDAS" ] ; then
    file_type=$FV3GFS_FILE_FMT_LBCS
  fi
  input_file_path=${EXTRN_MDL_SOURCE_BASEDIR_LBCS:-$EXTRN_MDL_SYSBASEDIR_LBCS}
fi

data_stores="${EXTRN_MDL_DATA_STORES}"

yyyymmddhh=${EXTRN_MDL_CDATE:0:10}
yyyy=${yyyymmddhh:0:4}
yyyymm=${yyyymmddhh:0:6}
yyyymmdd=${yyyymmddhh:0:8}
mm=${yyyymmddhh:4:2}
dd=${yyyymmddhh:6:2}
hh=${yyyymmddhh:8:2}

# Set to use the pre-defined data paths in the machine file (ush/machine/).
PDYext=${yyyymmdd}
cycext=${hh}

# Set an empty members directory
mem_dir=""

#
#-----------------------------------------------------------------------
#
# if path has space in between it is a command, otherwise
# treat it as a template path
#
#-----------------------------------------------------------------------
#
input_file_path=$(eval echo ${input_file_path})
if [[ $input_file_path = *" "* ]]; then
  input_file_path=$(eval ${input_file_path})
fi

#
#-----------------------------------------------------------------------
#
# Set up optional flags for calling retrieve_data.py
#
#-----------------------------------------------------------------------
#
additional_flags=""


if [ -n "${file_type:-}" ] ; then 
  additional_flags="$additional_flags \
  --file_type ${file_type}"
fi

if [ -n "${file_names:-}" ] ; then
  additional_flags="$additional_flags \
  --file_templates ${file_names[@]}"
fi

if [ -n "${input_file_path:-}" ] ; then
  data_stores="disk $data_stores"
  additional_flags="$additional_flags \
  --input_file_path ${input_file_path}"
fi

if [ $SYMLINK_FIX_FILES = "TRUE" ]; then
  additional_flags="$additional_flags \
  --symlink"
fi

if [ $DO_ENSEMBLE == "TRUE" ] ; then
  mem_dir="/mem{mem:03d}"
  member_list=(1 ${NUM_ENS_MEMBERS})
  additional_flags="$additional_flags \
  --members ${member_list[@]}"
fi
#
#-----------------------------------------------------------------------
#
# Call ush script to retrieve files
#
#-----------------------------------------------------------------------
#
if [ $RUN_ENVIR = "nco" ]; then
    EXTRN_DEFNS="${NET}.${cycle}.${EXTRN_MDL_NAME}.${ICS_OR_LBCS}.${EXTRN_MDL_VAR_DEFNS_FN}.sh"
else
    EXTRN_DEFNS="${EXTRN_MDL_VAR_DEFNS_FN}.sh"
fi
cmd="
python3 -u ${USHdir}/retrieve_data.py \
  --debug \
  --anl_or_fcst ${anl_or_fcst} \
  --config ${PARMdir}/data_locations.yml \
  --cycle_date ${EXTRN_MDL_CDATE} \
  --data_stores ${data_stores} \
  --external_model ${EXTRN_MDL_NAME} \
  --fcst_hrs ${fcst_hrs[@]} \
  --ics_or_lbcs ${ICS_OR_LBCS} \
  --output_path ${EXTRN_MDL_STAGING_DIR}${mem_dir} \
  --summary_file ${EXTRN_DEFNS} \
  $additional_flags"

$cmd || print_err_msg_exit "\
Call to retrieve_data.py failed with a non-zero exit status.

The command was:
${cmd}
"
#
#-----------------------------------------------------------------------
#
# Merge GEFS files
#
#-----------------------------------------------------------------------
#
function filename_mod() {
    # Function that modifies the filenames
    fn_mod=$(echo "$1" |
             sed "s|{mem:02d}|$num|g" |
             sed "s|t{hh}|t${hh}|g" |
             sed "s|f{fcst_hr:03d}|f`printf %03d $fcst_hr`|g" |
             sed "s|f{fcst_hr:02d}|f`printf %02d $fcst_hr`|g" )
    echo $fn_mod
}

if [ "${EXTRN_MDL_NAME}" = "GEFS" ]; then
    # Use grep command to fetch the variations of GEFS filenames from data_locations.yml
    filenames_lines=(8 9 10)
    filenames=(2 4)
    fn_list=()
    for line in "${filenames_lines[@]}"; do
        for name in "${filenames[@]}"; do
            filename=$( grep -A$line 'GEFS' ${PARMdir}/data_locations.yml |
                        tail -n1 |
                        awk -F "'" "{ print $ $name }" )
            fn_list+=( "$filename" )
        done
    done

    # This block of code sets the forecast hour range based on ICS/LBCS
    if [ "${ICS_OR_LBCS}" = "LBCS" ]; then
        fcst_hrs_tmp=( $fcst_hrs )
        all_fcst_hrs_array=( $(seq ${fcst_hrs_tmp[0]} ${fcst_hrs_tmp[2]} ${fcst_hrs_tmp[1]}) )
    else
        all_fcst_hrs_array=( ${fcst_hrs} )
    fi

    # Loop through ensemble member numbers and forecast hours
    for num in $(seq -f "%02g" ${NUM_ENS_MEMBERS}); do
        for fcst_hr in "${all_fcst_hrs_array[@]}"; do
            # Loop through GEFS filenames and call the filename_mod to get properly formatted names
            # Then store results as a list
            for fn in ${fn_list[@]}; do
                mod_fn=$(filename_mod $fn)
                mod_fn_list+=( $mod_fn )
            done
            # Define filename lists used to check if files exist
            fn_list_1=( ${mod_fn_list[0]} ${mod_fn_list[1]}
                       "gep$num.t${hh}z.pgrb2.0p50.f`printf %03d $fcst_hr`" )
            fn_list_2=( ${mod_fn_list[2]} ${mod_fn_list[3]}
                       "gep$num.t${hh}z.pgrb2`printf %02d $fcst_hr`" )
            fn_list_3=( ${mod_fn_list[4]} ${mod_fn_list[5]}
                       "gep$num.t${hh}z.pgrb2`printf %03d $fcst_hr`" )
            #echo ${fn_list_1[@]}
            fn_lists=( "fn_list_1" "fn_list_2" "fn_list_3" )

            base_path="${EXTRN_MDL_STAGING_DIR}/mem`printf %03d $num`"
            printf "Looking for files in $base_path\n"

            # Look for filenames, if they exist, merge files together
            for fn in "${fn_lists[@]}"; do
                fn_str="$fn[@]"
                fn_array=( "${!fn_str}" )
                if [ -f "$base_path/${fn_array[0]}" ] && [ -f "$base_path/${fn_array[1]}" ]; then
                    printf "Found files: ${fn_array[0]} and ${fn_array[1]} \nCreating new file: ${fn_array[2]}\n"
                    cat $base_path/${fn_array[0]} $base_path/${fn_array[1]} > $base_path/${fn_array[2]}
                    merged_fn+=( "${fn_array[2]}" )
                fi
            done
        done
        # If merge files exist, update the extrn_defn file
        merged_fn_str="( ${merged_fn[@]} )"
        printf "Merged files are: ${merged_fn_str} \nUpdating ${EXTRN_DEFNS}\n\n"
        sed -i "s|EXTRN_MDL_FNS=.*|EXTRN_MDL_FNS=${merged_fn_str}|g" $base_path/${EXTRN_DEFNS}
        merged_fn=()
        mod_fn_list=()
    done
fi
#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script/function.
#
#-----------------------------------------------------------------------
#
{ restore_shell_opts; } > /dev/null 2>&1

