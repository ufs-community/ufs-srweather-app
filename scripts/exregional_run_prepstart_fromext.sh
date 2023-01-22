#!/bin/bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. $USHdir/source_util_funcs.sh
source_config_for_task "task_run_prepstart|task_run_fcst" ${GLOBAL_VAR_DEFNS_FP}
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
scrfunc_fp=$( readlink -f "${BASH_SOURCE[0]}" )
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
This is the ex-script for the task that runs a analysis with FV3 for the
specified cycle.
========================================================================"
#
#-----------------------------------------------------------------------
#
# Extract from CDATE the starting year, month, day, and hour of the
# forecast.  These are needed below for various operations.
#
#-----------------------------------------------------------------------
#
START_DATE=$(echo "${CDATE}" | sed 's/\([[:digit:]]\{2\}\)$/ \1/')

YYYYMMDDHH=$(date +%Y%m%d%H -d "${START_DATE}")
JJJ=$(date +%j -d "${START_DATE}")

YYYY=${YYYYMMDDHH:0:4}
MM=${YYYYMMDDHH:4:2}
DD=${YYYYMMDDHH:6:2}
HH=${YYYYMMDDHH:8:2}
YYYYMMDD=${YYYYMMDDHH:0:8}

current_time=$(date "+%T")

YYYYMMDDm1=$(date +%Y%m%d -d "${START_DATE} 1 days ago")
YYYYMMDDm2=$(date +%Y%m%d -d "${START_DATE} 2 days ago")
#
#-----------------------------------------------------------------------
#
# go to INPUT directory.
# prepare initial conditions for 
#     cold start if BKTYPE=1 
#     warm start if BKTYPE=0
#     spinupcyc + warm start if BKTYPE=2
#       the previous 6 cycles are searched to find the restart files
#       valid at this time from the closet previous cycle.
#
#-----------------------------------------------------------------------
cd_vrfy ${DATA}
bkpath=${FG_ROOT}/${YYYYMMDDHH}${SLASH_ENSMEM_SUBDIR}/fcst_fv3lam/INPUT  # cycling, use background from INPUT

checkfile=${bkpath}/coupler.res
#
restart_prefix=""
filelistn="fv_core.res.tile1.nc fv_srf_wnd.res.tile1.nc fv_tracer.res.tile1.nc phy_data.nc sfc_data.nc gfs_ctrl.nc"
n_iolayouty=$(($IO_LAYOUT_Y-1))
list_iolayout=$(seq 0 $n_iolayouty)
if [ -r "${checkfile}" ] ; then
  cp_vrfy ${bkpath}/${restart_prefix}coupler.res                bk_coupler.res
  cp_vrfy ${bkpath}/${restart_prefix}fv_core.res.nc             fv_core.res.nc
  if [ "${IO_LAYOUT_Y}" == "1" ]; then
    for file in ${filelistn}; do
      cp_vrfy ${bkpath}/${restart_prefix}${file}     ${file}
    done
  else
    for file in ${filelistn}; do
      for ii in $list_iolayout
      do
        iii=$(printf %4.4i $ii)
        cp_vrfy ${bkpath}/${restart_prefix}${file}.${iii}     ${file}.${iii}
      done
    done
  fi
  cp_vrfy ${FG_ROOT}/${YYYYMMDDHH}${SLASH_ENSMEM_SUBDIR}/fcst_fv3lam/INPUT/gfs_ctrl.nc  gfs_ctrl.nc
  if [ ${SAVE_CYCLE_LOG} == "TRUE" ] ; then
    echo "${YYYYMMDDHH}(${CYCLE_TYPE}): warm start at ${current_time} from ${checkfile} " >> ${EXPTDIR}/log.cycles
  fi
#
# remove checksum from restart files. Checksum will cause trouble if model initializes from analysis
#
  if [ "${IO_LAYOUT_Y}" == "1" ]; then
    for file in ${filelistn}; do
      ncatted -a checksum,,d,, ${file}
    done
  else
    for file in ${filelistn}; do
      for ii in $list_iolayout
      do
        iii=$(printf %4.4i $ii)
        ncatted -a checksum,,d,, ${file}.${iii}
      done
    done
  fi
  ncatted -a checksum,,d,, fv_core.res.nc

# generate coupler.res with right date
  head -1 bk_coupler.res > coupler.res
  tail -1 bk_coupler.res >> coupler.res
  tail -1 bk_coupler.res >> coupler.res
else
  print_err_msg_exit "Error: cannot find background: ${checkfile}"
fi

