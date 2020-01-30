#
#-----------------------------------------------------------------------
#
# This file defines a function that replaces placeholder values of vari-
# ables in several different types of files with actual values.
#
#-----------------------------------------------------------------------
#
function set_file_param() {
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
  if [ "$#" -ne 3 ]; then

    print_err_msg_exit "
Incorrect number of arguments specified:

  Function name:  \"${func_name}\"
  Number of arguments specified:  $#

Usage:

  ${func_name}  file_full_path  param  value

where the arguments are defined as follows:

  file_full_path:
  Full path to the file in which the specified parameter's value will be
  set.

  param: 
  Name of the parameter whose value will be set.

  value:
  Value to set the parameter to.
"

  fi
#
#-----------------------------------------------------------------------
#
# Set local variables to appropriate input arguments.
#
#-----------------------------------------------------------------------
#
  local file_full_path="$1"
  local param="$2"
  local value="$3"
#
#-----------------------------------------------------------------------
#
# Extract just the file name from the full path.
#
#-----------------------------------------------------------------------
#
  local file="${file_full_path##*/}"
#
#-----------------------------------------------------------------------
#
# If VERBOSE is set to "TRUE", print out an informational message.
#
#-----------------------------------------------------------------------
#
  print_info_msg "$VERBOSE" "\
Setting parameter \"$param\" in file \"$file\" to \"$value\" ..."
#
#-----------------------------------------------------------------------
#
# The procedure we use to set the value of the specified parameter de-
# pends on the file the parameter is in.  Compare the file name to sev-
# eral known file names and set the regular expression to search for
# (regex_search) and the one to replace with (regex_replace) according-
# ly.  See the default configuration file (config_defaults.sh) for defi-
# nitions of the known file names.
#
#-----------------------------------------------------------------------
#
  local regex_search=""
  local regex_replace=""

  case $file in
#
  "${WFLOW_XML_FN}")
    regex_search="(^\s*<!ENTITY\s+$param\s*\")(.*)(\">.*)"
    regex_replace="\1$value\3"
    ;;
#
  "${RGNL_GRID_NML_FN}")
    regex_search="^(\s*$param\s*=)(.*)"
    regex_replace="\1 $value"
    ;;
#
  "${FV3_NML_FN}")
    regex_search="^(\s*$param\s*=)(.*)"
    regex_replace="\1 $value"
    ;;
#
  "${DIAG_TABLE_FN}")
    regex_search="(.*)(<$param>)(.*)"
    regex_replace="\1$value\3"
    ;;
#
  "${MODEL_CONFIG_FN}")
    regex_search="^(\s*$param:\s*)(.*)"
    regex_replace="\1$value"
    ;;
#
  "${GLOBAL_VAR_DEFNS_FN}")
    regex_search="(^\s*$param=)(\".*\")?([^ \"]*)?(\(.*\))?(\s*[#].*)?"
    regex_replace="\1$value\5"
#    set_bash_param "${file_full_path}" "$param" "$value"
    ;;
#
#-----------------------------------------------------------------------
#
# If "file" is set to a disallowed value, print out an error message and
# exit.
#
#-----------------------------------------------------------------------
#
  *)
    print_err_msg_exit "\
The regular expressions for performing search and replace have not been 
specified for this file:
  file = \"$file\""
    ;;
#
  esac
#
#-----------------------------------------------------------------------
#
# Use grep to determine whether regex_search exists in the specified 
# file.  If so, perform the regex replacement using sed.  If not, print
# out an error message and exit.
#
#-----------------------------------------------------------------------
#
  grep -q -E "${regex_search}" "${file_full_path}"

  if [ $? -eq 0 ]; then
    sed -i -r -e "s%${regex_search}%${regex_replace}%" "${file_full_path}"
  else
    print_err_msg_exit "\
Specified file (file_full_path) does not contain the searched-for regu-
lar expression (regex_search):
  file_full_path = \"${file_full_path}\"
  param = \"$param\"
  value = \"$value\"
  regex_search = ${regex_search}"
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

