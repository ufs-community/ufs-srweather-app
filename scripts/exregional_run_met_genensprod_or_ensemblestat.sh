#!/usr/bin/env bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. $USHdir/source_util_funcs.sh
for sect in user nco platform workflow nco global verification cpl_aqm_parm \
  constants fixed_files grid_params \
  task_run_post ; do
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
. $USHdir/set_vx_params.sh
. $USHdir/set_leadhrs.sh
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
# For debugging purposes, print out values of arguments passed to this
# script.  Note that these will be printed out only if VERBOSE is set to
# TRUE.
#
#-----------------------------------------------------------------------
#
print_input_args "valid_args"
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

This is the ex-script for the task that runs the METplus ${MetplusToolName}
tool either to generate ensemble products without performing verification
(if running the GenEnsProd tool) or to perform ensemble-based verification
(if running the EnsembleStat tool).
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
  outvarname_fieldname_in_obs_input="FIELDNAME_IN_OBS_INPUT" \
  outvarname_fieldname_in_fcst_input="FIELDNAME_IN_FCST_INPUT" \
  outvarname_fieldname_in_MET_output="FIELDNAME_IN_MET_OUTPUT" \
  outvarname_fieldname_in_MET_filedir_names="FIELDNAME_IN_MET_FILEDIR_NAMES"
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
if [ "${RUN_ENVIR}" = "nco" ]; then
  slash_cdate_or_null=""
else
  slash_cdate_or_null="/${CDATE}"
fi

if [ "${grid_or_point}" = "grid" ]; then

  case "${FIELDNAME_IN_MET_FILEDIR_NAMES}" in
    "APCP"*)
      OBS_INPUT_DIR="${vx_output_basedir}${slash_cdate_or_null}/obs/metprd/PcpCombine_obs"
      OBS_INPUT_FN_TEMPLATE="${OBS_CCPA_APCP_FN_TEMPLATE_PCPCOMBINE_OUTPUT}"
      FCST_INPUT_DIR="${vx_output_basedir}"
      ;;
    "ASNOW"*)
      OBS_INPUT_DIR="${vx_output_basedir}${slash_cdate_or_null}/obs/metprd/PcpCombine_obs"
      OBS_INPUT_FN_TEMPLATE="${OBS_NOHRSC_ASNOW_FN_TEMPLATE_PCPCOMBINE_OUTPUT}"
      FCST_INPUT_DIR="${vx_output_basedir}"
      ;;
    "REFC")
      OBS_INPUT_DIR="${OBS_DIR}"
      OBS_INPUT_FN_TEMPLATE="${OBS_MRMS_REFC_FN_TEMPLATE}"
      FCST_INPUT_DIR="${vx_fcst_input_basedir}"
      ;;
    "RETOP")
      OBS_INPUT_DIR="${OBS_DIR}"
      OBS_INPUT_FN_TEMPLATE="${OBS_MRMS_RETOP_FN_TEMPLATE}"
      FCST_INPUT_DIR="${vx_fcst_input_basedir}"
      ;;
  esac

elif [ "${grid_or_point}" = "point" ]; then

  OBS_INPUT_DIR="${vx_output_basedir}/metprd/Pb2nc_obs"
  OBS_INPUT_FN_TEMPLATE="${OBS_NDAS_ADPSFCandADPUPA_FN_TEMPLATE_PB2NC_OUTPUT}"
  FCST_INPUT_DIR="${vx_fcst_input_basedir}"

fi
OBS_INPUT_FN_TEMPLATE=$( eval echo ${OBS_INPUT_FN_TEMPLATE} )
#
# Construct variable that contains a METplus template of the paths to
# the files that the PcpCombine tool has generated (in previous workflow
# tasks).  This will be exported to the environment and read by the
# METplus configuration files.
#
FCST_INPUT_FN_TEMPLATE=""
for (( i=0; i<${NUM_ENS_MEMBERS}; i++ )); do

  ensmem_indx=$(printf "%0${VX_NDIGITS_ENSMEM_NAMES}d" "$((i+1))")
  ensmem_name="mem${ensmem_indx}"

  if [ "${RUN_ENVIR}" = "nco" ]; then
    cdate_ensmem_subdir_or_null=""
  else
    cdate_ensmem_subdir_or_null="${CDATE}/${ensmem_name}"
  fi

  time_lag=$( bc -l <<< "${ENS_TIME_LAG_HRS[$i]}*${SECS_PER_HOUR}" )

  if [ "${VAR}" = "APCP" ] || [ "${VAR}" = "ASNOW" ]; then
    template="${cdate_ensmem_subdir_or_null:+${cdate_ensmem_subdir_or_null}/}metprd/PcpCombine_fcst/${FCST_FN_TEMPLATE_PCPCOMBINE_OUTPUT}"
  else
    template="${FCST_SUBDIR_TEMPLATE}/${FCST_FN_TEMPLATE}"
  fi

  if [ -z "${FCST_INPUT_FN_TEMPLATE}" ]; then
    FCST_INPUT_FN_TEMPLATE="$(eval echo ${template})"
  else
    FCST_INPUT_FN_TEMPLATE="${FCST_INPUT_FN_TEMPLATE}, $(eval echo ${template})"
  fi

