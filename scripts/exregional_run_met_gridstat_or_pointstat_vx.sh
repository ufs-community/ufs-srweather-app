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
  constants
  fixed_files
  task_run_post
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
. $USHdir/set_vx_params.sh
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
# Print message indicating entry into script.
#
#-----------------------------------------------------------------------
#
print_info_msg "
========================================================================
Entering script:  \"${scrfunc_fn}\"
In directory:     \"${scrfunc_dir}\"

This is the ex-script for the task that runs the METplus ${MetplusToolName}
tool to perform deterministic verification of the specified field group 
(FIELD_GROUP) for a single forecast.
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

# Note that ACCUM_HH will not be defined for the REFC, RETOP, SFC, and
# UPA field groups.
set_vx_params \
  obtype="${OBTYPE}" \
  field_group="${FIELD_GROUP}" \
  accum_hh="${ACCUM_HH:-}" \
  outvarname_grid_or_point="grid_or_point" \
  outvarname_fieldname_in_obs_input="FIELDNAME_IN_OBS_INPUT" \
  outvarname_fieldname_in_fcst_input="FIELDNAME_IN_FCST_INPUT" \
  outvarname_fieldname_in_MET_output="FIELDNAME_IN_MET_OUTPUT" \
  outvarname_fieldname_in_MET_filedir_names="FIELDNAME_IN_MET_FILEDIR_NAMES"
#
#-----------------------------------------------------------------------
#
# If performing ensemble verification, get the time lag (if any) of the
# current ensemble forecast member.  The time lag is the duration (in
# seconds) by which the current forecast member was initialized before
# the current cycle date and time (with the latter specified by CDATE).
# For example, a time lag of 3600 means that the current member was
# initialized 1 hour before the current CDATE, while a time lag of 0
# means the current member was initialized on CDATE.
#
# Note that if we're not running ensemble verification (i.e. if we're
# running verification for a single deterministic forecast), the time
# lag gets set to 0.
#
#-----------------------------------------------------------------------
#
i="0"
if [ $(boolify "${DO_ENSEMBLE}") = "TRUE" ]; then
  i=$( bc -l <<< "${ENSMEM_INDX}-1" )
fi
time_lag=$( bc -l <<< "${ENS_TIME_LAG_HRS[$i]}*${SECS_PER_HOUR}" )
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

ensmem_indx=$(printf "%0${VX_NDIGITS_ENSMEM_NAMES}d" $(( 10#${ENSMEM_INDX})))
ensmem_name="mem${ensmem_indx}"
if [ "${RUN_ENVIR}" = "nco" ]; then
  slash_cdate_or_null=""
  slash_ensmem_subdir_or_null=""
  slash_obs_or_null=""
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
  if [ $(boolify "${DO_ENSEMBLE}") = "TRUE" ]; then
    slash_ensmem_subdir_or_null="/${ensmem_name}"
    slash_obs_or_null="/obs"
  else
    slash_ensmem_subdir_or_null=""
    slash_obs_or_null=""
  fi
fi

if [ "${grid_or_point}" = "grid" ]; then

  case "${FIELDNAME_IN_MET_FILEDIR_NAMES}" in
    "APCP"*)
      OBS_INPUT_DIR="${vx_output_basedir}${slash_cdate_or_null}${slash_obs_or_null}/metprd/PcpCombine_obs"
      OBS_INPUT_FN_TEMPLATE="${OBS_CCPA_APCP_FN_TEMPLATE_PCPCOMBINE_OUTPUT}"
      FCST_INPUT_DIR="${vx_output_basedir}${slash_cdate_or_null}${slash_ensmem_subdir_or_null}/metprd/PcpCombine_fcst"
      FCST_INPUT_FN_TEMPLATE="${FCST_FN_TEMPLATE_PCPCOMBINE_OUTPUT}"
      ;;
    "ASNOW"*)
      OBS_INPUT_DIR="${vx_output_basedir}${slash_cdate_or_null}${slash_obs_or_null}/metprd/PcpCombine_obs"
      OBS_INPUT_FN_TEMPLATE="${OBS_NOHRSC_ASNOW_FN_TEMPLATE_PCPCOMBINE_OUTPUT}"
      FCST_INPUT_DIR="${vx_output_basedir}${slash_cdate_or_null}${slash_ensmem_subdir_or_null}/metprd/PcpCombine_fcst"
      FCST_INPUT_FN_TEMPLATE="${FCST_FN_TEMPLATE_PCPCOMBINE_OUTPUT}"
      ;;
    "REFC")
      OBS_INPUT_DIR="${OBS_DIR}"
      OBS_INPUT_FN_TEMPLATE="${OBS_MRMS_FN_TEMPLATES[1]}"
      FCST_INPUT_DIR="${vx_fcst_input_basedir}"
      FCST_INPUT_FN_TEMPLATE="${FCST_SUBDIR_TEMPLATE:+${FCST_SUBDIR_TEMPLATE}/}${FCST_FN_TEMPLATE}"
      ;;
    "RETOP")
      OBS_INPUT_DIR="${OBS_DIR}"
      OBS_INPUT_FN_TEMPLATE="${OBS_MRMS_FN_TEMPLATES[3]}"
      FCST_INPUT_DIR="${vx_fcst_input_basedir}"
      FCST_INPUT_FN_TEMPLATE="${FCST_SUBDIR_TEMPLATE:+${FCST_SUBDIR_TEMPLATE}/}${FCST_FN_TEMPLATE}"
      ;;
  esac

