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
# Check arguments.
#
#-----------------------------------------------------------------------
#
  if [ "$#" -ne 3 ]; then
    print_err_msg_exit "\
Function \"${FUNCNAME[0]}\":  Incorrect number of arguments specified.
Usage:

  ${FUNCNAME[0]} file_full_path param value

where the arguments are defined as follows:

  file_full_path:
  Full path to the file in which the specified parameter's value will be set.

  param: 
  Name of the parameter whose value will be set.

  value:
  Value to set the parameter to."

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
# If VERBOSE is set to "true", print out an informational message.
#
#-----------------------------------------------------------------------
#
  print_info_msg_verbose "\
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
  "$WFLOW_XML_FN")
    regex_search="(^\s*<!ENTITY\s+$param\s*\")(.*)(\">.*)"
    regex_replace="\1$value\3"
    ;;
#
  "$RGNL_GRID_NML_FN")
    regex_search="^(\s*$param\s*=)(.*)"
    regex_replace="\1 $value"
    ;;
#
  "$FV3_NML_FN" | "$FV3_NML_CCPP_GFS_FN" | "$FV3_NML_CCPP_GSD_FN")
    regex_search="^(\s*$param\s*=)(.*)"
    regex_replace="\1 $value"
    ;;
#
  "$DIAG_TABLE_FN" | "$DIAG_TABLE_CCPP_GSD_FN" | "$DIAG_TABLE_CCPP_GSD_FN")
    regex_search="(.*)(<$param>)(.*)"
    regex_replace="\1$value\3"
    ;;
#
  "$MODEL_CONFIG_FN")
    regex_search="^(\s*$param:\s*)(.*)"
    regex_replace="\1$value"
    ;;
#
  "$SCRIPT_VAR_DEFNS_FN")
    regex_search="(^\s*$param=)(\".*\"|[^ \"]*)(\s*[#].*)?$"  # Whole line with regex_replace=\1.
#    regex_search="(^\s*$param=)(\".*\"|[^ \"]*)(\s*[#].*)?"
    regex_search="(^\s*$param=)(\".*\")?([^ \"]*)?(\(.*\))?(\s*[#].*)?"
#    regex_replace="\1\"$value\"\3"
#    regex_replace="\1$value\3"
#    regex_replace="\1\3"
#    regex_replace="\1AAAA\2BBBB\3CCCC\4DDDD\5"
    regex_replace="\1$value\5"
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
Function \"${FUNCNAME[0]}\":
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
  grep -q -E "$regex_search" $file_full_path

  if [ $? -eq 0 ]; then
    sed -i -r -e "s%$regex_search%$regex_replace%" $file_full_path
  else
    print_err_msg_exit "\
Specified file (file_full_path) does not contain the searched-for regular 
expression (regex_search):
  file_full_path = \"$file_full_path\"
  param = \"$param\"
  value = \"$value\"
  regex_search = $regex_search"
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


