#!/bin/bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. ${GLOBAL_VAR_DEFNS_FP}
. $USHdir/source_util_funcs.sh
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

This is the ex-script for the task that runs POST-UPP-STAT.
========================================================================"
#
#-----------------------------------------------------------------------
#
# Set OpenMP variables.
#
#-----------------------------------------------------------------------
#
export KMP_AFFINITY=${KMP_AFFINITY_RUN_POST_STAT}
export OMP_NUM_THREADS=${OMP_NUM_THREADS_RUN_POST_STAT}
export OMP_STACKSIZE=${OMP_STACKSIZE_RUN_POST_STAT}
#
#-----------------------------------------------------------------------
#
# Load modules.
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
DATA="${DATA}/tmp_POST_UPP"
mkdir_vrfy -p "$DATA"
cd_vrfy $DATA

set -x
#
#-----------------------------------------------------------------------
#
# Set up variable names and intermediate files for calculations
#
#-----------------------------------------------------------------------
#
name="POST-UPP-INPUT"

field1="PMTF"
field2="OZCON"
field3='1 hybrid level'

fname1pm25=day1-${name}-${field1}.grib2
fname1o3=day1-${name}-${field2}.grib2
fname18ho3=day1-${name}-${field2}_8hrmax.grib2

fname2pm25=day2-${name}-${field1}.grib2
fname2o3=day2-${name}-${field2}.grib2
fname28ho3=day2-${name}-${field2}_8hrmax.grib2

fname3pm25=day3-${name}-${field1}.grib2
fname3o3=day3-${name}-${field2}.grib2
fname38ho3=day3-${name}-${field2}_8hrmax.grib2

#
#-----------------------------------------------------------------------
#
# Locate the post data and get the necessary 04Z-04Z
#
#-----------------------------------------------------------------------
#
if [ "${RUN_ENVIR}" != "nco" ]; then
  postdir=${COMOUT_BASEDIR}/${PDY}${cyc}/postprd
  postdirx00=${COMOUT_BASEDIR}/${PDY}00/postprd
  postdirx06=${COMOUT_BASEDIR}/${PDY}06/postprd
else
  postdir=${COMOUT_BASEDIR}/${RUN}.${PDY}/${cyc}
  postdirx00=${COMOUT_BASEDIR}/${RUN}.${PDY}/00
  postdirx06=${COMOUT_BASEDIR}/${RUN}.${PDY}/06
fi

