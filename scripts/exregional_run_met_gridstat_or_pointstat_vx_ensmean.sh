#!/bin/bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. $USHdir/source_util_funcs.sh
source_config_for_task "task_run_vx_ensgrid_mean|task_run_vx_enspoint_mean|task_run_post" ${GLOBAL_VAR_DEFNS_FP}
#
#-----------------------------------------------------------------------
#
# Source files defining auxiliary functions for verification.
#
#-----------------------------------------------------------------------
#
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
# Specify the set of valid argument names for this script/function.
# Then process the arguments provided to this script/function (which
# should consist of a set of name-value pairs of the form arg1="value1",
# etc).
#
#-----------------------------------------------------------------------
#
valid_args=( \
  "met_tool_sc" \
  "met_tool_pc" \
  )
process_args valid_args "$@"
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

This is the ex-script for the task that runs the METplus ${met_tool_pc}
tool to perform verification of the specified field (VAR) on the ensemble
mean.
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
# Set additional field-dependent verification parameters.
#
#-----------------------------------------------------------------------
#
if [ "${grid_or_point}" = "grid" ]; then

  case "${FIELDNAME_IN_MET_FILEDIR_NAMES}" in
    "APCP01h")
      FIELD_THRESHOLDS="gt0.0, ge0.254, ge0.508, ge2.54"
      ;;
    "APCP03h")
      FIELD_THRESHOLDS="gt0.0, ge0.508, ge2.54, ge6.350"
      ;;
    "APCP06h")
      FIELD_THRESHOLDS="gt0.0, ge2.54, ge6.350, ge12.700"
      ;;
    "APCP24h")
      FIELD_THRESHOLDS="gt0.0, ge6.350, ge12.700, ge25.400"
      ;;
    "REFC")
      FIELD_THRESHOLDS="ge20, ge30, ge40, ge50"
      ;;
    "RETOP")
      FIELD_THRESHOLDS="ge20, ge30, ge40, ge50"
      ;;
    *)
      print_err_msg_exit "\
Verification parameters have not been defined for this field
(FIELDNAME_IN_MET_FILEDIR_NAMES):
  FIELDNAME_IN_MET_FILEDIR_NAMES = \"${FIELDNAME_IN_MET_FILEDIR_NAMES}\""
      ;;
  esac

elif [ "${grid_or_point}" = "point" ]; then

  FIELD_THRESHOLDS=""

fi
#
#-----------------------------------------------------------------------
#
# Set paths and file templates for input to and output from the MET/
# METplus tool to be run as well as other file/directory parameters.
#
#-----------------------------------------------------------------------
#
if [ "${grid_or_point}" = "grid" ]; then

  OBS_INPUT_FN_TEMPLATE=""
  if [ "${field_is_APCPgt01h}" = "TRUE" ]; then
    OBS_INPUT_DIR="${VX_OUTPUT_BASEDIR}/metprd/PcpCombine_obs"
    OBS_INPUT_FN_TEMPLATE=$( eval echo ${OBS_CCPA_APCPgt01h_FN_TEMPLATE} )
  else
    OBS_INPUT_DIR="${OBS_DIR}"
    case "${FIELDNAME_IN_MET_FILEDIR_NAMES}" in
      "APCP01h")
        OBS_INPUT_FN_TEMPLATE="${OBS_CCPA_APCP01h_FN_TEMPLATE}"
        ;;
      "REFC")
        OBS_INPUT_FN_TEMPLATE="${OBS_MRMS_REFC_FN_TEMPLATE}"
        ;;
      "RETOP")
        OBS_INPUT_FN_TEMPLATE="${OBS_MRMS_RETOP_FN_TEMPLATE}"
        ;;
    esac
    OBS_INPUT_FN_TEMPLATE=$( eval echo ${OBS_INPUT_FN_TEMPLATE} )
  fi
# Keep for when splitting GenEnsProd from EnsembleStat.
#  FCST_INPUT_DIR="${VX_OUTPUT_BASEDIR}/$CDATE/metprd/gen_ens_prod"
#  FCST_INPUT_FN_TEMPLATE=$( eval echo 'gen_ens_prod_${VX_FCST_MODEL_NAME}_${FIELDNAME_IN_MET_FILEDIR_NAMES}_${OBTYPE}_{valid?fmt=%Y%m%d}_{valid?fmt=%H%M%S}V.nc' )
  FCST_INPUT_DIR="${VX_OUTPUT_BASEDIR}/$CDATE/metprd/EnsembleStat"
  FCST_INPUT_FN_TEMPLATE=$( eval echo 'ensemble_stat_${VX_FCST_MODEL_NAME}_${FIELDNAME_IN_MET_FILEDIR_NAMES}_${OBTYPE}_{valid?fmt=%Y%m%d}_{valid?fmt=%H%M%S}V_ens.nc' )

