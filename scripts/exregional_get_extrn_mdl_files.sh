#!/usr/bin/env bash


#
#-----------------------------------------------------------------------
#
# The ex-script for getting the model files that will be used for either
# initial conditions or lateral boundary conditions for the experiment.
#
# Run-time environment variables:
#
#    CDATE
#    COMIN
#    cyc
#    DATA
#    EXTRN_MDL_CDATE
#    EXTRN_MDL_NAME
#    EXTRN_MDL_STAGING_DIR
#    GLOBAL_VAR_DEFNS_FP
#    ICS_OR_LBCS
#    NET
#    PDY
#    TIME_OFFSET_HRS
#
# Experiment variables
#
#  user:
#    MACHINE
#    PARMdir
#    RUN_ENVIR
#    USHdir
#
#  platform:
#    EXTRN_MDL_DATA_STORES
#
#  workflow:
#    DATE_FIRST_CYCL
#    EXTRN_MDL_VAR_DEFNS_FN
#    FCST_LEN_CYCL
#    INCR_CYCL_FREQ
#    SYMLINK_FIX_FILES
#
#  task_get_extrn_lbcs:
#    EXTRN_MDL_FILES_LBCS
#    EXTRN_MDL_SOURCE_BASEDIR_LBCS
#    EXTRN_MDL_SYSBASEDIR_LBCS
#    FV3GFS_FILE_FMT_LBCS
#    LBC_SPEC_INTVL_HRS
#
#  task_get_extrn_ics:
#    EXTRN_MDL_FILES_ICS
#    EXTRN_MDL_SOURCE_BASEDIR_ICS
#    EXTRN_MDL_SYSBASEDIR_ICS
#    FV3GFS_FILE_FMT_ICS
#
#  global:
#    DO_ENSEMBLE
#    NUM_ENS_MEMBERS
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
sections=(
  user
  nco
  platform
  workflow
  global
  task_get_extrn_ics.envvars
  task_get_extrn_lbcs.envvars
)
for sect in ${sections[*]} ; do
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
if [ "${ICS_OR_LBCS}" = "ICS" ]; then
  if [ ${TIME_OFFSET_HRS} -eq 0 ] ; then
    file_set="anl"
  else
    file_set="fcst"
  fi
  fcst_hrs=${TIME_OFFSET_HRS}
  file_names=${EXTRN_MDL_FILES_ICS[@]}
  if [ ${EXTRN_MDL_NAME} = FV3GFS ] || [ "${EXTRN_MDL_NAME}" == "GDAS" ] \
     || [ ${EXTRN_MDL_NAME} == "UFS-CASE-STUDY" ] ; then
    file_fmt=$FV3GFS_FILE_FMT_ICS
  fi
  input_file_path=${EXTRN_MDL_SOURCE_BASEDIR_ICS:-$EXTRN_MDL_SYSBASEDIR_ICS}

