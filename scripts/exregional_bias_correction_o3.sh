#!/bin/bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. $USHdir/source_util_funcs.sh
source_config_for_task "cpl_aqm_parm|task_run_post" ${GLOBAL_VAR_DEFNS_FP}
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
This is the ex-script for the task that runs BIAS-CORRECTION-O3.
========================================================================"
#
#-----------------------------------------------------------------------
#
# Set OpenMP variables.
#
#-----------------------------------------------------------------------
#
export KMP_AFFINITY=${KMP_AFFINITY_BIAS_CORRECTION_O3}
export OMP_NUM_THREADS=${OMP_NUM_THREADS_BIAS_CORRECTION_O3}
export OMP_STACKSIZE=${OMP_STACKSIZE_BIAS_CORRECTION_O3}
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
DATA="${DATA}/tmp_BIAS_CORRECTION_O3"
mkdir_vrfy -p "$DATA"
cd_vrfy $DATA

set -x

yyyy=${PDY:0:4}
#
#-----------------------------------------------------------------------
#
# Bias correction: O3
#
#-----------------------------------------------------------------------
#
if [ "${PREDEF_GRID_NAME}" = "AQM_NA_13km" ]; then
  id_domain=793
fi

case $cyc in
  00) bc_interp_hr=06;;
  06) bc_interp_hr=72;;
  12) bc_interp_hr=72;;
  18) bc_interp_hr=06;;
esac

#-----------------------------------------------------------------------------
# STEP 1:  Extracting PM2.5, O3, and met variables from CMAQ input and outputs

# remove any pre-exit ${NET}.${cycle}.chem_sfc/met_sfc.nc for 2-stage post processing
if [ -d ${DATA}/grid/${cyc}z/${PDY} ]; then
  rm_vrfy -rf ${DATA}/grid/${cyc}z/${PDY}
fi

mkdir_vrfy -p ${DATA}/grid/${cyc}z/${PDY}
mkdir_vrfy -p ${DATA}/data/coords 
mkdir_vrfy -p ${DATA}/data/site-lists.interp 
mkdir_vrfy -p ${DATA}/setup
mkdir_vrfy -p ${DATA}/out/ozone/${yyyy}
mkdir_vrfy -p ${DATA}/interpolated/ozone/${yyyy} 

ln_vrfy -sf ${COMIN}/${NET}.${cycle}.chem_sfc.*.nc ${DATA}/grid/${cyc}z/${PDY}
ln_vrfy -sf ${COMIN}/${NET}.${cycle}.met_sfc.*.nc ${DATA}/grid/${cyc}z/${PDY}

#-----------------------------------------------------------------------
# STEP 2 :  Intepolating CMAQ O3 into AIRNow sites

ln_vrfy -sf ${PARMaqm_utils}/sites.valid.ozone.20220724.12z.list ${DATA}/data/site-lists.interp
ln_vrfy -sf ${PARMaqm_utils}/setup.wcoss2.ifort.serial.opt-zero ${DATA}/setup
ln_vrfy -sf ${PARMaqm_utils}/aqm.t12z.chem_sfc.f000.nc ${DATA}/data/coords
ln_vrfy -sf ${PARMaqm_utils}/config.interp.ozone.7-vars_${id_domain}.${cyc}z ${DATA}
ln_vrfy -sf ${COMINbicor} ${DATA}/data

source ${DATA}/setup/setup.wcoss2.ifort.serial.opt-zero

${EXECdir}/aqm_bias_interpolate config.interp.ozone.7-vars_${id_domain}.${cyc}z ${cyc}z ${PDY} ${PDY}

