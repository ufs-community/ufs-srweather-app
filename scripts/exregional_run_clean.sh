#!/bin/bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. $USHdir/source_util_funcs.sh
source_config_for_task "task_run_clean" ${GLOBAL_VAR_DEFNS_FP}
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
# Get the full path to the file in which this script/function is located 
# (scrfunc_fp), the name of that file (scrfunc_fn), and the directory in
# which the file is located (scrfunc_dir).
#
#-----------------------------------------------------------------------
#
scrfunc_fp=$( $READLINK -f "${BASH_SOURCE[0]}" )
scrfunc_fn=$( basename "${scrfunc_fp}" )
scrfunc_dir=$( dirname "${scrfunc_fp}" )
#
#-----------------------------------------------------------------------
#
# Print message indicating entry into script.
#
#-----------------------------------------------------------------------
#
print_info_msg "
========================================================================
Entering script:  \"${scrfunc_fn}\"
In directory:     \"${scrfunc_dir}\"

This is the ex-script for the task that cleans directories.
========================================================================"
#
#
#-----------------------------------------------------------------------
# set up currentime from CDATE 
#-----------------------------------------------------------------------
#
currentime=$(echo "${CDATE}" | sed 's/\([[:digit:]]\{2\}\)$/ \1/')

listens=$(seq 1 $nens)

#-----------------------------------------------------------------------
# Delete COMOUT directories
#-----------------------------------------------------------------------
deletetime=$(date +%Y%m%d -d "${currentime} ${CLEAN_OLDPROD_HRS} hours ago")
echo "Deleting COMOUT directories before ${deletetime}..."
cd ${COMOUT_BASEDIR}
declare -a XX=$(ls -d ${RUN}.20* | sort -r)
for dir in ${XX[*]};do
  onetime=$(echo $dir | cut -d'.' -f2)
  if [[ ${onetime} =~ ^[0-9]+$ ]] && [[ ${onetime} -le ${deletetime} ]]; then
    rm -rf ${COMOUT_BASEDIR}/${RUN}.${onetime}
    echo "Deleted ${COMOUT_BASEDIR}/${RUN}.${onetime}"
  fi
done

#-----------------------------------------------------------------------
# Delete stmp directories
#-----------------------------------------------------------------------
deletetime=$(date +%Y%m%d%H -d "${currentime} ${CLEAN_OLDRUN_HRS} hours ago")
echo "Deleting DATA directories before ${deletetime}..."
cd ${DATAROOT}
#--- TODO ---#

#-----------------------------------------------------------------------
# Delete netCDF files
#-----------------------------------------------------------------------
deletetime=$(date +%Y%m%d%H -d "${currentime} ${CLEAN_OLDFCST_HRS} hours ago")
echo "Deleting netCDF files before ${deletetime}..."
cd ${COMIN_BASEDIR}
#--- TODO ---#

#-----------------------------------------------------------------------
# Delete duplicate postprod files in stmp
#-----------------------------------------------------------------------
deletetime=$(date +%Y%m%d%H -d "${currentime} ${CLEAN_OLDSTMPPOST_HRS} hours ago")
echo "Deleting stmp postprd files before ${deletetime}..."
cd ${COMIN_BASEDIR}
#--- TODO ---#

#-----------------------------------------------------------------------
# Delete old log files
#-----------------------------------------------------------------------
deletetime=$(date +%Y%m%d%H -d "${currentime} ${CLEAN_OLDLOG_HRS} hours ago")
echo "Deleting log files before ${deletetime}..."

# Remove template date from last two levels
logs=$(echo ${LOGDIR} | rev | cut -f 3- -d / | rev)
cd ${logs}
pwd
#--- TODO ---#

#-----------------------------------------------------------------------
# Delete nwges directories
#-----------------------------------------------------------------------
deletetime=$(date +%Y%m%d%H -d "${currentime} ${CLEAN_NWGES_HRS} hours ago")
echo "Deleting nwges directories before ${deletetime}..."
cd ${NWGES_BASEDIR}
declare -a XX=$(ls -d 20* | sort -r)
for onetime in ${XX[*]};do
  if [[ ${onetime} =~ ^[0-9]+$ ]] && [[ ${onetime} -le ${deletetime} ]]; then
    rm -rf ${NWGES_BASEDIR}/${onetime}
    echo "Deleted ${NWGES_BASEDIR}/${onetime}"
  fi
done

#
#-----------------------------------------------------------------------
#
# Print message indicating successful completion of script.
#
#-----------------------------------------------------------------------
#
print_info_msg "
========================================================================
Completed cleaning directories successfully.

Exiting script:  \"${scrfunc_fn}\"
In directory:    \"${scrfunc_dir}\"
========================================================================"
#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script/func-
# tion.
#
#-----------------------------------------------------------------------
#
{ restore_shell_opts; } > /dev/null 2>&1
