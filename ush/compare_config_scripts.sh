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
# Change shell behavior with "set" with these flags:
#
# -a
# This will cause the script to automatically export all variables and
# functions which are modified or created to the environments of subse-
# quent commands.
#
# -e
# This will cause the script to exit as soon as any line in the script
# fails (with some exceptions; see manual).  Apparently, it is a bad
# idea to use "set -e".  See here:
#   http://mywiki.wooledge.org/BashFAQ/105
#
# -u
# This will cause the script to exit if an undefined variable is encoun-
# tered.
#
# -x
# This will cause all executed commands in the script to be printed to
# the terminal (used for debugging).
#
#-----------------------------------------------------------------------
#
#set -aux
#set -eux
set -ux
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
  var_name=$(echo ${crnt_line} | sed -n -r -e "s/^([^ ]*)=.*/\1/p")

  if [ -z "${var_name}" ]; then
    MSG=$(printf "\
Error:
No variable name found in local configuration script \"${LOCAL_CONFIG_FN}\":
  crnt_line = \"${crnt_line}\"
  var_name = \"${var_name}\"
Exiting script.
")
    printf '%s\n' "$MSG"
    exit 1
  fi

  grep "^${var_name}=" <<< "${var_list_default}"
  if [ $? -ne 0 ]; then
    MSG=$(printf "\
Error:
Variable in local configuration script \"${LOCAL_CONFIG_FN}\" not set in default
configuration script \"${DEFAULT_CONFIG_FN}\":
  var_name = \"${var_name}\"
Please assign a default value to this variable in \"${DEFAULT_CONFIG_FN}\" 
and rerun.
Exiting script.
")
    printf '%s\n' "$MSG"
    exit 1
  fi

done <<< "${var_list_local}"


