#
#-----------------------------------------------------------------------
#
# This file defines a function that prints to stdout the names and val-
# ues of a specified list of variables that are the valid arguments to 
# the script or function that calls this function.  It is mainly used 
# for debugging to check that the argument values passed to the calling
# script/function have been set correctly.  Note that if a global varia-
# ble named VERBOSE is not defined, the message will be printed out.  If
# a global variable named VERBOSE is defined, then the message will be 
# printed out only if VERBOSE is set to TRUE.
# 
#-----------------------------------------------------------------------
#
function print_input_args() { 
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
# Get information about the script or function that calls this function.
# Note that caller_name will be set as follows:
#
# 1) If the caller is a function, caller_name will be set to the name of
#    that function.
# 2) If the caller is a sourced script, caller_name will be set to
#    "script".  Note that a sourced script cannot be the top level
#    script since by defintion, it is sourced by another script or func-
#    tion.
# 3) If the caller is the top-level script, caller_name will be set to
#    "main".
#
# Thus, if caller_name is set to "script" or "main", the caller is a
# script, and if it is set to anything else, the caller is a function.
#
#-----------------------------------------------------------------------
#
  local caller_fp=$( readlink -f "${BASH_SOURCE[1]}" )
  local caller_fn=$( basename "${caller_fp}" )
  local caller_dir=$( dirname "${caller_fp}" )
  local caller_name="${FUNCNAME[1]}"
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

  ${func_name}  array_name_valid_caller_args

where array_name_valid_caller_args is the name of the array containing
the names of valid arguments that can be passed to the calling script or
function.
"

  fi
#
#-----------------------------------------------------------------------
#
# Declare local variables.
#
#-----------------------------------------------------------------------
#
  local array_name_valid_caller_args \
        valid_caller_args \
        script_or_function \
        msg \
        num_valid_args \
        i \
        line
#
#-----------------------------------------------------------------------
#
# Get the array containing the list of valid argument names that can be 
# passed to the calling script/function.  Note that if this is set to an
# empty array in the calling script/function [e.g. using the notation 
# some_array=()], then it will (for whatever reason) not be defined in
# the scope of this function.  For this reason, we need the if-statement
# below to check for this case.  Then get the number of valid arguments. 
#
#-----------------------------------------------------------------------
#
  array_name_valid_caller_args="$1"
  valid_arg_names_0th="${array_name_valid_caller_args}[0]"
  if [ ${!valid_arg_names_0th:-"__unset__"} = "__unset__" ]; then
    valid_caller_args=()
  else
    valid_caller_args_at="${array_name_valid_caller_args}[@]"
    valid_caller_args=("${!valid_caller_args_at}")
  fi
  num_valid_caller_args="${#valid_caller_args[@]}"
#
#-----------------------------------------------------------------------
#
# Set the message to print to stdout.  Note that if the number of valid
# arguments is zero, then we simply print out a message stating this fact.
#
#-----------------------------------------------------------------------
#
  if [ "${caller_name}" = "main" ] || \
     [ "${caller_name}" = "script" ]; then
    script_or_function="the script"
  else
    script_or_function="function \"${caller_name}\""
  fi

  if [ ${num_valid_caller_args} -eq 0 ]; then

    msg="
No arguments have been passed to ${script_or_function} in file

  \"${caller_fp}\"
"

  else

    msg="
The arguments to ${script_or_function} in file

  \"${caller_fp}\"

have been set as follows:
"

    for (( i=0; i<${num_valid_caller_args}; i++ )); do
      line=$( declare -p "${valid_caller_args[$i]}" )
      msg=$( printf "%s\n%s" "$msg" "  $line" )
    done

  fi
#
#-----------------------------------------------------------------------
#
# If a global variable named VERBOSE is not defined, print out the mes-
# sage.  If it is defined, print out the message only if VERBOSE is set
# to TRUE.
#
#-----------------------------------------------------------------------
#
  if [ ! -v VERBOSE ]; then
    print_info_msg "$msg"
  else
    print_info_msg "$VERBOSE" "$msg"
  fi
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

