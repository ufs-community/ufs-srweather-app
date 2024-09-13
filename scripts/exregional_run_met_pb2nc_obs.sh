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
  constants fixed_files grid_params ; do
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

This is the ex-script for the task that runs the METplus tool ${MetplusToolName}
to convert NDAS prep buffer observation files to NetCDF format.
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
vx_output_basedir=$( eval echo "${VX_OUTPUT_BASEDIR}" )

OBS_INPUT_DIR="${OBS_DIR}"
OBS_INPUT_FN_TEMPLATE=$( eval echo ${OBS_NDAS_ADPSFCorADPUPA_FN_TEMPLATE} )

OUTPUT_BASE="${vx_output_basedir}"
OUTPUT_DIR="${OUTPUT_BASE}/metprd/${MetplusToolName}_obs"
OUTPUT_FN_TEMPLATE=$( eval echo ${OBS_NDAS_ADPSFCorADPUPA_FN_TEMPLATE_PB2NC_OUTPUT} )
STAGING_DIR="${OUTPUT_BASE}/stage/${MetplusToolName}_obs"
#
#-----------------------------------------------------------------------
#
# Set the array of forecast hours for which to run the MET/METplus tool.
#
#-----------------------------------------------------------------------
#
set_vx_fhr_list \
  cdate="${CDATE}" \
  fcst_len_hrs="${FCST_LEN_HRS}" \
  field="$VAR" \
  accum_hh="${ACCUM_HH}" \
  base_dir="${OBS_INPUT_DIR}" \
  fn_template="${OBS_INPUT_FN_TEMPLATE}" \
  check_accum_contrib_files="FALSE" \
  num_missing_files_max="${NUM_MISSING_OBS_FILES_MAX}" \
  outvarname_fhr_list="FHR_LIST"
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
metplus_config_tmpl_fn="${MetplusToolName}_obs"
#
# Note that we append the cycle date to the name of the configuration
# file because we are considering only observations when using Pb2NC, so
# the output files from METplus are not placed under cycle directories.
# Thus, another method is necessary to associate the configuration file
# with the cycle for which it is used.
#
# Note also that if considering an ensemble forecast, we include the
# ensemble member name to the config file name.  This is necessary in
# NCO mode (i.e. when RUN_ENVIR = "nco") because in that mode, the
# directory tree under which the configuration file is placed does not
# contain member information, so the file names must include it.  It is
# not necessary in community mode (i.e. when RUN_ENVIR = "community")
# because in that case, the directory structure does contain the member
# information, but we still include that info in the file name so that
# the behavior in the two modes is as similar as possible.
#
metplus_config_fn="${metplus_config_tmpl_fn}_${CDATE}"
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
