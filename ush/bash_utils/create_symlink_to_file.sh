#
#-----------------------------------------------------------------------
#
# This file defines a function that is used to create a symbolic link
# ("symlink") to the specified target file ("target").  It checks for 
# the existence of the target file and fails (with an appropriate error
# message) if that target does not exist or is not a file.  Also, the
# argument "relative" determines whether a relative or an absolute path
# to the symlink is used.  Note that on some platforms, relative symlinks
# are not supported.  In those cases, an absolute path is used regardless
# of the setting of "relative".
# 
#-----------------------------------------------------------------------
#
function create_symlink_to_file() { 
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
# Specify the set of valid argument names for this script/function.  Then
# process the arguments provided to this script/function (which should
# consist of a set of name-value pairs of the form arg1="value1", etc).
#
#-----------------------------------------------------------------------
#
  local valid_args=( \
"target" \
"symlink" \
"relative" \
  )
  process_args valid_args "$@"
#
#-----------------------------------------------------------------------
#
# For debugging purposes, print out values of arguments passed to this
# script.  Note that these will be printed out only if VERBOSE is set to
# TRUE.
#
#-----------------------------------------------------------------------
#
  print_input_args valid_args
#
#-----------------------------------------------------------------------
#
# Verify that the required arguments to this function have been specified.
# If not, print out an error message and exit.
#
#-----------------------------------------------------------------------
#
  if [ -z "${target}" ]; then
    print_err_msg_exit "\
The argument \"target\" specifying the target of the symbolic link that
this function will create was not specified in the call to this function:
  target = \"$target\""
  fi

  if [ -z "${symlink}" ]; then
    print_err_msg_exit "\
The argument \"symlink\" specifying the symbolic link that this function
will create was not specified in the call to this function:
  symlink = \"$symlink\""
  fi
#
#-----------------------------------------------------------------------
#
# Declare local variables.
#
#-----------------------------------------------------------------------
#
  local valid_vals_relative \
        relative_flag
#
#-----------------------------------------------------------------------
#
# If "relative" is not set (i.e. if it is set to a null string), reset 
# it to a default value of "TRUE".  Then check that it is set to a vaild 
# value.
#
#-----------------------------------------------------------------------
#
  relative=${relative:-"TRUE"}

  valid_vals_relative=("TRUE" "true" "YES" "yes" "FALSE" "false" "NO" "no")
  check_var_valid_value "relative" "valid_vals_relative"
#
#-----------------------------------------------------------------------
#
# Make sure that the target file exists and is a file.
#
#-----------------------------------------------------------------------
#
  if [ ! -f "${target}" ]; then
    print_err_msg_exit "\
Cannot create symlink to specified target file because the latter does
not exist or is not a file:
    target = \"$target\""
  fi
#
#-----------------------------------------------------------------------
#
# Set the flag that specifies whether or not a relative symlink should
# be created.
#
#-----------------------------------------------------------------------
#
  relative_flag=""
  if [ "${relative}" = "TRUE" ]; then
    relative_flag="${RELATIVE_LINK_FLAG}"
  fi
#
#-----------------------------------------------------------------------
#
# Create the symlink.
#
# Important note:
# In the ln_vrfy command below, do not quote ${relative_flag} because if 
# is quoted (either single or double quotes) but happens to be a null 
# string, it will be treated as the (empty) name of (or path to) the 
# target and will cause an error.
#
#-----------------------------------------------------------------------
#
  ln_vrfy -sf ${relative_flag} "$target" "$symlink"
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

