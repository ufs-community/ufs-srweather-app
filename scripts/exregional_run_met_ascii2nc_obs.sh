#!/usr/bin/env bash

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
  verification
  cpl_aqm_parm
)
for sect in ${sections[*]} ; do
  source_yaml ${GLOBAL_VAR_DEFNS_FP} ${sect}
done
#
#-----------------------------------------------------------------------
#
# Source files defining auxiliary functions for verification.
#
#-----------------------------------------------------------------------
#
. $USHdir/get_metplus_tool_name.sh
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
# Get the name of the MET/METplus tool in different formats that may be
# needed from the global variable METPLUSTOOLNAME.
#
#-----------------------------------------------------------------------
#
get_metplus_tool_name \
  METPLUSTOOLNAME="${METPLUSTOOLNAME}" \
  outvarname_metplus_tool_name="metplus_tool_name" \
  outvarname_MetplusToolName="MetplusToolName" \
  outvarname_METPLUS_TOOL_NAME="METPLUS_TOOL_NAME"
#
#-----------------------------------------------------------------------
#
print_info_msg "
========================================================================
Entering script:  \"${scrfunc_fn}\"
In directory:     \"${scrfunc_dir}\"

This is the ex-script for the task that runs the METplus tool ${MetplusToolName}
to convert ASCII format observation files to NetCDF format.
========================================================================"

yyyymmdd_task=${PDY}

# Seconds since some reference time that the DATE_UTIL utility uses of
# the day of the current task.  This will be used below to find hours
# since the start of this day.
sec_since_ref_task=$(${DATE_UTIL} --date "${yyyymmdd_task} 0 hours" +%s)
#
#-----------------------------------------------------------------------
#
# Get the list of all the times in the current day at which to retrieve
# obs.  This is an array with elements having format "YYYYMMDDHH".
#
#-----------------------------------------------------------------------
#
array_name="OBS_RETRIEVE_TIMES_${OBTYPE}_${yyyymmdd_task}"
eval obs_retrieve_times_crnt_day=\( \${${array_name}[@]} \)
#
CDATE="${PDY}${cyc}"
#
#-----------------------------------------------------------------------
#
# Set paths and file templates for input to and output from the MET/
# METplus tool to be run as well as other file/directory parameters.
#
#-----------------------------------------------------------------------
#
vx_output_basedir=$( eval echo "${VX_OUTPUT_BASEDIR}" )

OBS_INPUT_DIR="${OBS_DIR}"

OUTPUT_BASE="${vx_output_basedir}"
OUTPUT_DIR="${OUTPUT_BASE}/metprd/${MetplusToolName}_obs"
STAGING_DIR="${OUTPUT_BASE}/stage/${MetplusToolName}_obs"
if [ "${OBTYPE}" = "AERONET" ]; then
  OBS_INPUT_FN_TEMPLATE=${OBS_AERONET_FN_TEMPLATES[1]}
  OUTPUT_FN_TEMPLATE=${OBS_AERONET_FN_TEMPLATE_ASCII2NC_OUTPUT}
  ASCII2NC_INPUT_FORMAT=aeronetv3
elif [ "${OBTYPE}" = "AIRNOW" ]; then
  OBS_INPUT_FN_TEMPLATE=${OBS_AIRNOW_FN_TEMPLATES[1]}
  OUTPUT_FN_TEMPLATE=${OBS_AIRNOW_FN_TEMPLATE_ASCII2NC_OUTPUT}
  ASCII2NC_INPUT_FORMAT=${AIRNOW_INPUT_FORMAT}
else
  print_err_msg_exit "\nNo filename template set for OBTYPE \"${OBTYPE}\"!"
fi
#-----------------------------------------------------------------------
#
# Set the array of forecast hours for which to run the MET/METplus tool.
#
#-----------------------------------------------------------------------
#
LEADHR_LIST=""
num_missing_files=0
for yyyymmddhh in ${obs_retrieve_times_crnt_day[@]}; do
  yyyymmdd=$(echo ${yyyymmddhh} | cut -c1-8)
  hh=$(echo ${yyyymmddhh} | cut -c9-10)

  # Set the full path to the final processed obs file (fp_proc) we want to
  # create.
  sec_since_ref=$(${DATE_UTIL} --date "${yyyymmdd} ${hh} hours" +%s)
  lhr=$(( (sec_since_ref - sec_since_ref_task)/3600 ))

  fp=$( python3 $USHdir/eval_metplus_timestr_tmpl.py \
    --init_time="${yyyymmdd_task}00" \
    --lhr="${lhr}" \
    --fn_template="${OBS_DIR}/${OBS_INPUT_FN_TEMPLATE}") || \
    print_err_msg_exit "Call to eval_metplus_timestr_tmpl.py failed with return code: $?"

  if [[ -f "${fp}" ]]; then
    print_info_msg "
