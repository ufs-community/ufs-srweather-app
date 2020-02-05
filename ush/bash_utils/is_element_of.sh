#
#-----------------------------------------------------------------------
#
# For a description of this function, see the usage message below.
# 
#-----------------------------------------------------------------------
#
function is_element_of() { 
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

  ${func_name}  array_name  str_to_match

This function checks whether the specified array contains the specified
string, i.e. whether at least one of the elements of the array is equal
to the string.  The return code from this function will be zero if at 
least one match is found and nonzero if no matches are found.

The arguments to this function are defined as follows:

  array_name:
  The name of the array in which to search for str_to_match.  Note that
  this is the name of the array, not the array itself.

  str_to_match:
  The string to search for in array_name.

Use this function in a script as follows:

  . ./is_element_of.sh
  array_name=("1" "2" "3 4" "5")

  str_to_match="2"
  is_element_of "${str_to_match}" array_name
  echo $?  # Should output 0.

  str_to_match="3 4"
  is_element_of "${str_to_match}" array_name
  echo $?  # Should output 0.

  str_to_match="6"
  is_element_of "${str_to_match}" array_name
  echo $?  # Should output 1.
"

  fi
#
#-----------------------------------------------------------------------
#
# Declare local variables.
#
#-----------------------------------------------------------------------
#
  local array_name \
        str_to_match \
        array_name_at \
        array \
        found_match \
        num_elems \
        n
#
#-----------------------------------------------------------------------
#
# Set local variables to appropriate input arguments.
#
#-----------------------------------------------------------------------
#
  array_name="$1"
  str_to_match="$2"

  array_name_at="$array_name[@]"
  array=("${!array_name_at}")
#
#-----------------------------------------------------------------------
#
# Initialize the return variable found_match to 1 (false).  Then loop
# through the elements of the array and check whether each element is
# equal to str_to_match.  Once a match is found, reset found_match to 0
# (true) and break out of the loop.
#
#-----------------------------------------------------------------------
#
  found_match=1
  num_elems=${#array[@]}
  for (( n=0; n<${num_elems}; n++ )); do
    if [ "${array[$n]}" = "${str_to_match}" ]; then
      found_match=0
      break
    fi
  done
#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script/func-
# tion.
#
#-----------------------------------------------------------------------
#
  { restore_shell_opts; } > /dev/null 2>&1
#
#-----------------------------------------------------------------------
#
# Return the variable found_match.
#
#-----------------------------------------------------------------------
#
  return ${found_match}

}

