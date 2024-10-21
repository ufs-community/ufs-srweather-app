#!/usr/bin/env bash

set -xue
#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. ${PARMsrw}/source_util_funcs.sh
task_global_vars=( "COLDSTART" "DATE_FIRST_CYCL" "INCR_CYCL_FREQ" \
  "WARMSTART_CYCLE_DIR" )
for var in ${task_global_vars[@]}; do
  source_config_for_task ${var} ${GLOBAL_VAR_DEFNS_FP}
done
#
#-----------------------------------------------------------------------
#
# Save current shell options (in a global array).  Then set new options
# for this script/function.
#
#-----------------------------------------------------------------------
#
#{ save_shell_opts; set -xue; } > /dev/null 2>&1
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

This is the ex-script for the task that copies/fetches to a local direc-
tory (either from disk or HPSS) the external model files from which ini-
tial or boundary condition files for the FV3 will be generated.
========================================================================"
#
if [ $(boolify "${COLDSTART}") = "TRUE" ] && [ "${PDY}${cyc}" = "${DATE_FIRST_CYCL:0:10}" ]; then
  echo "This step is skipped for the first cycle of COLDSTART."
else
  # Check if restart file exists
  rst_file="fv_tracer.res.tile1.nc"
  rst_file_with_date="${PDY}.${cyc}0000.${rst_file}"

  # Warm start
  if [ $(boolify "${COLDSTART}") = "FALSE" ] && [ "${PDY}${cyc}" = "${DATE_FIRST_CYCL:0:10}" ]; then
    rst_dir="${WARMSTART_CYCLE_DIR}/RESTART"
  else
  # after the first cycle
    CDATEprev=$($NDATE -${INCR_CYCL_FREQ} ${PDY}${cyc})
    PDYprev=${CDATEprev:0:8}
    cycprev=${CDATEprev:8:2}
    COMINprev=${COMIN}/${RUN}.${PDYprev}/${cycprev}${SLASH_ENSMEM_SUBDIR}
    if [ -e "${COMINprev}/RESTART/${rst_file_with_date}" ]; then
      rst_dir="${COMINprev}/RESTART"
    elif [ -e "${DATA_SHARE}/RESTART/${rst_file_with_date}" ]; then
      rst_dir="${DATA_SHARE}/RESTART"
    fi
  fi
  if [ -e "${rst_dir}/${rst_file_with_date}" ]; then
    fv_tracer_file="${rst_dir}/${rst_file_with_date}"
  elif [ -e "${rst_dir}/${rst_file}" ]; then	
    fv_tracer_file="${rst_dir}/${rst_file}"
  else
    message_txt="WARNING: Tracer restart file: \"${fv_tracer_file}\" is NOT found"
    err_exit "${message_txt}"
    print_err_msg_exit "${message_txt}"
  fi
  print_info_msg "Tracer restart file: \"${fv_tracer_file}\""

  cplr_file="coupler.res"
  cplr_file_with_date="${PDY}.${cyc}0000.${cplr_file}"
  if [ -e "${rst_dir}/${cplr_file_with_date}" ]; then
    coupler_file="${rst_dir}/${cplr_file_with_date}"
  elif [ -e "${rst_dir}/${cplr_file}" ]; then	
    coupler_file="${rst_dir}/${cplr_file}"
  else
    message_txt="WARNING: Coupler file: \"${coupler_file}\" is NOT found"
    err_exit "${message_txt}"
    print_err_msg_exit "${message_txt}"
  fi
  print_info_msg "Coupler file: \"${coupler_file}\""

  if [ -r ${coupler_file} ]; then
    rst_info=( $( tail -n 1 ${coupler_file} ) )
    # Remove leading zeros from ${rst_info[1]}
    month="${rst_info[1]#"${rst_info[1]%%[!0]*}"}"
    # Remove leading zeros from ${rst_info[2]}
    day="${rst_info[2]#"${rst_info[2]%%[!0]*}"}"
    # Format the date without leading zeros
    rst_date=$(printf "%04d%02d%02d%02d" ${rst_info[0]} $((10#$month)) $((10#$day)) ${rst_info[3]})
    if [ "${rst_date}" = "${PDY}${cyc}" ]; then
      if [ -r ${fv_tracer_file} ]; then
        print_info_msg "Tracer restart file is for ${PDY}${cyc}"
      else
        message_txt="Tracer restart file \"${fv_tracer_file}\" is NOT readable."
        err_exit "${message_txt}"
        print_err_msg_exit "${message_txt}"
      fi
    else
      message_txt="Tracer restart file is NOT for ${PDY}${cyc}. 
Checking available restart date:
  requested date: \"${PDY}${cyc}\"
  available date: \"${rst_date}\""
      err_exit "${message_txt}"
      print_err_msg_exit "${message_txt}"
    fi
  fi
  #
  #-----------------------------------------------------------------------
  #
  # Add air quality tracer variables from previous cycle's restart output
  # to atmosphere's initial condition file according to the steps below:
  #
  # a. Python script to manipulate the files (see comments inside for details)
  # b. Remove checksum attribute to prevent overflow
  # c. Rename reulting file as the expected atmospheric IC file
  #
  #-----------------------------------------------------------------------
  #
  gfs_ic_fn="${NET}.${cycle}${dot_ensmem}.gfs_data.tile7.halo0.nc"
  gfs_ic_fp="${DATA_SHARE}/${gfs_ic_fn}"
  wrk_ic_fp="${DATA}/gfs.nc"

  print_info_msg "
  Adding air quality tracers to atmospheric initial condition file:
    tracer file: \"${fv_tracer_file}\"
    FV3 IC file: \"${gfs_ic_fp}\""

  cp -p ${gfs_ic_fp} ${wrk_ic_fp}
  ${USHsrw}/aqm_utils_python/add_aqm_ics.py --fv_tracer_file "${fv_tracer_file}" --wrk_ic_file "${wrk_ic_fp}"
  export err=$?
  if [ $err -ne 0 ]; then
    message_txt="Call to python script \"add_aqm_ics.py\" failed."
    err_exit "${message_txt}"
    print_err_msg_exit "${message_txt}"
  fi

  ncatted -a checksum,,d,s, tmp1.nc
  export err=$?
  if [ $err -ne 0 ]; then
    message_txt="Call to NCATTED returned with nonzero exit code."
    err_exit "${message_txt}"
    print_err_msg_exit "${message_txt}"
  fi

  mv tmp1.nc ${gfs_ic_fn}

  cp -p ${gfs_ic_fn} ${COMOUT}
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
Successfully added air quality tracers to atmospheric IC file!!!

Exiting script:  \"${scrfunc_fn}\"
In directory:    \"${scrfunc_dir}\"
========================================================================"
#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script/function.
#
#-----------------------------------------------------------------------
#
#{ restore_shell_opts; } > /dev/null 2>&1

