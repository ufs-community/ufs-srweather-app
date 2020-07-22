#
#-----------------------------------------------------------------------
#
# This file defines a function that creates a model configuration file
# for each cycle to be run.
#
#-----------------------------------------------------------------------
#
function create_model_config_files() {
#
#-----------------------------------------------------------------------
#
# Save current shell options (in a global array).  Then set new options
# for this script/function.
#
#-----------------------------------------------------------------------
#
  { save_shell_opts; set -u -x; } > /dev/null 2>&1
#
#-----------------------------------------------------------------------
#
# Get the full path to the file in which this script/function is located
# (scrfunc_fp), the name of that file (scrfunc_fn), and the directory in
# which the file is located (scrfunc_dir).
#
#-----------------------------------------------------------------------
#
  local scrfunc_fp=$( readlink -f "${BASH_SOURCE[0]}" )
  local scrfunc_fn=$( basename "${scrfunc_fp}" )
  local scrfunc_dir=$( dirname "${scrfunc_fp}" )
#
#-----------------------------------------------------------------------
#
# Get the name of this function.
#
#-----------------------------------------------------------------------
#
  local func_name="${FUNCNAME[0]}"
#
#-----------------------------------------------------------------------
#
# Specify the set of valid argument names for this script/function.  Then
# process the arguments provided to this script/function (which should
# consist of a set of name-value pairs of the form arg1="value1", etc).
#
#-----------------------------------------------------------------------
#
  local valid_args=()
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
  print_input_args valid_args
#
#-----------------------------------------------------------------------
#
# Declare local variables.
#
#-----------------------------------------------------------------------
#
  local i \
        cdate \
        cycle_dir \
        model_config_fp \
        yyyy \
        mm \
        dd \
        hh \
        mm \
        dot_quilting_dot \
        dot_print_esmf_dot
#
#-----------------------------------------------------------------------
#
# Create a model configuration file within each cycle directory.
#
#-----------------------------------------------------------------------
#
  print_info_msg "$VERBOSE" "
Creating a model configuration file (\"${MODEL_CONFIG_FN}\") within each
cycle directory..."

  for (( i=0; i<${NUM_CYCLES}; i++ )); do

    cdate="${ALL_CDATES[$i]}"
    cycle_dir="${CYCLE_BASEDIR}/$cdate"
#
# Copy template of cycle-dependent model configure files from the templates
# directory to the current cycle directory.
#
    model_config_fp="${cycle_dir}/${MODEL_CONFIG_FN}"
    cp_vrfy "${MODEL_CONFIG_TMPL_FP}" "${model_config_fp}"
#
# Extract from cdate the starting year, month, day, and hour of the forecast.
#
    yyyy=${cdate:0:4}
    mm=${cdate:4:2}
    dd=${cdate:6:2}
    hh=${cdate:8:2}
#
# Set parameters in the model configure file.
#
    dot_quilting_dot="."${QUILTING,,}"."
    dot_print_esmf_dot="."${PRINT_ESMF,,}"."

    set_file_param "${model_config_fp}" "PE_MEMBER01" "${PE_MEMBER01}"
    set_file_param "${model_config_fp}" "dt_atmos" "${DT_ATMOS}"
    set_file_param "${model_config_fp}" "start_year" "$yyyy"
    set_file_param "${model_config_fp}" "start_month" "$mm"
    set_file_param "${model_config_fp}" "start_day" "$dd"
    set_file_param "${model_config_fp}" "start_hour" "$hh"
    set_file_param "${model_config_fp}" "nhours_fcst" "${FCST_LEN_HRS}"
    set_file_param "${model_config_fp}" "ncores_per_node" "${NCORES_PER_NODE}"
    set_file_param "${model_config_fp}" "quilting" "${dot_quilting_dot}"
    set_file_param "${model_config_fp}" "print_esmf" "${dot_print_esmf_dot}"
#
#-----------------------------------------------------------------------
#
# If the write component is to be used, then a set of parameters, in-
# cluding those that define the write component's output grid, need to
# be specified in the model configuration file (model_config_fp).  This
# is done by appending a template file (in which some write-component
# parameters are set to actual values while others are set to placehol-
# ders) to model_config_fp and then replacing the placeholder values in
# the (new) model_config_fp file with actual values.  The full path of
# this template file is specified in the variable WRTCMP_PA RAMS_TEMP-
# LATE_FP.
#
#-----------------------------------------------------------------------
#
    if [ "$QUILTING" = "TRUE" ]; then

      cat ${WRTCMP_PARAMS_TMPL_FP} >> ${model_config_fp}

      set_file_param "${model_config_fp}" "write_groups" "$WRTCMP_write_groups"
      set_file_param "${model_config_fp}" "write_tasks_per_group" "$WRTCMP_write_tasks_per_group"

      set_file_param "${model_config_fp}" "output_grid" "\'$WRTCMP_output_grid\'"
      set_file_param "${model_config_fp}" "cen_lon" "$WRTCMP_cen_lon"
      set_file_param "${model_config_fp}" "cen_lat" "$WRTCMP_cen_lat"
      set_file_param "${model_config_fp}" "lon1" "$WRTCMP_lon_lwr_left"
      set_file_param "${model_config_fp}" "lat1" "$WRTCMP_lat_lwr_left"

      if [ "${WRTCMP_output_grid}" = "rotated_latlon" ]; then
        set_file_param "${model_config_fp}" "lon2" "$WRTCMP_lon_upr_rght"
        set_file_param "${model_config_fp}" "lat2" "$WRTCMP_lat_upr_rght"
        set_file_param "${model_config_fp}" "dlon" "$WRTCMP_dlon"
        set_file_param "${model_config_fp}" "dlat" "$WRTCMP_dlat"
      elif [ "${WRTCMP_output_grid}" = "lambert_conformal" ]; then
        set_file_param "${model_config_fp}" "stdlat1" "$WRTCMP_stdlat1"
        set_file_param "${model_config_fp}" "stdlat2" "$WRTCMP_stdlat2"
        set_file_param "${model_config_fp}" "nx" "$WRTCMP_nx"
        set_file_param "${model_config_fp}" "ny" "$WRTCMP_ny"
        set_file_param "${model_config_fp}" "dx" "$WRTCMP_dx"
        set_file_param "${model_config_fp}" "dy" "$WRTCMP_dy"
      elif [ "${WRTCMP_output_grid}" = "regional_latlon" ]; then
        set_file_param "${model_config_fp}" "lon2" "$WRTCMP_lon_upr_rght"
        set_file_param "${model_config_fp}" "lat2" "$WRTCMP_lat_upr_rght"
        set_file_param "${model_config_fp}" "dlon" "$WRTCMP_dlon"
        set_file_param "${model_config_fp}" "dlat" "$WRTCMP_dlat"
      fi

    fi

  done
#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script/function.
#
#-----------------------------------------------------------------------
#
  { restore_shell_opts; } > /dev/null 2>&1

}