cp_vrfy ${DATA}/out/ozone/${yyyy}/*nc ${DATA}/interpolated/ozone/${yyyy}

#-----------------------------------------------------------------------
# STEP 3:  Performing Bias Correction for PM2.5 

mkdir_vrfy -p ${DATA}/data/sites

ln_vrfy -sf ${PARMaqm_utils}/setup.wcoss2.ifort.parallel.opt-3 ${DATA}/setup
ln_vrfy -sf ${PARMaqm_utils}/config.ozone.bias_corr_${id_domain}.${cyc}z ${DATA}

source ${DATA}/setup/setup.wcoss2.ifort.parallel.opt-3
  
${EXECdir}/aqm_bias_correct config.ozone.bias_corr_${id_domain}.${cyc}z ${cyc}z ${BC_STDAY} ${PDY}
 
cp_vrfy ${DATA}/out/ozone.corrected* ${COMIN}

if [ "${cyc}" = "12" ]; then
  cp_vrfy ${DATA}/sites/sites.valid.ozone.${PDY}.${cyc}z.list ${DATA}
fi

#------------------------------------------------------------------------
# STEP 4:  converting netcdf to grib format

ln_vrfy -sf ${COMIN}/ozone.corrected.${PDY}.${cyc}z.nc .

#
cat >bias_cor.ini <<EOF1
&control
varlist='o3','O3_8hr'
infile='ozone.corrected.${PDY}.${cyc}z.nc'
outfile='${NET}.${cycle}.awpozcon_bc'
id_gribdomain=${id_domain}
/
EOF1

# convert from netcdf to grib2 format
${EXECdir}/aqm_post_bias_cor_grib2 ${PDY} ${cyc} 

cp_vrfy ${DATA}/${NET}.${cycle}.awpozcon*bc*.grib2 ${COMOUT}

#--------------------------------------------------------------
# STEP 5: calculating 24-hr ave PM2.5
if [ "${cyc}" = "06" ] || [ "${cyc}" = "12" ]; then
  ln_vrfy -sf ${COMOUT}/ozone.corrected.${PDY}.${cyc}z.nc a.nc 

  chk=1 
  chk1=1 
  # today 00z file exists otherwise chk=0
cat >bias_cor_max.ini <<EOF1
&control
varlist='O3_1h_max','O3_8h_max'
outfile='aqm-maxi_bc'
id_gribdomain=${id_domain}
max_proc=72
/
EOF1

  flag_run_bicor_max=yes
  # 06z needs b.nc to find current day output from 04Z to 06Z
  if [ "${cyc}" = "06" ]; then
    if [ -s ${COMIN_PDY}/00/ozone.corrected.${PDY}.00z.nc ]; then
      ln_vrfy -sf ${COMIN_PDY}/00/ozone.corrected.${PDY}.00z.nc b.nc
    elif [ -s ${COMIN_PDYm1}/12/ozone.corrected.${PDYm1}.12z.nc ]; then
      ln_vrfy -sf ${COMIN_PDYm1}/12/ozone.corrected.${PDYm1}.12z.nc b.nc
      chk=0
    else
      flag_run_bicor_max=no
    fi
  fi

  if [ "${cyc}" = "12" ]; then
    # 12z needs b.nc to find current day output from 04Z to 06Z
    if [ -s ${COMIN_PDY}/00/ozone.corrected.${PDY}.00z.nc ]; then
      ln_vrfy -sf ${COMIN_PDY}/00/ozone.corrected.${PDY}.00z.nc b.nc
    elif [ -s ${COMIN_PDYm1}/12/ozone.corrected.${PDYm1}.12z.nc ]; then
      ln_vrfy -sf ${COMIN_PDYm1}/12/ozone.corrected.${PDYm1}.12z.nc b.nc
      chk=0
    else
      flag_run_bicor_max=no
    fi

    # 12z needs c.nc to find current day output from 07Z to 12z
    if [ -s ${COMIN_PDY}/06/ozone.corrected.${PDY}.06z.nc ]; then
      ln_vrfy -sf ${COMIN_PDY}/06/ozone.corrected.${PDY}.06z.nc c.nc
    elif [ -s ${COMIN_PDYm1}/12/ozone.corrected.${PDYm1}.12z.nc ]; then
      ln_vrfy -sf ${COMIN_PDYm1}/12/ozone.corrected.${PDYm1}.12z.nc c.nc
      chk1=0
    else
      flag_run_bicor_max=no
    fi
  fi

  if [ "${flag_run_bicor_max}" = "yes" ]; then
    #-------------------------------------------------
    # write out grib2 format 
    #-------------------------------------------------
    ${EXECdir}/aqm_post_maxi_bias_cor_grib2  ${PDY} ${cyc} ${chk} ${chk1}
   
    # split into max_1h and max_8h files and copy to grib227
    wgrib2 aqm-maxi_bc.${id_domain}.grib2 |grep "OZMAX1" | wgrib2 -i aqm-maxi_bc.${id_domain}.grib2 -grib  ${NET}.${cycle}.max_1hr_o3_bc.${id_domain}.grib2
    wgrib2 aqm-maxi_bc.${id_domain}.grib2 |grep "OZMAX8" | wgrib2 -i aqm-maxi_bc.${id_domain}.grib2 -grib  ${NET}.${cycle}.max_8hr_o3_bc.${id_domain}.grib2

    grid227="lambert:265.0000:25.0000:25.0000 226.5410:1473:5079.000 12.1900:1025:5079.000"
   
    wgrib2 ${NET}.${cycle}.max_8hr_o3_bc.${id_domain}.grib2 -set_grib_type same -new_grid_winds earth -new_grid ${grid227} ${NET}.${cycle}.max_8hr_o3_bc.227.grib2
    wgrib2 ${NET}.${cycle}.max_1hr_o3_bc.${id_domain}.grib2 -set_grib_type same -new_grid_winds earth -new_grid ${grid227} ${NET}.${cycle}.max_1hr_o3_bc.227.grib2

    cp_vrfy ${DATA}/${NET}.${cycle}.max_*hr_o3_bc.*.grib2 ${COMOUT}
   
    if [ "$SENDDBN" = "YES" ]; then
      ${DBNROOT}/bin/dbn_alert MODEL AQM_MAX ${job} ${COMOUT}/${NET}.${cycle}.max_1hr_o3_bc.227.grib2
      ${DBNROOT}/bin/dbn_alert MODEL AQM_MAX ${job} ${COMOUT}/${NET}.${cycle}.max_8hr_o3_bc.227.grib2
    fi
   
    # Add WMO header for daily 1h and 8h max O3 
    for hr in 1 8; do
      echo 0 > filesize
      export XLFRTEOPTS="unit_vars=yes"
      export FORT11=${NET}.${cycle}.max_${hr}hr_o3_bc.227.grib2
      export FORT12="filesize"
      export FORT31=
      export FORT51=${NET}-${hr}hro3-maxi.227.grib2.temp
      tocgrib2super < ${PARMaqm_utils}/wmo/grib2_aqm-${hr}hro3-maxi.${cycle}.227
   
      echo `ls -l ${NET}-${hr}hro3-maxi.227.grib2.temp | awk '{print $5} '` > filesize
      export XLFRTEOPTS="unit_vars=yes"
      export FORT11=${NET}-${hr}hro3-maxi.227.grib2.temp
      export FORT12="filesize"
      export FORT31=
      export FORT51=awpaqm.${cycle}.${hr}ho3-max-bc.227.grib2
      tocgrib2super < ${PARMaqm_utils}/wmo/grib2_aqm-${hr}hro3-maxi.${cycle}.227
    done
   
    # Post Files to COMOUT
    cp_vrfy awpaqm.${cycle}.*o3-max-bc.227.grib2 ${COMOUT}

    # Distribute Data
    if [ "${SENDDBN_NTC}" = "YES" ] ; then
      ${DBNROOT}/bin/dbn_alert ${DBNALERT_TYPE} ${NET} ${job} ${COMOUT}/awpaqm.${cycle}.1ho3-max-bc.227.grib2
      ${DBNROOT}/bin/dbn_alert ${DBNALERT_TYPE} ${NET} ${job} ${COMOUT}/awpaqm.${cycle}.8ho3-max-bc.227.grib2
    fi
  fi
fi

#-------------------------------------
fhr=01
case $cyc in
  00) endfhr=06;;
  06) endfhr=72;;
  12) endfhr=72;;
  18) endfhr=06;;
esac

rm_vrfy -rf tmpfile

while [ "${fhr}" -le "${endfhr}" ]; do
  fhr=$( printf "%02d" "${fhr}" )
  
  cp_vrfy ${DATA}/${NET}.${cycle}.awpozcon_bc.f${fhr}.${id_grib}.grib2 ${COMIN}

  # create GRIB file to convert to grid 227 then to GRIB2 for NDFD
  cat ${DATA}/${NET}.${cycle}.awpozcon_bc.f${fhr}.${id_grib}.grib2 >> tmpfile
  if [ "${fhr}" -le "07" ]; then
    cat ${DATA}/${NET}.${cycle}.awpozcon_bc.f${fhr}.${id_grib}.grib2 >> tmpfile.1hr
  else
    ${DATA}/${NET}.${cycle}.awpozcon_bc.f${fhr}.${id_grib}.grib2 -d 1 -append -grib tmpfile.1hr
    wgrib2 ${DATA}/${NET}.${cycle}.awpozcon_bc.f${fhr}.${id_grib}.grib2 -d 2 -append -grib tmpfile.8hr
  fi
  (( fhr=fhr+1 ))
done

###############
# Convert ozone Concentration to grid 227 in GRIB2 format
###############
echo ' &NLCOPYGB IDS(180)=1, /' > ozcon_scale

newgrib2file1=${NET}.${cycle}.ave_1hr_o3_bc.227.grib2
newgrib2file2=${NET}.${cycle}.ave_8hr_o3_bc.227.grib2

grid227="lambert:265.0000:25.0000:25.0000 226.5410:1473:5079.000 12.1900:1025:5079.000"

wgrib2 tmpfile.1hr -set_grib_type same -new_grid_winds earth -new_grid ${grid227} ${newgrib2file1} 
cp_vrfy tmpfile.1hr ${COMOUT}/${NET}.${cycle}.ave_1hr_o3_bc.${id_domain}.grib2
cp_vrfy ${NET}.${cycle}.ave_1hr_o3_bc.227.grib2 ${COMOUT}

if [ "${cyc}" = "06" ] || [ "${cyc}" = "12" ]; then
  wgrib2 tmpfile.8hr -set_grib_type same -new_grid_winds earth -new_grid ${grid227} ${newgrib2file2} 
  cp_vrfy tmpfile.8hr ${COMOUT}/${NET}.${cycle}.ave_8hr_o3_bc.${id_domain}.grib2
  cp_vrfy ${NET}.${cycle}.ave_8hr_o3_bc.227.grib2 ${COMOUT}
fi

if [ "${SENDDBN}" = "YES" ] ; then
   ${DBNROOT}/bin/dbn_alert MODEL AQM_CONC ${job} ${COMOUT}/${NET}.${cycle}.ave_1hr_o3_bc.227.grib2
  if [ "${cyc}" = "06" ] || [ "${cyc}" = "12" ]; then
   ${DBNROOT}/bin/dbn_alert MODEL AQM_CONC ${job} ${COMOUT}/${NET}.${cycle}.ave_8hr_o3_bc.227.grib2
  fi
fi

#################################################
#    Part III:  Insert WMO header to GRIB files
#################################################

if [ "${cyc}" = "06" ] || [ "${cyc}" = "12" ]; then
  # Create AWIPS GRIB data for 1hr and 8hr ave ozone
  for hr in 1 8; do
    echo 0 > filesize
    export XLFRTEOPTS="unit_vars=yes"
    export FORT11=${NET}.${cycle}.ave_${hr}hr_o3_bc.227.grib2
    export FORT12="filesize"
    export FORT31=
    export FORT51=grib2.${cycle}.awpcsozcon_aqm_${hr}-bc.temp
    tocgrib2super < ${PARMaqm_utils}/wmo/grib2_aqm_ave_${hr}hr_o3_bc-awpozcon.${cycle}.227

    echo `ls -l grib2.${cycle}.awpcsozcon_aqm_${hr}-bc.temp  | awk '{print $5} '` > filesize
    export XLFRTEOPTS="unit_vars=yes"
    export FORT11=grib2.${cycle}.awpcsozcon_aqm_${hr}-bc.temp
    export FORT12="filesize"
    export FORT31=
    export FORT51=awpaqm.${cycle}.${hr}ho3-bc.227.grib2
    tocgrib2super < ${PARMaqm_utils}/wmo/grib2_aqm_ave_${hr}hr_o3_bc-awpozcon.${cycle}.227

    # Create AWIPS GRIB data for dailly 1-hr and 8hr max ozone
    echo 0 > filesize
    export XLFRTEOPTS="unit_vars=yes"
    export FORT11=${NET}.${cycle}.max_${hr}hr_o3_bc.227.grib2
    export FORT12="filesize"
    export FORT31=
    export FORT51=${NET}.${cycle}.max_${hr}hr_o3-bc.227.grib2.temp
    tocgrib2super < ${PARMaqm_utils}/wmo/grib2_aqm-${hr}hro3_bc-maxi.${cycle}.227

    echo `ls -l  ${NET}.${cycle}.max_${hr}hr_o3-bc.227.grib2.temp | awk '{print $5} '` > filesize
    export XLFRTEOPTS="unit_vars=yes"
    export FORT11=${NET}.${cycle}.max_${hr}hr_o3-bc.227.grib2.temp
    export FORT12="filesize"
    export FORT31=
    export FORT51=awpaqm.${cycle}.${hr}ho3-max-bc.227.grib2
    tocgrib2super < ${PARMaqm_utils}/wmo/grib2_aqm-${hr}hro3_bc-maxi.${cycle}.227

    # Post Files to COMOUT
    cp_vrfy awpaqm.${cycle}.${hr}ho3-bc.227.grib2 ${COMOUT}
    cp_vrfy awpaqm.${cycle}.${hr}ho3-max-bc.227.grib2 ${COMOUT}

    # Distribute Data
    if [ "${SENDDBN}" = "YES" ]; then
      ${DBNROOT}/bin/dbn_alert ${DBNALERT_TYPE} ${NET} ${job} ${COMOUT}/awpaqm.${cycle}.${hr}ho3-bc.227.grib2
      ${DBNROOT}/bin/dbn_alert ${DBNALERT_TYPE} ${NET} ${job} ${COMOUT}/awpaqm.${cycle}.${hr}ho3-max-bc.227.grib2
    fi
  done
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
BIAS-CORRECTION-O3 completed successfully.

Exiting script:  \"${scrfunc_fn}\"
In directory:    \"${scrfunc_dir}\"
========================================================================"
#
#-----------------------------------------------------------------------
#
{ restore_shell_opts; } > /dev/null 2>&1
