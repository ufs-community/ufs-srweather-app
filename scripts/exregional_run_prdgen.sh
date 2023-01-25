#!/bin/bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. $USHdir/source_util_funcs.sh
source_config_for_task "task_run_prdgen|task_run_post" ${GLOBAL_VAR_DEFNS_FP}
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
scrfunc_fp=$( readlink -f "${BASH_SOURCE[0]}" )
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
This is the ex-script for the task that runs the post-processor (UPP) on
the output files corresponding to a specified forecast hour.
========================================================================"
#
#-----------------------------------------------------------------------
#
# Set OpenMP variables.
#
#-----------------------------------------------------------------------
#
export KMP_AFFINITY=${KMP_AFFINITY_RUN_PRDGEN}
export OMP_NUM_THREADS=${OMP_NUM_THREADS_RUN_PRDGEN}
export OMP_STACKSIZE=${OMP_STACKSIZE_RUN_PRDGEN}
#
#-----------------------------------------------------------------------
#
# Load modules.
#
#-----------------------------------------------------------------------
#
eval ${PRE_TASK_CMDS}

#
#-----------------------------------------------------------------------
#
# Get the cycle date and hour (in formats of yyyymmdd and hh, respectively)
# from CDATE.
#
#-----------------------------------------------------------------------
#
yyyymmdd=${PDY}
hh=${cyc}
#-----------------------------------------------------------------------
#
# A separate ${post_fhr} forecast hour variable is required for the post
# files, since they may or may not be three digits long, depending on the
# length of the forecast.
#
#-----------------------------------------------------------------------
#

