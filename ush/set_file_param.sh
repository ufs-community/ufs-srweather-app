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
  if [ "$#" -ne 4 ]; then
    print_err_msg_exit "\
Function \"${FUNCNAME[0]}\":  Incorrect number of arguments specified.
Usage:

  ${FUNCNAME[0]} file_full_path param value verbose

where the arguments are defined as follows:

  file_full_path:
  Full path to the file in which the specified parameter's value will be set.

  param: 
  Name of the parameter whose value will be set.

  value:
  Value to set the parameter to.

  verbose:
  Whether to be verbose (\"true\" or \"false\")."
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
  local verbose="$4"
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
# If verbose is set to "true", print out an informational message.
#
#-----------------------------------------------------------------------
#
  print_info_msg_verbose "\
Setting parameter \"$param\" in file \"$file\"..."
#
#-----------------------------------------------------------------------
#
# The procedure we use to set the value of the specified parameter de-
# pends on the file the parameter is in.  Compare the file name to seve-
# ral known file names and issue the appropriate sed command.  See the
# configuration file for definitions of the known file names.
#
#-----------------------------------------------------------------------
#
  local regex_orig=""
  case $file in
#
  "$WFLOW_XML_FN")
    regex_orig="(^\s*<!ENTITY\s+$param\s*\")(.*)(\">.*)"
    sed -i -r -e "s|$regex_orig|\1$value\3|g" $file_full_path
    ;;
#
  "$FV3_NAMELIST_FN")
    regex_orig="^(\s*$param\s*=)(.*)"
    sed -i -r -e "s|$regex_orig|\1 $value|g" $file_full_path
    ;;
#
  "$FV3_CCPP_GFS_NAMELIST_FN")
    regex_orig="^(\s*$param\s*=)(.*)"
    sed -i -r -e "s|$regex_orig|\1 $value|g" $file_full_path
    ;;
#
  "$FV3_CCPP_GSD_NAMELIST_FN")
    regex_orig="^(\s*$param\s*=)(.*)"
    sed -i -r -e "s|$regex_orig|\1 $value|g" $file_full_path
    ;;
#
  "$DIAG_TABLE_FN")
    regex_orig="(.*)(<$param>)(.*)"
    sed -i -r -e "s|(.*)(<$param>)(.*)|\1$value\3|g" $file_full_path
    ;;
#
  "$DIAG_TABLE_CCPP_GSD_FN")
    regex_orig="(.*)(<$param>)(.*)"
    sed -i -r -e "s|(.*)(<$param>)(.*)|\1$value\3|g" $file_full_path
    ;;
#
  "$MODEL_CONFIG_FN")
    regex_orig="^(\s*$param:\s*)(.*)"
    sed -i -r -e "s|$regex_orig|\1$value|g" $file_full_path
    ;;
#
  "$SCRIPT_VAR_DEFNS_FN")
#
# In the following regex (regex_orig), we have to escape the pipe (|) 
# (which acts as an "OR") because that's also the character we use as 
# the delimiter in the following sed command.
#
    regex_orig="(^\s*$param=)(\".*\"\|[^ \"]*)(\s*[#].*)?"
    sed -i -r -e "s|$regex_orig|\1\"$value\"\3|g" $file_full_path
    ;;
#
#-----------------------------------------------------------------------
#
# If "file" is set to a disallowed value, we simply exit with a nonzero
# status.  Note that "exit" is different than "return" because it will
# cause the calling script (in which this file/function is sourced) to
# stop execution.
#
#-----------------------------------------------------------------------
#
  *)
    print_err_msg_exit "\
Function \"${FUNCNAME[0]}\":  Unkown file:
  file = \"$file\""
    ;;
#
  esac
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


