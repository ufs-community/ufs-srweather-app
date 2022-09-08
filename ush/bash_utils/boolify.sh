#
#-----------------------------------------------------------------------
#
# This file defines a function used to change a variety of input boolean
# strings to standard TRUE and FALSE
#
#-----------------------------------------------------------------------
#

function boolify() {
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
# Get the name of this function and input.
#
#-----------------------------------------------------------------------
#
  local func_name="${FUNCNAME[0]}"
  local input uc_input

  if [ "$#" -eq 1 ]; then
    input="$1"
  else

    print_err_msg_exit "
Incorrect number of arguments specified:

  Function name:  \"${func_name}\"
  Number of arguments specified:  $#

Usage:

  ${func_name}  string

where:

  string:
  This is the string that should be converted to TRUE or FALSE
"
  fi

  uc_input=$(echo_uppercase $input)
  if [ "$uc_input" = "TRUE" ] || \
       [ "$uc_input" = "YES" ]; then
    echo "TRUE"
  elif [ "$uc_input" = "FALSE" ] || \
         [ "$uc_input" = "NO" ]; then
    echo "FALSE"
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
