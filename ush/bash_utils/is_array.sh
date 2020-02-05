#
#-----------------------------------------------------------------------
#
# This file defines a function that is used to check whether a specified
# variable is a bash array.  It is called as follows:
#
#   is_array var_name
#
# Here, var_name is the name of the variable to check to determine whe-
# ther or not it is an array.  If the variable is an array, this func-
# tion will return a 0, and if it is not, this function will return a 1.
# 
#-----------------------------------------------------------------------
#
function is_array() { 
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
# Check arguments.
#
#-----------------------------------------------------------------------
#
  if [ "$#" -ne 1 ]; then

    print_err_msg_exit "
Incorrect number of arguments specified:

  Function name:  \"${func_name}\"
  Number of arguments specified:  $#

Usage:

  ${func_name}  var_name

where var_name is the name of the variable to check to determine whether 
or not it is an array.
"

  fi
#
#-----------------------------------------------------------------------
#
# Set local variables to appropriate input arguments.
#
#-----------------------------------------------------------------------
#
  local var_name="$1"
  local declare_output=$( declare -p "$var_name" 2> /dev/null )
  local regex="^declare -[aA] ${var_name}(=|$)"
  printf "%s" "$declare_output" | grep --extended-regexp "$regex" >/dev/null 
  is_an_array="$?"
#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script/func-
# tion.
#
#-----------------------------------------------------------------------
#
  { restore_shell_opts; } > /dev/null 2>&1
#
#-----------------------------------------------------------------------
#
# Return the variable "is_an_array".
#
#-----------------------------------------------------------------------
#
  return ${is_an_array}

}

