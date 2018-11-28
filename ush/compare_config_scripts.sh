#!/bin/sh

#
#-----------------------------------------------------------------------
#
# This script checks that all variables defined in the local configura-
# tion script (whose file name is stored in the variable LOCAL_CONFIG_-
# FN) are also assigned a default value in the default configuration
# script (whose file name is stored in the variable DEFAULT_CONFIG_FN).
#
#-----------------------------------------------------------------------
#

#
#-----------------------------------------------------------------------
#
# Source utility functions.
#
#-----------------------------------------------------------------------
#
. ./utility_funcs.sh
#
#-----------------------------------------------------------------------
#
# Save current shell options (in a global array).  Then set new options
# for this script/function.
#
#-----------------------------------------------------------------------
#
save_shell_opts
{ set -u; } > /dev/null 2>&1
#
#-----------------------------------------------------------------------
#
# Create a list of variable settings in the default workflow/experiment
# default script by stripping out comments, blank lines, extraneous 
# leading whitespace, etc from that script and saving the result in the
# variable var_list_default.  Each line of var_list_default will have 
# the form
#
#      VAR=...
#
# where the VAR is a variable name and ... is the value (including any 
# trailing comments).  Then create an equivalent list for the local con-
# figuration script and save the result in var_list_local.
#
#-----------------------------------------------------------------------
#
var_list_default=$( \
sed -r \
    -e "s/^([ ]*)([^ ]+.*)/\2/g" \
    -e "/^#.*/d" \
    -e "/^$/d" \
    ${DEFAULT_CONFIG_FN} \
)

var_list_local=$( \
sed -r \
    -e "s/^([ ]*)([^ ]+.*)/\2/g" \
    -e "/^#.*/d" \
    -e "/^$/d" \
    ${LOCAL_CONFIG_FN} \
)
#
#-----------------------------------------------------------------------
#
# Loop through each line of var_list_local.  For each line, extract the
# the name of the variable that is being set (say VAR) and check that 
# this variable is set somewhere in the default configuration script by
# verifying that a line that starts with "VAR=" exists in var_list_de-
# fault.
#
#-----------------------------------------------------------------------
#
while read crnt_line; do
#
# Note that a variable name will be found only if the equal sign immed-
# iately follows the variable name.
# 
  var_name=$( printf "%s" "${crnt_line}" | sed -n -r -e "s/^([^ ]*)=.*/\1/p")

  if [ -z "${var_name}" ]; then
    print_err_msg_exit "\
No variable name found in local configuration script \"${LOCAL_CONFIG_FN}\":
  crnt_line = \"${crnt_line}\"
  var_name = \"${var_name}\""
  fi
#
# Use a herestring to input list of variables in the default configura-
# tion file to grep.  Also, redirect the output to null because we are
# only interested in the exit status of grep (which will be nonzero if 
# the specified regex was not found in the list)..
#
  grep "^${var_name}=" <<< "${var_list_default}" > /dev/null 2>&1

  if [ $? -ne 0 ]; then
    print_err_msg_exit "\
Variable in local configuration script \"${LOCAL_CONFIG_FN}\" not set in default
configuration script \"${DEFAULT_CONFIG_FN}\":
  var_name = \"${var_name}\"
Please assign a default value to this variable in \"${DEFAULT_CONFIG_FN}\" 
and rerun."
  fi

done <<< "${var_list_local}"
#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script/func-
# tion.
#
#-----------------------------------------------------------------------
#
restore_shell_opts