elif [ "${ICS_OR_LBCS}" = "LBCS" ]; then
  file_set="fcst"
  first_time=$((TIME_OFFSET_HRS + LBC_SPEC_INTVL_HRS))

  if [ ${#FCST_LEN_CYCL[@]} -gt 1 ]; then
    cyc_mod=$(( 10#${cyc} - ${DATE_FIRST_CYCL:8:2} ))
    CYCLE_IDX=$(( ${cyc_mod} / ${INCR_CYCL_FREQ} ))
    FCST_LEN_HRS=${FCST_LEN_CYCL[$CYCLE_IDX]}
  fi
  end_hr=$FCST_LEN_HRS
  first_time=$((TIME_OFFSET_HRS + LBC_SPEC_INTVL_HRS ))
  last_time=$((TIME_OFFSET_HRS + end_hr))

  #
  # If a single cycle of EXTRN_MDL_NAME_LBCS cannot provide forecast hours
  # out to last_time (e.g. HRRR, which tops out at 48 h), cap this (base)
  # retrieval at EXTRN_MDL_LBCS_MAX_FCST_HRS and bridge in subsequent cycles
  # for the remaining hours after the base retrieve_data.py call succeeds
  # (see the bridging block below, after the main retrieve_data.py call).
  #
  lbcs_bridging=NO
  base_last_time=${last_time}
  if [ -n "${EXTRN_MDL_LBCS_MAX_FCST_HRS:-}" ] && [ "${EXTRN_MDL_LBCS_MAX_FCST_HRS}" -lt "${last_time}" ]; then
    lbcs_bridging=YES
    base_last_time=${EXTRN_MDL_LBCS_MAX_FCST_HRS}
  fi

  fcst_hrs="${first_time} ${base_last_time} ${LBC_SPEC_INTVL_HRS}"
  file_names=${EXTRN_MDL_FILES_LBCS[@]}
  if [ ${EXTRN_MDL_NAME} = FV3GFS ] || [ "${EXTRN_MDL_NAME}" == "GDAS" ] \
     || [ ${EXTRN_MDL_NAME} == "UFS-CASE-STUDY" ] ; then
    file_fmt=$FV3GFS_FILE_FMT_LBCS
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


if [ -n "${file_fmt:-}" ] ; then
  additional_flags="$additional_flags \
  --file_fmt ${file_fmt}"
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

if [ $(boolify $SYMLINK_FIX_FILES) = "TRUE" ]; then
  additional_flags="$additional_flags \
  --symlink"
fi

if [ $(boolify $DO_ENSEMBLE) = "TRUE" ] ; then
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

mkdir -p ${EXTRN_MDL_STAGING_DIR}${mem_dir}

if [ $RUN_ENVIR = "nco" ]; then
    EXTRN_DEFNS="${NET}.${cycle}.${EXTRN_MDL_NAME}.${ICS_OR_LBCS}.${EXTRN_MDL_VAR_DEFNS_FN}.sh"
else
    EXTRN_DEFNS="${EXTRN_MDL_VAR_DEFNS_FN}.sh"
fi

if [ "${ICS_OR_LBCS}" = "LBCS" ] && [ "${lbcs_bridging}" = "YES" ]; then
  #
  #-----------------------------------------------------------------------
  #
  # The requested LBC forecast length exceeds what a single cycle of
  # EXTRN_MDL_NAME_LBCS can provide (EXTRN_MDL_LBCS_MAX_FCST_HRS). Retrieve
  # the LBCs in EXTRN_MDL_LBCS_BRIDGE_INTVL_HRS-sized chunks. Before each
  # chunk, check whether a fresher (later, on-schedule) cycle of the same
  # external model has become available and, if so, switch to it -- always
  # prefer the freshest available guidance. This check repeats every
  # EXTRN_MDL_LBCS_BRIDGE_INTVL_HRS for the whole run (no permanent
  # opt-out); whenever the fresher cycle is not yet available, that chunk
  # simply falls back to extending whichever cycle is currently in use, up
  # to its own EXTRN_MDL_LBCS_MAX_FCST_HRS.
  #
  #-----------------------------------------------------------------------
  #
  lbcs_staging_dir="${EXTRN_MDL_STAGING_DIR}${mem_dir}"
  base_defns_fp="${lbcs_staging_dir}/${EXTRN_DEFNS}"

  bridge_additional_flags=""
  bridge_data_stores="${EXTRN_MDL_DATA_STORES}"
  if [ -n "${file_fmt:-}" ] ; then
    bridge_additional_flags="$bridge_additional_flags --file_fmt ${file_fmt}"
  fi
  if [ -n "${file_names:-}" ] ; then
    bridge_additional_flags="$bridge_additional_flags --file_templates ${file_names[@]}"
  fi
  if [ -n "${input_file_path:-}" ] ; then
    # input_file_path may contain date/time templates (e.g. {yyyymmddhh})
    # that retrieve_data.py fills in per-call using each cycle's own
    # --cycle_date, so the same staging convention used for the nominal
    # cycle also works for locally-staged bridge cycles.
    bridge_data_stores="disk ${EXTRN_MDL_DATA_STORES}"
    bridge_additional_flags="$bridge_additional_flags --input_file_path ${input_file_path}"
  fi
  if [ $(boolify $SYMLINK_FIX_FILES) = "TRUE" ]; then
    bridge_additional_flags="$bridge_additional_flags --symlink"
  fi

  combined_fns=()
  combined_fhrs=()

  # State for the rolling freshness check: current_cdate is the cycle
  # presently in use, current_cycle_start_offset is the relative forecast
  # hour at which that cycle's own hour 0 aligns.
  current_cdate=${EXTRN_MDL_CDATE}
  current_cycle_start_offset=${TIME_OFFSET_HRS}

  offset=${TIME_OFFSET_HRS}
  while [ "${offset}" -lt "${last_time}" ]; do

    chunk_end=$(( offset + EXTRN_MDL_LBCS_BRIDGE_INTVL_HRS ))
    if [ "${chunk_end}" -gt "${last_time}" ]; then
      chunk_end=${last_time}
    fi

    use_cdate=${current_cdate}
    use_start_offset=${current_cycle_start_offset}
    fetched_dir=""
    fetched_defns=""

    # Every EXTRN_MDL_LBCS_BRIDGE_INTVL_HRS, check whether a fresher
    # (later, on-schedule) cycle of the external model has become
    # available, and prefer it if so. This check repeats every interval,
    # for the whole run -- there is no permanent opt-out. If the fresher
    # cycle is not available, this chunk simply falls back to extending
    # whichever cycle is currently in use.
    n_intervals=$(( offset / EXTRN_MDL_LBCS_BRIDGE_INTVL_HRS ))
    ideal_cdate=$( $DATE_UTIL --utc --date "${yyyymmdd} ${hh} UTC + $(( n_intervals * EXTRN_MDL_LBCS_BRIDGE_INTVL_HRS )) hours" "+%Y%m%d%H" )

    if [ "${ideal_cdate}" -gt "${current_cdate}" ]; then

      trial_dir="${lbcs_staging_dir}/fcst_cycle_${ideal_cdate}"
      mkdir -p "${trial_dir}"
      trial_defns="fcst_cycle_${ideal_cdate}.sh"
      trial_len=$(( chunk_end - offset ))

      trial_cmd="
      python3 -u ${USHdir}/retrieve_data.py \
        --debug \
        --file_set ${file_set} \
        --config ${PARMdir}/data_locations.yml \
        --cycle_date ${ideal_cdate} \
        --data_stores ${bridge_data_stores} \
        --data_type ${EXTRN_MDL_NAME} \
        --fcst_hrs ${LBC_SPEC_INTVL_HRS} ${trial_len} ${LBC_SPEC_INTVL_HRS} \
        --ics_or_lbcs ${ICS_OR_LBCS} \
        --output_path ${trial_dir} \
        --summary_file ${trial_defns} \
        $bridge_additional_flags"

      if $trial_cmd; then
        use_cdate=${ideal_cdate}
        use_start_offset=${offset}
        fetched_dir=${trial_dir}
        fetched_defns=${trial_defns}
        current_cdate=${use_cdate}
        current_cycle_start_offset=${use_start_offset}
      fi

    fi

    rel_start=$(( offset - use_start_offset + LBC_SPEC_INTVL_HRS ))
    rel_end=$(( chunk_end - use_start_offset ))

    if [ "${rel_end}" -gt "${EXTRN_MDL_LBCS_MAX_FCST_HRS}" ]; then
      message_txt="Unable to obtain LBCs for the external model (EXTRN_MDL_NAME):
  EXTRN_MDL_NAME = \"${EXTRN_MDL_NAME}\"
Cycle ${use_cdate} cannot provide forecast hour ${rel_end} (its own limit is
EXTRN_MDL_LBCS_MAX_FCST_HRS=${EXTRN_MDL_LBCS_MAX_FCST_HRS} h), and no fresher
cycle is available to cover relative forecast hours $((offset + LBC_SPEC_INTVL_HRS)) through ${chunk_end}."
      if [ "${RUN_ENVIR}" = "nco" ] && [ "${MACHINE}" = "WCOSS2" ]; then
        err_exit "${message_txt}"
      else
        print_err_msg_exit "${message_txt}"
      fi
    fi

    if [ -z "${fetched_dir}" ]; then
      fetched_dir="${lbcs_staging_dir}/fcst_cycle_${use_cdate}"
      mkdir -p "${fetched_dir}"
      fetched_defns="fcst_cycle_${use_cdate}_$(printf %03d ${rel_start})-$(printf %03d ${rel_end}).sh"

      fetch_cmd="
      python3 -u ${USHdir}/retrieve_data.py \
        --debug \
        --file_set ${file_set} \
        --config ${PARMdir}/data_locations.yml \
        --cycle_date ${use_cdate} \
        --data_stores ${bridge_data_stores} \
        --data_type ${EXTRN_MDL_NAME} \
        --fcst_hrs ${rel_start} ${rel_end} ${LBC_SPEC_INTVL_HRS} \
        --ics_or_lbcs ${ICS_OR_LBCS} \
        --output_path ${fetched_dir} \
        --summary_file ${fetched_defns} \
        $bridge_additional_flags"

      if ! $fetch_cmd; then
        message_txt="Call to retrieve_data.py failed with a non-zero exit status.
The command was:
${fetch_cmd}
"
        if [ "${RUN_ENVIR}" = "nco" ] && [ "${MACHINE}" = "WCOSS2" ]; then
          err_exit "${message_txt}"
        else
          print_err_msg_exit "${message_txt}"
        fi
      fi
    fi

    EXTRN_MDL_FNS=()
    EXTRN_MDL_FHRS=()
    . "${fetched_dir}/${fetched_defns}"
    for idx in "${!EXTRN_MDL_FNS[@]}"; do
      rel_fhr=$(( use_start_offset + EXTRN_MDL_FHRS[$idx] ))
      new_fn="bridge.f$(printf %03d ${rel_fhr}).$(basename ${EXTRN_MDL_FNS[$idx]})"
      ln -sf "${fetched_dir}/${EXTRN_MDL_FNS[$idx]}" "${lbcs_staging_dir}/${new_fn}"
      combined_fns+=( "${new_fn}" )
      combined_fhrs+=( "${rel_fhr}" )
    done

    offset=${chunk_end}

  done

  {
    echo "DATA_SRC=disk_and_bridge"
    echo "EXTRN_MDL_CDATE=${EXTRN_MDL_CDATE}"
    echo "EXTRN_MDL_STAGING_DIR=${lbcs_staging_dir}"
    echo "EXTRN_MDL_FNS=( ${combined_fns[@]} )"
    echo "EXTRN_MDL_FHRS=( ${combined_fhrs[@]} )"
  } > "${base_defns_fp}"

else
  cmd="
  python3 -u ${USHdir}/retrieve_data.py \
    --debug \
    --file_set ${file_set} \
    --config ${PARMdir}/data_locations.yml \
    --cycle_date ${EXTRN_MDL_CDATE} \
    --data_stores ${data_stores} \
    --data_type ${EXTRN_MDL_NAME} \
    --fcst_hrs ${fcst_hrs[@]} \
    --ics_or_lbcs ${ICS_OR_LBCS} \
    --output_path ${EXTRN_MDL_STAGING_DIR}${mem_dir} \
    --summary_file ${EXTRN_DEFNS} \
    $additional_flags"

  $cmd
  export err=$?
  if [ $err -ne 0 ]; then
    message_txt="Call to retrieve_data.py failed with a non-zero exit status.
The command was:
${cmd}
"
    if [ "${RUN_ENVIR}" = "nco" ] && [ "${MACHINE}" = "WCOSS2" ]; then
      err_exit "${message_txt}"
    else
      print_err_msg_exit "${message_txt}"
    fi
  fi
fi

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
            # Read in filenames from EXTRN_MDL_FNS and sort them
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
# unzip UFS-CASE-STUDY ICS/LBCS files
#
#-----------------------------------------------------------------------
#
if [ "${EXTRN_MDL_NAME}" = "UFS-CASE-STUDY" ]; then
    # Look for filenames, if they exist, unzip them
    base_path="${EXTRN_MDL_STAGING_DIR}${mem_dir}"
    for filename in ${base_path}/*.tar.gz; do
        printf "unzip file: ${filename}\n"
        tar -zxvf ${filename} --directory ${base_path}
    done
    # check file naming issue
    for filename in ${base_path}/*.nemsio; do
        filename=$(basename -- "${filename}")
        len=`echo $filename | wc -c`
        if [ "${filename:4:4}" != "t${hh}z" ]; then
            printf "rename ${filename} to ${filename:0:4}t${hh}z.${filename:4:${len}} \n"
           mv ${base_path}/${filename} ${base_path}/${filename:0:4}t${hh}z.${filename:4:${len}}
        fi
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

