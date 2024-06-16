#!/bin/bash

set -x

msg="JOB $job HAS BEGUN"
postmsg "$msg"

export pgm=aqm_bias_correction_pm25

#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. $USHaqm/source_util_funcs.sh
source_config_for_task "cpl_aqm_parm|task_bias_correction_pm25" ${GLOBAL_VAR_DEFNS_FP}
#
#-----------------------------------------------------------------------
#
# Save current shell options (in a global array).  Then set new options
# for this script/function.
#
#-----------------------------------------------------------------------
#
{ save_shell_opts; . $USHaqm/preamble.sh; } > /dev/null 2>&1
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
This is the ex-script for the task that runs BIAS-CORRECTION-PM25.
========================================================================"
#
#-----------------------------------------------------------------------
export DBNROOT=${DBNROOT:-${UTILROOT}/fakedbn}
export DBNALERT_TYPE=${DBNALERT_TYPE:-GRIB_HIGH}
#-----------------------------------------------------------------------
#
# Set OpenMP variables.
#
#-----------------------------------------------------------------------
#
export KMP_AFFINITY=${KMP_AFFINITY_BIAS_CORRECTION_PM25}
export OMP_NUM_THREADS=${OMP_NUM_THREADS_BIAS_CORRECTION_PM25}
export OMP_STACKSIZE=${OMP_STACKSIZE_BIAS_CORRECTION_PM25}
export OMP_PLACES=cores
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

yyyy=${PDY:0:4}
yyyymm=${PDY:0:6}
yyyy_m1=${PDYm1:0:4}
yyyymm_m1=${PDYm1:0:6}
yyyy_m2=${PDYm2:0:4}
yyyymm_m2=${PDYm2:0:6}
yyyy_m3=${PDYm3:0:4}
yyyymm_m3=${PDYm3:0:6}

#
#-----------------------------------------------------------------------
#
# Bias correction: PM25
#
#-----------------------------------------------------------------------
#
if [ "${PREDEF_GRID_NAME}" = "AQM_NA_13km" ]; then
  id_domain=793
fi

if [ ${#FCST_LEN_CYCL[@]} -gt 1 ]; then
  cyc_mod=$(( ${cyc} - ${DATE_FIRST_CYCL:8:2} ))
  CYCLE_IDX=$(( ${cyc_mod} / ${INCR_CYCL_FREQ} ))
  FCST_LEN_HRS=${FCST_LEN_CYCL[$CYCLE_IDX]}
fi

#-----------------------------------------------------------------------------
# STEP 1: Retrieve AIRNOW observation data
#-----------------------------------------------------------------------------

mkdir -p "${DATA}/data"

# Retrieve real-time airnow data for the last three days
  for ipdym in {1..3}; do
    case $ipdym in
      1)
        cvt_yyyy="${yyyy_m1}"
        cvt_yyyymm="${yyyymm_m1}"
        cvt_pdy="${PDYm1}"
        ;;
      2)
        cvt_yyyy="${yyyy_m2}"
        cvt_yyyymm="${yyyymm_m2}"
        cvt_pdy="${PDYm2}"
        ;;
      3)
        cvt_yyyy="${yyyy_m3}"
        cvt_yyyymm="${yyyymm_m3}"
        cvt_pdy="${PDYm3}"
        ;;
    esac

    cvt_input_dir="${DATA}/data/bcdata.${cvt_yyyymm}/airnow/csv"
    cvt_output_dir="${DATA}/data/bcdata.${cvt_yyyymm}/airnow/netcdf"
    cvt_input_fn="HourlyAQObs_YYYYMMDDHH.dat"
    cvt_output_fn="HourlyAQObs.YYYYMMDD.nc"
    cvt_input_fp="${cvt_input_dir}/YYYY/YYYYMMDD/${cvt_input_fn}"
    cvt_output_fp="${cvt_output_dir}/YYYY/YYYYMMDD/${cvt_output_fn}"

    mkdir -p "${cvt_input_dir}/${cvt_yyyy}/${cvt_pdy}"
    mkdir -p "${cvt_output_dir}/${cvt_yyyy}/${cvt_pdy}"
    #jp if [ "$(ls -A ${DCOMINairnow}/${cvt_pdy}/airnow)" ]; then
    if [ -s ${DCOMINairnow}/${cvt_pdy}/airnow/HourlyAQObs_${cvt_pdy}00.dat ]; then
      cp ${DCOMINairnow}/${cvt_pdy}/airnow/HourlyAQObs_${cvt_pdy}*.dat "${cvt_input_dir}/${cvt_yyyy}/${cvt_pdy}"
    else
      message_warning="WARNING: airnow data missing. skip this date ${cvt_pdy}"
      print_info_msg "${message_warning}"
    fi

    startmsg
    eval ${RUN_CMD_SERIAL} ${EXECaqm}/convert_airnow_csv ${cvt_input_fp} ${cvt_output_fp} ${cvt_pdy} ${cvt_pdy} ${REDIRECT_OUT_ERR} >> $pgmout 2>errfile
    export err=$?; err_chk
    if [ -e "${pgmout}" ]; then
      cat ${pgmout}
    fi
  done

