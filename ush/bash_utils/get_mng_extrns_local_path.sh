#!/bin/bash

#
#-----------------------------------------------------------------------
#
# This file searches the specified manage_externals configuration file
# and finds in it the relative path on the local disk (relative to the 
# location of the manage_externals configuration file) where the external with the specified name has been/will be placed by the manage_externals utility.
# 
#-----------------------------------------------------------------------
#
function get_mng_extrns_local_path() { 
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
  if [ "$#" -ne 2 ]; then

    print_err_msg_exit "
Incorrect number of arguments specified:

  Function name:  \"${func_name}\"
  Number of arguments specified:  $#

Usage:

  ${func_name}  externals_cfg_fp  external_name

where the arguments are defined as follows:

  externals_cfg_fp:
  The absolute or relative path to the manage_externals configuration
  file that will be searched for the external named external_name.

  external_name:
  The name of the external to search for in the file specified by 
  externals_cfg_fp.  Once this 
"

  fi
#
#-----------------------------------------------------------------------
#
# 
#
#-----------------------------------------------------------------------
#
  externals_cfg_fp="$1"
  external_name="$2"

  local_path=$( sed -r -n \
    -e "/^[ ]*\[${external_name}\]/!b" \
    -e ":SearchForLocalPath" \
    -e "s/^[ ]*local_path[ ]*=[ ]*([^ ]*).*/\1/;t FoundLocalPath" \
    -e "n;bSearchForLocalPath" \
    -e ":FoundLocalPath" \
    -e "p;q" \
    "${externals_cfg_fp}" \
  )

  if [ -z "${local_path}" ]; then

    print_err_msg_exit "\
The local path for the specified external name (external_name) in the
specified manage_externals configuration file (externals_cfg_fp) was not
found:
  externals_cfg_fp = \"${externals_cfg_fp}\"
  external_name = \"${external_name}\"
It is possible that the specified external_name does not exist in the 
configuration file."

  else

    printf "%s\n" "${local_path}"

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
