#!/usr/bin/env bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. ${USHsrw}/source_util_funcs.sh
for sect in user nco platform workflow nco global verification cpl_aqm_parm \
  constants fixed_files grid_params \
  task_nexus_emission ; do
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

This is the ex-script for the task that runs NEXUS EMISSION.
========================================================================"
#
#-----------------------------------------------------------------------
#
# Set OpenMP variables.
#
#-----------------------------------------------------------------------
#
export KMP_AFFINITY=${KMP_AFFINITY_NEXUS_EMISSION}
export OMP_NUM_THREADS=${OMP_NUM_THREADS_NEXUS_EMISSION}
export OMP_STACKSIZE=${OMP_STACKSIZE_NEXUS_EMISSION}
#
#-----------------------------------------------------------------------
#
# Set run command.
#
#-----------------------------------------------------------------------
#
eval ${PRE_TASK_CMDS}

if [ -z "${RUN_CMD_NEXUS:-}" ] ; then
  print_err_msg_exit "\
  Run command was not set in machine file. \
  Please set RUN_CMD_NEXUS for your platform"
else
  RUN_CMD_NEXUS=$(eval echo ${RUN_CMD_NEXUS})
  print_info_msg "$VERBOSE" "
  All executables will be submitted with command \'${RUN_CMD_NEXUS}\'."
fi
#
#-----------------------------------------------------------------------
#
# Create NEXUS input directory in working directory
#
#-----------------------------------------------------------------------
#
DATAinput="${DATA}/input"
mkdir -p "$DATAinput"
#
#-----------------------------------------------------------------------
#
# Link GFS surface data files to the tmp directory if they exist
#
#-----------------------------------------------------------------------
#
USE_GFS_SFC="FALSE"
GFS_SFC_INPUT="${DATA_SHARE}"
if [ -d "${GFS_SFC_INPUT}" ]; then
  if [ "$(ls -A ${GFS_SFC_INPUT}/gfs*.nc)" ]; then
    ln -sf "${GFS_SFC_INPUT}" "GFS_SFC"
    USE_GFS_SFC="TRUE"
  fi
fi
#
#-----------------------------------------------------------------------
#
# Copy the NEXUS config files to the tmp directory  
#
#-----------------------------------------------------------------------
#
cp -p ${FIXaqm}/nexus/${NEXUS_GRID_FN} ${DATA}/grid_spec.nc

