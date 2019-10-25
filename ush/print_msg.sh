#
#-----------------------------------------------------------------------
#
# This file defines functions used in printing formatted output to std-
# out (e.g. informational and error messages).
#
#-----------------------------------------------------------------------
#

#
#-----------------------------------------------------------------------
#
# Function to print informational messages using printf.
#
#-----------------------------------------------------------------------
#
function print_info_msg() {
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
# Get the name of this function.
#
#-----------------------------------------------------------------------
#
  local func_name="${FUNCNAME[0]}"
#
#-----------------------------------------------------------------------
#
# Declare local variables.
#
#-----------------------------------------------------------------------
#
  local info_msg
  local verbose
#
#-----------------------------------------------------------------------
#
# If one argument is supplied, we assume it is the message to print out.
# between informational lines that are always printed.
#
#-----------------------------------------------------------------------
#
  if [ "$#" -eq 1 ]; then

    info_msg="$1"
    verbose="FALSE"
    
  elif [ "$#" -eq 2 ]; then

    verbose="$1"
    info_msg="$2"
#
#-----------------------------------------------------------------------
#
# If no arguments or more than two arguments are supplied, print out a 
# usage message and exit.
#
#-----------------------------------------------------------------------
#
  else

    printf "\
Function \"${func_name}\":  Incorrect number of arguments specified.
Usage:

  ${func_name} [verbose] info_msg

where the arguments are defined as follows:

  verbose:
  This is an optional argument.  If set to \"TRUE\", info_msg will be
  printed to stdout.  Otherwise, info_msg will not be printed.

  info_msg:
  This is the informational message to print to stdout.

This function prints an informational message to stout.  If one argument
is passed in, then that argument is assumed to be info_msg and is print-
ed.  If two arguments are passed in, then the first is assumed to be 
verbose and the second info_msg.  In this case, info_msg gets printed
only if verbose is set to \"TRUE\".\n"

  fi
#
#-----------------------------------------------------------------------
#
# If verbose is set to "TRUE", print out the message.
#
#-----------------------------------------------------------------------
#
  if [ "$verbose" = "TRUE" ]; then
    printf "%s\n" "${info_msg}"
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




#
#-----------------------------------------------------------------------
#
# Function to print out an error message to stderr using printf and then
# exit.
#
#-----------------------------------------------------------------------
#
function print_err_msg_exit() {
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
# Get the name of this function.
#
#-----------------------------------------------------------------------
#
  local func_name="${FUNCNAME[0]}"
#
#-----------------------------------------------------------------------
#
# Declare local variables.
#
#-----------------------------------------------------------------------
#
  local err_msg
  local caller_name
#
#-----------------------------------------------------------------------
#
# If no arguments are supplied, use a standard error message. 
#
#-----------------------------------------------------------------------
#
  if [ "$#" -eq 0 ]; then

    err_msg=$( printf "\
ERROR.  Exiting script or function with nonzero status."
             )
#
#-----------------------------------------------------------------------
#
# If one argument is supplied, we assume it is the message to print out
# between informational lines that are always printed.
#
#-----------------------------------------------------------------------
#
  elif [ "$#" -eq 1 ]; then

    err_msg="$1"
#
#-----------------------------------------------------------------------
#
# Remove trailing newlines from err_msg.  Command substitution [i.e. the
# $( ... )] will do this automatically.
#
#-----------------------------------------------------------------------
#
    err_msg=$( printf '%s' "${err_msg}" )
#
#-----------------------------------------------------------------------
#
# Add informational lines at the beginning and end of the message.
#
#-----------------------------------------------------------------------
#
    err_msg=$( printf "\
ERROR:
${err_msg}
Exiting script/function with nonzero status."
             )
#
#-----------------------------------------------------------------------
#
# If two arguments are supplied, we assume the first argument is the 
# name of the script or function from which this function is being 
# called while the second argument is the message to print out between 
# informational lines that are always printed.
#
#-----------------------------------------------------------------------
#
  elif [ "$#" -eq 2 ]; then

    caller_name="$1"
    err_msg="$2"
#
#-----------------------------------------------------------------------
#
# Remove trailing newlines from err_msg.  Command substitution [i.e. the
# $( ... )] will do this automatically.
#
#-----------------------------------------------------------------------
#
    err_msg=$( printf '%s' "${err_msg}" )
#
#-----------------------------------------------------------------------
#
# Add informational lines at the beginning and end of the message.
#
#-----------------------------------------------------------------------
#
    err_msg=$(printf "\
ERROR from script/file \"${caller_name}\":
${err_msg}
Exiting script/function with nonzero status."
             )
#
#-----------------------------------------------------------------------
#
# If more than two arguments are supplied, print out a usage message and
# exit.
#
#-----------------------------------------------------------------------
#
  else

    printf "\
Function \"${func_name}\":  Incorrect number of arguments specified.
Usage:

  ${func_name} [caller_name] [err_msg]

where the arguments are defined as follows:

  caller_name:
  This is an optional argument that specifies the name of the script or 
  function that calls this function (i.e. the caller).  

  err_msg:
  This is an optional argument that specifies the error message to print
  to stderr.

This function prints an error message to stderr.  If no arguments are 
passed in, then a standard error message is printed.  If only one argu-
ment is passed in, then that argument is assumed to be err_msg, and this
along with appropriate leading and trailing lines are printed.  If two 
arguments are passed in, then the first is assumed to be caller_name and
the second err_msg.  In this case, err_msg along with appropriate lead-
ing and trailing lines are printed, with the leading line containing the
name of the caller.\n"

  fi
#
#-----------------------------------------------------------------------
#
# Print out err_msg and exit function/script with nonzero status.
#
#-----------------------------------------------------------------------
#
  printf "\n%s\n" "${err_msg}" 1>&2
  exit 1
#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script/func-
# tion.  This statement will not be reached due to the preceeding exit
# statement, but we include it here for completeness (i.e. there should
# be a call to restore_shell_opts that matches a preceeding call to 
# save_shell_opts).
#
#-----------------------------------------------------------------------
#
  { restore_shell_opts; } > /dev/null 2>&1
}

