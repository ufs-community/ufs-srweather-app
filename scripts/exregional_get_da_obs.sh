#!/bin/bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. $USHdir/source_util_funcs.sh
source_config_for_task "task_run_anl|task_run_enkf" ${GLOBAL_VAR_DEFNS_FP}
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
# Enter working directory; set up variables for call to retrieve_data.py
#
#-----------------------------------------------------------------------
#
print_info_msg "$VERBOSE" "
Entering working directory for observation files ..."

cd_vrfy ${DATA}

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

if [ $SYMLINK_FIX_FILES = "TRUE" ]; then
  additional_flags="$additional_flags \
  --symlink"
fi

#
#-----------------------------------------------------------------------
#
# Call script to retrieve files
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
  --file_set ${file_set} \
  --config ${PARMdir}/data_locations.yml \
  --cycle_date ${EXTRN_MDL_CDATE} \
  --data_stores ${data_stores} \
  --external_model ${EXTRN_MDL_NAME} \
  --fcst_hrs ${fcst_hrs[@]} \
  --output_path ${DATA} \
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
if [ "${EXTRN_MDL_NAME}" = "GEFS" ]; then
    
    # This block of code sets the forecast hour range based on ICS/LBCS
    if [ "${ICS_OR_LBCS}" = "LBCS" ]; then
        fcst_hrs_tmp=( $fcst_hrs )
        all_fcst_hrs_array=( $(seq ${fcst_hrs_tmp[0]} ${fcst_hrs_tmp[2]} ${fcst_hrs_tmp[1]}) )
    else
        all_fcst_hrs_array=( ${fcst_hrs} )
    fi

    # Loop through ensemble member numbers and forecast hours
    for num in $(seq -f "%02g" ${NUM_ENS_MEMBERS}); do
        sorted_fn=( )
        for fcst_hr in "${all_fcst_hrs_array[@]}"; do
            # Read in filenames from $EXTRN_MDL_FNS and sort them
            base_path="${EXTRN_MDL_STAGING_DIR}/mem`printf %03d $num`"
            filenames_array=`awk -F= '/EXTRN_MDL_FNS/{print $2}' $base_path/${EXTRN_DEFNS}`
            for filename in ${filenames_array[@]}; do
                IFS='.' read -ra split_fn <<< "$filename"
                if [ `echo -n $filename | tail -c 2` == `printf %02d $fcst_hr` ] && [ "${split_fn[1]}" == "t${hh}z" ] ; then
                    if [ "${split_fn[2]}" == 'pgrb2a' ] ; then
                        sorted_fn+=( "$filename" )
                    elif [ "${split_fn[2]}" == 'pgrb2b' ] ; then
                        sorted_fn+=( "$filename" )
                    elif [ "${split_fn[2]}" == "pgrb2af`printf %02d $fcst_hr`" ] ; then
                        sorted_fn+=( "$filename" )
                    elif [ "${split_fn[2]}" == "pgrb2bf`printf %02d $fcst_hr`" ] ; then
                        sorted_fn+=( "$filename" )
                    elif [ "${split_fn[2]}" == "pgrb2af`printf %03d $fcst_hr`" ] ; then
                        sorted_fn+=( "$filename" )
                    elif [ "${split_fn[2]}" == "pgrb2bf`printf %03d $fcst_hr`" ] ; then
                        sorted_fn+=( "$filename" )
                    fi
                fi
            done

            # Define filename lists used to check if files exist
            fn_list_1=( ${sorted_fn[0]} ${sorted_fn[1]}
                       "gep$num.t${hh}z.pgrb2.0p50.f`printf %03d $fcst_hr`" )
            fn_list_2=( ${sorted_fn[2]} ${sorted_fn[3]}
                       "gep$num.t${hh}z.pgrb2`printf %02d $fcst_hr`" )
            fn_list_3=( ${sorted_fn[4]} ${sorted_fn[5]}
                       "gep$num.t${hh}z.pgrb2`printf %03d $fcst_hr`" )
            echo ${fn_list_1[@]}
            fn_lists=( "fn_list_1" "fn_list_2" "fn_list_3" )

            # Look for filenames, if they exist, merge files together
            printf "Looking for files in $base_path\n"
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
        echo "$(awk -F= -v val="${merged_fn_str}" '/EXTRN_MDL_FNS/ {$2=val} {print}' OFS== $base_path/${EXTRN_DEFNS})" > $base_path/${EXTRN_DEFNS}
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

