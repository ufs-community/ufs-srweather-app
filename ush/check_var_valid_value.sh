#
#-----------------------------------------------------------------------
#
# This function checks whether the specified variable contains a valid 
# value (where the set of valid values is also specified).
#
#-----------------------------------------------------------------------
#
function check_var_valid_value() {
#
#-----------------------------------------------------------------------
#
# Save current shell options (in a global array).  Then set new options
# for this script/function.
#
#-----------------------------------------------------------------------
#
  { save_shell_opts; set -u +x; } > /dev/null 2>&1
#
#-----------------------------------------------------------------------
#
# Check arguments.
#
#-----------------------------------------------------------------------
#
  if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then

    print_err_msg_exit "\
Function \"${FUNCNAME[0]}\":  Incorrect number of arguments specified.
Usage:

  ${FUNCNAME[0]}  var_name   valid_var_values_array_name  [msg]

where the arguments are defined as follows:

  var_name:
  The name of the variable whose value we want to check for validity.

  valid_var_values_array_name:
  The name of the array containing a list of valid values that var_name
  can take on.

  msg
  Optional argument specifying the first portion of the error message to
  print out if var_name does not have a valid value.
"

  fi
#
#-----------------------------------------------------------------------
#
# Declare local variables.
#
#-----------------------------------------------------------------------
#
  local var_name \
        valid_var_values_array_name \
        var_value \
        valid_var_values_at \
        valid_var_values \
        err_msg \
        valid_var_values_str
#
#-----------------------------------------------------------------------
#
# Set local variable values.
#
#-----------------------------------------------------------------------
#
  var_name="$1"
  valid_var_values_array_name="$2"

  var_value=${!var_name}
  valid_var_values_at="$valid_var_values_array_name[@]"
  valid_var_values=("${!valid_var_values_at}")

  if [ "$#" -eq 3 ]; then
    err_msg="$3"
  else
    err_msg="\
The value specified in ${var_name} is not supported:
  ${var_name} = \"${var_value}\""
  fi
#
#-----------------------------------------------------------------------
#
# Check whether var_value is equal to one of the elements of the array
# valid_var_values.  If not, print out an error message and exit the 
# calling script.
#
#-----------------------------------------------------------------------
#
  iselementof "${var_value}" valid_var_values || { \
    caller_name=$( basename "${BASH_SOURCE[1]}" )
    valid_var_values_str=$(printf "\"%s\" " "${valid_var_values[@]}");
    print_err_msg_exit "\
${err_msg}
${var_name} must be set to one of the following:
  ${valid_var_values_str}"; \
  }
#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script/func-
# tion.
#
#-----------------------------------------------------------------------
#
  { restore_shell_opts; } > /dev/null 2>&1

}

