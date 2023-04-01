#!/bin/bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. $USHdir/source_util_funcs.sh
source_config_for_task "cpl_aqm_parm|task_run_post|task_post_stat_o3" ${GLOBAL_VAR_DEFNS_FP}
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

This is the ex-script for the task that runs POST-STAT-O3.
========================================================================"
#
#-----------------------------------------------------------------------
#
# Set OpenMP variables.
#
#-----------------------------------------------------------------------
#
export KMP_AFFINITY=${KMP_AFFINITY_POST_STAT_O3}
export OMP_NUM_THREADS=${OMP_NUM_THREADS_POST_STAT_O3}
export OMP_STACKSIZE=${OMP_STACKSIZE_POST_STAT_O3}
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
DATA="${DATA}/tmp_POST_STAT_O3"
mkdir_vrfy -p "$DATA"
cd_vrfy $DATA

set -x
#
#-----------------------------------------------------------------------
#
# POST-STAT: O3
#
#-----------------------------------------------------------------------
#
if [ "${PREDEF_GRID_NAME}" = "AQM_NA_13km" ]; then
  id_domain=793
fi

ln_vrfy -sf ${COMIN}/${NET}.${cycle}.chem_sfc.nc .

#
cat >aqm_post.ini <<EOF1
&control
varlist='o3','O3_8hr'
infile='${NET}.${cycle}.chem_sfc.nc'
outfile='${NET}.${cycle}.awpozcon'
id_gribdomain=${id_domain}
/
EOF1

# convert from netcdf to grib2 format
PREP_STEP
eval ${RUN_CMD_SERIAL} ${EXECdir}/aqm_post_grib2 ${PDY} ${cyc} ${REDIRECT_OUT_ERR} || print_err_msg_exit "\
Call to executable to run AQM_POST_GRIB2 returned with nonzero exit code."
POST_STEP

if [ "${FCST_LEN_HRS}" = "-1" ]; then
  CYCLE_IDX=$(( ${cyc} / ${INCR_CYCL_FREQ} ))
  FCST_LEN_HRS=${FCST_LEN_CYCL[$CYCLE_IDX]}
fi

fhr=01
while [ ${fhr} -le ${FCST_LEN_HRS} ]; do
  fhr9=$( printf "%02d" "${fhr}" )

  if [ "${fhr9}" -le "07" ]; then
    cat ${DATA}/${NET}.${cycle}.awpozcon.f${fhr9}.${id_domain}.grib2 >> ${NET}.${cycle}.1ho3.${id_domain}.grib2
  else
    wgrib2 ${DATA}/${NET}.${cycle}.awpozcon.f${fhr9}.${id_domain}.grib2 -d 1 -append -grib ${NET}.${cycle}.1ho3.${id_domain}.grib2
    wgrib2 ${DATA}/${NET}.${cycle}.awpozcon.f${fhr9}.${id_domain}.grib2 -d 2 -append -grib ${NET}.${cycle}.8ho3.${id_domain}.grib2
  fi
  (( fhr=fhr+1 ))
done

grid227="lambert:265.0000:25.0000:25.0000 226.5410:1473:5079.000 12.1900:1025:5079.000"
#grid148="lambert:263.0000:33.0000:45.0000 239.3720:442:12000.000 21.8210:265:12000.000"
grid196="mercator:20.0000 198.4750:321:2500.000:206.1310 18.0730:255:2500.000:23.0880"
grid198="nps:210.0000:60.0000 181.4290:825:5953.000 40.5300:553:5953.000"

