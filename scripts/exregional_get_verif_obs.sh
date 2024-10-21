#!/usr/bin/env bash

#
#-----------------------------------------------------------------------
#
# The ex-script that checks, pulls, and stages observation data for
# model verification.
#
# Run-time environment variables:
#
#    FHR
#    GLOBAL_VAR_DEFNS_FP
#    OBS_DIR
#    OBTYPE
#    PDY
#    VAR
#
# Experiment variables
#
#   user:
#    USHdir
#    PARMdir
#
#-----------------------------------------------------------------------

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. $USHdir/source_util_funcs.sh
for sect in user workflow nco ; do
  source_yaml ${GLOBAL_VAR_DEFNS_FP} ${sect}
done
#
#-----------------------------------------------------------------------
#
# Save current shell options (in a global array).  Then set new options
# for this script/function.
#
#-----------------------------------------------------------------------
#
{ save_shell_opts; . $USHdir/preamble.sh; } > /dev/null 2>&1
#
#-----------------------------------------------------------------------
#
# Make sure the obs type is valid.  Then call a python script to check
# for the presence of obs files on disk and get them if needed.
#
#-----------------------------------------------------------------------
#
valid_obtypes=("CCPA" "MRMS" "NDAS" "NOHRSC")
if [[ ! ${valid_obtypes[@]} =~ ${OBTYPE} ]]; then
  print_err_msg_exit "\
Invalid observation type (OBTYPE) specified for script:
  OBTYPE = \"${OBTYPE}\"
Valid observation types are:
  $(printf "\"%s\" " ${valid_obtypes[@]})
"
fi

cmd="\
python3 -u ${USHdir}/get_obs.py \
--var_defns_path "${GLOBAL_VAR_DEFNS_FP}" \
--obtype ${OBTYPE} \
--obs_day ${PDY}"
print_info_msg "
CALLING: ${cmd}"
${cmd} || print_err_msg_exit "Error calling ${script_bn}.py."
#
#-----------------------------------------------------------------------
#
# Create flag file that indicates completion of task.  This is needed by
# the workflow.
#
#-----------------------------------------------------------------------
#
mkdir -p ${WFLOW_FLAG_FILES_DIR}
file_bn="get_obs_$(echo_lowercase ${OBTYPE})"
touch "${WFLOW_FLAG_FILES_DIR}/${file_bn}_${PDY}_complete.txt"
#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script/func-
# tion.
#
#-----------------------------------------------------------------------
#
{ restore_shell_opts; } > /dev/null 2>&1