#-----------------------------------------------------------------------
#
# go to INPUT directory.
# prepare boundary conditions:
#       the previous 12 cycles are searched to find the boundary files
#       that can cover the forecast length.
#       The 0-h boundary is copied and others are linked.
#
#-----------------------------------------------------------------------

if [[ "${NET}" = "RTMA"* ]]; then
    #find a bdry file, make sure it exists and was written out completely.
    for i in $(seq 0 24); do #track back up to 24 cycles to find bdry files
      lbcDIR="${LBCS_ROOT}/$(date -d "${START_DATE} ${i} hours ago" +"%Y%m%d%H")/lbcs"
      if [[  -f ${lbcDIR}/gfs_bndy.tile7.001.nc ]]; then
        age=$(( $(date +%s) - $(date -r ${lbcDIR}/gfs_bndy.tile7.001.nc +%s) ))
        [[ age -gt 300 ]] && break
      fi
    done
    ln_vrfy -snf ${lbcDIR}/gfs_bndy.tile7.000.nc .
    ln_vrfy -snf ${lbcDIR}/gfs_bndy.tile7.001.nc .

else
  num_fhrs=( "${#FCST_LEN_HRS_CYCLES[@]}" )
  ihh=$( expr ${HH} + 0 )
  if [ ${num_fhrs} -gt ${ihh} ]; then
     FCST_LEN_HRS_thiscycle=${FCST_LEN_HRS_CYCLES[${ihh}]}
  else
     FCST_LEN_HRS_thiscycle=${FCST_LEN_HRS}
  fi
  if [ ${CYCLE_TYPE} == "spinup" ]; then
     FCST_LEN_HRS_thiscycle=${FCST_LEN_HRS_SPINUP}
  fi 
  print_info_msg "$VERBOSE" " The forecast length for cycle (\"${HH}\") is
                 ( \"${FCST_LEN_HRS_thiscycle}\") "

#   let us figure out which boundary file is available
  bndy_prefix=gfs_bndy.tile7
  n=${EXTRN_MDL_LBCS_SEARCH_OFFSET_HRS}
  end_search_hr=$(( 12 + ${EXTRN_MDL_LBCS_SEARCH_OFFSET_HRS} ))
  YYYYMMDDHHmInterv=$(date +%Y%m%d%H -d "${START_DATE} ${n} hours ago")
  lbcs_path=${LBCS_ROOT}/${YYYYMMDDHHmInterv}${SLASH_ENSMEM_SUBDIR}/lbcs
  while [[ $n -le ${end_search_hr} ]] ; do
    last_bdy_time=$(( n + ${FCST_LEN_HRS_thiscycle} ))
    last_bdy=$(printf %3.3i $last_bdy_time)
    checkfile=${lbcs_path}/${bndy_prefix}.${last_bdy}.nc
    if [ -r "${checkfile}" ]; then
      print_info_msg "$VERBOSE" "Found ${checkfile}; Use it as boundary for forecast "
      break
    else
      n=$((n + 1))
      YYYYMMDDHHmInterv=$(date +%Y%m%d%H -d "${START_DATE} ${n} hours ago")
      lbcs_path=${LBCS_ROOT}/${YYYYMMDDHHmInterv}${SLASH_ENSMEM_SUBDIR}/lbcs
    fi
  done
#
  relative_or_null="--relative"
  nb=1
  if [ -r "${checkfile}" ]; then
    while [ $nb -le ${FCST_LEN_HRS_thiscycle} ]
    do
      bdy_time=$(( ${n} + ${nb} ))
      this_bdy=$(printf %3.3i $bdy_time)
      local_bdy=$(printf %3.3i $nb)

      if [ -f "${lbcs_path}/${bndy_prefix}.${this_bdy}.nc" ]; then
        ln_vrfy -sf ${relative_or_null} ${lbcs_path}/${bndy_prefix}.${this_bdy}.nc ${bndy_prefix}.${local_bdy}.nc
      fi

      nb=$((nb + 1))
    done
# check 0-h boundary condition
    if [ ! -f "${bndy_prefix}.000.nc" ]; then
      this_bdy=$(printf %3.3i ${n})
      cp_vrfy ${lbcs_path}/${bndy_prefix}.${this_bdy}.nc ${bndy_prefix}.000.nc 
    fi
  else
    print_err_msg_exit "Error: cannot find boundary file: ${checkfile}"
  fi

fi 
#
#-----------------------------------------------------------------------
#
# Print message indicating successful completion of script.
#
#-----------------------------------------------------------------------
#
print_info_msg "
========================================================================
Prepare start completed successfully!!!
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