for grid in 227 196 198;do
  gg="grid${grid}"
  wgrib2 ${NET}.${cycle}.1ho3.${id_domain}.grib2 -set_grib_type c3b -new_grid_winds earth -new_grid ${!gg} ${NET}.${cycle}.1ho3.${grid}.grib2

  if [ "${cyc}" = "06" ] || [ "${cyc}" = "12" ]; then
    wgrib2 ${NET}.${cycle}.8ho3.${id_domain}.grib2 -set_grib_type c3b -new_grid_winds earth -new_grid ${!gg} ${NET}.${cycle}.8ho3.${grid}.grib2

    for hr in 1 8; do
      echo 0 > filesize
      export XLFRTEOPTS="unit_vars=yes"
      export FORT11=${NET}.${cycle}.${hr}ho3.${grid}.grib2
      export FORT12="filesize"
      export FORT31=
      export FORT51=grib2.${cycle}.${hr}awpcsozcon.${grid}.temp
      tocgrib2super < ${PARMaqm_utils}/wmo/grib2_aqm_ave_${hr}hr_o3-awpozcon.${cycle}.${grid}

      echo `ls -l grib2.${cycle}.${hr}awpcsozcon.${grid}.temp  | awk '{print $5} '` > filesize
      export XLFRTEOPTS="unit_vars=yes"
      export FORT11=grib2.${cycle}.${hr}awpcsozcon.${grid}.temp
      export FORT12="filesize"
      export FORT31=
      export FORT51=awpaqm.${cycle}.${hr}ho3.${grid}.grib2
      tocgrib2super < ${PARMaqm_utils}/wmo/grib2_aqm_ave_${hr}hr_o3-awpozcon.${cycle}.${grid}
    done
    for var in 1ho3 8ho3 awpozcon;do
      cp_vrfy ${DATA}/${NET}.${cycle}.${var}*grib2 ${COMOUT}
      cp_vrfy ${DATA}/awpaqm.${cycle}.${var}*grib2 ${COMOUT}
    done
  else
    for var in 1ho3 awpozcon;do
      cp_vrfy ${DATA}/${NET}.${cycle}.${var}*grib2 ${COMOUT}
    done
  fi
done

#------------------------------------------------------------
# o3_post_maxi
#------------------------------------------------------------
if [ "${cyc}" = "06" ] || [ "${cyc}" = "12" ]; then

  ln_vrfy -sf ${COMIN}/${NET}.${cycle}.chem_sfc.nc a.nc

  export chk=1
  export chk1=1
  # today 00z file exists otherwise chk=0

