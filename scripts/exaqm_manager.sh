#! /bin/bash
set -x

ecflow_sid=emc_aqm

##############################################
# Set variables used in the script
##############################################
CDATE=${PDY}${cyc}
GDATE=$($NDATE -06 $CDATE)
gPDY=$(echo $GDATE | cut -c1-8)
gcyc=$(echo $GDATE | cut -c9-10)
NEXTDATE=$($NDATE +06 $CDATE)
NEXTPDY=$(echo $NEXTDATE | cut -c1-8)
NEXTcyc=$(echo $NEXTDATE | cut -c9-10)
# NEXT24HPDY=$($NDATE +24 ${PDY}00)
CURRENTDAYPDY=$(ecflow_client --query variable /${ecflow_sid}/primary/${gcyc}:PDY)00
NEXTDAYPDY_CDATE=$($NDATE +24 $CURRENTDAYPDY)
NEXTDAYPDY=$(echo $NEXTDAYPDY_CDATE | cut -c1-8)

#aqm_forecast_RESTART_file=$(ls ${DATAROOT}/aqm_forecast_${cyc}.${PDY}${cyc}/RESTART/*coupler.res|wc -l)
#aqm_forecast_RESTART_file="${DATAROOT}/aqm_forecast_${cyc}.${PDY}${cyc}/RESTART/*coupler.res"
gefs_check=$(compath.py ${envir}/gefs/${gefs_ver})/gefs.${NEXTPDY}/${NEXTcyc}/chem/sfcsig/geaer.t${NEXTcyc}z.atmf078.nemsio
gfs_check=$(compath.py ${envir}/gfs/${gfs_ver})/gfs.${NEXTPDY}/${NEXTcyc}/atmos/gfs.t${NEXTcyc}z.sfcf078.nc
found_required_file_for_next_cycle=NO
fcst_job_completed=NO
release_next_cycle=NO
previous_cycle_run_completed=NO
cleanup_job_done=NO
previous_cycle_aqm_manager_complete=NO

h_try=1
while [ $h_try -lt 70 ]; do
  ####################################
  # Set release_next_cycle event when 
  #   current cycle fcst restart file exist
  ####################################
  if [ ${found_required_file_for_next_cycle} = "NO" ]; then
    aqm_forecast_RESTART_file=$(ls ${DATAROOT}/aqm_forecast_${cyc}.${PDY}${cyc}/RESTART/*coupler.res|wc -l)
    if [[ ${aqm_forecast_RESTART_file} -ge 1 && -f ${gefs_check} && -f ${gfs_check} ]]; then
      ecflow_client --event release_next_cycle
      found_required_file_for_next_cycle=YES
    fi
  fi
  ####################################
  # Requeue previous cycle when
  #   current forecast job is completed
  ####################################
  if [ ${fcst_job_completed} = "NO" ]; then
    P_state=$(ecflow_client --query state /${ecflow_sid}/primary/${gcyc})
    e_state=$(ecflow_client --query state /${ecflow_sid}/primary/${cyc}/aqm/v1.0/forecast/jforecast)
    if [[ ${e_state} = "complete" && ${P_state} = "complete" ]]; then
      ecflow_client --event requeue_cycle
      ecflow_client --alter change variable PDY $NEXTDAYPDY /${ecflow_sid}/primary/${gcyc}
      ecflow_client --requeue force /${ecflow_sid}/primary/${gcyc}/aqm
      fcst_job_completed=YES
    fi
  fi 

  h_try=$((h_try+1))
  if [ ${found_required_file_for_next_cycle} = "YES" -a ${fcst_job_completed} = "YES" ]; then
    h_try=99
  else
    sleep 300
  fi
done
if [ $h_try -eq 70 ]; then
  exit 70
fi
