#!/bin/bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. $USHdir/source_util_funcs.sh
source_config_for_task "task_run_met_pcpcombine|task_run_post" ${GLOBAL_VAR_DEFNS_FP}
#
#-----------------------------------------------------------------------
#
# Source files defining auxiliary functions for verification.
#
#-----------------------------------------------------------------------
#
. $USHdir/get_met_metplus_tool_name.sh
. $USHdir/set_vx_params.sh
. $USHdir/set_vx_fhr_list.sh
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
# needed from the global variable MET_TOOL.
#
#-----------------------------------------------------------------------
#
get_met_metplus_tool_name \
  generic_tool_name="${MET_TOOL}" \
  outvarname_met_tool_name="met_tool_name" \
  outvarname_metplus_tool_name="metplus_tool_name"
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

This is the ex-script for the task that runs the METplus ${metplus_tool_name}
tool to combine hourly accumulated precipitation (APCP) data to generate
files containing multi-hour accumulated precipitation (e.g. 3-hour, 6-
hour, 24-hour).  The input files can come from either observations or
a forecast.
========================================================================"
#
#-----------------------------------------------------------------------
#
# Get the cycle date and time in YYYYMMDDHH format.
#
#-----------------------------------------------------------------------
#
CDATE="${PDY}${cyc}"
#
#-----------------------------------------------------------------------
#
# Set various verification parameters associated with the field to be
# verified.  Not all of these are necessarily used later below but are
# set here for consistency with other verification ex-scripts.
#
#-----------------------------------------------------------------------
#
FIELDNAME_IN_OBS_INPUT=""
FIELDNAME_IN_FCST_INPUT=""
FIELDNAME_IN_MET_OUTPUT=""
FIELDNAME_IN_MET_FILEDIR_NAMES=""

set_vx_params \
  obtype="${OBTYPE}" \
  field="$VAR" \
  accum_hh="${ACCUM_HH}" \
  outvarname_grid_or_point="grid_or_point" \
  outvarname_field_is_APCPgt01h="field_is_APCPgt01h" \
  outvarname_fieldname_in_obs_input="FIELDNAME_IN_OBS_INPUT" \
  outvarname_fieldname_in_fcst_input="FIELDNAME_IN_FCST_INPUT" \
  outvarname_fieldname_in_MET_output="FIELDNAME_IN_MET_OUTPUT" \
  outvarname_fieldname_in_MET_filedir_names="FIELDNAME_IN_MET_FILEDIR_NAMES"
#
#-----------------------------------------------------------------------
#
# If performing forecast ensemble verification, get the time lag (if any)
# of the current ensemble forecast member.  The time lag is the duration
# (in units of seconds) by which the current forecast member was initialized
# before the current cycle date and time (with the latter specified by
# CDATE).  For example, a time lag of 3600 means that the current member
# was initialized 1 hour before the current CDATE, while a time lag of 0
# means the current member was initialized on CDATE.
#
# Note that if we're not running ensemble verification (i.e. if we're
# running verification for a single deterministic forecast), the time
# lag gets set to 0.
#
#-----------------------------------------------------------------------
#
time_lag="0"
if [ "${obs_or_fcst}" = "fcst" ]; then
  i="0"
  if [ "${DO_ENSEMBLE}" = "TRUE" ]; then
    i=$( bc -l <<< "${ENSMEM_INDX}-1" )
  fi
  time_lag=$( bc -l <<< "${ENS_TIME_LAG_HRS[$i]}*${SECS_PER_HOUR}" )
fi
#
#-----------------------------------------------------------------------
#
# Set paths and file templates for input to and output from the MET/
# METplus tool to be run as well as other file/directory parameters.
#
#-----------------------------------------------------------------------
#
vx_fcst_input_basedir=$( eval echo "${VX_FCST_INPUT_BASEDIR}" )
vx_output_basedir=$( eval echo "${VX_OUTPUT_BASEDIR}" )
ensmem_indx=$(printf "%0${VX_NDIGITS_ENSMEM_NAMES}d" "${ENSMEM_INDX}")
ensmem_name="mem${ensmem_indx}"
if [ "${RUN_ENVIR}" = "nco" ]; then
  slash_cdate_or_null=""
  slash_ensmem_subdir_or_null=""
