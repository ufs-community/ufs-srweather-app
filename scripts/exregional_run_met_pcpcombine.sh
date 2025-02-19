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
  field_group="${FIELD_GROUP}" \
  accum_hh="${ACCUM_HH}" \
  outvarname_grid_or_point="grid_or_point" \
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
if [ "${FCST_OR_OBS}" = "FCST" ]; then
  i="0"
  if [ $(boolify "${DO_ENSEMBLE}") = "TRUE" ]; then
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
if [ "${FCST_OR_OBS}" = "FCST" ]; then
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
    else
      slash_ensmem_subdir_or_null=""
    fi
  fi
elif [ "${FCST_OR_OBS}" = "OBS" ]; then
  slash_cdate_or_null="/${CDATE}"
  if [ $(boolify "${DO_ENSEMBLE}") = "TRUE" ]; then
    slash_obs_or_null="/obs"
  else
    slash_obs_or_null=""
  fi
fi

OBS_INPUT_DIR=""
OBS_INPUT_FN_TEMPLATE=""
FCST_INPUT_DIR=""
FCST_INPUT_FN_TEMPLATE=""
PCP_COMBINE_METHOD="ADD"
PCP_COMBINE_COMMAND=""
if [ "${FCST_OR_OBS}" = "FCST" ]; then

  FCST_INPUT_DIR="${vx_fcst_input_basedir}"
  FCST_INPUT_FN_TEMPLATE=$( eval echo ${FCST_SUBDIR_TEMPLATE:+${FCST_SUBDIR_TEMPLATE}/}${FCST_FN_TEMPLATE} )

  OUTPUT_BASE="${vx_output_basedir}${slash_cdate_or_null}${slash_ensmem_subdir_or_null}"
  OUTPUT_DIR="${OUTPUT_BASE}/metprd/${MetplusToolName}_fcst"
  OUTPUT_FN_TEMPLATE=$( eval echo ${FCST_FN_TEMPLATE_PCPCOMBINE_OUTPUT} )
  STAGING_DIR="${OUTPUT_BASE}/stage/${FIELDNAME_IN_MET_FILEDIR_NAMES}"
  if [ "${OBTYPE}" = "AIRNOW" ]; then
    PCP_COMBINE_METHOD="USER_DEFINED"

    if [ "${FIELD_GROUP}" = "PM25" ]; then
    # Need to combine two fields (different PM types) and convert units from forecast files to create PM25 equivalent to obs
      PCP_COMBINE_COMMAND="-add {FCST_PCP_COMBINE_INPUT_DIR}/{FCST_PCP_COMBINE_INPUT_TEMPLATE} 'name=\"MASSDEN\"; level=\"Z8\"; GRIB2_aerosol_type=62010; convert(x)=x*1e9;' {FCST_PCP_COMBINE_INPUT_DIR}/{FCST_PCP_COMBINE_INPUT_TEMPLATE} 'name=\"MASSDEN\"; level=\"Z8\"; GRIB2_aerosol_type=62001; GRIB2_aerosol_interval_type=0; convert(x)=x*1e9;'"
    elif [ "${FIELD_GROUP}" = "PM10" ]; then
    # for PM10, command is just a passthrough
      PCP_COMBINE_COMMAND="-add {FCST_PCP_COMBINE_INPUT_DIR}/{FCST_PCP_COMBINE_INPUT_TEMPLATE} -field 'name=\"MASSDEN\"; level=\"Z8\"; GRIB2_aerosol_type=62001; GRIB2_aerosol_interval_type=2; convert(x)=x*1e9;'"
    fi
  fi
elif [ "${FCST_OR_OBS}" = "OBS" ]; then

  OBS_INPUT_DIR="${OBS_DIR}"
  fn_template=$(eval echo \${OBS_${OBTYPE}_FN_TEMPLATES[1]})
  OBS_INPUT_FN_TEMPLATE=$( eval echo ${fn_template} )

  OUTPUT_BASE="${vx_output_basedir}${slash_cdate_or_null}${slash_obs_or_null}"
  OUTPUT_DIR="${OUTPUT_BASE}/metprd/${MetplusToolName}_obs"
  fn_template=$(eval echo \${OBS_${OBTYPE}_${FIELD_GROUP}_FN_TEMPLATE_PCPCOMBINE_OUTPUT})
  OUTPUT_FN_TEMPLATE=$( eval echo ${fn_template} )
  STAGING_DIR="${OUTPUT_BASE}/stage/${FIELDNAME_IN_MET_FILEDIR_NAMES}"

