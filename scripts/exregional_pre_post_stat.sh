#!/bin/bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. $USHdir/source_util_funcs.sh
source_config_for_task "cpl_aqm_parm" ${GLOBAL_VAR_DEFNS_FP}
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

This is the ex-script for the task that runs POST-UPP-STAT.
========================================================================"
#
#-----------------------------------------------------------------------
#
# Set OpenMP variables.
#
#-----------------------------------------------------------------------
#
export KMP_AFFINITY=${KMP_AFFINITY_PRE_POST_STAT}
export OMP_NUM_THREADS=${OMP_NUM_THREADS_PRE_POST_STAT}
export OMP_STACKSIZE=${OMP_STACKSIZE_PRE_POST_STAT}
#
#-----------------------------------------------------------------------
#
# Set run command.
#
#-----------------------------------------------------------------------
#
eval ${PRE_TASK_CMDS}

if [ -z "${RUN_CMD_SERIAL:-}" ] ; then
  print_err_msg_exit "\
  Run command was not set in machine file. \
  Please set RUN_CMD_SERIAL for your platform"
else
  RUN_CMD_SERIAL=$(eval echo ${RUN_CMD_SERIAL})
  print_info_msg "$VERBOSE" "
  All executables will be submitted with command \'${RUN_CMD_SERIAL}\'."
fi

#
#-----------------------------------------------------------------------
#
# Move to the working directory
#
#-----------------------------------------------------------------------
#
DATA="${DATA}/tmp_PRE_POST_STAT"
rm_vrfy -r $DATA
mkdir_vrfy -p "$DATA"
cd_vrfy $DATA

set -x

if [ "${FCST_LEN_HRS}" = "-1" ]; then
  for i_cdate in "${!ALL_CDATES[@]}"; do
    if [ "${ALL_CDATES[$i_cdate]}" = "${PDY}${cyc}" ]; then
      FCST_LEN_HRS="${FCST_LEN_CYCL[$i_cdate]}"
      break
    fi
  done
fi

ist=1
while [ "$ist" -le "${FCST_LEN_HRS}" ]; do
  hst=$( printf "%03d" "${ist}" )

  rm_vrfy -f ${DATA}/tmp*nc
  rm_vrfy -f ${DATA}/${NET}.${cycle}.chem_sfc_f${hst}*nc
  rm_vrfy -f ${DATA}/${NET}.${cycle}.met_sfc_f${hst}*nc

  ncks -v lat,lon,o3_ave,no_ave,no2_ave,pm25_ave -d pfull,63,63 ${COMIN}/${NET}.${cycle}.dyn.f${hst}.nc ${DATA}/tmp2a.nc

  ncks -C -O -x -v pfull ${DATA}/tmp2a.nc ${DATA}/tmp2b.nc

  ncwa -a pfull ${DATA}/tmp2b.nc ${DATA}/tmp2c.nc

  ncrename -v o3_ave,o3 -v no_ave,no -v no2_ave,no2 -v pm25_ave,PM25_TOT ${DATA}/tmp2c.nc

  mv_vrfy ${DATA}/tmp2c.nc ${DATA}/${NET}.${cycle}.chem_sfc.f${hst}.nc

  ncks -v dswrf,hpbl,tmp2m,ugrd10m,vgrd10m,spfh2m ${COMIN}/${NET}.${cycle}.phy.f${hst}.nc ${DATA}/${NET}.${cycle}.met_sfc.f${hst}.nc

  (( ist=ist+1 ))
done

ist=1
while [ "${ist}" -le "${FCST_LEN_HRS}" ]; do
  hst=$( printf "%03d" "${ist}" )
  ic=0
  while [ $ic -lt 900 ]; do
    if [ -s ${DATA}/${NET}.${cycle}.chem_sfc.f${hst}.nc ]; then
      echo "${DATA}/${NET}.${cycle}.chem_sfc.f${hst}.nc" "exist!"
      break
    else
      sleep 10
      (( ic=ic+1 ))
    fi
  done
  (( ist=ist+1 ))
done

ncecat ${DATA}/${NET}.${cycle}.chem_sfc.f*.nc  ${DATA}/${NET}.${cycle}.chem_sfc.nc

#
#-----------------------------------------------------------------------
#
# Move output to COMIN directory.
#
#-----------------------------------------------------------------------
#
mv_vrfy ${DATA}/${NET}.${cycle}.met_sfc.f*.nc ${COMIN}
mv_vrfy ${DATA}/${NET}.${cycle}.chem_sfc.f*.nc ${COMIN}
mv_vrfy ${DATA}/${NET}.${cycle}.chem_sfc.nc ${COMIN}
#
#-----------------------------------------------------------------------
#
# Print message indicating successful completion of script.
#
#-----------------------------------------------------------------------
#
print_info_msg "
========================================================================
PRE-POST-STAT completed successfully.

Exiting script:  \"${scrfunc_fn}\"
In directory:    \"${scrfunc_dir}\"
========================================================================"
#
#-----------------------------------------------------------------------
#
{ restore_shell_opts; } > /dev/null 2>&1
