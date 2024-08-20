#!/usr/bin/env bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. ${USHsrw}/source_util_funcs.sh
for sect in user nco platform workflow nco global smoke_dust_parm \
  constants fixed_files grid_params task_run_fcst ; do
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
{ save_shell_opts; set -xue; } > /dev/null 2>&1
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

This is the ex-script for the task that runs prepstart.
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
YYYYJJJHH=${YYYY}${JJJ}${HH}

current_time=$(date "+%T")
cdate_crnt_fhr=$( date --utc --date "${YYYYMMDD} ${HH} UTC" "+%Y%m%d%H" )

YYYYMMDDm1=$(date +%Y%m%d -d "${START_DATE} 1 days ago")
YYYYMMDDm2=$(date +%Y%m%d -d "${START_DATE} 2 days ago")
YYYYMMDDm3=$(date +%Y%m%d -d "${START_DATE} 3 days ago")

#-----------------------------------------------------------------------
#
#  smoke/dust cycling
#
#-----------------------------------------------------------------------
if [ "${DO_SMOKE_DUST}" = "TRUE" ] && [ "${CYCLE_TYPE}" = "spinup" ]; then  # cycle smoke/dust fields
  if_cycle_smoke_dust="FALSE"
  if [ ${HH} -eq 4 ] || [ ${HH} -eq 16 ] ; then
     if_cycle_smoke_dust="TRUE"
  elif [ ${HH} -eq 6 ] && [ -f ${COMOUT}/../04_spinup/cycle_smoke_dust_skipped.txt ]; then
     if_cycle_smoke_dust="TRUE"
  elif [ ${HH} -eq 18 ] && [ -f ${COMOUT}/../16_spinup/cycle_smoke_dust_skipped.txt ]; then
     if_cycle_smoke_dust="TRUE"
  fi
  if [ "${if_cycle_smoke_dust}" = "TRUE" ] ; then
      # figure out which surface is available
      surface_file_dir_name=fcst_fv3lam
      bkpath_find="missing"
      restart_prefix_find="missing"
      restart_prefix=$( date +%Y%m%d.%H0000. -d "${START_DATE}" )
      if [ "${bkpath_find}" = "missing" ]; then

          offset_hours=${DA_CYCLE_INTERV}
          YYYYMMDDHHmInterv=$( date +%Y%m%d%H -d "${START_DATE} ${offset_hours} hours ago" )
          bkpath=${fg_root}/${YYYYMMDDHHmInterv}${SLASH_ENSMEM_SUBDIR}/${surface_file_dir_name}/RESTART

          n=${DA_CYCLE_INTERV}
          while [[ $n -le 25 ]] ; do
             if [ "${IO_LAYOUT_Y}" = "1" ]; then
               checkfile=${bkpath}/${restart_prefix}fv_tracer.res.tile1.nc
             else
               checkfile=${bkpath}/${restart_prefix}fv_tracer.res.tile1.nc.0000
             fi
             if [ -r "${checkfile}" ] && [ "${bkpath_find}" = "missing" ]; then
               bkpath_find=${bkpath}
               restart_prefix_find=${restart_prefix}
               print_info_msg "$VERBOSE" "Found ${checkfile}; Use it for smoke/dust cycle "
               break
             fi
 
             n=$((n + ${DA_CYCLE_INTERV}))
             offset_hours=${n}
             YYYYMMDDHHmInterv=$( date +%Y%m%d%H -d "${START_DATE} ${offset_hours} hours ago" )
             bkpath=${fg_root}/${YYYYMMDDHHmInterv}${SLASH_ENSMEM_SUBDIR}/${surface_file_dir_name}/RESTART  # cycling, use background from RESTART
             print_info_msg "$VERBOSE" "Trying this path: ${bkpath}"
          done
      fi

      # check if there are tracer file in continue cycle data space:
      if [ "${bkpath_find}" = "missing" ]; then
         checkfile=${CONT_CYCLE_DATA_ROOT}/tracer/${restart_prefix}fv_tracer.res.tile1.nc
         if [ -r "${checkfile}" ]; then
            bkpath_find=${CONT_CYCLE_DATA_ROOT}/tracer
            restart_prefix_find=${restart_prefix}
            print_info_msg "$VERBOSE" "Found ${checkfile}; Use it for smoke/dust cycle "
         fi
      fi

      # cycle smoke/dust
      rm -f cycle_smoke_dust.done
      if [ "${bkpath_find}" = "missing" ]; then
        print_info_msg "Warning: cannot find smoke/dust files from previous cycle"
        touch ${COMOUT}/cycle_smoke_dust_skipped.txt
      else
        if [ "${IO_LAYOUT_Y}" = "1" ]; then
          checkfile=${bkpath_find}/${restart_prefix_find}fv_tracer.res.tile1.nc
          if [ -r "${checkfile}" ]; then
            ncks -A -v smoke,dust,coarsepm ${checkfile}  fv_tracer.res.tile1.nc
          fi
        else
          for ii in ${list_iolayout}
          do
            iii=$(printf %4.4i $ii)
            checkfile=${bkpath_find}/${restart_prefix_find}fv_tracer.res.tile1.nc.${iii}
            if [ -r "${checkfile}" ]; then
              ncks -A -v smoke,dust,coarsepm ${checkfile}  fv_tracer.res.tile1.nc.${iii}
            fi
          done
        fi
        echo "${YYYYMMDDHH}(${CYCLE_TYPE}): cycle smoke/dust from ${checkfile} " >> ${EXPTDIR}/log.cycles
      fi
  fi