if [ "${cyc}" = "06" ] && [ "${FCST_LEN_HRS}" = "72" ]; then

  if [ ! -d ${postdirx00} ]; then
    print_err_msg_exit "00z postprd folder not available."
  fi
  #
  #-----------------------------------------------------------------------
  #
  # Get grib data at certain record
  #
  # - subset $field & ":1 hybrid level" and append all time together
  #
  #-----------------------------------------------------------------------
  #
  #=== Day1 O3 and PM2.5
  #--- borrow two hours from 00Z cycle (i.e., UTC 05-06z)
  #--- $NDATE -6  ==> "00z"
  let istart=5
  let iend=6

  echo $istart > meta_time-step.txt
  echo $istart > meta_time-step.max8ho3.txt
  let i=$istart

  while [ $i -le $iend ]; do

    printf -v i2 "%02g" $i
    file="${NET}.t00z.cmaq.f0${i2}.${POST_OUTPUT_DOMAIN_NAME}.grib2"
    if [ $i -eq $istart ]; then
      wgrib2 $postdirx00/$file -match ":$field1" -match ":$field3" -GRIB $fname1pm25
      wgrib2 $postdirx00/$file -match ":$field2" -match ":$field3" -GRIB $fname1o3
      wgrib2 $postdirx00/$file -match ":$field2" -match ":$field3" -GRIB $fname18ho3
    else
      wgrib2 $postdirx00/$file -match ":$field1" -match ":$field3" -append -GRIB $fname1pm25
      wgrib2 $postdirx00/$file -match ":$field2" -match ":$field3" -append -GRIB $fname1o3
      wgrib2 $postdirx00/$file -match ":$field2" -match ":$field3" -append -GRIB $fname18ho3
    fi

    let i=i+1
  done      # while

  #=== Day1 O3 and PM2.5 
  #--- hours 1-22 from 06Z cycle (i.e., UTC 07z-next day 04z)
 
  let istart=1
  let iend=22
  
  echo $iend >> meta_time-step.txt
  
  let i=$istart
  
  while [ $i -le $iend ]; do
  
    printf -v i2 "%02g" $i
    file="${NET}.t${cyc}z.cmaq.f0${i2}.${POST_OUTPUT_DOMAIN_NAME}.grib2"
  
    wgrib2 $postdir/$file -match ":$field1" -match ":$field3" -append -GRIB $fname1pm25
    wgrib2 $postdir/$file -match ":$field2" -match ":$field3" -append -GRIB $fname1o3
  
    let i=i+1
  done      # while

  #========================================
  #=== Day 1 max 8hr O3
  #--- hours 1-29 from 06Z cycle (i.e., UTC 07-next day 11z)
  
  let istart=1
  let iend=29
  
  let iend2=$iend-1
  echo $iend2 >> meta_time-step.max8ho3.txt
  echo $iend >> meta_time-step.max8ho3.txt
  
  let i=$istart
  
  while [ $i -le $iend ]; do
  
    printf -v i2 "%02g" $i
    file="${NET}.t${cyc}z.cmaq.f0${i2}.${POST_OUTPUT_DOMAIN_NAME}.grib2"
  
    wgrib2 $postdir/$file -match ":$field2" -match ":$field3" -append -GRIB $fname18ho3
  
    let i=i+1
  done      # while
  
  #========================================
  #=== Day2 O3 and PM2.5
  #--- hours 23-46 from 06Z cycle (i.e., UTC 05z-next day 04z)
  
  let istart=23
  let iend=46
  
  echo $istart >> meta_time-step.txt
  echo $iend   >> meta_time-step.txt
  
  let i=$istart
  
  while [ $i -le $iend ]; do
  
    printf -v i2 "%02g" $i
    file="${NET}.t${cyc}z.cmaq.f0${i2}.${POST_OUTPUT_DOMAIN_NAME}.grib2"
  
    if [ $i -eq $istart ]; then
      wgrib2 $postdir/$file -match ":$field1" -match ":$field3"  -GRIB $fname2pm25
      wgrib2 $postdir/$file -match ":$field2" -match ":$field3"  -GRIB $fname2o3
    else
      wgrib2 $postdir/$file -match ":$field1" -match ":$field3" -append -GRIB $fname2pm25
      wgrib2 $postdir/$file -match ":$field2" -match ":$field3" -append -GRIB $fname2o3
    fi
  
    let i=i+1
  done      # while
  
  #=== Day2 Max 8hr O3
  #--- hours 23-53 from 06Z cycle (i.e., UTC 05z-next day 11z)
  
  let istart=23
  let iend=53
  
  let iend2=$iend-1
  echo $iend2 >> meta_time-step.max8ho3.txt
  echo $iend >> meta_time-step.max8ho3.txt
  
  let i=$istart
  
  while [ $i -le $iend ]; do
  
    printf -v i2 "%02g" $i
    file="${NET}.t${cyc}z.cmaq.f0${i2}.${POST_OUTPUT_DOMAIN_NAME}.grib2"
  
    if [ $i -eq $istart ]; then
      wgrib2 $postdir/$file -match ":$field2" -match ":$field3"  -GRIB $fname28ho3
    else
      wgrib2 $postdir/$file -match ":$field2" -match ":$field3" -append -GRIB $fname28ho3
    fi
  
    let i=i+1
  done      # while
  
  
  #========================================
  #=== Day3 O3 and PM2.5
  #--- hours 47-70 from 06Z cycle (i.e., UTC 05z-next day 04z)
  
  let istart=47
  let iend=70
  
  echo $istart >> meta_time-step.txt
  echo $iend   >> meta_time-step.txt
  
  let i=$istart
  
  while [ $i -le $iend ]; do
  
    printf -v i2 "%02g" $i
    file="${NET}.t${cyc}z.cmaq.f0${i2}.${POST_OUTPUT_DOMAIN_NAME}.grib2"
  
    if [ $i -eq $istart ]; then
      wgrib2 $postdir/$file -match ":$field1" -match ":$field3"  -GRIB $fname3pm25
      wgrib2 $postdir/$file -match ":$field2" -match ":$field3"  -GRIB $fname3o3
    else
      wgrib2 $postdir/$file -match ":$field1" -match ":$field3" -append -GRIB $fname3pm25
      wgrib2 $postdir/$file -match ":$field2" -match ":$field3" -append -GRIB $fname3o3
    fi
  
    let i=i+1
  done      # while
  
  #=== Day 3 max 8hr O3
  #--- hours 47-72 from 06Z cycle (i.e., UTC 05z-next day 06z, the last hour of current cycle)
  
  let istart=47
  let iend=72
  
  echo $iend   >> meta_time-step.max8ho3.txt
  
  let i=$istart
  
  while [ $i -le $iend ]; do
  
    printf -v i2 "%02g" $i
    file="${NET}.t${cyc}z.cmaq.f0${i2}.${POST_OUTPUT_DOMAIN_NAME}.grib2"
  
     if [ $i -eq $istart ]; then
       wgrib2 $postdir/$file -match ":$field2" -match ":$field3"  -GRIB $fname38ho3
     else
       wgrib2 $postdir/$file -match ":$field2" -match ":$field3" -append -GRIB $fname38ho3
     fi
  
    let i=i+1
  done      # while

