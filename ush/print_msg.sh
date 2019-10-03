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
# Check arguments.
#
#-----------------------------------------------------------------------
#
  if [ "$#" -ne 1 ]; then
    print_err_msg_exit "\
Function \"${FUNCNAME[0]}\":  Incorrect number of arguments specified.
Usage:

  ${FUNCNAME[0]} msg

where msg is the message to print."
  fi
#
#-----------------------------------------------------------------------
#
# Set local variables.
#
#-----------------------------------------------------------------------
#
  local info_msg="$1"
#
#-----------------------------------------------------------------------
#
# Remove trailing newlines from info_msg.  Command substitution [i.e.
# the $( ... )] will do this automatically.
#
#-----------------------------------------------------------------------
#
  info_msg=$( printf '%s' "${info_msg}" )
#
#-----------------------------------------------------------------------
#
# Add informational lines at the beginning and end of the message.
#
#-----------------------------------------------------------------------
#
  local MSG=$(printf "\
$info_msg
")
#
#-----------------------------------------------------------------------
#
# Print out the message.
#
#-----------------------------------------------------------------------
#
  printf '%s\n' "$MSG"
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
# Function to print informational messages using printf, but only if the
# VERBOSE flag is set to "TRUE".
#
#-----------------------------------------------------------------------
#
function print_info_msg_verbose() {
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
  if [ "$#" -ne 1 ]; then
    print_err_msg_exit "\
Function \"${FUNCNAME[0]}\":  Incorrect number of arguments specified.
Usage:

  ${FUNCNAME[0]} msg

where msg is the message to print."
  fi
#
#-----------------------------------------------------------------------
#
# Print the message only if VERBOSE is set to "TRUE".
#
#-----------------------------------------------------------------------
#
  if [ "$VERBOSE" = "TRUE" ]; then
    print_info_msg "$1"
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
# Function to print error messages using printf and exit.
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
# If no arguments are supplied, use a standard error message. 
#
#-----------------------------------------------------------------------
#
  if [ "$#" -eq 0 ]; then

    local MSG=$(printf "\
ERROR.  Exiting script or function with nonzero status.
")
#
#-----------------------------------------------------------------------
#
# If one argument is supplied, we assume it is the message to print out
# between informational lines that are always printed.
#
#-----------------------------------------------------------------------
#
  elif [ "$#" -eq 1 ]; then

    local err_msg="$1"
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
    local MSG=$(printf "\
ERROR:
$err_msg
Exiting script/function with nonzero status.
")
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

    local script_func_name="$1"
    local err_msg="$2"
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
    local MSG=$(printf "\
ERROR from script/function \"${script_func_name}\":
$err_msg
Exiting script/function with nonzero status.
")
#
#-----------------------------------------------------------------------
#
# If more than two arguments are supplied, print out a usage error mes-
# sage.
#
#-----------------------------------------------------------------------
#
  elif [ "$#" -gt 1 ]; then

    local MSG=$(printf "\
Function \"${FUNCNAME[0]}\":  Incorrect number of arguments specified.
Usage:

  ${FUNCNAME[0]}

or

  ${FUNCNAME[0]} msg

where msg is an optional error message to print.  Exiting with nonzero status.
")

  fi
#
#-----------------------------------------------------------------------
#
# Print out MSG and exit function/script with nonzero status.
#
#-----------------------------------------------------------------------
#
  printf '\n%s\n' "$MSG" 1>&2
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