len_fhr=${#fhr}
if [ ${len_fhr} -eq 9 ]; then
  post_min=${fhr:4:2}
  if [ ${post_min} -lt 15 ]; then
    post_min=00
  fi
else
  post_min=00
fi

subh_fhr=${fhr}
if [ ${len_fhr} -eq 2 ]; then
  post_fhr=${fhr}00
elif [ ${len_fhr} -eq 3 ]; then
  if [ "${fhr:0:1}" = "0" ]; then
    post_fhr="${fhr:1}00"
  else
    post_fhr=${fhr}00
  fi
elif [ ${len_fhr} -eq 9 ]; then
  if [ "${fhr:0:1}" = "0" ]; then
    if [ ${post_min} -eq 00 ]; then
      post_fhr="${fhr:1:2}00"
      subh_fhr="${fhr:0:3}"
    else
      post_fhr="${fhr:1:2}${fhr:4:2}"
    fi
  else
    if [ ${post_min} -eq 00 ]; then
      post_fhr="${fhr:0:3}00"
      subh_fhr="${fhr:0:3}"
    else
      post_fhr="${fhr:0:3}${fhr:4:2}"
    fi
  fi
else
  print_err_msg_exit "\
The \${fhr} variable contains too few or too many characters:
  fhr = \"$fhr\""
fi

# replace fhr with subh_fhr
echo "fhr=${fhr} and subh_fhr=${subh_fhr}"
fhr=${subh_fhr}

#
# background files
#
bgdawp=${COMOUT}/${NET}.${cycle}${dot_ensmem}.bgdawp.f${fhr}.${POST_OUTPUT_DOMAIN_NAME}.grib2
bgrd3d=${COMOUT}/${NET}.${cycle}${dot_ensmem}.bgrd3d.f${fhr}.${POST_OUTPUT_DOMAIN_NAME}.grib2
bgsfc=${COMOUT}/${NET}.${cycle}${dot_ensmem}.bgsfc.f${fhr}.${POST_OUTPUT_DOMAIN_NAME}.grib2
bgifi=${COMOUT}/${NET}.${cycle}${dot_ensmem}.bgifi.f${fhr}.${POST_OUTPUT_DOMAIN_NAME}.grib2

# extract the output fields for the testbed
touch ${bgsfc}
if [[ ! -z ${TESTBED_FIELDS_FN} ]]; then
  if [[ -f "${PARMdir}/upp/${TESTBED_FIELDS_FN}" ]]; then
    wgrib2 ${bgdawp} | grep -F -f "${PARMdir}/upp/${TESTBED_FIELDS_FN}" | wgrib2 -i -grib ${bgsfc} ${bgdawp}
  else
    echo "${PARMdir}/upp/${TESTBED_FIELDS_FN} not found"
  fi
fi
if [[ ! -z ${TESTBED_FIELDS_FN2} ]]; then
  if [[ -f "${PARMdir}/upp/${TESTBED_FIELDS_FN2}" ]]; then
    wgrib2 ${bgrd3d} | grep -F -f "${PARMdir}/upp/${TESTBED_FIELDS_FN2}" | wgrib2 -i -append -grib ${bgsfc} ${bgrd3d}
  else
    echo "${PARMdir}/upp/${TESTBED_FIELDS_FN2} not found"
  fi
fi

#Link output for transfer to Jet
# Should the following be done only if on jet??

# Seems like start_date is the same as "$yyyymmdd $hh", where yyyymmdd
# and hh are calculated above, i.e. start_date is just CDATE but with a
# space inserted between the dd and hh.  If so, just use "$yyyymmdd $hh"
# instead of calling sed.

gridname=""
if [ ${PREDEF_GRID_NAME} = "RRFS_CONUS_3km" ]; then
  gridname="conus_3km."
elif  [ ${PREDEF_GRID_NAME} = "RRFS_NA_3km" ]; then
  gridname=""
fi
basetime=$( date +%y%j%H%M -d "${yyyymmdd} ${hh}" )
cp_vrfy ${bgdawp} ${COMOUT}/${NET}.${cycle}${dot_ensmem}.bgdawp.f${fhr}.${POST_OUTPUT_DOMAIN_NAME}.grib2
cp_vrfy ${bgrd3d} ${COMOUT}/${NET}.${cycle}${dot_ensmem}.bgrd3d.f${fhr}.${POST_OUTPUT_DOMAIN_NAME}.grib2
if [ -f  ${bgifi} ]; then
  cp_vrfy ${bgifi} ${COMOUT}/${NET}.${cycle}${dot_ensmem}.bgifi.f${fhr}.${POST_OUTPUT_DOMAIN_NAME}.grib2
fi
cp_vrfy ${bgsfc}  ${COMOUT}/${NET}.${cycle}${dot_ensmem}.bgsfc.f${fhr}.${POST_OUTPUT_DOMAIN_NAME}.grib2
ln_vrfy -sf --relative ${COMOUT}/${NET}.${cycle}${dot_ensmem}.bgdawp.f${fhr}.${POST_OUTPUT_DOMAIN_NAME}.grib2 ${COMOUT}/BGDAWP_${basetime}${post_fhr}
ln_vrfy -sf --relative ${COMOUT}/${NET}.${cycle}${dot_ensmem}.bgrd3d.f${fhr}.${POST_OUTPUT_DOMAIN_NAME}.grib2 ${COMOUT}/BGRD3D_${basetime}${post_fhr}
if [ -f ${COMOUT}/${NET}.${cycle}${dot_ensmem}.bgifi.f${fhr}.${POST_OUTPUT_DOMAIN_NAME}.grib2 ]; then
  ln_vrfy -sf --relative ${COMOUT}/${NET}.${cycle}${dot_ensmem}.bgifi.f${fhr}.${POST_OUTPUT_DOMAIN_NAME}.grib2 ${COMOUT}/BGIFI_${basetime}${post_fhr}
fi
ln_vrfy -sf --relative ${COMOUT}/${NET}.${cycle}${dot_ensmem}.bgsfc.f${fhr}.${POST_OUTPUT_DOMAIN_NAME}.grib2  ${COMOUT}/BGSFC_${basetime}${post_fhr}

net4=$(echo ${NET:0:4} | tr '[:upper:]' '[:lower:]')
ln_vrfy -sf --relative ${COMOUT}/${NET}.${cycle}${dot_ensmem}.bgdawp.f${fhr}.${POST_OUTPUT_DOMAIN_NAME}.grib2 ${COMOUT}/${net4}.${cycle}.prslev.f${fhr}.${gridname}grib2
wgrib2 ${COMOUT}/${net4}.${cycle}.prslev.f${fhr}.${gridname}grib2 -s > ${COMOUT}/${net4}.${cycle}.prslev.f${fhr}.${gridname}grib2.idx
ln_vrfy -sf --relative ${COMOUT}/${NET}.${cycle}${dot_ensmem}.bgrd3d.f${fhr}.${POST_OUTPUT_DOMAIN_NAME}.grib2 ${COMOUT}/${net4}.${cycle}.natlev.f${fhr}.${gridname}grib2
wgrib2 ${COMOUT}/${net4}.${cycle}.natlev.f${fhr}.${gridname}grib2 -s > ${COMOUT}/${net4}.${cycle}.natlev.f${fhr}.${gridname}grib2.idx
if [ -f ${COMOUT}/${NET}.${cycle}${dot_ensmem}.bgifi.f${fhr}.${POST_OUTPUT_DOMAIN_NAME}.grib2 ]; then
  ln_vrfy -sf --relative ${COMOUT}/${NET}.${cycle}${dot_ensmem}.bgifi.f${fhr}.${POST_OUTPUT_DOMAIN_NAME}.grib2 ${COMOUT}/${net4}.${cycle}.ififip.f${fhr}.${gridname}grib2
  wgrib2 ${COMOUT}/${net4}.${cycle}.ififip.f${fhr}.${gridname}grib2 -s > ${COMOUT}/${net4}.${cycle}.ififip.f${fhr}.${gridname}grib2.idx
fi
ln_vrfy -sf --relative ${COMOUT}/${NET}.${cycle}${dot_ensmem}.bgsfc.f${fhr}.${POST_OUTPUT_DOMAIN_NAME}.grib2  ${COMOUT}/${net4}.${cycle}.testbed.f${fhr}.${gridname}grib2
wgrib2 ${COMOUT}/${net4}.${cycle}.testbed.f${fhr}.${gridname}grib2 -s > ${COMOUT}/${net4}.${cycle}.testbed.f${fhr}.${gridname}grib2.idx
# Remap to additional output grids if requested

if [ ${DO_PARALLEL_PRDGEN} == "TRUE" ]; then
#
#  parallel run wgrib2 for product generation
#

if [ ${PREDEF_GRID_NAME} = "RRFS_NA_3km" ]; then

module load cfp/2.0.4   #- Daniel: Move this to modulefiles
DATA=$COMOUT
PRDGENdir=$USHdir/prdgen

wgrib2 ${COMOUT}/rrfs.${cycle}.prslev.f${fhr}.grib2 >& $DATA/prslevf${fhr}.txt

# Create parm files for subsetting on the fly - do it for each forecast hour
# 10 subpieces for North American grid
sed -n -e '1,120p' $DATA/prslevf${fhr}.txt >& $DATA/namerica_1.txt
sed -n -e '121,240p' $DATA/prslevf${fhr}.txt >& $DATA/namerica_2.txt
sed -n -e '241,360p' $DATA/prslevf${fhr}.txt >& $DATA/namerica_3.txt
sed -n -e '361,480p' $DATA/prslevf${fhr}.txt >& $DATA/namerica_4.txt
sed -n -e '481,600p' $DATA/prslevf${fhr}.txt >& $DATA/namerica_5.txt
sed -n -e '601,720p' $DATA/prslevf${fhr}.txt >& $DATA/namerica_6.txt
sed -n -e '721,750p' $DATA/prslevf${fhr}.txt >& $DATA/namerica_7.txt
sed -n -e '751,780p' $DATA/prslevf${fhr}.txt >& $DATA/namerica_8.txt
sed -n -e '781,880p' $DATA/prslevf${fhr}.txt >& $DATA/namerica_9.txt
sed -n -e '881,$p' $DATA/prslevf${fhr}.txt >& $DATA/namerica_10.txt

# 4 subpieces for CONUS and Alaska grids
sed -n -e '1,250p' $DATA/prslevf${fhr}.txt >& $DATA/conus_ak_1.txt
sed -n -e '251,500p' $DATA/prslevf${fhr}.txt >& $DATA/conus_ak_2.txt
sed -n -e '501,750p' $DATA/prslevf${fhr}.txt >& $DATA/conus_ak_3.txt
sed -n -e '751,$p' $DATA/prslevf${fhr}.txt >& $DATA/conus_ak_4.txt

# 2 subpieces for Hawaii and Puerto Rico grids
sed -n -e '1,500p' $DATA/prslevf${fhr}.txt >& $DATA/hi_pr_1.txt
sed -n -e '501,$p' $DATA/prslevf${fhr}.txt >& $DATA/hi_pr_2.txt

mkdir -p $DATA/prdgen_conus_1
mkdir -p $DATA/prdgen_conus_2
mkdir -p $DATA/prdgen_conus_3
mkdir -p $DATA/prdgen_conus_4
mkdir -p $DATA/prdgen_ak_1
mkdir -p $DATA/prdgen_ak_2
mkdir -p $DATA/prdgen_ak_3
mkdir -p $DATA/prdgen_ak_4
mkdir -p $DATA/prdgen_hi_1
mkdir -p $DATA/prdgen_hi_2
mkdir -p $DATA/prdgen_pr_1
mkdir -p $DATA/prdgen_pr_2
mkdir -p $DATA/prdgen_namerica_1
mkdir -p $DATA/prdgen_namerica_2
mkdir -p $DATA/prdgen_namerica_3
mkdir -p $DATA/prdgen_namerica_4
mkdir -p $DATA/prdgen_namerica_5
mkdir -p $DATA/prdgen_namerica_6
mkdir -p $DATA/prdgen_namerica_7
mkdir -p $DATA/prdgen_namerica_8
mkdir -p $DATA/prdgen_namerica_9
mkdir -p $DATA/prdgen_namerica_10

echo "#!/bin/bash" > $DATA/poescript_${fhr}
echo "export DATA=${DATA}" >> $DATA/poescript_${fhr}
echo "export COMOUT=${COMOUT}" >> $DATA/poescript_${fhr}
echo "$PRDGENdir/rrfs_prdgen_subpiece.sh $fhr $cyc 1 conus ${DATA} ${COMOUT} &" >> $DATA/poescript_${fhr}
echo "$PRDGENdir/rrfs_prdgen_subpiece.sh $fhr $cyc 2 conus ${DATA} ${COMOUT} &" >> $DATA/poescript_${fhr}
echo "$PRDGENdir/rrfs_prdgen_subpiece.sh $fhr $cyc 3 conus ${DATA} ${COMOUT} &" >> $DATA/poescript_${fhr}
echo "$PRDGENdir/rrfs_prdgen_subpiece.sh $fhr $cyc 4 conus ${DATA} ${COMOUT} &" >> $DATA/poescript_${fhr}
echo "$PRDGENdir/rrfs_prdgen_subpiece.sh $fhr $cyc 1 ak ${DATA} ${COMOUT} &" >> $DATA/poescript_${fhr}
echo "$PRDGENdir/rrfs_prdgen_subpiece.sh $fhr $cyc 2 ak ${DATA} ${COMOUT} &" >> $DATA/poescript_${fhr}
echo "$PRDGENdir/rrfs_prdgen_subpiece.sh $fhr $cyc 3 ak ${DATA} ${COMOUT} &" >> $DATA/poescript_${fhr}
echo "$PRDGENdir/rrfs_prdgen_subpiece.sh $fhr $cyc 4 ak ${DATA} ${COMOUT} &" >> $DATA/poescript_${fhr}
echo "$PRDGENdir/rrfs_prdgen_subpiece.sh $fhr $cyc 1 hi ${DATA} ${COMOUT} &" >> $DATA/poescript_${fhr}
echo "$PRDGENdir/rrfs_prdgen_subpiece.sh $fhr $cyc 2 hi ${DATA} ${COMOUT} &" >> $DATA/poescript_${fhr}
echo "$PRDGENdir/rrfs_prdgen_subpiece.sh $fhr $cyc 1 pr ${DATA} ${COMOUT} &" >> $DATA/poescript_${fhr}
echo "$PRDGENdir/rrfs_prdgen_subpiece.sh $fhr $cyc 2 pr ${DATA} ${COMOUT} &" >> $DATA/poescript_${fhr}
echo "$PRDGENdir/rrfs_prdgen_subpiece.sh $fhr $cyc 1 namerica ${DATA} ${COMOUT} &" >> $DATA/poescript_${fhr}
echo "$PRDGENdir/rrfs_prdgen_subpiece.sh $fhr $cyc 2 namerica ${DATA} ${COMOUT} &" >> $DATA/poescript_${fhr}
echo "$PRDGENdir/rrfs_prdgen_subpiece.sh $fhr $cyc 3 namerica ${DATA} ${COMOUT} &" >> $DATA/poescript_${fhr}
echo "$PRDGENdir/rrfs_prdgen_subpiece.sh $fhr $cyc 4 namerica ${DATA} ${COMOUT} &" >> $DATA/poescript_${fhr}
echo "$PRDGENdir/rrfs_prdgen_subpiece.sh $fhr $cyc 5 namerica ${DATA} ${COMOUT} &" >> $DATA/poescript_${fhr}
echo "$PRDGENdir/rrfs_prdgen_subpiece.sh $fhr $cyc 6 namerica ${DATA} ${COMOUT} &" >> $DATA/poescript_${fhr}
echo "$PRDGENdir/rrfs_prdgen_subpiece.sh $fhr $cyc 7 namerica ${DATA} ${COMOUT} &" >> $DATA/poescript_${fhr}
echo "$PRDGENdir/rrfs_prdgen_subpiece.sh $fhr $cyc 8 namerica ${DATA} ${COMOUT} &" >> $DATA/poescript_${fhr}
echo "$PRDGENdir/rrfs_prdgen_subpiece.sh $fhr $cyc 9 namerica ${DATA} ${COMOUT} &" >> $DATA/poescript_${fhr}
echo "$PRDGENdir/rrfs_prdgen_subpiece.sh $fhr $cyc 10 namerica ${DATA} ${COMOUT} &" >> $DATA/poescript_${fhr}
echo "wait" >> $DATA/poescript_${fhr}
chmod 775 $DATA/poescript_${fhr}

#
# Execute the script
#

export CMDFILE=$DATA/poescript_${fhr}
mpiexec -np 22 --cpu-bind core cfp $CMDFILE  #Daniel: Move this somewhere else
#export err=$?; err_chk

# reassemble the output grids

cat $DATA/prdgen_conus_1/conus_1.grib2 \
    $DATA/prdgen_conus_2/conus_2.grib2 \
    $DATA/prdgen_conus_3/conus_3.grib2 \
    $DATA/prdgen_conus_4/conus_4.grib2 \
    > ${COMOUT}/rrfs.${cycle}.prslev.f${fhr}.conus_3km.grib2
wgrib2 ${COMOUT}/rrfs.${cycle}.prslev.f${fhr}.conus_3km.grib2 -s > ${COMOUT}/rrfs.${cycle}.prslev.f${fhr}.conus_3km.grib2.idx

cat $DATA/prdgen_ak_1/ak_1.grib2 \
    $DATA/prdgen_ak_2/ak_2.grib2 \
    $DATA/prdgen_ak_3/ak_3.grib2 \
    $DATA/prdgen_ak_4/ak_4.grib2 \
    > ${COMOUT}/rrfs.${cycle}.prslev.f${fhr}.ak.grib2
wgrib2 ${COMOUT}/rrfs.${cycle}.prslev.f${fhr}.ak.grib2 -s > ${COMOUT}/rrfs.${cycle}.prslev.f${fhr}.ak.grib2.idx

cat $DATA/prdgen_hi_1/hi_1.grib2 \
    $DATA/prdgen_hi_2/hi_2.grib2 \
    > ${COMOUT}/rrfs.${cycle}.prslev.f${fhr}.hi.grib2
wgrib2 ${COMOUT}/rrfs.${cycle}.prslev.f${fhr}.hi.grib2 -s > ${COMOUT}/rrfs.${cycle}.prslev.f${fhr}.hi.grib2.idx

cat $DATA/prdgen_pr_1/pr_1.grib2 \
    $DATA/prdgen_pr_2/pr_2.grib2 \
    > ${COMOUT}/rrfs.${cycle}.prslev.f${fhr}.pr.grib2
wgrib2 ${COMOUT}/rrfs.${cycle}.prslev.f${fhr}.pr.grib2 -s > ${COMOUT}/rrfs.${cycle}.prslev.f${fhr}.pr.grib2.idx

cat $DATA/prdgen_namerica_1/namerica_1.grib2 \
    $DATA/prdgen_namerica_2/namerica_2.grib2 \
    $DATA/prdgen_namerica_3/namerica_3.grib2 \
    $DATA/prdgen_namerica_4/namerica_4.grib2 \
    $DATA/prdgen_namerica_5/namerica_5.grib2 \
    $DATA/prdgen_namerica_6/namerica_6.grib2 \
    $DATA/prdgen_namerica_7/namerica_7.grib2 \
    $DATA/prdgen_namerica_8/namerica_8.grib2 \
    $DATA/prdgen_namerica_9/namerica_9.grib2 \
    $DATA/prdgen_namerica_10/namerica_10.grib2 \
    > ${COMOUT}/rrfs.${cycle}.prslev.f${fhr}.namerica.grib2
wgrib2 ${COMOUT}/rrfs.${cycle}.prslev.f${fhr}.namerica.grib2 -s > ${COMOUT}/rrfs.${cycle}.prslev.f${fhr}.namerica.grib2.idx

else
  echo "this grid is not ready for parallel prdgen: ${PREDEF_GRID_NAME}"
fi
else
#
# use single core to process all addition grids.
#
if [ ${#ADDNL_OUTPUT_GRIDS[@]} -gt 0 ]; then

  cd_vrfy ${COMOUT}

  grid_specs_130="lambert:265:25.000000 233.862000:451:13545.000000 16.281000:337:13545.000000"
  grid_specs_200="lambert:253:50.000000 285.720000:108:16232.000000 16.201000:94:16232.000000"
  grid_specs_221="lambert:253:50.000000 214.500000:349:32463.000000 1.000000:277:32463.000000"
  grid_specs_242="nps:225:60.000000 187.000000:553:11250.000000 30.000000:425:11250.000000"
  grid_specs_243="latlon 190.0:126:0.400 10.000:101:0.400"
  grid_specs_clue="lambert:262.5:38.5 239.891:1620:3000.0 20.971:1120:3000.0"
  grid_specs_hrrr="lambert:-97.5:38.5 -122.719528:1799:3000.0 21.138123:1059:3000.0"
  grid_specs_hrrre="lambert:-97.5:38.5 -122.719528:1800:3000.0 21.138123:1060:3000.0"
  grid_specs_rrfsak="lambert:-161.5:63.0 172.102615:1379:3000.0 45.84576:1003:3000.0"
  grid_specs_hrrrak="nps:225:60.000000 185.117126:1299:3000.0 41.612949:919:3000.0"

  for grid in ${ADDNL_OUTPUT_GRIDS[@]}
  do
    for leveltype in dawp rd3d ifi sfc
    do
      
      eval grid_specs=\$grid_specs_${grid}
      subdir=${COMOUT}/${grid}_grid
      mkdir -p ${subdir}/${fhr}
      bg_remap=${subdir}/${NET}.${cycle}${dot_ensmem}.bg${leveltype}.f${fhr}.${POST_OUTPUT_DOMAIN_NAME}.grib2

      # Interpolate fields to new grid
      eval infile=\$bg${leveltype}
      if [ ${NET} = "RRFS_NA_13km" ]; then
         wgrib2 ${infile} -set_bitmap 1 -set_grib_type c3 -new_grid_winds grid \
           -new_grid_vectors "UGRD:VGRD:USTM:VSTM:VUCSH:VVCSH" \
           -new_grid_interpolation bilinear \
           -if ":(WEASD|APCP|NCPCP|ACPCP|SNOD):" -new_grid_interpolation budget -fi \
           -if ":(NCONCD|NCCICE|SPNCR|CLWMR|CICE|RWMR|SNMR|GRLE|PMTF|PMTC|REFC|CSNOW|CICEP|CFRZR|CRAIN|LAND|ICEC|TMP:surface|VEG|CCOND|SFEXC|MSLMA|PRES:tropopause|LAI|HPBL|HGT:planetary boundary layer):|ICPRB|SIPD|ICSEV" -new_grid_interpolation neighbor -fi \
           -new_grid ${grid_specs} ${subdir}/${fhr}/tmp_${grid}.grib2 &
      else
         wgrib2 ${infile} -set_bitmap 1 -set_grib_type c3 -new_grid_winds grid \
           -new_grid_vectors "UGRD:VGRD:USTM:VSTM:VUCSH:VVCSH" \
           -new_grid_interpolation neighbor \
           -new_grid ${grid_specs} ${subdir}/${fhr}/tmp_${grid}.grib2 &
      fi
      wait 

      # Merge vector field records
      wgrib2 ${subdir}/${fhr}/tmp_${grid}.grib2 -new_grid_vectors "UGRD:VGRD:USTM:VSTM:VUCSH:VVCSH" -submsg_uv ${bg_remap} &
      wait 

      # Remove temporary files
      rm -f ${subdir}/${fhr}/tmp_${grid}.grib2

      # Save to com directory 
      mkdir -p ${COMOUT}/${grid}_grid
      cp_vrfy ${bg_remap} ${COMOUT}/${grid}_grid/${NET}.${cycle}${dot_ensmem}.bg${leveltype}.f${fhr}.${POST_OUTPUT_DOMAIN_NAME}.grib2

      if [ $leveltype = 'dawp' ]; then
         ln_vrfy -fs --relative ${COMOUT}/${grid}_grid/${NET}.${cycle}${dot_ensmem}.bg${leveltype}.f${fhr}.${POST_OUTPUT_DOMAIN_NAME}.grib2 ${COMOUT}/${net4}.${cycle}.prslev.f${fhr}.${gridname}grib2
         wgrib2 ${COMOUT}/${net4}.${cycle}.prslev.f${fhr}.${gridname}grib2 -s > ${COMOUT}/${net4}.${cycle}.prslev.f${fhr}.${gridname}grib2.idx
      fi

      if [ $leveltype = 'rd3d' ]; then
         ln_vrfy -fs --relative ${COMOUT}/${grid}_grid/${NET}.${cycle}${dot_ensmem}.bg${leveltype}.f${fhr}.${POST_OUTPUT_DOMAIN_NAME}.grib2 ${COMOUT}/${net4}.${cycle}.natlev.f${fhr}.${gridname}grib2
         wgrib2 ${COMOUT}/${net4}.${cycle}.natlev.f${fhr}.${gridname}grib2 -s > ${COMOUT}/${net4}.${cycle}.natlev.f${fhr}.${gridname}grib2.idx
      fi

      if [[ $leveltype = 'ifi' ]] && [[ -f ${COMOUT}/${grid}_grid/${NET}.${cycle}${dot_ensmem}.bg${leveltype}.f${fhr}.${POST_OUTPUT_DOMAIN_NAME}.grib2  ]]; then
         ln_vrfy -fs --relative ${COMOUT}/${grid}_grid/${NET}.${cycle}${dot_ensmem}.bg${leveltype}.f${fhr}.${POST_OUTPUT_DOMAIN_NAME}.grib2 ${COMOUT}/${net4}.${cycle}.ififip.f${fhr}.${gridname}grib2
         wgrib2 ${COMOUT}/${net4}.${cycle}.ififip.f${fhr}.${gridname}grib2 -s > ${COMOUT}/${net4}.${cycle}.ififip.f${fhr}.${gridname}grib2.idx
      fi

      if [ $leveltype = 'sfc' ]; then
         ln_vrfy -fs --relative ${COMOUT}/${grid}_grid/${NET}.${cycle}${dot_ensmem}.bg${leveltype}.f${fhr}.${POST_OUTPUT_DOMAIN_NAME}.grib2 ${COMOUT}/${net4}.${cycle}.testbed.f${fhr}.${gridname}grib2
         wgrib2 ${COMOUT}/${net4}.${cycle}.testbed.f${fhr}.${gridname}grib2 -s > ${COMOUT}/${net4}.${cycle}.testbed.f${fhr}.${gridname}grib2.idx
      fi

      # Link output for transfer from Jet to web
      ln_vrfy -fs --relative ${COMOUT}/${grid}_grid/${NET}.${cycle}${dot_ensmem}.bg${leveltype}.f${fhr}.${POST_OUTPUT_DOMAIN_NAME}.grib2 ${COMOUT}/${grid}_grid/BG${leveltype^^}_${basetime}${post_fhr}
    done
  done
fi

fi  # block for parallel or series wgrib2 runs.

rm_vrfy -rf ${DATA_FHR}
#
#-----------------------------------------------------------------------
#
# Print message indicating successful completion of script.
#
#-----------------------------------------------------------------------
#
print_info_msg "
========================================================================
Post-processing for forecast hour $fhr completed successfully.
Exiting script:  \"${scrfunc_fn}\"
In directory:    \"${scrfunc_dir}\"
========================================================================"
#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script/func-
# tion.
#
#-----------------------------------------------------------------------
#
{ restore_shell_opts; } > /dev/null 2>&1