elif [ "${cyc}" = "12" ] && [ "${FCST_LEN_HRS}" = "72" ]; then

  if [ ! -d ${postdirx00} ] || [ ! -d ${postdirx06} ]; then
    print_err_msg_exit "00z or 06z postprd folder not available."
  fi
  
  #
  #-----------------------------------------------------------------------
  #
  # Get grib data at certain record
  #   - subset $field & ":1 hybrid level" and append all time together
  #
  #-----------------------------------------------------------------------
  #
  #========================================
  #=== Day1 O3 and PM2.5
  #--- borrow two hours from 00Z cycle (i.e., UTC 05-06z)
  #--- $NDATE - 12  ==> "00z"
  
  let istart=5
  let iend=6
   
  echo $istart > meta_time-step.txt
  echo $istart > meta_time-step.max8ho3.txt
  
  let i=$istart
  
  while [ $i -le $iend ]; do
  
    printf -v i2 "%02g" $i
    file="${NET}.t00z.cmaq.f0${i2}.${POST_OUTPUT_DOMAIN_NAME}.grib2"
  
    if [ $i -eq $istart ]; then
      wgrib2 $postdirx00/$file -match ":$field1" -match ":$field3" -GRIB $fname1pm25
      wgrib2 $postdirx00/$file -match ":$field2" -match ":$field3" -GRIB $fname1o3
      wgrib2 $postdirx00/$file -match ":$field2" -match ":$field3" -GRIB $fname18ho3
    else
      wgrib2 $postdirx00/$file -match ":$field1" -match ":$field3" -append -GRIB $fname1pm25
      wgrib2 $postdirx00/$file -match ":$field2" -match ":$field3" -append -GRIB $fname1o3
      wgrib2 $postdirx00/$file -match ":$field2" -match ":$field3" -append -GRIB $fname18ho3
    fi
  
    let i=i+1
  done      # while
  
  #=== Day1 O3 and PM2.5
  #--- borrow six hours from 06Z cycle (i.e., UTC 07-12z)
  #--- $NDATE - 6  ==> "06z"
  
  let istart=1
  let iend=6
  
  let i=$istart
  
  while [ $i -le $iend ]; do
  
    printf -v i2 "%02g" $i
    file="${NET}.t06z.cmaq.f0${i2}.${POST_OUTPUT_DOMAIN_NAME}.grib2"
  
    wgrib2 $postdirx06/$file -match ":$field1" -match ":$field3" -append -GRIB $fname1pm25
    wgrib2 $postdirx06/$file -match ":$field2" -match ":$field3" -append -GRIB $fname1o3
    wgrib2 $postdirx06/$file -match ":$field2" -match ":$field3" -append -GRIB $fname18ho3
  
    let i=i+1
  done      # while
  
  #=== Day1 O3 and PM2.5 
  #--- hours 1-16 from 12Z cycle (i.e., UTC 13z-next day 04z)
  
  let istart=1
  let iend=16
  
  echo $iend >> meta_time-step.txt
  
  let i=$istart
  
  while [ $i -le $iend ]; do
  
    printf -v i2 "%02g" $i
    file="${NET}.t${cyc}z.cmaq.f0${i2}.${POST_OUTPUT_DOMAIN_NAME}.grib2"
  
    wgrib2 $postdir/$file -match ":$field1" -match ":$field3" -append -GRIB $fname1pm25
    wgrib2 $postdir/$file -match ":$field2" -match ":$field3" -append -GRIB $fname1o3
  
    let i=i+1
  done      # while
  
  #=== Day 1 max 8hr O3
  #--- hours 1-23 from 12Z cycle (i.e., UTC 13z-next day 11z)
  
  let istart=1
  let iend=23
  
  let iend2=$iend-1
  echo $iend2 >> meta_time-step.max8ho3.txt
  echo $iend >> meta_time-step.max8ho3.txt
  
  let i=$istart
  
  while [ $i -le $iend ]; do
  
    printf -v i2 "%02g" $i
    file="${NET}.t${cyc}z.cmaq.f0${i2}.${POST_OUTPUT_DOMAIN_NAME}.grib2"
  
    wgrib2 $postdir/$file -match ":$field2" -match ":$field3" -append -GRIB $fname18ho3
  
    let i=i+1
  done      # while
  
  #========================================
  #=== Day2 O3 and PM2.5
  #--- hours 17-40 from 12Z cycle (i.e., UTC 05z-next day 04z)
  
  let istart=17
  let iend=40
  
  echo $istart >> meta_time-step.txt
  echo $iend   >> meta_time-step.txt
  
  let i=$istart
  
  while [ $i -le $iend ]; do
  
    printf -v i2 "%02g" $i
    file="${NET}.t${cyc}z.cmaq.f0${i2}.${POST_OUTPUT_DOMAIN_NAME}.grib2"
  
    if [ $i -eq $istart ]; then
      wgrib2 $postdir/$file -match ":$field1" -match ":$field3"  -GRIB $fname2pm25
      wgrib2 $postdir/$file -match ":$field2" -match ":$field3"  -GRIB $fname2o3
    else
      wgrib2 $postdir/$file -match ":$field1" -match ":$field3" -append -GRIB $fname2pm25
      wgrib2 $postdir/$file -match ":$field2" -match ":$field3" -append -GRIB $fname2o3
    fi
  
    let i=i+1
  done      # while
  
  #=== Day2 Max 8hr O3
  #--- hours 17-47 from 12Z cycle (i.e., UTC 05z-next day 11z)
  
  let istart=17
  let iend=47
  
  let iend2=$iend-1
  echo $iend2 >> meta_time-step.max8ho3.txt
  echo $iend >> meta_time-step.max8ho3.txt
  
  let i=$istart
  
  while [ $i -le $iend ]; do
  
    printf -v i2 "%02g" $i
    file="${NET}.t${cyc}z.cmaq.f0${i2}.${POST_OUTPUT_DOMAIN_NAME}.grib2"
  
    if [ $i -eq $istart ]; then
      wgrib2 $postdir/$file -match ":$field2" -match ":$field3"  -GRIB $fname28ho3
    else
      wgrib2 $postdir/$file -match ":$field2" -match ":$field3" -append -GRIB $fname28ho3
    fi
  
    let i=i+1
  done      # while
  
  #========================================
  #=== Day3 O3 and PM2.5
  #--- hours 41-64 from 12Z cycle (i.e., UTC 05z-next day 04z)
  
  let istart=41
  let iend=64
  
  echo $istart >> meta_time-step.txt
  echo $iend   >> meta_time-step.txt
  
  let i=$istart
  
  while [ $i -le $iend ]; do
  
    printf -v i2 "%02g" $i
    file="${NET}.t${cyc}z.cmaq.f0${i2}.${POST_OUTPUT_DOMAIN_NAME}.grib2"
  
    if [ $i -eq $istart ]; then
      wgrib2 $postdir/$file -match ":$field1" -match ":$field3"  -GRIB $fname3pm25
      wgrib2 $postdir/$file -match ":$field2" -match ":$field3"  -GRIB $fname3o3
    else
      wgrib2 $postdir/$file -match ":$field1" -match ":$field3" -append -GRIB $fname3pm25
      wgrib2 $postdir/$file -match ":$field2" -match ":$field3" -append -GRIB $fname3o3
    fi
  
    let i=i+1
  done      # while
  
  #=== Day 3 max 8hr O3
  #--- hours 41-71 from 12Z cycle (i.e., UTC 05z-next day 11z)
  
  let istart=41
  let iend=71
  
  let iend2=$iend-1
  echo $iend2 >> meta_time-step.max8ho3.txt
  
  let i=$istart
  
  while [ $i -le $iend ]; do
  
    printf -v i2 "%02g" $i
    file="${NET}.t${cyc}z.cmaq.f0${i2}.${POST_OUTPUT_DOMAIN_NAME}.grib2"
  
    if [ $i -eq $istart ]; then
      wgrib2 $postdir/$file -match ":$field2" -match ":$field3"  -GRIB $fname38ho3
    else
      wgrib2 $postdir/$file -match ":$field2" -match ":$field3" -append -GRIB $fname38ho3
    fi
  
    let i=i+1
  done      # while

