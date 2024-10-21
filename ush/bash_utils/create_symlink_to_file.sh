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
# Specify the set of valid argument names for this script/function.  Then
# process the arguments provided to this script/function (which should
# consist of a set of name-value pairs of the form arg1="value1", etc).
#
#-----------------------------------------------------------------------
#
if [[ $# -lt 2 ]]; then
  print_err_msg_exit "Function create_symlink_to_file() requires at least two arguments"
fi

target=$1
symlink=$2
relative=${3:-TRUE}
relative=$(boolify $relative)
if [ "$relative" != "TRUE" ] && [ "$relative" != "FALSE" ]; then
  print_err_msg_exit "'relative' must be set to TRUE or FALSE"
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
#-----------------------------------------------------------------------
#
ln -sf ${relative_flag} "$target" "$symlink"

}

