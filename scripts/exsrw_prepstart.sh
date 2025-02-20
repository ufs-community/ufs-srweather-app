#!/usr/bin/env bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. ${USHdir}/source_util_funcs.sh
for sect in user nco platform workflow global smoke_dust_parm \
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
set -xue
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
#  update IC files
#
#-----------------------------------------------------------------------
if [ $(boolify "${COLDSTART}") = "TRUE" ] && [ "${PDY}${cyc}" = "${DATE_FIRST_CYCL:0:10}" ]; then
  echo "This step is skipped for the first cycle of COLDSTART."
else
  eval ${PRE_TASK_CMDS}  
  if [ $(boolify "${DO_SMOKE_DUST}") = "TRUE" ]; then
    # IC gfs data file: gfs_data.tile7.halo0.nc
    gfs_ic_fn="${NET}.${cycle}${dot_ensmem}.gfs_data.tile7.halo0.nc"
    gfs_ic_fp="${DATA_SHARE}/${gfs_ic_fn}"
    gfs_ic_mod_fn="gfs_data.tile7.halo0.nc"
    cp -p ${gfs_ic_fp} ${gfs_ic_mod_fn}

    # restart tracer file: fv_tracer.res.tile1.nc
    bkpath_find="missing"
    if [ "${bkpath_find}" = "missing" ]; then
      restart_prefix="${PDY}.${cyc}0000."
      CDATEprev=$($NDATE -${INCR_CYCL_FREQ} ${PDY}${cyc})
      PDYprev=${CDATEprev:0:8}
      cycprev=${CDATEprev:8:2}
      path_restart="${EXPTDIR}/${CDATEprev}/RESTART"

      n=${INCR_CYCL_FREQ}
      while [[ $n -le 25 ]] ; do
        if [ "${IO_LAYOUT_Y}" = "1" ]; then
          checkfile=${path_restart}/${restart_prefix}fv_tracer.res.tile1.nc
        else
          checkfile=${path_restart}/${restart_prefix}fv_tracer.res.tile1.nc.0000
        fi
        if [ -r "${checkfile}" ] && [ "${bkpath_find}" = "missing" ]; then
          bkpath_find=${path_restart}
          print_info_msg "Found ${checkfile}; Use it for smoke/dust cycle "
          break
        fi
        n=$((n + ${INCR_CYCL_FREQ}))
        CDATEprev=$($NDATE -$n ${PDY}${cyc})
        PDYprev=${CDATEprev:0:8}
        cycprev=${CDATEprev:8:2}
        path_restart=${COMIN}/${RUN}.${PDYprev}/${cycprev}${SLASH_ENSMEM_SUBDIR}/RESTART
        print_info_msg "Trying this path: ${path_restart}"
      done
    fi

    # cycle smoke/dust
    if [ "${bkpath_find}" = "missing" ]; then
      print_info_msg "WARNING: cannot find smoke/dust files from previous cycle"
    else
      if [ "${IO_LAYOUT_Y}" = "1" ]; then
        checkfile=${bkpath_find}/${restart_prefix}fv_tracer.res.tile1.nc
        if [ -r "${checkfile}" ]; then
          ncks -A -v smoke,dust,coarsepm ${checkfile} fv_tracer.res.tile1.nc
        fi
      else
        for ii in ${list_iolayout}
        do
          iii=$(printf %4.4i $ii)
          checkfile=${bkpath_find}/${restart_prefix}fv_tracer.res.tile1.nc.${iii}
          if [ -r "${checkfile}" ]; then
            ncks -A -v smoke,dust,coarsepm ${checkfile} fv_tracer.res.tile1.nc.${iii}
          fi
        done
      fi
      echo "${PDY}${cyc}: cycle smoke/dust from ${checkfile} "
    fi

    ${USHdir}/smoke_dust_add_smoke.py
    export err=$?
    if [ $err -ne 0 ]; then
      message_txt="add_smoke.py failed with return code $err"
      err_exit "${message_txt}"
      print_err_msg_exit "${message_txt}"
    fi
    # copy output to COMOUT
    cp -p ${gfs_ic_mod_fn} ${COMOUT}/${gfs_ic_fn}
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
PREPSTART has successfully been complete !!!!

Exiting script:  \"${scrfunc_fn}\"
In directory:    \"${scrfunc_dir}\"
========================================================================"
#
#-----------------------------------------------------------------------
#
#{ restore_shell_opts; } > /dev/null 2>&1
