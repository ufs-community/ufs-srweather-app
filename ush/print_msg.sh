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
  save_shell_opts
  { set +x; } > /dev/null 2>&1
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
  printf '\n%s\n' "$MSG"
#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script/func-
# tion.
#
#-----------------------------------------------------------------------
#
  restore_shell_opts
}



#
#-----------------------------------------------------------------------
#
# Function to print informational messages using printf, but only if the
# VERBOSE flag is set to "true".
#
#-----------------------------------------------------------------------
#
function print_info_msg_verbose() {
#
  if [ "$VERBOSE" = "true" ]; then
    print_info_msg "$1"
  fi
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
  save_shell_opts
  { set +x; } > /dev/null 2>&1
#
#-----------------------------------------------------------------------
#
# Set local variables.
#
#-----------------------------------------------------------------------
#
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
Exiting script or function with nonzero status.
")
#
#-----------------------------------------------------------------------
#
# Print out the message and exit.
#
#-----------------------------------------------------------------------
#
  printf '\n%s\n' "$MSG"
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
  restore_shell_opts
}