else
  print_info_msg "Post-UPP only works for 06z or 12z cycle and 72 hour run length."
  exit 0
fi	

#
#----------------------------------------------------------------------
#
# Execute POST-UPP-STAT
#
#-----------------------------------------------------------------------
#
PREP_STEP
eval ${RUN_CMD_SERIAL} ${EXECdir}/O3-PM25-stat ${REDIRECT_OUT_ERR} || \
	print_err_msg_exit "\
	Call to execute POST-UPP-STAT for Online-CMAQ failed."
POST_STEP

#
#-----------------------------------------------------------------------
#
# Rearrange output files.
#
#-----------------------------------------------------------------------
#
for fhr in $(seq -f "%02g" 1 72); do
  wgrib2 $postdir/${NET}.t${cyc}z.cmaq.f0${i2}.${POST_OUTPUT_DOMAIN_NAME}.grib2 -match ":$field1" -match ":$field3" -GRIB ${NET}.t${cyc}z.pm25.f${fhr}.${POST_OUTPUT_DOMAIN_NAME}.grib2
  wgrib2 $postdir/${NET}.t${cyc}z.cmaq.f0${i2}.${POST_OUTPUT_DOMAIN_NAME}.grib2 -match ":$field2" -match ":$field3" -GRIB ${NET}.t${cyc}z.awpozcon.f${fhr}.${POST_OUTPUT_DOMAIN_NAME}.grib2