fi
#
#-----------------------------------------------------------------------
#
# Set the array of lead hours for which to run the MET/METplus tool.
#
#-----------------------------------------------------------------------
#
vx_intvl="$((10#${ACCUM_HH}))"
#Airnow obs use PCP_Combine simply to combine two fields, so run for every hour
if [ "${OBTYPE}" = "AIRNOW" ]; then
  lhr_min=0
else
  lhr_min=${vx_intvl}
fi
VX_LEADHR_LIST=$( python3 $USHdir/set_leadhrs.py \
  --lhr_min="${lhr_min}" \
  --lhr_max="${FCST_LEN_HRS}" \
  --lhr_intvl="${vx_intvl}" \
  --skip_check_files ) || \
  print_err_msg_exit "Call to set_leadhrs.py failed with return code: $?"
#
#-----------------------------------------------------------------------
#
# Check for the presence of files (either from observations or forecasts) 
# needed to create required accumulation given by ACCUM_HH.
#
#-----------------------------------------------------------------------
#
if [ "${FCST_OR_OBS}" = "FCST" ]; then
  base_dir="${FCST_INPUT_DIR}"
  fn_template="${FCST_INPUT_FN_TEMPLATE}"
  subintvl="${VX_FCST_OUTPUT_INTVL_HRS}"
elif [ "${FCST_OR_OBS}" = "OBS" ]; then
  base_dir="${OBS_INPUT_DIR}"
  fn_template="${OBS_INPUT_FN_TEMPLATE}"
  subintvl="${OBS_AVAIL_INTVL_HRS}"
fi
num_missing_files_max="0"
input_accum_hh=$(printf "%02d" ${subintvl})
#
# Convert the list of hours at which the PcpCombine tool will be run to
# an array.  This represents the hours at which each accumulation period
# ends.  Then use it to check the presence of all files requied to build
# the required accumulations from the sub-accumulations.
#
subintvl_end_hrs=($( echo ${VX_LEADHR_LIST} | $SED "s/,//g" ))
for hr_end in ${subintvl_end_hrs[@]}; do
  hr_start=$((hr_end - vx_intvl + subintvl))
  print_info_msg "
Checking for the presence of files that will contribute to the ${vx_intvl}-hour
accumulation ending at lead hour ${hr_end} (relative to ${CDATE})...
"
  python3 $USHdir/set_leadhrs.py \
    --date_init="${CDATE}" \
    --lhr_min="${hr_start}" \
    --lhr_max="${hr_end}" \
    --lhr_intvl="${subintvl}" \
    --base_dir="${base_dir}" \
    --fn_template="${fn_template}" \
    --num_missing_files_max="${num_missing_files_max}" \
    --time_lag="${time_lag%.*}" || \
    print_err_msg_exit "Call to set_leadhrs.py failed with return code: $?"
done

print_info_msg "
${MetplusToolName} will be run for the following lead hours (relative to ${CDATE}):
  VX_LEADHR_LIST = ${VX_LEADHR_LIST}
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
metplus_config_tmpl_fn="${MetplusToolName}"
if [ "${FCST_OR_OBS}" = "FCST" ]; then
  suffix="${ENSMEM_INDX:+_${ensmem_name}}"
elif [ "${FCST_OR_OBS}" = "OBS" ]; then
  suffix="_${OBTYPE}"
fi
metplus_config_fn="${metplus_config_tmpl_fn}_$(echo_lowercase ${FCST_OR_OBS})_${FIELDNAME_IN_MET_FILEDIR_NAMES}${suffix}"
metplus_log_fn="${metplus_config_fn}_$CDATE"
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
  'vx_leadhr_list': '${VX_LEADHR_LIST}'
#
# Input and output directory/file information.
#
  'metplus_config_fn': '${metplus_config_fn:-}'
  'metplus_log_fn': '${metplus_log_fn:-}'
  'input_dir': '${FCST_INPUT_DIR:-${OBS_INPUT_DIR}}'
  'input_fn_template': '${FCST_INPUT_FN_TEMPLATE:-${OBS_INPUT_FN_TEMPLATE}}'
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
  'FCST_OR_OBS': '${FCST_OR_OBS}'
  'input_accum_hh': '${input_accum_hh}'
  'output_accum_hh': '${ACCUM_HH:-}'
  'accum_no_pad': '${ACCUM_NO_PAD:-}'
  'metplus_templates_dir': '${METPLUS_CONF:-}'
  'input_field_group': '${FIELD_GROUP:-}'
  'input_level_fcst': '${FCST_LEVEL:-}'
  'input_thresh_fcst': '${FCST_THRESH:-}'
#
# Configuration information
#
  'pcp_combine_method': '${PCP_COMBINE_METHOD}'
# NOTE: this command must remain un-quoted for proper rendering of nested quotes in command
  'pcp_combine_command': ${PCP_COMBINE_COMMAND}
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