elif [ "${grid_or_point}" = "point" ]; then

  if [ "${OBTYPE}" = "NDAS" ]; then
    OBS_INPUT_DIR="${vx_output_basedir}/metprd/Pb2nc_obs"
    OBS_INPUT_FN_TEMPLATE="${OBS_NDAS_SFCandUPA_FN_TEMPLATE_PB2NC_OUTPUT}"
    FCST_INPUT_DIR="${vx_fcst_input_basedir}"
    FCST_INPUT_FN_TEMPLATE="${FCST_SUBDIR_TEMPLATE:+${FCST_SUBDIR_TEMPLATE}/}${FCST_FN_TEMPLATE}"
  elif [ "${OBTYPE}" = "AERONET" ]; then
    FIELDNAME_IN_MET_FILEDIR_NAMES="AERONET_AOD"
    OBS_INPUT_DIR="${vx_output_basedir}/metprd/Ascii2nc_obs"
    OBS_INPUT_FN_TEMPLATE="${OBS_AERONET_FN_TEMPLATE_ASCII2NC_OUTPUT}"
    FCST_INPUT_DIR="${vx_fcst_input_basedir}"
    FCST_INPUT_FN_TEMPLATE="${FCST_SUBDIR_TEMPLATE:+${FCST_SUBDIR_TEMPLATE}/}${FCST_FN_TEMPLATE}"
  elif [ "${OBTYPE}" = "AIRNOW" ]; then
    # It's very annoying that the names for specifying Airnow format are slightly different
    # for ASCII2NC and Pointstat. This logic deals with that.
    if [[ "${AIRNOW_INPUT_FORMAT}" == "airnowhourly" ]]; then
      FIELDNAME_IN_MET_FILEDIR_NAMES="AIRNOW_HOURLY"
    elif [[ "${AIRNOW_INPUT_FORMAT}" == "airnowhourlyaqobs" ]]; then
      FIELDNAME_IN_MET_FILEDIR_NAMES="AIRNOW_HOURLY_AQOBS"
    else
      print_err_msg_exit "Invalid AIRNOW_INPUT_FORMAT: ${AIRNOW_INPUT_FORMAT}"
    fi
    ACCUM_HH='01'
    OBS_INPUT_DIR="${vx_output_basedir}/metprd/Ascii2nc_obs"
    OBS_INPUT_FN_TEMPLATE="${OBS_AIRNOW_FN_TEMPLATE_ASCII2NC_OUTPUT}"
    # The forecast input for Airnow obs is the output from PcP combine
    FCST_INPUT_DIR="${vx_output_basedir}${slash_cdate_or_null}${slash_ensmem_subdir_or_null}/metprd/PcpCombine_fcst"
    FCST_INPUT_FN_TEMPLATE=$( eval echo ${FCST_FN_TEMPLATE_PCPCOMBINE_OUTPUT} )
  else
    print_err_msg_exit "Invalid OBTYPE for PointStat: ${OBTYPE}"
  fi

fi
OBS_INPUT_FN_TEMPLATE=$( eval echo ${OBS_INPUT_FN_TEMPLATE} )
FCST_INPUT_FN_TEMPLATE=$( eval echo ${FCST_INPUT_FN_TEMPLATE} )

OUTPUT_BASE="${vx_output_basedir}${slash_cdate_or_null}${slash_ensmem_subdir_or_null}"
OUTPUT_DIR="${OUTPUT_BASE}/metprd/${MetplusToolName}"
STAGING_DIR="${OUTPUT_BASE}/stage/${FIELDNAME_IN_MET_FILEDIR_NAMES}"
#
#-----------------------------------------------------------------------
#
# Set the lead hours for which to run the MET/METplus tool.  This is done
# by starting with the full list of lead hours for which we expect to
# find forecast output and then removing from that list any hours for
# which there is no corresponding observation data.
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

VX_LEADHR_LIST=$( python3 $USHdir/set_leadhrs.py \
  --date_init="${CDATE}" \
  --lhr_min="${vx_hr_start}" \
  --lhr_max="${vx_hr_end}" \
  --lhr_intvl="${vx_intvl}" \
  --base_dir="${OBS_INPUT_DIR}" \
  --fn_template="${OBS_INPUT_FN_TEMPLATE}" \
  --num_missing_files_max="${NUM_MISSING_OBS_FILES_MAX}" \
  --time_lag="${time_lag%.*}") || \
  print_err_msg_exit "Call to set_leadhrs.py failed with return code: $?"
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
metplus_config_tmpl_bn="GridStat_or_PointStat"
metplus_config_bn="${MetplusToolName}_${FIELDNAME_IN_MET_FILEDIR_NAMES}_${FIELD_GROUP}_${ensmem_name}"
metplus_log_bn="${metplus_config_bn}_$CDATE"
#
# Add prefixes and suffixes (extensions) to the base file names.
#
metplus_config_tmpl_fn="${metplus_config_tmpl_bn}.conf"
metplus_config_fn="${metplus_config_bn}.conf"
metplus_log_fn="metplus.log.${metplus_log_bn}"
#
#-----------------------------------------------------------------------
#
# Load the yaml-like file containing the configuration for deterministic
# verification.
#
#-----------------------------------------------------------------------
#
vx_config_fp="${METPLUS_CONF}/${VX_CONFIG_DET_FN}"
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
'input_field_group': '${FIELD_GROUP:-}'
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
# Ugly hack to deal with different obs variable name (PM25 -->PM2.5) for
# data retrieved from AWS
if [[ "${AIRNOW_INPUT_FORMAT}" == "airnowhourly" ]]; then
  sed -i -e 's/OBS_VAR1_NAME = PM25/OBS_VAR1_NAME = PM2.5/g' ${metplus_config_fp}
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
