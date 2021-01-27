#
#-----------------------------------------------------------------------
#
# This file defines a function that checks whether the RUC land surface
# model (LSM) parameterization is being called by the selected physics
# suite.  If so, it sets the variable ruc_lsm used to "TRUE".  If not, 
# it sets this variable to "FALSE".  It then "returns" this variable, 
# i.e. it sets the environment variable whose name is specified by the 
# input argument output_varname_sdf_uses_ruc_lsm to whatever sdf_uses_ruc_lsm 
# is set to.
#
#-----------------------------------------------------------------------
#
function check_ruc_lsm() {
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
  local valid_args=( \
    "ccpp_phys_suite_fp" \
    "output_varname_sdf_uses_ruc_lsm" \
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
  print_input_args valid_args
#
#-----------------------------------------------------------------------
#
# Declare local variables.
#
#-----------------------------------------------------------------------
#
  local ruc_lsm_name \
        regex_search \
        ruc_lsm_name_or_null \
        sdf_uses_ruc_lsm
#
#-----------------------------------------------------------------------
#
# Check the suite definition file to see whether the Thompson microphysics
# parameterization is being used.
#
#-----------------------------------------------------------------------
#
  ruc_lsm_name="lsm_ruc"
  regex_search="^[ ]*<scheme>(${ruc_lsm_name})<\/scheme>[ ]*$"
  ruc_lsm_name_or_null=$( sed -r -n -e "s/${regex_search}/\1/p" "${ccpp_phys_suite_fp}" )

  if [ "${ruc_lsm_name_or_null}" = "${ruc_lsm_name}" ]; then
    sdf_uses_ruc_lsm="TRUE"
  elif [ -z "${ruc_lsm_name_or_null}" ]; then
    sdf_uses_ruc_lsm="FALSE"
  else
    print_err_msg_exit "\
Unexpected value returned for ruc_lsm_name_or_null:
  ruc_lsm_name_or_null = \"${ruc_lsm_name_or_null}\"
This variable should be set to either \"${ruc_lsm_name}\" or an empty
string."
  fi
#
#-----------------------------------------------------------------------
#
# Set output variables.
#
#-----------------------------------------------------------------------
#
  eval ${output_varname_sdf_uses_ruc_lsm}="${sdf_uses_ruc_lsm}"
#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script/function.
#
#-----------------------------------------------------------------------
#
  { restore_shell_opts; } > /dev/null 2>&1

}