fi

#-----------------------------------------------------------------------
#
#  smoke/dust cycling for Retros
#
#-----------------------------------------------------------------------

if [ "${DO_SMOKE_DUST}" = "TRUE" ]; then
      surface_file_dir_name=fcst_fv3lam
      bkpath_find="missing"
      restart_prefix_find="missing"
      if [ "${bkpath_find}" = "missing" ]; then
          restart_prefix=$( date +%Y%m%d.%H0000. -d "${START_DATE}" )

          offset_hours=${DA_CYCLE_INTERV}
          YYYYMMDDHHmInterv=$( date +%Y%m%d%H -d "${START_DATE} ${offset_hours} hours ago" )
          bkpath=${fg_root}/${YYYYMMDDHHmInterv}${SLASH_ENSMEM_SUBDIR}/${surface_file_dir_name}/RESTART

          n=${DA_CYCLE_INTERV}
          while [[ $n -le 25 ]] ; do
             if [ "${IO_LAYOUT_Y}" = "1" ]; then
               checkfile=${bkpath}/${restart_prefix}fv_tracer.res.tile1.nc
             else
               checkfile=${bkpath}/${restart_prefix}fv_tracer.res.tile1.nc.0000
             fi
             if [ -r "${checkfile}" ] && [ "${bkpath_find}" = "missing" ]; then
               bkpath_find=${bkpath}
               restart_prefix_find=${restart_prefix}
               print_info_msg "$VERBOSE" "Found ${checkfile}; Use it for smoke/dust cycle "
               break
             fi
             n=$((n + ${DA_CYCLE_INTERV}))
             offset_hours=${n}
             YYYYMMDDHHmInterv=$( date +%Y%m%d%H -d "${START_DATE} ${offset_hours} hours ago" )
             bkpath=${fg_root}/${YYYYMMDDHHmInterv}${SLASH_ENSMEM_SUBDIR}/${surface_file_dir_name}/RESTART  # cycling, use background from RESTART
             print_info_msg "$VERBOSE" "Trying this path: ${bkpath}"
          done
      fi

      # cycle smoke/dust
      rm -f cycle_smoke_dust.done
      if [ "${bkpath_find}" = "missing" ]; then
        print_info_msg "Warning: cannot find smoke/dust files from previous cycle"
      else
        if [ "${IO_LAYOUT_Y}" = "1" ]; then
          checkfile=${bkpath_find}/${restart_prefix_find}fv_tracer.res.tile1.nc
          if [ -r "${checkfile}" ]; then
            ncks -A -v smoke,dust,coarsepm ${checkfile}  fv_tracer.res.tile1.nc
          fi
        else
          for ii in ${list_iolayout}
          do
            iii=$(printf %4.4i $ii)
            checkfile=${bkpath_find}/${restart_prefix_find}fv_tracer.res.tile1.nc.${iii}
            if [ -r "${checkfile}" ]; then
              ncks -A -v smoke,dust,coarsepm ${checkfile}  fv_tracer.res.tile1.nc.${iii}
            fi
          done
        fi
        echo "${YYYYMMDDHH}(${CYCLE_TYPE}): cycle smoke/dust from ${checkfile} " >> ${EXPTDIR}/log.cycles
      fi

  ${USHsrw}/add_smoke.py
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
PREPSTART has successfully been complete !!!!

Exiting script:  \"${scrfunc_fn}\"
In directory:    \"${scrfunc_dir}\"
========================================================================"
#
#-----------------------------------------------------------------------
#
{ restore_shell_opts; } > /dev/null 2>&1
