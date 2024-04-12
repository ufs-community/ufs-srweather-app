#!/bin/bash

set -x 

msg="JOB COPYING MODEL OUTPUTS HAS BEGUN"
postmsg "$msg"
   
export pgm=aqm_output

#-----------------------------------------------------------------------
# Source the variable definitions file and the bash utility functions.
#-----------------------------------------------------------------------
#
. $USHaqm/source_util_funcs.sh
source_config_for_task "task_output" ${GLOBAL_VAR_DEFNS_FP}
#
#-----------------------------------------------------------------------
# Save current shell options (in a global array).  Then set new options
# for this script/function.
#-----------------------------------------------------------------------
{ save_shell_opts; . $USHaqm/preamble.sh; } > /dev/null 2>&1
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
# Print message indicating entry into script.
#-----------------------------------------------------------------------
#
print_info_msg "
========================================================================
Entering script:  \"${scrfunc_fn}\"
In directory:     \"${scrfunc_dir}\"
This is the ex-script for the task that copy AQM forecast and RESTART file to COMOUT
========================================================================"
#
umbrella_forecast_data=${DATAROOT}/${RUN}_forecast_${cyc}_${aqm_ver}
shared_output_data=${umbrella_forecast_data}/output
shared_restart_data=${umbrella_forecast_data}/RESTART
NCP="cpreq"
# Configure scan target
[ ${cyc} = "00" ] && FCST_LEN_HRS=6
[ ${cyc} = "06" ] && FCST_LEN_HRS=72
[ ${cyc} = "12" ] && FCST_LEN_HRS=72
[ ${cyc} = "18" ] && FCST_LEN_HRS=6
restart_group=1
icnt=1
file_ids=( "coupler.res" "fv_core.res.nc" "fv_core.res.tile1.nc" "fv_srf_wnd.res.tile1.nc" "fv_tracer.res.tile1.nc" "phy_data.nc" "sfc_data.nc" )
num_file_ids=${#file_ids[*]}
read -a restart_hrs <<< "${RESTART_INTERVAL}"
num_restart_hrs=${#restart_hrs[*]}

# 06Z and 12Z
if [ $cyc = 06 -o $cyc = 12 ]; then
  # 06Z and 12Z
  restart_interval_group_ct=0
  for (( ih_rst=0; ih_rst<${num_restart_hrs}; ih_rst++ )); do
    cdate_restart_hr=`$NDATE +${restart_hrs[ih_rst]} ${PDY}${cyc}`
    rst_yyyymmdd="${cdate_restart_hr:0:8}"
    rst_hh="${cdate_restart_hr:8:2}"
    proceed_copy=NO
    rst_exist=NO
    while [ $proceed_copy = "NO" -a $rst_exist = "NO" ]; do
      # Looking for the key file on each forecast interval
      if [ -e ${shared_restart_data}/${rst_yyyymmdd}.${rst_hh}0000.coupler.res ]; then
        if [ $(ls ${shared_restart_data}/${rst_yyyymmdd}.${rst_hh}0000.*|wc -l) -eq 7 ]; then
          # found the restart files for the current interval
          proceed_copy=YES
        fi
      fi
      # Check if this run is a restart run by looking at existing restart files
      if [ -e ${COMOUT}/RESTART/${rst_yyyymmdd}.${rst_hh}0000.coupler.res ]; then
        proceed_copy=NO
        rst_exist=YES
        (( restart_interval_group_ct=restart_interval_group_ct+1 ))
      fi
      if [ $proceed_copy = "YES" ]; then
        [ ! -d ${COMOUT}/RESTART ] && mkdir -p ${COMOUT}/RESTART
        if [ ${restart_interval_group_ct} -eq 0 ]; then
          output_fhr_begin=0
        else
          output_fhr_begin=$((${restart_hrs[$(($restart_interval_group_ct-1))]}+1))
        fi
        output_fhr_ending=$((${restart_hrs[$restart_interval_group_ct]}))
        fhr_ct=0
        fhr=$output_fhr_begin
        # copy forecast output
        while [ $fhr -le ${output_fhr_ending} ]; do
          fhr_ct=$(printf "%03d" $fhr)
          source_dyn="${shared_output_data}/${NET}.${cycle}${dot_ensmem}.dyn.f${fhr_ct}.nc"
          source_phy="${shared_output_data}/${NET}.${cycle}${dot_ensmem}.phy.f${fhr_ct}.nc"
          target_dyn="${COMOUT}/${NET}.${cycle}${dot_ensmem}.dyn.f${fhr_ct}.nc"
          target_phy="${COMOUT}/${NET}.${cycle}${dot_ensmem}.phy.f${fhr_ct}.nc"
          source_log="${shared_output_data}/${NET}.${cycle}${dot_ensmem}.logf${fhr_ct}"
          if [ -e ${source_log} ]; then
            eval $NCP ${source_dyn} ${target_dyn}
            eval $NCP ${source_phy} ${target_phy}
            (( fhr=fhr+1 ))
            ecflow_client --event ${fhr_ct}_rdy
          fi
        done
        # copy RESTART files
        for file_id_source in "${file_ids[@]}"; do
          eval $NCP ${shared_restart_data}/${rst_yyyymmdd}.${rst_hh}0000.${file_id_source} ${COMOUT}/RESTART
        done 
        ecflow_client --event restart_gp${restart_group}_rdy
        # last sector
        restart_interval_group_ct=$(($restart_interval_group_ct+1))
        if [ ${restart_interval_group_ct} -eq ${num_restart_hrs} ]; then
          fhr=$((${output_fhr_ending}+1))
          output_fhr_ending=${FCST_LEN_HRS}
          time_limit=0
          while [ $fhr -le ${output_fhr_ending} ]; do
            fhr_ct=$(printf "%03d" $fhr)
            source_dyn="${shared_output_data}/${NET}.${cycle}${dot_ensmem}.dyn.f${fhr_ct}.nc"
            source_phy="${shared_output_data}/${NET}.${cycle}${dot_ensmem}.phy.f${fhr_ct}.nc"
            target_dyn="${COMOUT}/${NET}.${cycle}${dot_ensmem}.dyn.f${fhr_ct}.nc"
            target_phy="${COMOUT}/${NET}.${cycle}${dot_ensmem}.phy.f${fhr_ct}.nc"
            source_log="${shared_output_data}/${NET}.${cycle}${dot_ensmem}.logf${fhr_ct}"
            if [ -e ${source_log} ]; then
              eval $NCP ${source_dyn} ${target_dyn}
              eval $NCP ${source_phy} ${target_phy}
              (( fhr=fhr+1 ))
              ecflow_client --event ${fhr_ct}_rdy
            else
              sleep 60
              time_limit=$(($time_limit+1))
              if [ $time_limit -ge 60 ]; then
                echo "FATAL ERROR - ABORTING after waiting for forecast output file ${source_log}"
                exit 9
              fi
            fi
          done
        fi
      else
        # Only wait if restart is not already found
        if [ $rst_exist = "NO" ]; then
          sleep 60
          (( icnt=icnt+1 ))
          if [ $icnt -ge 210 ]; then
            echo "FATAL ERROR - ABORTING after waiting for forecast RESTART file ${shared_restart_data}/${rst_yyyymmdd}.${rst_hh}0000.coupler.res"
            exit 9
          fi
        fi
      fi
    done
    (( restart_group=restart_group+1 ))
  done
else
  # 00Z and 18Z
  cdate_restart_hr=`$NDATE +6 ${PDY}${cyc}`
  rst_yyyymmdd="${cdate_restart_hr:0:8}"
  rst_hh="${cdate_restart_hr:8:2}"
  proceed_copy=NO
  while [ $proceed_copy = "NO" ]; do
    if [ -e ${shared_restart_data}/${rst_yyyymmdd}.${rst_hh}0000.coupler.res ]; then 
      if [ $(ls ${shared_restart_data}/${rst_yyyymmdd}.${rst_hh}0000.*|wc -l) -eq 7 ]; then 
        # found the restart files for the current interval
        proceed_copy=YES
      fi
    fi
    if [ $proceed_copy = "YES" ]; then
      [ ! -d ${COMOUT}/RESTART ] && mkdir -p ${COMOUT}/RESTART
      #### copy forecast output
      fhr_ct=0
      fhr=0
      while [ $fhr -le ${FCST_LEN_HRS} ]; do
        fhr_ct=$(printf "%03d" $fhr)
        source_dyn="${shared_output_data}/${NET}.${cycle}${dot_ensmem}.dyn.f${fhr_ct}.nc"
        source_phy="${shared_output_data}/${NET}.${cycle}${dot_ensmem}.phy.f${fhr_ct}.nc"
        target_dyn="${COMOUT}/${NET}.${cycle}${dot_ensmem}.dyn.f${fhr_ct}.nc"
        target_phy="${COMOUT}/${NET}.${cycle}${dot_ensmem}.phy.f${fhr_ct}.nc"
        eval $NCP ${source_dyn} ${target_dyn}
        eval $NCP ${source_phy} ${target_phy}
        ecflow_client --alter change event ${fhr_ct}_rdy set ${ECF_NAME}
        (( fhr=fhr+1 ))
      done
      #### copy forecast restart
      for file_id in "${file_ids[@]}"; do
        eval $NCP ${shared_restart_data}/${rst_yyyymmdd}.${rst_hh}0000.${file_id} ${COMOUT}/RESTART
      done
      ecflow_client --alter change event restart_gp${restart_group}_rdy set ${ECF_NAME}
    else
      sleep 60
      (( icnt=icnt+1 ))
      if [ $icnt -ge 90 ]; then
        echo "FATAL ERROR - ABORTING after waiting for forecast RESTART file ${shared_restart_data}/${rst_yyyymmdd}.${rst_hh}0000.coupler.res"
        exit 9
      fi
    fi
  done
fi
[[ ${proceed_copy} = "YES" ]] && mv ${umbrella_forecast_data}/RESTART ${umbrella_forecast_data}/RESTART_ORG
#
#-----------------------------------------------------------------------
#  Deleting DATA and shared RESTART/output directories 
#-----------------------------------------------------------------------
if [ "${KEEPDATA}" != "YES" ]; then
  icnt=0
  wtm=20
  while [ $icnt -lt $wtm ]; do
   if [ -e ${umbrella_forecast_data}/clean.flag ]; then
     cd ${DATAROOT}
     rm -rf ${umbrella_forecast_data}
     icnt=$wtm
   else
     sleep 60
     (( icnt=icnt+1 ))
     if [ $icnt -eq $wtm ]; then
       echo "FATAL ERROR Forecast manager is done copy file for over ${wtm} minutes however forecast job is still running."
       exit 9
     fi
   fi
  done
fi
#
#-----------------------------------------------------------------------
# Print message indicating successful completion of script.
#-----------------------------------------------------------------------
#
print_info_msg "
========================================================================
AQM forecast manager completed successfully.

Exiting script:  \"${scrfunc_fn}\"
In directory:    \"${scrfunc_dir}\"
========================================================================"
#
#-----------------------------------------------------------------------
#
{ restore_shell_opts; } > /dev/null 2>&1
#
