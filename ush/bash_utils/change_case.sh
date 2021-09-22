#
#-----------------------------------------------------------------------
#
# This file defines functions used to change string to all uppercase or
# all lowercase
#
#-----------------------------------------------------------------------
#


#
#-----------------------------------------------------------------------
#
# Function to echo the given string as an uppercase string
#
#-----------------------------------------------------------------------
#
function echo_uppercase() {
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
# Get information about the script or function that calls this function.
# Note that caller_name will be set as follows:
#
# 1) If the caller is a function, caller_name will be set to the name of
#    that function.
# 2) If the caller is a sourced script, caller_name will be set to
#    "script".  Note that a sourced script cannot be the top level
#    script since by defintion, it is sourced by another script or func-
#    tion.
# 3) If the caller is the top-level script, caller_name will be set to
#    "main".
#
# Thus, if caller_name is set to "script" or "main", the caller is a
# script, and if it is set to anything else, the caller is a function.
#
#-----------------------------------------------------------------------
#
  local caller_fp=$( $READLINK -f "${BASH_SOURCE[1]}" )
  local caller_fn=$( basename "${caller_fp}" )
  local caller_dir=$( dirname "${caller_fp}" )
  local caller_name="${FUNCNAME[1]}"
#
# Get input string

  local input

  if [ "$#" -eq 1 ]; then

    input="$1"

#
#-----------------------------------------------------------------------
#
# If no arguments or more than one, print out a usage message and exit.
#
#-----------------------------------------------------------------------
#
  else

    print_err_msg_exit "
Incorrect number of arguments specified:

  Function name:  \"${func_name}\"
  Number of arguments specified:  $#

Usage:

  ${func_name}  string

where:

  string:
  This is the string that should be converted to uppercase and echoed.
"

  fi

# Echo the input string as upperercase

echo $input| tr '[a-z]' '[A-Z]'

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


#
#-----------------------------------------------------------------------
#
# Function to echo the given string as a lowercase string
#
#-----------------------------------------------------------------------
#
function echo_lowercase() {
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
# Get information about the script or function that calls this function.
# Note that caller_name will be set as follows:
#
# 1) If the caller is a function, caller_name will be set to the name of 
#    that function.
# 2) If the caller is a sourced script, caller_name will be set to 
#    "script".  Note that a sourced script cannot be the top level 
#    script since by defintion, it is sourced by another script or func-
#    tion.
# 3) If the caller is the top-level script, caller_name will be set to
#    "main".
#
# Thus, if caller_name is set to "script" or "main", the caller is a 
# script, and if it is set to anything else, the caller is a function.
#
#-----------------------------------------------------------------------
#
  local caller_fp=$( $READLINK -f "${BASH_SOURCE[1]}" )
  local caller_fn=$( basename "${caller_fp}" )
  local caller_dir=$( dirname "${caller_fp}" )
  local caller_name="${FUNCNAME[1]}"
#
# Get input string

  local input

  if [ "$#" -eq 1 ]; then

    input="$1"
    
#
#-----------------------------------------------------------------------
#
# If no arguments or more than one, print out a usage message and exit.
#
#-----------------------------------------------------------------------
#
  else

    print_err_msg_exit "
Incorrect number of arguments specified:

  Function name:  \"${func_name}\"
  Number of arguments specified:  $#

Usage:

  ${func_name}  string

where:

  string:
  This is the string that should be converted to lowercase and echoed.
"

  fi

# Echo the input string as lowercase

echo $input| tr '[A-Z]' '[a-z]'

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

