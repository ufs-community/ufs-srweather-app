#
#-----------------------------------------------------------------------
#
# This file defines a function that checks for a preexisting version of
# the specified directory or file and, if present, deals with it according
# to the specified method.
#
#-----------------------------------------------------------------------
#
function check_for_preexist_dir_file() {
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

  ${func_name}  dir_or_file  method

where the arguments are defined as follows:

  dir_or_file:
  Name of directory or file to check for a preexisting version.

  method:
  String specifying the action to take if a preexisting version of 
  dir_or_file is found.  Valid values are \"delete\", \"rename\", and \"quit\".
"

  fi
#
#-----------------------------------------------------------------------
#
# Set local variables to appropriate input arguments.
#
#-----------------------------------------------------------------------
#
  local dir_or_file="$1"
  local method="$2"
#
#-----------------------------------------------------------------------
#
# Set the valid values that method can take on and check to make sure 
# the specified value is valid.
#
#-----------------------------------------------------------------------
#
  local valid_vals_method=( "delete" "rename" "quit" )
  check_var_valid_value "method" "valid_vals_method"
#
#-----------------------------------------------------------------------
#
# Check if dir_or_file already exists.  If so, act depending on the value
# of method.
#
#-----------------------------------------------------------------------
#
  if [ -e "${dir_or_file}" ]; then

    case "$method" in
#
#-----------------------------------------------------------------------
#
# If method is set to "delete", we remove the preexisting directory or
# file.
#
#-----------------------------------------------------------------------
#
    "delete")

      rm_vrfy -rf "${dir_or_file}"
      ;;
#
#-----------------------------------------------------------------------
#
# If method is set to "rename", we move (rename) the preexisting directory
# or file.
#
#-----------------------------------------------------------------------
#
    "rename")

      local i=1
      local old_indx=$( printf "%03d" "$i" )
      local old_dir_or_file="${dir_or_file}_old${old_indx}"
      while [ -e "${old_dir_or_file}" ]; do
        i=$[$i+1]
        old_indx=$( printf "%03d" "$i" )
        old_dir_or_file="${dir_or_file}_old${old_indx}"
      done

      print_info_msg "$VERBOSE" "
Specified directory or file (dir_or_file) already exists:
  dir_or_file = \"${dir_or_file}\"
Moving (renaming) preexisting directory or file to:
  old_dir_or_file = \"${old_dir_or_file}\""

      mv_vrfy "${dir_or_file}" "${old_dir_or_file}"
      ;;
#
#-----------------------------------------------------------------------
#
# If method is set to "quit", we simply exit with a nonzero status.  Note
# that "exit" is different than "return" because it will cause the calling
# script (in which this file/function is sourced) to stop execution.
#
#-----------------------------------------------------------------------
#
    "quit")

      print_err_msg_exit "\
Specified directory or file (dir_or_file) already exists:
  dir_or_file = \"${dir_or_file}\""
      ;;

    esac
  
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