#-----------------------------------------------------------------------------
# STEP 2:  Extracting PM2.5, O3, and met variables from CMAQ input and outputs
#-----------------------------------------------------------------------------

FCST_LEN_HRS=$( printf "%03d" ${FCST_LEN_HRS} )
ic=1
while [ $ic -lt 120 ]; do
  if [ -s ${COMIN}/${cyc}/${NET}.${cycle}.chem_sfc.f${FCST_LEN_HRS}.nc ]; then
    echo "cycle ${cyc} post1 is done!"
    break
  else  
    sleep 10
    (( ic=ic+1 ))
  fi    
done    

if [ $ic -ge 120 ]; then 
  print_err_msg_exit "FATAL ERROR - COULD NOT LOCATE:${NET}.${cycle}.chem_sfc.f${FCST_LEN_HRS}.nc"
fi      

# remove any pre-exit ${NET}.${cycle}.chem_sfc/met_sfc.nc for 2-stage post processing
DATA_grid="${DATA}/data/bcdata.${yyyymm}/grid"
if [ -d "${DATA_grid}/${cyc}z/${PDY}" ]; then
  rm -rf "${DATA_grid}/${cyc}z/${PDY}"
fi

mkdir -p "${DATA_grid}/${cyc}z/${PDY}"
cpreq ${COMIN}/${cyc}/${NET}.${cycle}.chem_sfc.*.nc ${DATA_grid}/${cyc}z/${PDY}
cpreq ${COMIN}/${cyc}/${NET}.${cycle}.met_sfc.*.nc ${DATA_grid}/${cyc}z/${PDY}

#-----------------------------------------------------------------------
# STEP 3:  Intepolating CMAQ PM2.5 into AIRNow sites
#-----------------------------------------------------------------------

mkdir -p ${DATA}/data/coords 
mkdir -p ${DATA}/data/site-lists.interp 
mkdir -p ${DATA}/out/pm25/${yyyy}
mkdir -p ${DATA}/data/bcdata.${yyyymm}/interpolated/pm25/${yyyy}

cpreq ${PARMaqm}/aqm_utils/bias_correction/sites.valid.pm25.20240610.12z.list ${DATA}/data/site-lists.interp
cpreq ${PARMaqm}/aqm_utils/bias_correction/aqm.t12z.chem_sfc.f000.nc ${DATA}/data/coords
cpreq ${PARMaqm}/aqm_utils/bias_correction/config.interp.pm2.5.5-vars_${id_domain}.${cyc}z ${DATA}

startmsg
eval ${RUN_CMD_SERIAL} ${EXECaqm}/aqm_bias_interpolate config.interp.pm2.5.5-vars_${id_domain}.${cyc}z ${cyc}z ${PDY} ${PDY} ${REDIRECT_OUT_ERR} >> $pgmout 2>errfile
export err=$? err_chk
if [ -e "${pgmout}" ]; then
   cat ${pgmout}