Found ${OBTYPE} obs file corresponding to observation retrieval time (yyyymmddhh):
  yyyymmddhh = \"${yyyymmddhh}\"
  fp = \"${fp}\"
"
    hh_noZero=$((10#${hh}))
    LEADHR_LIST="${LEADHR_LIST},${hh_noZero}"
  else
    num_missing_files=$((num_missing_files+1))
    print_info_msg "
${OBTYPE} obs file corresponding to observation retrieval time (yyyymmddhh)
does not exist on disk:
  yyyymmddhh = \"${yyyymmddhh}\"
  fp = \"${fp}\"
Removing this time from the list of times to be processed by ${METPLUSTOOLNAME}.
"
  fi
done

# If the number of missing files is greater than the maximum allowed
# (specified by num_missing_files_max), print out an error message and
# exit.
if [ "${num_missing_files}" -gt "${NUM_MISSING_OBS_FILES_MAX}" ]; then
  print_err_msg_exit "\
The number of missing ${OBTYPE} obs files (num_missing_files) is greater
than the maximum allowed number (NUM_MISSING_FILES_MAX):
  num_missing_files = ${num_missing_files}
  NUM_MISSING_OBS_FILES_MAX = ${NUM_MISSING_OBS_FILES_MAX}"
fi

# Remove leading comma from LEADHR_LIST.
LEADHR_LIST=$( echo "${LEADHR_LIST}" | $SED "s/^,//g" )
print_info_msg "$VERBOSE" "\
Final (i.e. after filtering for missing obs files) set of lead hours
(saved in a scalar string variable) is:
  LEADHR_LIST = \"${LEADHR_LIST}\"
"
#
#-----------------------------------------------------------------------
#
# Make sure the MET/METplus output directory(ies) exists.
#
#-----------------------------------------------------------------------
#
mkdir -p "${OUTPUT_DIR}"
#
#-----------------------------------------------------------------------
#
# Check for existence of top-level OBS_DIR.
#
#-----------------------------------------------------------------------
#
if [ ! -d "${OBS_DIR}" ]; then
  print_err_msg_exit "\
OBS_DIR does not exist or is not a directory:
  OBS_DIR = \"${OBS_DIR}\""
fi
#
#-----------------------------------------------------------------------
#
# Export variables needed in the common METplus configuration file (at
# ${METPLUS_CONF}/common.conf).
#
#-----------------------------------------------------------------------
#
export METPLUS_CONF
export LOGDIR
#
#-----------------------------------------------------------------------
#
# Do not run METplus if there isn't at least one valid forecast hour for
# which to run it.
#
#-----------------------------------------------------------------------
#
if [ -z "${LEADHR_LIST}" ]; then
  print_err_msg_exit "\
The list of forecast hours for which to run METplus is empty:
  LEADHR_LIST = [${LEADHR_LIST}]"
fi
#
#-----------------------------------------------------------------------
#
# Set the names of the template METplus configuration file, the METplus
# configuration file generated from this template, and the METplus log
# file.
#
#-----------------------------------------------------------------------
#
# First, set the base file names.
#
metplus_config_tmpl_fn="${MetplusToolName}_obs"
#
# Set the name of the final conf file that will be used for this task. We
# append the OBTYPE and cycle date to ensure that different tasks in the same
# workflow won't overwrite each others' conf files.
#
metplus_config_fn="${metplus_config_tmpl_fn}_${OBTYPE}_${CDATE}"
metplus_log_fn="${metplus_config_fn}"
#
# Add prefixes and suffixes (extensions) to the base file names.
#
metplus_config_tmpl_fn="${metplus_config_tmpl_fn}.conf"
metplus_config_fn="${metplus_config_fn}.conf"
metplus_log_fn="metplus.log.${metplus_log_fn}"
#
#-----------------------------------------------------------------------
#
# Generate the METplus configuration file from its jinja template.
#
#-----------------------------------------------------------------------
#
# Set the full paths to the jinja template METplus configuration file
# (which already exists) and the METplus configuration file that will be
# generated from it.
#
metplus_config_tmpl_fp="${METPLUS_CONF}/${metplus_config_tmpl_fn}"
metplus_config_fp="${OUTPUT_DIR}/${metplus_config_fn}"
#
# Define variables that appear in the jinja template.
#
settings="\
#
# MET/METplus information.
#
  'metplus_tool_name': '${metplus_tool_name}'
  'MetplusToolName': '${MetplusToolName}'
  'METPLUS_TOOL_NAME': '${METPLUS_TOOL_NAME}'
  'metplus_verbosity_level': '${METPLUS_VERBOSITY_LEVEL}'
#
# Date and forecast hour information.
#
  'cdate': '$CDATE'
  'fhr_list': '${LEADHR_LIST}'
#
# Input and output directory/file information.
#
  'metplus_config_fn': '${metplus_config_fn:-}'
  'metplus_log_fn': '${metplus_log_fn:-}'
  'obs_input_dir': '${OBS_INPUT_DIR:-}'
  'obs_input_fn_template': '${OBS_INPUT_FN_TEMPLATE:-}'
  'fcst_input_dir': '${FCST_INPUT_DIR:-}'
  'fcst_input_fn_template': '${FCST_INPUT_FN_TEMPLATE:-}'
  'output_base': '${OUTPUT_BASE}'
  'output_dir': '${OUTPUT_DIR}'
  'output_fn_template': '${OUTPUT_FN_TEMPLATE:-}'
  'staging_dir': '${STAGING_DIR}'
  'vx_fcst_model_name': '${VX_FCST_MODEL_NAME}'
  'input_format': '${ASCII2NC_INPUT_FORMAT}'
#
# Ensemble and member-specific information.
#
  'num_ens_members': '${NUM_ENS_MEMBERS}'
  'ensmem_name': '${ensmem_name:-}'
  'time_lag': '${time_lag:-}'
#
# Field information.
#
  'obtype': '${OBTYPE}'
"

# Render the template to create a METplus configuration file
tmpfile=$( $READLINK -f "$(mktemp ./met_plus_settings.XXXXXX.yaml)")
printf "%s" "$settings" > "$tmpfile"
uw template render \
  -i ${metplus_config_tmpl_fp} \
  -o ${metplus_config_fp} \
  --verbose \
  --values-file "${tmpfile}" \
  --search-path "/" 

err=$?
rm $tmpfile
if [ $err -ne 0 ]; then
  message_txt="Error rendering template for METplus config.
     Contents of input are:
$settings"
  if [ "${RUN_ENVIR}" = "nco" ] && [ "${MACHINE}" = "WCOSS2" ]; then
    err_exit "${message_txt}"
  else
    print_err_msg_exit "${message_txt}"
  fi
fi
#
#-----------------------------------------------------------------------
#
# Call METplus.
#
#-----------------------------------------------------------------------
#
print_info_msg "$VERBOSE" "
Calling METplus to run MET's ${metplus_tool_name} tool on observations of type: ${OBTYPE}"
${METPLUS_PATH}/ush/run_metplus.py \
  -c ${METPLUS_CONF}/common.conf \
  -c ${metplus_config_fp} || \
print_err_msg_exit "
Call to METplus failed with return code: $?
METplus configuration file used is:
  metplus_config_fp = \"${metplus_config_fp}\""
#
#-----------------------------------------------------------------------
#
# Create flag file that indicates completion of task.  This is needed by
# the workflow.
#
#-----------------------------------------------------------------------
#
mkdir -p ${WFLOW_FLAG_FILES_DIR}
touch "${WFLOW_FLAG_FILES_DIR}/${OBTYPE}_nc_obs_${PDY}_ready.txt"
#
#-----------------------------------------------------------------------
#
# Print message indicating successful completion of script.
#
#-----------------------------------------------------------------------
#
print_info_msg "
========================================================================
METplus ${MetplusToolName} tool completed successfully.

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