done

mv_vrfy day*.grib2 meta_time-step* ${COMOUT}
mv_vrfy ${NET}.t${cyc}z.pm25.f*.${POST_OUTPUT_DOMAIN_NAME}.grib2 ${COMOUT}
mv_vrfy ${NET}.t${cyc}z.awpozcon.f*.${POST_OUTPUT_DOMAIN_NAME}.grib2 ${COMOUT}
mv_vrfy ${NET}.max_1hr_o3.grib2 ${COMOUT}/${NET}.t${cyc}z.max_1hr_o3.${POST_OUTPUT_DOMAIN_NAME}.grib2
mv_vrfy ${NET}.max_8hr_o3.grib2 ${COMOUT}/${NET}.t${cyc}z.max_8hr_o3.${POST_OUTPUT_DOMAIN_NAME}.grib2
mv_vrfy ${NET}.ave_24hr_pm25.grib2 ${COMOUT}/${NET}.t${cyc}z.ave_24hr_pm25.${POST_OUTPUT_DOMAIN_NAME}.grib2
mv_vrfy ${NET}.max_1hr_pm25.grib2 ${COMOUT}/${NET}.t${cyc}z.max_1hr_pm25.${POST_OUTPUT_DOMAIN_NAME}.grib2

if [ "${PREDEF_GRID_NAME}" = "AQM_NA_13km" ]; then

  grid227="lambert:265.0000:25.0000:25.0000 226.5410:1473:5079.000 12.1900:1025:5079.000"
  grid148="lambert:263.0000:33.0000:45.0000 239.3720:442:12000.000 21.8210:265:12000.000"
  grid196="mercator:20.0000 198.4750:321:2500.000:206.1310 18.0730:255:2500.000:23.0880"
  grid198="nps:210.0000:60.0000 181.4290:825:5953.000 40.5300:553:5953.000"

  mkdir_vrfy cs.${PDY}
  mkdir_vrfy ak.${PDY}
  mkdir_vrfy hi.${PDY}

  for grid in 148 227 196 198
  do
    gg="grid${grid}"
    wgrib2 ${NET}.t${cyc}z.max_8hr_o3.${POST_OUTPUT_DOMAIN_NAME}.grib2 -set_grib_type same -new_grid_winds earth -new_grid ${!gg} ${NET}.t${cyc}z.max_8hr_o3.${grid}.grib2
    wgrib2 ${NET}.t${cyc}z.max_1hr_o3.${POST_OUTPUT_DOMAIN_NAME}.grib2 -set_grib_type same -new_grid_winds earth -new_grid ${!gg}} ${NET}.t${cyc}z.max_1hr_o3.${grid}.grib2
    wgrib2 ${NET}.t${cyc}z.ave_24hr_pm25.${POST_OUTPUT_DOMAIN_NAME}.grib2 -set_grib_type same -new_grid_winds earth -new_grid ${!gg} ${NET}.t${cyc}z.ave_24hr_pm25.${grid}.grib2
    wgrib2 ${NET}.t${cyc}z.max_1hr_pm25.${POST_OUTPUT_DOMAIN_NAME}.grib2 -set_grib_type same -new_grid_winds earth -new_grid ${!gg} ${NET}.t${cyc}z.max_1hr_pm25.${grid}.grib2

    for fhr in $(seq -f "%02g" 1 72); do
      wgrib2 ${NET}.t${cyc}z.pm25.f${fhr}.${POST_OUTPUT_DOMAIN_NAME}.grib2 -set_grib_type same -new_grid_winds earth -new_grid ${!gg} aqm.t${cyc}z.pm25.f${fhr}.${grid}.grib2
      wgrib2 ${NET}.t${cyc}z.awpozcon.f${fhr}.${POST_OUTPUT_DOMAIN_NAME}.grib2 -set_grib_type same -new_grid_winds earth -new_grid ${!gg} aqm.t${cyc}z.awpozcon.f${fhr}.${grid}.grib2
    done
  done

  mv_vrfy *.148.grib2 *.227.grib2 cs.${PDY}
  mv_vrfy *.198.grib2 ak.${PDY}
  mv_vrfy *.196.grib2 hi.${PDY}

  mv_vrfy cs.${PDY} ${COMOUT}/cs.${PDY}
  mv_vrfy ak.${PDY} ${COMOUT}/ak.${PDY}
  mv_vrfy hi.${PDY} ${COMOUT}/hi.${PDY}
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
UPP-POST-STAT completed successfully.

Exiting script:  \"${scrfunc_fn}\"
In directory:    \"${scrfunc_dir}\"
========================================================================"
#
#-----------------------------------------------------------------------
#
{ restore_shell_opts; } > /dev/null 2>&1