elif [ "${grid_or_point}" = "point" ]; then

  OBS_INPUT_DIR="${VX_OUTPUT_BASEDIR}/metprd/Pb2nc_obs"
  OBS_INPUT_FN_TEMPLATE=$( eval echo ${OBS_NDAS_SFCorUPA_FN_METPROC_TEMPLATE} )
# Keep for when splitting GenEnsProd from EnsembleStat.
#  FCST_INPUT_DIR="${VX_OUTPUT_BASEDIR}/${CDATE}/metprd/gen_ens_prod"
#  FCST_INPUT_FN_TEMPLATE=$( eval echo 'gen_ens_prod_${VX_FCST_MODEL_NAME}_ADP${FIELDNAME_IN_MET_FILEDIR_NAMES}_${OBTYPE}_{valid?fmt=%Y%m%d}_{valid?fmt=%H%M%S}V.nc' )
  FCST_INPUT_DIR="${VX_OUTPUT_BASEDIR}/${CDATE}/metprd/EnsembleStat"
  FCST_INPUT_FN_TEMPLATE=$( eval echo 'ensemble_stat_${VX_FCST_MODEL_NAME}_ADP${FIELDNAME_IN_MET_FILEDIR_NAMES}_${OBTYPE}_{valid?fmt=%Y%m%d}_{valid?fmt=%H%M%S}V_ens.nc' )

fi

OUTPUT_BASE="${VX_OUTPUT_BASEDIR}/${CDATE}"
OUTPUT_DIR="${OUTPUT_BASE}/metprd/${met_tool_pc}_ensmean"
STAGING_DIR="${OUTPUT_BASE}/stage/${FIELDNAME_IN_MET_FILEDIR_NAMES}_ensmean"
LOG_SUFFIX="_${FIELDNAME_IN_MET_FILEDIR_NAMES}_ensmean_${CDATE}"
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
  check_hourly_files="FALSE" \
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
# Set variable containing accumulation period without leading zero
# padding.  This may be needed in the METplus configuration files.
#
#-----------------------------------------------------------------------
#
ACCUM_NO_PAD=$( printf "%0d" "${ACCUM_HH}" )
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
if [ "${field_is_APCPgt01h}" = "TRUE" ]; then
  metplus_config_tmpl_fn="APCPgt01h"
else
  metplus_config_tmpl_fn="${FIELDNAME_IN_MET_FILEDIR_NAMES}"
fi
metplus_config_tmpl_fn="${met_tool_pc}_ensmean_${metplus_config_tmpl_fn}"
metplus_config_fn="${met_tool_pc}_ensmean_${FIELDNAME_IN_MET_FILEDIR_NAMES}"
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
  'uscore_ensmem_name_or_null': '${USCORE_ENSMEM_NAME_OR_NULL:-}'
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
#
# Call the python script to generate the METplus configuration file from
# the jinja template.
#
$USHdir/fill_jinja_template.py -q \
                               -u "${settings}" \
                               -t ${metplus_config_tmpl_fp} \
                               -o ${metplus_config_fp} || \
print_err_msg_exit "\
Call to python script fill_jinja_template.py to generate a METplus
configuration file from a jinja template failed.  Parameters passed
to this script are:
  Full path to template METplus configuration file:
    metplus_config_tmpl_fp = \"${metplus_config_tmpl_fp}\"
  Full path to output METplus configuration file:
    metplus_config_fp = \"${metplus_config_fp}\"
  Namelist settings specified on command line:
    settings =
$settings"
#
#-----------------------------------------------------------------------
#
# Call METplus.
#
#-----------------------------------------------------------------------
#
print_info_msg "$VERBOSE" "
Calling METplus to run MET's ${met_tool_sc} tool for field(s): ${FIELDNAME_IN_MET_FILEDIR_NAMES}"
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
METplus ${met_tool_pc} tool completed successfully.

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