if [ "${USE_GFS_SFC}" = "TRUE" ]; then
  cp -p ${PARMsrw}/nexus_config/cmaq_gfs_megan/*.rc ${DATA}
else
  cp -p ${PARMsrw}/nexus_config/cmaq/*.rc ${DATA}
fi
#
#-----------------------------------------------------------------------
#
# Get the starting and ending year, month, day, and hour of the emission
# time series.
#
#-----------------------------------------------------------------------
#
MM="${PDY:4:2}"
DD="${PDY:6:2}"
HH="${cyc}"
YYYYMMDD="${PDY}"

NUM_SPLIT_NEXUS=$( printf "%02d" ${NUM_SPLIT_NEXUS} )

if [ ${#FCST_LEN_CYCL[@]} -gt 1 ]; then
  cyc_mod=$(( ${cyc} - ${DATE_FIRST_CYCL:8:2} ))
  CYCLE_IDX=$(( ${cyc_mod} / ${INCR_CYCL_FREQ} ))
  FCST_LEN_HRS=${FCST_LEN_CYCL[$CYCLE_IDX]}
fi

if [ "${NUM_SPLIT_NEXUS}" = "01" ]; then
  start_date="${YYYYMMDD}${HH}"
  end_date=`$NDATE +${FCST_LEN_HRS} ${YYYYMMDD}${HH}`
else
  len_per_split=$(( FCST_LEN_HRS / NUM_SPLIT_NEXUS  ))
  nsptp=$(( nspt+1 ))

  # Compute start and end dates for nexus split option
  start_del_hr=$(( len_per_split * nspt ))
  start_date=`$NDATE +${start_del_hr} ${YYYYMMDD}${HH}`
  if [ "${nsptp}" = "${NUM_SPLIT_NEXUS}" ];then
    end_date=`$NDATE +$(expr $FCST_LEN_HRS + 1) ${YYYYMMDD}${HH}` 
  else
    end_del_hr=$(( len_per_split * nsptp ))
    end_del_hr1=$(( $end_del_hr + 1 ))
    end_date=`$NDATE +${end_del_hr1} ${YYYYMMDD}${HH}`
  fi
fi
#
#----------------------------------------------------------------------
#
# This will be the section to set the datasets used in $workdir/NEXUS_Config.rc 
# All Datasets in that file need to be placed here as it will link the files 
# necessary to that folder.  In the future this will be done by a get_nexus_input 
# script
#
#----------------------------------------------------------------------
#
NEI2016="TRUE"
TIMEZONES="TRUE"
CEDS="TRUE"
HTAP2010="TRUE"
OMIHTAP="TRUE"
MASKS="TRUE"
NOAAGMD="TRUE"
SOA="TRUE"
EDGAR="TRUE"
MEGAN="TRUE"
MODIS_XLAI="FALSE"
OLSON_MAP="TRUE"
Yuan_XLAI="TRUE"
GEOS="TRUE"
AnnualScalar="TRUE"
OFFLINE_SOILNOX="TRUE"
#
#----------------------------------------------------------------------
# 
# modify time configuration file
#
#----------------------------------------------------------------------
#
${USHsrw}/nexus_utils/python/nexus_time_parser.py -f ${DATA}/HEMCO_sa_Time.rc -s $start_date -e $end_date
export err=$?
if [ $err -ne 0 ]; then
  message_txt="Call to python script \"nexus_time_parser.py\" failed."
  err_exit "${message_txt}"
  print_err_msg_exit "${message_txt}"
fi
#
#---------------------------------------------------------------------
#
# set the root directory to the temporary directory
#
#----------------------------------------------------------------------
#
${USHsrw}/nexus_utils/python/nexus_root_parser.py -f ${DATA}/NEXUS_Config.rc -d ${DATAinput}
export err=$?
if [ $err -ne 0 ]; then
  message_txt="Call to python script \"nexus_root_parser.py\" failed."
  err_exit "${message_txt}"
  print_err_msg_exit "${message_txt}"
fi
#
#----------------------------------------------------------------------
#
# Get all the files needed (TEMPORARILY JUST COPY FROM THE DIRECTORY)
#
#----------------------------------------------------------------------
#
if [ "${NEI2016}" = "TRUE" ]; then #NEI2016
  mkdir -p ${DATAinput}/NEI2016v1
  mkdir -p ${DATAinput}/NEI2016v1/v2022-07
  mkdir -p ${DATAinput}/NEI2016v1/v2022-07/${MM}
  ${USHsrw}/nexus_utils/python/nexus_nei2016_linker.py --src_dir ${FIXemis} --date ${YYYYMMDD} --work_dir ${DATAinput} -v "v2022-07"
  export err=$?
  if [ $err -ne 0 ]; then
    message_txt="Call to python script \"nexus_nei2016_linker.py\" failed."
    err_exit "${message_txt}"
    print_err_msg_exit "${message_txt}"
  fi

  ${USHsrw}/nexus_utils/python/nexus_nei2016_control_tilefix.py -f ${DATA}/NEXUS_Config.rc -t ${DATA}/HEMCO_sa_Time.rc # -d ${yyyymmdd}
  export err=$?
  if [ $err -ne 0 ]; then
    message_txt="Call to python script \"nexus_nei2016_control_tilefix.py\" failed."
    err_exit "${message_txt}"
    print_err_msg_exit "${message_txt}"
  fi
fi

if [ "${TIMEZONES}" = "TRUE" ]; then # TIME ZONES
  ln -sf ${FIXemis}/TIMEZONES ${DATAinput}
fi

if [ "${MASKS}" = "TRUE" ]; then # MASKS
  ln -sf ${FIXemis}/MASKS ${DATAinput}
fi

if [ "${CEDS}" = "TRUE" ]; then #CEDS
  ln -sf ${FIXemis}/CEDS ${DATAinput}
fi

if [ "${HTAP2010}" = "TRUE" ]; then #CEDS2014
  ln -sf ${FIXemis}/HTAP ${DATAinput}
fi

if [ "${OMIHTAP}" = "TRUE" ]; then #CEDS2014
  ln -sf ${FIXemis}/OMI-HTAP_2019 ${DATAinput}
fi

if [ "${NOAAGMD}" = "TRUE" ]; then #NOAA_GMD
  ln -sf ${FIXemis}/NOAA_GMD ${DATAinput}
fi

if [ "${SOA}" = "TRUE" ]; then #SOA
  ln -sf ${FIXemis}/SOA ${DATAinput}
fi

if [ "${EDGAR}" = "TRUE" ]; then #EDGARv42
  ln -sf ${FIXemis}/EDGARv42 ${DATAinput}
fi

if [ "${MEGAN}" = "TRUE" ]; then #MEGAN
  ln -sf ${FIXemis}/MEGAN ${DATAinput}
fi

if [ "${OLSON_MAP}" = "TRUE" ]; then #OLSON_MAP
  ln -sf ${FIXemis}/OLSON_MAP ${DATAinput}
fi

if [ "${Yuan_XLAI}" = "TRUE" ]; then #Yuan_XLAI
  ln -sf ${FIXemis}/Yuan_XLAI ${DATAinput}
fi

if [ "${GEOS}" = "TRUE" ]; then #GEOS
  ln -sf ${FIXemis}/GEOS_0.5x0.625 ${DATAinput}
fi

if [ "${AnnualScalar}" = "TRUE" ]; then #ANNUAL_SCALAR
  ln -sf ${FIXemis}/AnnualScalar ${DATAinput}
fi

if [ "${MODIS_XLAI}" = "TRUE" ]; then #MODIS_XLAI
  ln -sf ${FIXemis}/MODIS_XLAI ${DATAinput}
fi

if [ "${OFFLINE_SOILNOX}" = "TRUE" ]; then #OFFLINE_SOILNOX
  ln -sf ${FIXemis}/OFFLINE_SOILNOX ${DATAinput}
fi

if [ "${USE_GFS_SFC}" = "TRUE" ]; then # GFS INPUT
  mkdir -p ${DATAinput}/GFS_SFC
  ${USHsrw}/nexus_utils/python/nexus_gfs_bio.py -i ${DATA}/GFS_SFC/gfs.t??z.sfcf???.nc -o ${DATA}/GFS_SFC_MEGAN_INPUT.nc
  export err=$?
  if [ $err -ne 0 ]; then
    message_txt="Call to python script \"nexus_gfs_bio.py\" failed."
    err_exit "${message_txt}"
    print_err_msg_exit "${message_txt}"
  fi
fi
#
#----------------------------------------------------------------------
#
# Execute NEXUS
#
#-----------------------------------------------------------------------
#
export pgm="nexus"
. prep_step

eval ${RUN_CMD_NEXUS} ${EXECdir}/$pgm -c NEXUS_Config.rc -r grid_spec.nc -o NEXUS_Expt_split.nc >>$pgmout 2>${DATA}/errfile
export err=$?; err_chk
if [ $err -ne 0 ]; then
  print_err_msg_exit "Call to execute nexus failed."
fi
#
#-----------------------------------------------------------------------
#
# Make NEXUS output pretty and move to INPUT_DATA directory.
#
#-----------------------------------------------------------------------
#
${USHsrw}/nexus_utils/python/make_nexus_output_pretty.py --src ${DATA}/NEXUS_Expt_split.nc --grid ${DATA}/grid_spec.nc -o ${DATA_SHARE}/${NET}.${cycle}${dot_ensmem}.NEXUS_Expt_split.${nspt}.nc -t ${DATA}/HEMCO_sa_Time.rc
export err=$?
if [ $err -ne 0 ]; then
  message_txt="Call to python script \"make_nexus_output_pretty.py\" failed."
  err_exit "${message_txt}"
  print_err_msg_exit "${message_txt}"
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
NEXUS has successfully generated emissions files in netcdf format!!!!

Exiting script:  \"${scrfunc_fn}\"
In directory:    \"${scrfunc_dir}\"
========================================================================"
#
#-----------------------------------------------------------------------
#
{ restore_shell_opts; } > /dev/null 2>&1
