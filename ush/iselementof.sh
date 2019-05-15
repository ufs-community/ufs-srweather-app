#
#-----------------------------------------------------------------------
#
# This file defines a function that is used to check whether a given ar-
# ray contains a specified string as one of its elements.  It is called
# as follows:
#
#   iselemof "$str_to_match" array_name
#
# where $str_to_match is the string to find in the array array_name.
# Use this function in a script as follows:
#
#   . ./iselementof.sh
#   array_name=("1" "2" "3 4" "5")
#
#   str_to_match="2"
#   iselementof "$str_to_match" array_name
#   echo $?  # Should output 0.
#
#   str_to_match="3 4"
#   iselementof "$str_to_match" array_name
#   echo $?  # Should output 0.
#
#   str_to_match="6"
#   iselementof "$str_to_match" array_name
#   echo $?  # Should output 1.
#
# Note that the first argument to this function is the array name (with-
# out a "$" before it or "[@]" after it).
# 
#-----------------------------------------------------------------------
#
function iselementof () { 
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
  if [ "$#" -ne 2 ]; then
    print_err_msg_exit "\
Function \"${FUNCNAME[0]}\":  Incorrect number of arguments specified.
Usage:

  ${FUNCNAME[0]} str_to_match array_name

where the arguments are defined as follows:

  str_to_match:
  The string to find in array_name (as one of its elements).

  array_name:
  The name of the array to search.
 
"

  fi
#
#-----------------------------------------------------------------------
#
# Set local variables to appropriate input arguments.
#
#-----------------------------------------------------------------------
#
  local match="$1"
  local array="$2[@]"
#
#-----------------------------------------------------------------------
#
# Loop through the array elements and look for $match in the array.  If
# it is found, set contains to 0.  Otherwise, set it to 1.
#
#-----------------------------------------------------------------------
#
  local contains=1
  local element
  for element in "${!array}"; do
    if [ "$element" = "$match" ]; then
      contains=0
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
# Return the variable "contains".
#
#-----------------------------------------------------------------------
#
  return $contains
}

