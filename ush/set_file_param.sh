function set_file_param() {

  file_full_path="$1"
  param="$2"
  value="$3"
  verbose="$4"
#
# Extract just the file name from the full path.
#
  file="${file_full_path##*/}"
#
# If verbose is set to "true", print out an informational message.
#
  if [ "$verbose" = "true" ]; then
    echo
    echo "Setting parameter \"$param\" in file \"$file\"..."
  fi
#
# The procedure we use to set the value of the specified parameter de-
# pends on the file the parameter is in.  Compare the file name to seve-
# ral known file names and issue the appropriate sed command.  See the
# configuration file for definitions of the known file names.
#
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
  "$DIAG_TABLE_FN")
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
# Note that we have to escape the pipe (|) in regex_orig (the pipe acts
# as "OR") because that's also the character we use as the delimiter in
# the sed command.
#
    regex_orig="(^\s*$param=)(\".*\"\|[^ \"]*)(\s*[#].*)?"
    sed -i -r -e "s|$regex_orig|\1\"$value\"\3|g" $file_full_path
    ;;
#
# If "file" is set to a disallowed value, we simply exit with a nonzero
# status.  Note that "exit" is different than "return" because it will
# cause the calling script (in which this file/function is sourced) to
# stop execution.
#
  *)
    echo
    echo "Error from function $0:  Unkown file:"
    echo "  file = $file"
    echo "Exiting with nonzero status."
    exit 1
    ;;
#
  esac
  
}


