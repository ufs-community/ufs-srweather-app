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
# Declare local variables.
#
#-----------------------------------------------------------------------
#
  local verbose \
        info_msg
#
#-----------------------------------------------------------------------
#
# If one argument is supplied, we assume it is the message to print out.
# between informational lines that are always printed.
#
#-----------------------------------------------------------------------
#
  if [ "$#" -eq 1 ]; then

    verbose="TRUE"
    info_msg="$1"
    
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

    print_err_msg_exit "
Incorrect number of arguments specified:

  Function name:  \"${func_name}\"
  Number of arguments specified:  $#

Usage:

  ${func_name}  [verbose]  info_msg

where the arguments are defined as follows:

  verbose:
  This is an optional argument.  If set to \"TRUE\", info_msg will be
  printed to stdout.  Otherwise, info_msg will not be printed.

  info_msg:
  This is the informational message to print to stdout.

This function prints an informational message to stdout.  If one argu-
ment is passed in, then that argument is assumed to be info_msg and is 
printed.  If two arguments are passed in, then the first is assumed to
be verbose and the second info_msg.  In this case, info_msg gets printed
only if verbose is set to \"TRUE\".
"

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
# Declare local variables.
#
#-----------------------------------------------------------------------
#
  local msg_header \
        msg_footer \
        err_msg
#
#-----------------------------------------------------------------------
#
# Set the message header and footer.
#
#-----------------------------------------------------------------------
#
  if [ "${caller_name}" = "main" ] || \
     [ "${caller_name}" = "script" ]; then

    msg_header=$( printf "\n\
ERROR:
  From script:  \"${caller_fn}\"
  Full path to script:  \"${caller_fp}\"
"
                )

  else

    msg_header=$( printf "\n\
ERROR:
  From function:  \"${caller_name}\"
  In file:  \"${caller_fn}\"
  Full path to file:  \"${caller_fp}\"
"
                )

  fi

  msg_footer=$( printf "\nExiting with nonzero status." )
#
#-----------------------------------------------------------------------
#
# Check number of arguments and, if necessary, print out a usage message
# and exit.
#
#-----------------------------------------------------------------------
#
  if [ "$#" -gt 1 ]; then

    print_err_msg_exit "
Incorrect number of arguments specified:

  Function name:  \"${func_name}\"
  Number of arguments specified:  $#

Usage:

  ${func_name}  err_msg

where err_msg is an optional error message to print to stderr.  Note 
that a header and a footer are always added to err_msg.  Thus, if err_-
msg is not specified, the message that is printed will consist of only
the header and footer.
"
#
#-----------------------------------------------------------------------
#
# If an argument is listed, set err_msg to that argument.  Otherwise, 
# set it to a null string.  Then print out the complete error message to
# stderr and exit.
#
#-----------------------------------------------------------------------
#
  else

    if [ "$#" -eq 0 ]; then
      err_msg=""
    elif [ "$#" -eq 1 ]; then
      err_msg="\n$1"
    fi

    printf "${msg_header}${err_msg}${msg_footer}\n" 1>&2
    exit 1

  fi
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

