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

}
