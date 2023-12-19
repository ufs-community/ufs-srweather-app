#!/bin/bash

set -xe 

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
This is the ex-script for the task that runs COPY_MODEL_OUTPUT.
========================================================================"
#
if [ ${#FCST_LEN_CYCL[@]} -gt 1 ]; then
  cyc_mod=$(( ${cyc} - ${DATE_FIRST_CYCL:8:2} ))
  CYCLE_IDX=$(( ${cyc_mod} / ${INCR_CYCL_FREQ} ))
  FCST_LEN_HRS=${FCST_LEN_CYCL[$CYCLE_IDX]}
fi

file_ids=( "fv_tracer.res.tile1.nc" "fv_core.res.nc" "fv_core.res.tile1.nc" "fv_srf_wnd.res.tile1.nc" "sfc_data.nc" "phy_data.nc" "coupler.res" )
read -a restart_hrs <<< "${RESTART_INTERVAL}"
num_restart_hrs=${#restart_hrs[*]}

sleep  200

DATA_FORECAST=$(/bin/ls -1rtd ${DATAROOT}/aqm_forecast_${cyc}.* | tail -n 1)

#-----------------------------------------------------------------------
# Get the total file number of aqm.t${cyc}z.dyn*nc at $COMOUT
# total_files=$(ls -1 "$COMOUT"/aqm.t${cyc}z.dyn*nc | wc -l)

 files_exist=false

 shopt -s nullglob
 files=("$COMOUT"/aqm.t${cyc}z.dyn*nc)
 if [ ${#files[@]} -gt 0 ]; then
      files_exist=true
      total_files=${#files[@]}
 fi
#-----------------------------------------------------------------------
# Check the conditions and set ist accordingly
 if [ "$files_exist" = true ]; then
   for ((i=0; i<num_restart_hrs; i++)); do
     if ((total_files >= restart_hrs[i] && total_files < restart_hrs[i+1])); then
       ist=$((restart_hrs[i] + 1))
       break
     fi
   done

# If total_files is greater than or equal to the last value in RESTART_INTERVAL
   if ((total_files >= restart_hrs[num_restart_hrs-1])); then
      ist=$((restart_hrs[num_restart_hrs-1] + 1))
   elif ((total_files < restart_hrs[0])); then
      ist=0
   fi
 else 
   ist=0
 fi 
#                             
#-----------------------------------------------------------------------
while [ "$ist" -le "${FCST_LEN_HRS}" ]; do
  hst=$( printf "%03d" "${ist}" )
  ic=0
  while [ $ic -lt 600 ]
  do 
    if [ -s ${DATA_FORECAST}/dynf${hst}.nc ] && [ $(stat -c %s `ls ${DATA_FORECAST}/dynf${hst}.nc`) -gt 1170900000 ]; then	
     sleep 60	    
     cpreq ${DATA_FORECAST}/dynf${hst}.nc  ${COMOUT}/aqm.t${cyc}z.dyn.f${hst}.nc
     cpreq ${DATA_FORECAST}/phyf${hst}.nc  ${COMOUT}/aqm.t${cyc}z.phy.f${hst}.nc
     cpreq ${DATA_FORECAST}/aqm.prod.nc    ${COMOUT}/aqm.t${cyc}z.prod.nc
     break
   else
    sleep 20
    (( ic=ic+1 ))
   fi 
  done

#
#-----------------------------------------------------------------------
# Copy restart files at the prescribed-resart forecast hours
  for (( ih_rst=${num_restart_hrs}-1; ih_rst>=0; ih_rst-- )); do
   hst_rst=$( printf "%03d" "${restart_hrs[ih_rst]}" )
   if [ $hst  == $hst_rst ] ;then
      cdate_restart_hr=`$NDATE +${restart_hrs[ih_rst]} ${PDY}${cyc}`
      rst_yyyymmdd="${cdate_restart_hr:0:8}"
      rst_hh="${cdate_restart_hr:8:2}"
      if [ $cyc = 06 -o $cyc = 12 ]; then
        ic1=0
        while [ $ic1 -lt 240 ]; do
          if [ -s ${DATA_FORECAST}/RESTART/${rst_yyyymmdd}.${rst_hh}0000.fv_tracer.res.tile1.nc ] && [ $(stat -c %s `ls ${DATA_FORECAST}/RESTART/${rst_yyyymmdd}.${rst_hh}0000.fv_tracer.res.tile1.nc`) -gt 21836600000 ]; then
	     if [ ! -d "${COMOUT}/RESTART" ]; then
	        mkdir -p "${COMOUT}/RESTART"
	     fi
	     sleep 30
           for file_id in "${file_ids[@]}"; do
	       source_file="${DATA_FORECAST}/RESTART/${rst_yyyymmdd}.${rst_hh}0000.${file_id}"
	       destination_dir="${COMOUT}/RESTART/${rst_yyyymmdd}.${rst_hh}0000.${file_id}"
	       while [ ! -e "${source_file}" ]; do
	          echo "Waiting for ${source_file} to exist..."
	          sleep 10  
               done
	      sleep 10
              cpreq $source_file  $destination_dir 
           done
	   sleep 20
	   break
	  else
	   sleep 20
           (( ic1=ic1+1 ))
          fi
        done
      else
        # 00Z and 18Z
	  cdate_restart_hr=`$NDATE +6 ${PDY}${cyc}`
	  rst_yyyymmdd="${cdate_restart_hr:0:8}"
	  rst_hh="${cdate_restart_hr:8:2}"
          ic2=0
          while [ $ic2 -lt 240 ]; do
            if [ -s ${DATA_FORECAST}/RESTART/fv_tracer.res.tile1.nc ] && [ $(stat -c %s `ls ${DATA_FORECAST}/RESTART/fv_tracer.res.tile1.nc`) -gt 21836600000 ]; then
	      sleep 30	    
	     if [ ! -d "${COMOUT}/RESTART" ]; then
	        mkdir -p "${COMOUT}/RESTART"
	     fi
             for file_id in "${file_ids[@]}"; do
		 source_file="${DATA_FORECAST}/RESTART/${file_id}"
		 destination_dir="${COMOUT}/RESTART/${rst_yyyymmdd}.${rst_hh}0000.${file_id}"
		 while [ ! -e "${source_file}" ]; do
		    echo "Waiting for ${source_file} to exist..."
		    sleep 10  
                 done
	         sleep 20
                 cpreq $source_file  $destination_dir 
             done
	     break
	    else
	     sleep 20
             (( ic2=ic2+1 ))
            fi
          done
      fi
   fi
  done 
  (( ist=ist+1 ))
done
#
#-----------------------------------------------------------------------
#  Deleting FORECAAT run dir 
#  Note: This needs to done by the output job rather than the forecast job 
#-----------------------------------------------------------------------
if [ "${KEEPDATA}" = "FALSE" ]; then
   rm -rf ${DATA_FORECAST}
fi
#
#-----------------------------------------------------------------------
# Print message indicating successful completion of script.
#-----------------------------------------------------------------------
#
print_info_msg "
========================================================================
COPY-MODEL-OUTPUT completed successfully.

Exiting script:  \"${scrfunc_fn}\"
In directory:    \"${scrfunc_dir}\"
========================================================================"
#
#-----------------------------------------------------------------------
#
{ restore_shell_opts; } > /dev/null 2>&1
#