else
  slash_cdate_or_null="/${CDATE}"
#
# Since other aspects of a deterministic run use the "mem000" string (e.g.
# in rocoto workflow task names, in log file names), it seems reasonable
# that a deterministic run create a "mem000" subdirectory under the $CDATE
# directory.  But since that is currently not the case in in the run_fcst
# task, we need the following if-statement.  If and when such a modification
# is made for the run_fcst task, we would remove this if-statement and
# simply set 
#   slash_ensmem_subdir_or_null="/${ensmem_name}"
# or, better, just remove this variale and code "/${ensmem_name}" where
# slash_ensmem_subdir_or_null currently appears below.
#
  if [ "${DO_ENSEMBLE}" = "TRUE" ]; then
    slash_ensmem_subdir_or_null="/${ensmem_name}"
  else
    slash_ensmem_subdir_or_null=""
  fi
fi

OBS_INPUT_DIR=""
OBS_INPUT_FN_TEMPLATE=""
FCST_INPUT_DIR=""
FCST_INPUT_FN_TEMPLATE=""

if [ "${obs_or_fcst}" = "obs" ]; then

  OBS_INPUT_DIR="${OBS_DIR}"
  OBS_INPUT_FN_TEMPLATE=$( eval echo ${OBS_CCPA_APCP01h_FN_TEMPLATE} )

  OUTPUT_BASE="${vx_output_basedir}"
  OUTPUT_DIR="${OUTPUT_BASE}/metprd/${metplus_tool_name}_obs"
  OUTPUT_FN_TEMPLATE=$( eval echo ${OBS_CCPA_APCPgt01h_FN_TEMPLATE} )
  STAGING_DIR="${OUTPUT_BASE}/stage/${FIELDNAME_IN_MET_FILEDIR_NAMES}"

elif [ "${obs_or_fcst}" = "fcst" ]; then

  FCST_INPUT_DIR="${vx_fcst_input_basedir}"
  FCST_INPUT_FN_TEMPLATE=$( eval echo ${FCST_SUBDIR_TEMPLATE:+${FCST_SUBDIR_TEMPLATE}/}${FCST_FN_TEMPLATE} )

  OUTPUT_BASE="${vx_output_basedir}${slash_cdate_or_null}/${slash_ensmem_subdir_or_null}"
  OUTPUT_DIR="${OUTPUT_BASE}/metprd/${metplus_tool_name}_fcst"
  OUTPUT_FN_TEMPLATE=$( eval echo ${FCST_FN_METPROC_TEMPLATE} )
  STAGING_DIR="${OUTPUT_BASE}/stage/${FIELDNAME_IN_MET_FILEDIR_NAMES}"

fi
#
#-----------------------------------------------------------------------
#
# Set the array of forecast hours for which to run the MET/METplus tool.
#
#-----------------------------------------------------------------------
#
if [ "${obs_or_fcst}" = "obs" ]; then
  base_dir="${OBS_INPUT_DIR}"
  fn_template="${OBS_INPUT_FN_TEMPLATE}"
  num_missing_files_max="${NUM_MISSING_OBS_FILES_MAX}"
elif [ "${obs_or_fcst}" = "fcst" ]; then
  base_dir="${FCST_INPUT_DIR}"
  fn_template="${FCST_INPUT_FN_TEMPLATE}"
  num_missing_files_max="${NUM_MISSING_FCST_FILES_MAX}"
fi

