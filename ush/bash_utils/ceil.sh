#
#-----------------------------------------------------------------------
#
# This function returns the ceiling of the quotient of two numbers.  The
# ceiling of a number is the number rounded up to the nearest integer.
#
#-----------------------------------------------------------------------
#
function ceil() {
#
#-----------------------------------------------------------------------
#
# Save current shell options (in a global array).  Then set new options
# for this script/function.
#
#-----------------------------------------------------------------------
#
  { save_shell_opts; . ${USHdir}/preamble.sh; } > /dev/null 2>&1
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
# Check number of arguments.
#
#-----------------------------------------------------------------------
#
  if [ "$#" -ne 2 ]; then

    print_err_msg_exit "
Incorrect number of arguments specified:

  Function name:  \"${func_name}\"
  Number of arguments specified:  $#

Usage:

  ${func_name} numer denom

where denom is a nonnegative integer and denom is a positive integer.
"

  fi
#
#-----------------------------------------------------------------------
#
# Make sure arguments are of the right form.
#
#-----------------------------------------------------------------------
#
  local numer="$1"
  local denom="$2"

  if ! [[ "${numer}" =~ ^[0-9]+$ ]]; then
    print_err_msg_exit "
The first argument to the \"${func_name}\" function (numer) must be a nonnegative
integer but isn't:
  numer = ${numer}
"
  fi

  if [[ "${denom}" -eq 0 ]]; then
    print_err_msg_exit "
The second argument to the \"${func_name}\" function (denom) cannot be zero:
  denom = ${denom}
"
  fi

  if ! [[ "${denom}" =~ ^[0-9]+$ ]]; then
    print_err_msg_exit "
The second argument to the \"${func_name}\" function (denom) must be a positive
integer but isn't:
  denom = ${denom}
"
  fi
#
#-----------------------------------------------------------------------
#
# Let ceil(a,b) denote the ceiling of the quotient of a and b.  It can be
# shown that for two positive integers a and b, we have:
#
#   ceil(a,b) = floor((a+b-1)/b)
#
# where floor(a,b) is the integer obtained by rounding the quotient of
# a and b (i.e. a/b) down to the nearest integer.  Since in bash a
# division returns only the integer part of the result, it is effectively
# the floor function.  Thus the following.
#
#-----------------------------------------------------------------------
#
  result=$(( (numer+denom-1)/denom ))
  print_info_msg "${result}"
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