cat >aqm_max.ini <<EOF1
&control
varlist='O3_1h_max','O3_8h_max'
outfile='aqm-maxi'
id_gribdomain=${id_domain}
max_proc=72
/
EOF1

  flag_run_bicor_max=yes

  ## 06z needs b.nc to find current day output from 04Z to 06Z
  if [ "${cyc}" = "06" ]; then
    if [ -s ${COMIN_PDY}/00/${NET}.t00z.chem_sfc.nc ]; then
      ln_vrfy -s  ${COMIN_PDY}/00/${NET}.t00z.chem_sfc.nc b.nc
    elif [ -s ${COMIN_PDYm1}/12/${NET}.t12z.chem_sfc.nc ]; then
      ln_vrfy -s ${COMIN_PDYm1}/12/${NET}.t12z.chem_sfc.nc b.nc
      chk=0
    else
      flag_run_bicor_max=no
    fi
  fi

  if [ "${cyc}" = "12" ]; then
    ## 12z needs b.nc to find current day output from 04Z to 06Z 
    if [ -s ${COMIN_PDY}/00/${NET}.t00z.chem_sfc.nc ]; then
      ln_vrfy -s ${COMIN_PDY}/00/${NET}.t00z.chem_sfc.nc b.nc
    elif [ -s ${COMIN_PDYm1}/12/${NET}.t12z.chem_sfc.nc ]; then
      ln_vrfy -s ${COMIN_PDYm1}/12/${NET}.t12z.chem_sfc.nc b.nc
      chk=0
    else
      flag_run_bicor_max=no
    fi

    ## 12z needs c.nc to find current day output from 07Z to 12z
    if [ -s ${COMIN_PDY}/06/${NET}.t06z.chem_sfc.nc ]; then
      ln_vrfy -s ${COMIN_PDY}/06/${NET}.t06z.chem_sfc.nc c.nc
    elif [ -s ${COMIN_PDYm1}/12/${NET}.t12z.chem_sfc.nc ]; then
      ln_vrfy -s ${COMIN_PDYm1}/12/${NET}.t12z.chem_sfc.nc c.nc
      chk1=0
    else
      flag_run_bicor_max=no
    fi
  fi

  PREP_STEP
  eval ${RUN_CMD_SERIAL} ${EXECdir}/aqm_post_maxi_grib2 ${PDY} ${cyc} ${chk} ${chk1} ${REDIRECT_OUT_ERR} || print_err_msg_exit "\
  Call to executable to run AQM_POST_MAXI_GRIB2 returned with nonzero exit code."
  POST_STEP

  # split into max_1h and max_8h files and copy to grib227
  wgrib2 aqm-maxi.${id_domain}.grib2 |grep "OZMAX1" | wgrib2 -i aqm-maxi.${id_domain}.grib2 -grib ${NET}.${cycle}.max_1hr_o3.${id_domain}.grib2
  wgrib2 aqm-maxi.${id_domain}.grib2 |grep "OZMAX8" | wgrib2 -i aqm-maxi.${id_domain}.grib2 -grib ${NET}.${cycle}.max_8hr_o3.${id_domain}.grib2

  grid227="lambert:265.0000:25.0000:25.0000 226.5410:1473:5079.000 12.1900:1025:5079.000"
  #export grid148="lambert:263.0000:33.0000:45.0000 239.3720:442:12000.000 21.8210:265:12000.000"
  grid196="mercator:20.0000 198.4750:321:2500.000:206.1310 18.0730:255:2500.000:23.0880"
  grid198="nps:210.0000:60.0000 181.4290:825:5953.000 40.5300:553:5953.000"

  for grid in 227 196 198; do
    gg="grid${grid}"
    wgrib2 ${NET}.${cycle}.max_8hr_o3.${id_domain}.grib2 -set_grib_type c3b -new_grid_winds earth -new_grid ${!gg} ${NET}.${cycle}.max_8hr_o3.${grid}.grib2
    wgrib2 ${NET}.${cycle}.max_1hr_o3.${id_domain}.grib2 -set_grib_type c3b -new_grid_winds earth -new_grid ${!gg} ${NET}.${cycle}.max_1hr_o3.${grid}.grib2

    cp_vrfy ${DATA}/${NET}.${cycle}.max_*hr_o3.*.grib2  ${COMOUT}
    if [ "$SENDDBN" = "YES" ]; then
      ${DBNROOT}/bin/dbn_alert MODEL AQM_MAX ${job} ${COMOUT}/${NET}.${cycle}.max_1hr_o3.${grid}.grib2
      ${DBNROOT}/bin/dbn_alert MODEL AQM_MAX ${job} ${COMOUT}/${NET}.${cycle}.max_8hr_o3.${grid}.grib2
    fi

    # Add WMO header for daily 1h and 8h max O3
    for hr in 1 8; do
      echo 0 > filesize
      export XLFRTEOPTS="unit_vars=yes"
      export FORT11=${NET}.${cycle}.max_${hr}hr_o3.${grid}.grib2
      export FORT12="filesize"
      export FORT31=
      export FORT51=aqm-${hr}hro3-maxi.${grid}.grib2.temp
      tocgrib2super < ${PARMaqm_utils}/wmo/grib2_aqm-${hr}hro3-maxi.${cycle}.${grid}
      echo `ls -l  aqm-${hr}hro3-maxi.${grid}.grib2.temp | awk '{print $5} '` > filesize
      export XLFRTEOPTS="unit_vars=yes"
      export FORT11=aqm-${hr}hro3-maxi.${grid}.grib2.temp
      export FORT12="filesize"
      export FORT31=
      export FORT51=awpaqm.${cycle}.${hr}ho3-max.${grid}.grib2
      tocgrib2super < ${PARMaqm_utils}/wmo/grib2_aqm-${hr}hro3-maxi.${cycle}.${grid}
    done

    cp_vrfy awpaqm.${cycle}.*o3-max.${grid}.grib2 ${COMOUT}
    if [ "${SENDDBN_NTC}" = "YES" ]; then
      ${DBNROOT}/bin/dbn_alert ${DBNALERT_TYPE} ${NET} ${job} ${COMOUT}/awpaqm.${cycle}.1ho3-max.${grid}.grib2
      ${DBNROOT}/bin/dbn_alert ${DBNALERT_TYPE} ${NET} ${job} ${COMOUT}/awpaqm.${cycle}.8ho3-max.${grid}.grib2
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
POST-STAT-O3 completed successfully.

Exiting script:  \"${scrfunc_fn}\"
In directory:    \"${scrfunc_dir}\"
========================================================================"
#
#-----------------------------------------------------------------------
#
{ restore_shell_opts; } > /dev/null 2>&1