set_vx_fhr_list \
  cdate="${CDATE}" \
  fcst_len_hrs="${FCST_LEN_HRS}" \
  field="$VAR" \
  accum_hh="${ACCUM_HH}" \
  base_dir="${base_dir}" \
  fn_template="${fn_template}" \
  check_accum_contrib_files="TRUE" \
  num_missing_files_max="${num_missing_files_max}" \
  outvarname_fhr_list="FHR_LIST"
#
#-----------------------------------------------------------------------
#
# Make sure the MET/METplus output directory(ies) exists.
#
#-----------------------------------------------------------------------
#
mkdir_vrfy -p "${OUTPUT_DIR}"
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
export MET_INSTALL_DIR
export METPLUS_PATH
export MET_BIN_EXEC
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
if [ -z "${FHR_LIST}" ]; then
  print_err_msg_exit "\
The list of forecast hours for which to run METplus is empty:
  FHR_LIST = [${FHR_LIST}]"
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
metplus_config_tmpl_fn="${metplus_tool_name}_${obs_or_fcst}"
metplus_config_fn="${metplus_config_tmpl_fn}_${FIELDNAME_IN_MET_FILEDIR_NAMES}${ENSMEM_INDX:+_${ensmem_name}}"
metplus_log_fn="${metplus_config_fn}_$CDATE"
#
# If operating on observation files, append the cycle date to the name
# of the configuration file because in this case, the output files from
# METplus are not placed under cycle directories (so another method is
# necessary to associate the configuration file with the cycle for which
# it is used).
#
if [ "${obs_or_fcst}" = "obs" ]; then
  metplus_config_fn="${metplus_log_fn}"
fi
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
# Date and forecast hour information.
#
  'cdate': '$CDATE'
  'fhr_list': '${FHR_LIST}'
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
#
# Ensemble and member-specific information.
#
  'num_ens_members': '${NUM_ENS_MEMBERS}'
  'ensmem_name': '${ensmem_name:-}'
  'time_lag': '${time_lag:-}'
#
# Field information.
#
  'fieldname_in_obs_input': '${FIELDNAME_IN_OBS_INPUT}'
  'fieldname_in_fcst_input': '${FIELDNAME_IN_FCST_INPUT}'
  'fieldname_in_met_output': '${FIELDNAME_IN_MET_OUTPUT}'
  'fieldname_in_met_filedir_names': '${FIELDNAME_IN_MET_FILEDIR_NAMES}'
  'obtype': '${OBTYPE}'
  'accum_hh': '${ACCUM_HH:-}'
  'accum_no_pad': '${ACCUM_NO_PAD:-}'
  'field_thresholds': '${FIELD_THRESHOLDS:-}'
"
# Store the settings in a temporary file
tmpfile=$( $READLINK -f "$(mktemp ./met_plus_settings.XXXXXX.yaml)")
cat > $tmpfile << EOF
$settings
EOF

#
# Call the python script to generate the METplus configuration file from
# the jinja template.
#
python3 $USHdir/python_utils/workflow-tools/scripts/templater.py \
  -c ${tmpfile} \
  -i ${metplus_config_tmpl_fp} \
  -o ${metplus_config_fp} || \
print_err_msg_exit "\
Call to workflow-tools templater.py to generate a METplus
configuration file from a jinja template failed.  Parameters passed
to this script are:
  Full path to template METplus configuration file:
    metplus_config_tmpl_fp = \"${metplus_config_tmpl_fp}\"
  Full path to output METplus configuration file:
    metplus_config_fp = \"${metplus_config_fp}\"
  Full path to configuration file:
    ${tmpfile}
"
rm $tmpfile
#
#-----------------------------------------------------------------------
#
# Call METplus.
#
#-----------------------------------------------------------------------
#
print_info_msg "$VERBOSE" "
Calling METplus to run MET's ${met_tool_name} tool for field(s): ${FIELDNAME_IN_MET_FILEDIR_NAMES}"
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
# Print message indicating successful completion of script.
#
#-----------------------------------------------------------------------
#
print_info_msg "
========================================================================
METplus ${metplus_tool_name} tool completed successfully.

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