fi
cpreq ${DATA}/out/pm25/${yyyy}/*nc ${DATA}/data/bcdata.${yyyymm}/interpolated/pm25/${yyyy}

if [ "${DO_AQM_SAVE_AIRNOW_HIST}" = "TRUE" ]; then

   # NetCDF files
   for i in {1..3}; do
      yyyymm_m="yyyymm_m${i}"
      yyyy_m="yyyy_m${i}"
      PDYm="PDYm${i}"

      target_dir="${COMOUTbicor}/bcdata.${!yyyymm_m}/airnow/netcdf/${!yyyy_m}/${!PDYm}"

      if [ ! -d "$target_dir" ]; then
           mkdir -p "$target_dir"
      fi

      # Check if the file exists before attempting to copy it
      if [ -s "${DATA}/data/bcdata.${!yyyymm_m}/airnow/netcdf/${!yyyy_m}/${!PDYm}/HourlyAQObs.${!PDYm}.nc" ]; then
          cp "${DATA}/data/bcdata.${!yyyymm_m}/airnow/netcdf/${!yyyy_m}/${!PDYm}/HourlyAQObs.${!PDYm}.nc" "${COMOUTbicor}/bcdata.${!yyyymm_m}/airnow/netcdf/${!yyyy_m}/${!PDYm}"
       else
           message_warning="WARNING: File not found: HourlyAQObs.${!PDYm}.nc"
           print_info_msg "${message_warning}"
       fi
    done

   mkdir -p  ${COMOUTbicor}/bcdata.${yyyymm}/interpolated/pm25/${yyyy}
   cp ${DATA}/out/pm25/${yyyy}/*nc ${COMOUTbicor}/bcdata.${yyyymm}/interpolated/pm25/${yyyy}


   mkdir -p  "${COMOUTbicor}/bcdata.${yyyymm}/grid/${cyc}z/${PDY}"
   cpreq ${COMIN}/${cyc}/${NET}.${cycle}.*_sfc.f*.nc ${COMOUTbicor}/bcdata.${yyyymm}/grid/${cyc}z/${PDY}

   # Check if the directory exists before creating it
   if [ ! -d "${COMOUTbicor}/bcdata.${yyyymm}/grid/${cyc}z/${PDY}" ]; then
       mkdir -p "${COMOUTbicor}/bcdata.${yyyymm}/grid/${cyc}z/${PDY}"
   fi
   
   # Loop through files and copy each one individually if it exists
    for file in ${COMIN}/${cyc}/${NET}.${cycle}.*_sfc.f*.nc; do
      if [ -f "$file" ]; then
          cpreq "$file" "${COMOUTbicor}/bcdata.${yyyymm}/grid/${cyc}z/${PDY}"
      else
          message_warning="WARNING: File not found: ${NET}.${cycle}.*_sfc.f*.nc"
          print_info_msg "${message_warning}"
      fi
    done

fi

#-----------------------------------------------------------------------
# STEP 4:  Performing Bias Correction for PM2.5 
#-----------------------------------------------------------------------

rm -rf ${DATA}/data/bcdata*

ln -sf ${COMINbicor}/bcdata* "${DATA}/data"
#if [ $(find . -xtype l|wc -l) -gt 0 ]; then
if [ $(find "${DATA}/data" -xtype l | wc -l) -gt 0 ]; then
  message_txt="FATAL ERROR broken file or dir link found under ${DATA}"
  err_exit "${message_txt}"
fi 


mkdir -p ${DATA}/data/sites

cpreq ${PARMaqm}/aqm_utils/bias_correction/config.pm2.5.bias_corr_${id_domain}.${cyc}z ${DATA}
cpreq ${PARMaqm}/aqm_utils/bias_correction/site_blocking.pm2.5.2021.0427.2-sites.txt ${DATA}
cpreq ${PARMaqm}/aqm_utils/bias_correction/bias_thresholds.pm2.5.2015.1030.32-sites.txt ${DATA}

eval ${RUN_CMD_SERIAL} ${EXECaqm}/aqm_bias_correct config.pm2.5.bias_corr_${id_domain}.${cyc}z ${cyc}z ${BC_STDAY} ${PDY} ${REDIRECT_OUT_ERR} >> $pgmout 2>errfile
export err=$?; err_chk
if [ -e "${pgmout}" ]; then
   cat ${pgmout}
fi
cpreq $DATA/out/pm2.5.corrected* ${COMOUT}

if [ "${cyc}" = "12" ]; then
  cpreq ${DATA}/data/sites/sites.valid.pm25.${PDY}.${cyc}z.list ${DATA}
fi

#------------------------------------------------------------------------
# STEP 5:  converting netcdf to grib format
#------------------------------------------------------------------------

cpreq ${COMIN}/${cyc}/pm2.5.corrected.${PDY}.${cyc}z.nc .

# convert from netcdf to grib2 format
cat >bias_cor.ini <<EOF1
&control
varlist='PM25_TOT'
infile='pm2.5.corrected.${PDY}.${cyc}z.nc'
outfile='${NET}.${cycle}.pm25_bc'
id_gribdomain=${id_domain}
/
EOF1

startmsg 
eval ${RUN_CMD_SERIAL} ${EXECaqm}/aqm_post_bias_cor_grib2 ${PDY} ${cyc} ${REDIRECT_OUT_ERR} >> $pgmout 2>errfile
export err=$?; err_chk
if [ -e "${pgmout}" ]; then
   cat ${pgmout}
fi
cpreq ${DATA}/${NET}.${cycle}.pm25*bc*.grib2 ${COMOUT}

#-----------------------------------------------------------------------
# STEP 6: calculating 24-hr ave PM2.5
#------------------------------------------------------------------------

. prep_step

if [ "${cyc}" = "06" ] || [ "${cyc}" = "12" ]; then
  cpreq ${COMOUT}/pm2.5.corrected.${PDY}.${cyc}z.nc  a.nc 

  chk=1 
  chk1=1 
  # today 00z file exists otherwise chk=0
cat >bias_cor_max.ini <<EOF1
&control
varlist='pm25_24h_ave','pm25_1h_max'
outfile='aqm-pm25_bc'
id_gribdomain=${id_domain}
max_proc=72
/
EOF1

  flag_run_bicor_max=yes
  # 06z needs b.nc to find current day output from 04Z to 06Z
  if [ "${cyc}" = "06" ]; then
    if [ -s ${COMIN}/00/pm2.5.corrected.${PDY}.00z.nc ]; then
      cpreq ${COMIN}/00/pm2.5.corrected.${PDY}.00z.nc  b.nc 
    elif [ -s ${COMINm1}/12/pm2.5.corrected.${PDYm1}.12z.nc ]; then
      cpreq ${COMINm1}/12/pm2.5.corrected.${PDYm1}.12z.nc  b.nc
      chk=0
    else 
      flag_run_bicor_max=no
    fi
  fi

  if [ "${cyc}" = "12" ]; then
    # 12z needs b.nc to find current day output from 04Z to 06Z
    if [ -s ${COMIN}/00/pm2.5.corrected.${PDY}.00z.nc ]; then
      cpreq ${COMIN}/00/pm2.5.corrected.${PDY}.00z.nc  b.nc
    elif [ -s ${COMINm1}/12/pm2.5.corrected.${PDYm1}.12z.nc ]; then
      cpreq ${COMINm1}/12/pm2.5.corrected.${PDYm1}.12z.nc  b.nc
      chk=0
    else
      flag_run_bicor_max=no
    fi

    # 12z needs c.nc to find current day output from 07Z to 12z
    if [ -s ${COMIN}/06/pm2.5.corrected.${PDY}.06z.nc ]; then
      cpreq ${COMIN}/06/pm2.5.corrected.${PDY}.06z.nc c.nc
    elif [ -s ${COMINm1}/12/pm2.5.corrected.${PDYm1}.12z.nc ]; then
      cpreq ${COMINm1}/12/pm2.5.corrected.${PDYm1}.12z.nc  c.nc
      chk1=0
    else
      flag_run_bicor_max=no
    fi
  fi
  if [ "${flag_run_bicor_max}" = "yes" ]; then
    #-------------------------------------------------
    # write out grib2 format 
    #-------------------------------------------------
    startmsg
    eval ${RUN_CMD_SERIAL} ${EXECaqm}/aqm_post_maxi_bias_cor_grib2  ${PDY} ${cyc} ${chk} ${chk1} ${REDIRECT_OUT_ERR} >> $pgmout 2>errfile
    export err=$?; err_chk
    if [ -e "${pgmout}" ]; then
      cat ${pgmout}
    fi
    # split into two files: one for 24hr_ave and one for 1h_max
    wgrib2 aqm-pm25_bc.${id_domain}.grib2  |grep  "PMTF"   | ${WGRIB2} -i  aqm-pm25_bc.${id_domain}.grib2  -grib aqm.t${cyc}z.ave_24hr_pm25_bc.793.grib2 
    wgrib2 aqm-pm25_bc.${id_domain}.grib2  |grep  "PDMAX1" | ${WGRIB2} -i  aqm-pm25_bc.${id_domain}.grib2  -grib aqm.t${cyc}z.max_1hr_pm25_bc.793.grib2 
   
    cpreq ${DATA}/${NET}.${cycle}.ave_24hr_pm25_bc.${id_domain}.grib2 ${COMOUT}
    cpreq ${DATA}/${NET}.${cycle}.max_1hr_pm25_bc.${id_domain}.grib2 ${COMOUT}
  fi

  # interpolate to grid 227
  oldgrib2file1=${NET}.${cycle}.ave_24hr_pm25_bc.${id_domain}.grib2
  newgrib2file1=${NET}.${cycle}.tmp.ave_24hr_pm25_bc.227.grib2

  grid227="lambert:265.0000:25.0000:25.0000 226.5410:1473:5079.000 12.1900:1025:5079.000"
  wgrib2 ${oldgrib2file1} -set_grib_type c3b -new_grid_winds grid -new_grid ${grid227}  ${newgrib2file1} 

  oldgrib2file2=${NET}.${cycle}.max_1hr_pm25_bc.${id_domain}.grib2
  newgrib2file2=${NET}.${cycle}.tmp.max_1hr_pm25_bc.227.grib2
  wgrib2 ${oldgrib2file2} -set_grib_type c3b -new_grid_winds grid -new_grid ${grid227}  ${newgrib2file2}

  # fix res flags
  wgrib2 -set_flag_table_3.3 8 "${newgrib2file1}" -grib "${NET}.${cycle}.ave_24hr_pm25_bc.227.grib2"
  wgrib2 -set_flag_table_3.3 8 "${newgrib2file2}" -grib "${NET}.${cycle}.max_1hr_pm25_bc.227.grib2"

  cpreq ${NET}.${cycle}.max_1hr_pm25_bc.${id_domain}.grib2   ${COMOUT}
  cpreq ${NET}.${cycle}.ave_24hr_pm25_bc.${id_domain}.grib2  ${COMOUT}
  cpreq ${NET}.${cycle}.max_1hr_pm25_bc.227.grib2   ${COMOUT}
  cpreq ${NET}.${cycle}.ave_24hr_pm25_bc.227.grib2  ${COMOUT}

  if [ "${SENDDBN}" = "YES" ]; then
    ${DBNROOT}/bin/dbn_alert MODEL AQM_MAX ${job} ${COMOUT}/${NET}.${cycle}.max_1hr_pm25_bc.227.grib2
    ${DBNROOT}/bin/dbn_alert MODEL AQM_PM ${job} ${COMOUT}/${NET}.${cycle}.ave_24hr_pm25_bc.227.grib2
#    ${DBNROOT}/bin/dbn_alert MODEL AQM_MAX ${job} ${COMOUT}/${NET}.${cycle}.max_1hr_pm25_bc.793.grib2
#    ${DBNROOT}/bin/dbn_alert MODEL AQM_PM ${job} ${COMOUT}/${NET}.${cycle}.ave_24hr_pm25_bc.793.grib2
  fi
fi

fhr=01
while [ "${fhr}" -le "${FCST_LEN_HRS}" ]; do
  fhr3d=$( printf "%03d" "${fhr}" )
  cat ${DATA}/${NET}.${cycle}.pm25_bc.f${fhr3d}.${id_domain}.grib2 >> tmpfile_pm25_bc
  (( fhr=fhr+1 ))
done

grid227="lambert:265.0000:25.0000:25.0000 226.5410:1473:5079.000 12.1900:1025:5079.000"
wgrib2 tmpfile_pm25_bc -set_grib_type c3b -new_grid_winds grid -new_grid ${grid227} ${NET}.${cycle}.tmp.grib2_pm25_bc.227

# fix res flags
wgrib2 -set_flag_table_3.3 8 "${NET}.${cycle}.tmp.grib2_pm25_bc.227" -grib "${NET}.${cycle}.grib2_pm25_bc.227"

cpreq tmpfile_pm25_bc ${COMOUT}/${NET}.${cycle}.ave_1hr_pm25_bc.${id_domain}.grib2
cpreq ${NET}.${cycle}.grib2_pm25_bc.227 ${COMOUT}/${NET}.${cycle}.ave_1hr_pm25_bc.227.grib2
if [ "${cyc}" = "06" ] || [ "${cyc}" = "12" ]; then
 if [ "${SENDDBN}" = "YES" ]; then
  ${DBNROOT}/bin/dbn_alert MODEL AQM_PM ${job} ${COMOUT}/${NET}.${cycle}.ave_1hr_pm25_bc.227.grib2
#  ${DBNROOT}/bin/dbn_alert MODEL AQM_PM ${job} ${COMOUT}/${NET}.${cycle}.ave_1hr_pm25_bc.793.grib2
 fi
fi

#--------------------------------------------------------------
# STEP 7: adding WMO header  
#--------------------------------------------------------------

# Create AWIPS GRIB2 data for Bias-Corrected PM2.5
if [ "${cyc}" = "06" ] || [ "${cyc}" = "12" ]; then
  echo 0 > filesize
  export XLFRTEOPTS="unit_vars=yes"
  export FORT11=${NET}.${cycle}.grib2_pm25_bc.227
  export FORT12="filesize"
  export FORT51=${NET}.${cycle}.grib2_pm25_bc.227.temp
  tocgrib2super < ${PARMaqm}/aqm_utils/wmo/grib2_aqm_pm25_bc.${cycle}.227

  echo `ls -l ${NET}.${cycle}.grib2_pm25_bc.227.temp  | awk '{print $5} '` > filesize
  export XLFRTEOPTS="unit_vars=yes"
  export FORT11=${NET}.${cycle}.grib2_pm25_bc.227.temp
  export FORT12="filesize"
  export FORT51=awpaqm.${cycle}.1hpm25-bc.227.grib2
  tocgrib2super < ${PARMaqm}/aqm_utils/wmo/grib2_aqm_pm25_bc.${cycle}.227

  ####################################################
  rm -f filesize
  echo 0 > filesize
  export XLFRTEOPTS="unit_vars=yes"
  export FORT11=${NET}.${cycle}.max_1hr_pm25_bc.227.grib2
  export FORT12="filesize"
  export FORT51=${NET}.${cycle}.max_1hr_pm25_bc.227.grib2.temp
  tocgrib2super < ${PARMaqm}/aqm_utils/wmo/grib2_aqm_max_1hr_pm25_bc.${cycle}.227

  echo `ls -l  ${NET}.${cycle}.max_1hr_pm25_bc.227.grib2.temp | awk '{print $5} '` > filesize
  export XLFRTEOPTS="unit_vars=yes"
  export FORT11=${NET}.${cycle}.max_1hr_pm25_bc.227.grib2.temp
  export FORT12="filesize"
  export FORT51=awpaqm.${cycle}.daily-1hr-pm25-max-bc.227.grib2
  tocgrib2super < ${PARMaqm}/aqm_utils/wmo/grib2_aqm_max_1hr_pm25_bc.${cycle}.227

  rm -f filesize
  # daily_24hr_ave_PM2.5
  echo 0 > filesize
  export XLFRTEOPTS="unit_vars=yes"
  export FORT11=${NET}.${cycle}.ave_24hr_pm25_bc.227.grib2
  export FORT12="filesize"
  export FORT51=${NET}.${cycle}.ave_24hr_pm25_bc.227.grib2.temp
  tocgrib2super < ${PARMaqm}/aqm_utils/wmo/grib2_aqm_ave_24hrpm25_bc_awp.${cycle}.227

  echo `ls -l  ${NET}.${cycle}.ave_24hr_pm25_bc.227.grib2.temp | awk '{print $5} '` > filesize
  export XLFRTEOPTS="unit_vars=yes"
  export FORT11=${NET}.${cycle}.ave_24hr_pm25_bc.227.grib2.temp
  export FORT12="filesize"
  export FORT51=awpaqm.${cycle}.24hr-pm25-ave-bc.227.grib2
  tocgrib2super < ${PARMaqm}/aqm_utils/wmo/grib2_aqm_ave_24hrpm25_bc_awp.${cycle}.227

  # Post Files to COMOUTwmo
  cpreq awpaqm.${cycle}.1hpm25-bc.227.grib2             ${COMOUTwmo}
  cpreq awpaqm.${cycle}.daily-1hr-pm25-max-bc.227.grib2 ${COMOUTwmo}
  cpreq awpaqm.${cycle}.24hr-pm25-ave-bc.227.grib2      ${COMOUTwmo}

  # Distribute Data
  if [ "${SENDDBN_NTC}" = "YES" ] ; then
    ${DBNROOT}/bin/dbn_alert ${DBNALERT_TYPE} ${NET} ${job} ${COMOUTwmo}/awpaqm.${cycle}.1hpm25-bc.227.grib2
    ${DBNROOT}/bin/dbn_alert ${DBNALERT_TYPE} ${NET} ${job} ${COMOUTwmo}/awpaqm.${cycle}.daily-1hr-pm25-max-bc.227.grib2
    ${DBNROOT}/bin/dbn_alert ${DBNALERT_TYPE} ${NET} ${job} ${COMOUTwmo}/awpaqm.${cycle}.24hr-pm25-ave-bc.227.grib2
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
BIAS-CORRECTION-PM25 completed successfully.

Exiting script:  \"${scrfunc_fn}\"
In directory:    \"${scrfunc_dir}\"
========================================================================"
#
#-----------------------------------------------------------------------
#
{ restore_shell_opts; } > /dev/null 2>&1