done

OUTPUT_BASE="${vx_output_basedir}${slash_cdate_or_null}"
OUTPUT_DIR="${OUTPUT_BASE}/metprd/${MetplusToolName}"
STAGING_DIR="${OUTPUT_BASE}/stage/${FIELDNAME_IN_MET_FILEDIR_NAMES}"
#
#-----------------------------------------------------------------------
#
# Generate the list of forecast hours for which to run the specified
# METplus tool.
#
# If running the GenEnsProd tool, we set this to the list of forecast 
# output times without filtering for the existence of observation files
# corresponding to those times.  This is because GenEnsProd operates
# only on forecasts; it does not need observations.
#
# On the other hand, if running the EnsembleStat tool, we set the list of
# forecast hours to a set of times that takes into consideration whether
# or not observations exist.  We do this by starting with the full list
# of forecast times for which there is forecast output and then removing
# from that list any times for which there is no corresponding observations.
#
#-----------------------------------------------------------------------
#
case "$OBTYPE" in
  "CCPA"|"NOHRSC")
    vx_intvl="$((10#${ACCUM_HH}))"
    vx_hr_start="${vx_intvl}"
    ;;
  *)
    vx_intvl="$((${VX_FCST_OUTPUT_INTVL_HRS}))"
    vx_hr_start="0"
    ;;
esac
vx_hr_end="${FCST_LEN_HRS}"

if [ "${MetplusToolName}" = "GenEnsProd" ]; then
  set_leadhrs_no_missing \
    lhr_min="${vx_hr_start}" \
    lhr_max="${vx_hr_end}" \
    lhr_intvl="${vx_intvl}" \
    outvarname_lhrs_list_no_missing="VX_LEADHR_LIST"
elif [ "${MetplusToolName}" = "EnsembleStat" ]; then
  set_leadhrs \
    yyyymmddhh_init="${CDATE}" \
    lhr_min="${vx_hr_start}" \
    lhr_max="${vx_hr_end}" \
    lhr_intvl="${vx_intvl}" \
    base_dir="${OBS_INPUT_DIR}" \
    fn_template="${OBS_INPUT_FN_TEMPLATE}" \
    num_missing_files_max="${NUM_MISSING_OBS_FILES_MAX}" \
    outvarname_lhrs_list="VX_LEADHR_LIST"
fi
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
# Do not run METplus if there isn't at least one lead hour for which to
# run it.
#
#-----------------------------------------------------------------------
#
if [ -z "${VX_LEADHR_LIST}" ]; then
  print_err_msg_exit "\
The list of lead hours for which to run METplus is empty:
  VX_LEADHR_LIST = [${VX_LEADHR_LIST}]"
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
metplus_config_tmpl_bn="${MetplusToolName}"
metplus_config_bn="${MetplusToolName}_${FIELDNAME_IN_MET_FILEDIR_NAMES}"
metplus_log_bn="${metplus_config_bn}"
#
# Add prefixes and suffixes (extensions) to the base file names.
#
metplus_config_tmpl_fn="${metplus_config_tmpl_bn}.conf"
metplus_config_fn="${metplus_config_bn}.conf"
metplus_log_fn="metplus.log.${metplus_log_bn}"
#
#-----------------------------------------------------------------------
#
# Load the yaml-like file containing the configuration for ensemble
# verification.
#
#-----------------------------------------------------------------------
#
vx_config_fp="${METPLUS_CONF}/${VX_CONFIG_ENS_FN}"
vx_config_dict=$(<"${vx_config_fp}")
# Indent each line of vx_config_dict so that it is aligned properly when
# included in the yaml-formatted variable "settings" below.
vx_config_dict=$( printf "%s\n" "${vx_config_dict}" | sed 's/^/    /' )
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
'vx_leadhr_list': '${VX_LEADHR_LIST}'
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
'metplus_templates_dir': '${METPLUS_CONF:-}'
'input_field_group': '${VAR:-}'
'input_level_fcst': '${FCST_LEVEL:-}'
'input_thresh_fcst': '${FCST_THRESH:-}'
#
# Verification configuration dictionary.
#
'vx_config_dict':
${vx_config_dict:-}
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
Calling METplus to run MET's ${metplus_tool_name} tool for field(s): ${FIELDNAME_IN_MET_FILEDIR_NAMES}"
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
