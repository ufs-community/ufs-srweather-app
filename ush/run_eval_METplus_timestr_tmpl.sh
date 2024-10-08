#!/usr/bin/env bash
#
#-----------------------------------------------------------------------
#
# This script is simply a wrapper to the eval_METplus_timestr_tmpl bash
# function.  It is needed in order to enable the function to be called
# from a python script.
#
#-----------------------------------------------------------------------
#
set -u
. $USHdir/source_util_funcs.sh
eval_METplus_timestr_tmpl \
  init_time="${yyyymmdd_task}00" \
  fhr="${lhr}" \
  METplus_timestr_tmpl="${METplus_timestr_tmpl}" \
  outvarname_evaluated_timestr="fp_proc"
echo "${fp_proc}"
