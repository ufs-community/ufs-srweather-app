#!/bin/bash

#
#-----------------------------------------------------------------------
#
# This file defines a function that checks for a preexisting version of
# the specified directory or file and, if present, deals with it according
# to the specified method.
#
#-----------------------------------------------------------------------
#
function check_dead_link() {
#
#-----------------------------------------------------------------------
#
# Save current shell options (in a global array).  Then set new options
# for this script/function.
#
#-----------------------------------------------------------------------
#
  { save_shell_opts; . ${USHdir}/preamble.sh; } > /dev/null 2>&1
#
#-----------------------------------------------------------------------
#
# Get the full path to the file in which this script/function is located 
# (scrfunc_fp), the name of that file (scrfunc_fn), and the directory in
# which the file is located (scrfunc_dir).
#
#-----------------------------------------------------------------------
#
  local scrfunc_fp=$( $READLINK -f "${BASH_SOURCE[0]}" )
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

  ${func_name}  directory_name

where the arguments are defined as follows:

  directory_name:
  Name of directory to check for dead link.
"

  fi
#
#-----------------------------------------------------------------------
#
# Set local variables to appropriate input arguments.
#
#-----------------------------------------------------------------------
#
  local directory_name="$1"
#
#-----------------------------------------------------------------------
#
# Check if directory exists then check for dead link.
# If found, perform exception handling.
#
#-----------------------------------------------------------------------
#
  if [ -e "${directory_name}" ]; then
    local deal_link_count=$(find ${directory_name} -xtype l|wc -l)
    if [ ${deal_link_count} -gt 0 ]; then
      echo "FATAL ERROR ${deal_link_count} dead link found in ${directory_name}"
      exit 8
    fi
  else
   echo "FATAL ERROR ${deal_link_count} not exist"
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


