#
#-----------------------------------------------------------------------
#
# This file defines and then calls a function that checks that all vari-
# ables defined in the user-specified experiment/workflow configuration 
# file (whose file name is stored in the variable EXPT_CONFIG_FN) are 
# also assigned default values in the default configuration file (whose 
# file name is stored in the variable EXPT_DEFAULT_CONFIG_FN).
#
#-----------------------------------------------------------------------
#
function compare_config_scripts() {
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
# Source bash utility functions.
#
#-----------------------------------------------------------------------
#
. ${scrfunc_dir}/source_util_funcs.sh
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
# Create a list of variable settings in the default workflow/experiment
# file (script) by stripping out comments, blank lines, extraneous lead-
# ing whitespace, etc from that file and saving the result in the varia-
# ble var_list_default.  Each line of var_list_default will have the 
# form
#
#      VAR=...
#
# where the VAR is a variable name and ... is the value (including any 
# trailing comments).  Then create an equivalent list for the local con-
# figuration file and save the result in var_list_local.
#
#-----------------------------------------------------------------------
#
var_list_default=$( \
$SED -r \
    -e "s/^([ ]*)([^ ]+.*)/\2/g" \
    -e "/^#.*/d" \
    -e "/^$/d" \
    ${EXPT_DEFAULT_CONFIG_FN} \
)

var_list_local=$( \
$SED -r \
    -e "s/^([ ]*)([^ ]+.*)/\2/g" \
    -e "/^#.*/d" \
    -e "/^$/d" \
    ${EXPT_CONFIG_FN} \
)
#
#-----------------------------------------------------------------------
#
# Loop through each line of var_list_local.  For each line, extract the
# the name of the variable that is being set (say VAR) and check that 
# this variable is set somewhere in the default configuration file by
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
  var_name=$( printf "%s" "${crnt_line}" | $SED -n -r -e "s/^([^ =\"]*)=.*/\1/p")

  if [ -z "${var_name}" ]; then

    print_info_msg "
Current line (crnt_line) of user-specified experiment/workflow configu-
ration file (EXPT_CONFIG_FN) does not contain a variable name (i.e. 
var_name is empty):
  EXPT_CONFIG_FN = \"${EXPT_CONFIG_FN}\"
  crnt_line = \"${crnt_line}\"
  var_name = \"${var_name}\"
Skipping to next line."

  else
#
# Use a herestring to input list of variables in the default configura-
# tion file to grep.  Also, redirect the output to null because we are
# only interested in the exit status of grep (which will be nonzero if 
# the specified regex was not found in the list)..
#
    grep "^${var_name}=" <<< "${var_list_default}" > /dev/null 2>&1 || \
    print_err_msg_exit "\
The variable specified by var_name in the user-specified experiment/
workflow configuration file (EXPT_CONFIG_FN) does not appear in the de-
fault experiment/workflow configuration file (EXPT_DEFAULT_CONFIG_FN):
  EXPT_CONFIG_FN = \"${EXPT_CONFIG_FN}\"
  EXPT_DEFAULT_CONFIG_FN = \"${EXPT_DEFAULT_CONFIG_FN}\"
  var_name = \"${var_name}\"
Please assign a default value to this variable in the default configura-
tion file and rerun."

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
{ restore_shell_opts; } > /dev/null 2>&1

}
#
#-----------------------------------------------------------------------
#
# Call the function defined above.
#
#-----------------------------------------------------------------------
#
compare_config_scripts

