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

nprocs=$(( NNODES_RUN_PRDGEN*PPN_RUN_PRDGEN ))
if [ -z "${RUN_CMD_PRDGEN:-}" ] ; then
  print_err_msg_exit "\
  Run command was not set in machine file. \
  Please set RUN_CMD_PRDGEN for your platform"
else
  print_info_msg "$VERBOSE" "
  All executables will be submitted with command \'${RUN_CMD_PRDGEN}\'."
fi
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
prslev=${COMOUT}/${NET}.${cycle}${dot_ensmem}.prslev.f${fhr}.${POST_OUTPUT_DOMAIN_NAME}.grib2
natlev=${COMOUT}/${NET}.${cycle}${dot_ensmem}.natlev.f${fhr}.${POST_OUTPUT_DOMAIN_NAME}.grib2
testbed=${COMOUT}/${NET}.${cycle}${dot_ensmem}.testbed.f${fhr}.${POST_OUTPUT_DOMAIN_NAME}.grib2
ififip=${COMOUT}/${NET}.${cycle}${dot_ensmem}.ififip.f${fhr}.${POST_OUTPUT_DOMAIN_NAME}.grib2

# extract the output fields for the testbed files
touch ${testbed}
if [[ ! -z ${TESTBED_FIELDS_FN} ]]; then
  if [[ -f "${PARMdir}/upp/${TESTBED_FIELDS_FN}" ]]; then
    wgrib2 ${prslev} | grep -F -f "${PARMdir}/upp/${TESTBED_FIELDS_FN}" | wgrib2 -i -grib ${testbed} ${prslev}
  else
    echo "${PARMdir}/upp/${TESTBED_FIELDS_FN} not found"
  fi
fi
if [[ ! -z ${TESTBED_FIELDS_FN2} ]]; then
  if [[ -f "${PARMdir}/upp/${TESTBED_FIELDS_FN2}" ]]; then
    wgrib2 ${natlev} | grep -F -f "${PARMdir}/upp/${TESTBED_FIELDS_FN2}" | wgrib2 -i -append -grib ${testbed} ${natlev}
  else
    echo "${PARMdir}/upp/${TESTBED_FIELDS_FN2} not found"
  fi
fi

gridname=""
if [ ${PREDEF_GRID_NAME} = "RRFS_CONUS_3km" ]; then
  gridname="conus_3km."
elif  [ ${PREDEF_GRID_NAME} = "RRFS_NA_3km" ]; then
  gridname=""
fi
basetime=$( date +%y%j%H%M -d "${yyyymmdd} ${hh}" )

# Create index (idx) files
net4=$(echo ${NET:0:4} | tr '[:upper:]' '[:lower:]')
ln_vrfy -sf --relative ${COMOUT}/${NET}.${cycle}${dot_ensmem}.prslev.f${fhr}.${POST_OUTPUT_DOMAIN_NAME}.grib2 ${COMOUT}/${net4}.${cycle}.prslev.f${fhr}.${gridname}grib2
wgrib2 ${COMOUT}/${net4}.${cycle}.prslev.f${fhr}.${gridname}grib2 -s > ${COMOUT}/${net4}.${cycle}.prslev.f${fhr}.${gridname}grib2.idx
ln_vrfy -sf --relative ${COMOUT}/${NET}.${cycle}${dot_ensmem}.natlev.f${fhr}.${POST_OUTPUT_DOMAIN_NAME}.grib2 ${COMOUT}/${net4}.${cycle}.natlev.f${fhr}.${gridname}grib2
wgrib2 ${COMOUT}/${net4}.${cycle}.natlev.f${fhr}.${gridname}grib2 -s > ${COMOUT}/${net4}.${cycle}.natlev.f${fhr}.${gridname}grib2.idx
if [ -f ${COMOUT}/${NET}.${cycle}${dot_ensmem}.ififip.f${fhr}.${POST_OUTPUT_DOMAIN_NAME}.grib2 ]; then
  ln_vrfy -sf --relative ${COMOUT}/${NET}.${cycle}${dot_ensmem}.ififip.f${fhr}.${POST_OUTPUT_DOMAIN_NAME}.grib2 ${COMOUT}/${net4}.${cycle}.ififip.f${fhr}.${gridname}grib2
  wgrib2 ${COMOUT}/${net4}.${cycle}.ififip.f${fhr}.${gridname}grib2 -s > ${COMOUT}/${net4}.${cycle}.ififip.f${fhr}.${gridname}grib2.idx
fi
ln_vrfy -sf --relative ${COMOUT}/${NET}.${cycle}${dot_ensmem}.testbed.f${fhr}.${POST_OUTPUT_DOMAIN_NAME}.grib2  ${COMOUT}/${net4}.${cycle}.testbed.f${fhr}.${gridname}grib2
wgrib2 ${COMOUT}/${net4}.${cycle}.testbed.f${fhr}.${gridname}grib2 -s > ${COMOUT}/${net4}.${cycle}.testbed.f${fhr}.${gridname}grib2.idx

#-----------------------------------------------
# Remap to additional output grids if requested
#-----------------------------------------------

if [ ${DO_PARALLEL_PRDGEN} == "TRUE" ]; then
#
#  parallel run wgrib2 for product generation
#

if [ ${PREDEF_GRID_NAME} = "RRFS_NA_3km" ]; then

DATA=$COMOUT
DATAprdgen=$DATA/prdgen_${fhr}
mkdir $DATAprdgen

wgrib2 ${COMOUT}/rrfs.${cycle}.prslev.f${fhr}.grib2 >& $DATAprdgen/prslevf${fhr}.txt

# Create parm files for subsetting on the fly - do it for each forecast hour
# 10 subpieces for North American grid
sed -n -e '1,120p' $DATAprdgen/prslevf${fhr}.txt >& $DATAprdgen/namerica_1.txt
sed -n -e '121,240p' $DATAprdgen/prslevf${fhr}.txt >& $DATAprdgen/namerica_2.txt
sed -n -e '241,360p' $DATAprdgen/prslevf${fhr}.txt >& $DATAprdgen/namerica_3.txt
sed -n -e '361,480p' $DATAprdgen/prslevf${fhr}.txt >& $DATAprdgen/namerica_4.txt
sed -n -e '481,600p' $DATAprdgen/prslevf${fhr}.txt >& $DATAprdgen/namerica_5.txt
sed -n -e '601,720p' $DATAprdgen/prslevf${fhr}.txt >& $DATAprdgen/namerica_6.txt
sed -n -e '721,750p' $DATAprdgen/prslevf${fhr}.txt >& $DATAprdgen/namerica_7.txt
sed -n -e '751,780p' $DATAprdgen/prslevf${fhr}.txt >& $DATAprdgen/namerica_8.txt
sed -n -e '781,880p' $DATAprdgen/prslevf${fhr}.txt >& $DATAprdgen/namerica_9.txt
sed -n -e '881,$p' $DATAprdgen/prslevf${fhr}.txt >& $DATAprdgen/namerica_10.txt

# 4 subpieces for CONUS and Alaska grids
sed -n -e '1,250p' $DATAprdgen/prslevf${fhr}.txt >& $DATAprdgen/conus_ak_1.txt
sed -n -e '251,500p' $DATAprdgen/prslevf${fhr}.txt >& $DATAprdgen/conus_ak_2.txt
sed -n -e '501,750p' $DATAprdgen/prslevf${fhr}.txt >& $DATAprdgen/conus_ak_3.txt
sed -n -e '751,$p' $DATAprdgen/prslevf${fhr}.txt >& $DATAprdgen/conus_ak_4.txt

# 2 subpieces for Hawaii and Puerto Rico grids
sed -n -e '1,500p' $DATAprdgen/prslevf${fhr}.txt >& $DATAprdgen/hi_pr_1.txt
sed -n -e '501,$p' $DATAprdgen/prslevf${fhr}.txt >& $DATAprdgen/hi_pr_2.txt

mkdir -p $DATAprdgen/prdgen_conus_1
mkdir -p $DATAprdgen/prdgen_conus_2
mkdir -p $DATAprdgen/prdgen_conus_3
mkdir -p $DATAprdgen/prdgen_conus_4
mkdir -p $DATAprdgen/prdgen_ak_1
mkdir -p $DATAprdgen/prdgen_ak_2
mkdir -p $DATAprdgen/prdgen_ak_3
mkdir -p $DATAprdgen/prdgen_ak_4
mkdir -p $DATAprdgen/prdgen_hi_1
mkdir -p $DATAprdgen/prdgen_hi_2
mkdir -p $DATAprdgen/prdgen_pr_1
mkdir -p $DATAprdgen/prdgen_pr_2
mkdir -p $DATAprdgen/prdgen_namerica_1
mkdir -p $DATAprdgen/prdgen_namerica_2
mkdir -p $DATAprdgen/prdgen_namerica_3
mkdir -p $DATAprdgen/prdgen_namerica_4
mkdir -p $DATAprdgen/prdgen_namerica_5
mkdir -p $DATAprdgen/prdgen_namerica_6
mkdir -p $DATAprdgen/prdgen_namerica_7
mkdir -p $DATAprdgen/prdgen_namerica_8
mkdir -p $DATAprdgen/prdgen_namerica_9
mkdir -p $DATAprdgen/prdgen_namerica_10

# Create script to execute production generation tasks in parallel using CFP
echo "#!/bin/bash" > $DATAprdgen/poescript_${fhr}
echo "export DATA=${DATAprdgen}" >> $DATAprdgen/poescript_${fhr}
echo "export COMOUT=${COMOUT}" >> $DATAprdgen/poescript_${fhr}
echo "$SCRIPTSdir/exregional_run_prdgen_subpiece.sh $fhr $cyc 1 conus ${DATAprdgen} ${COMOUT} &" >> $DATAprdgen/poescript_${fhr}
echo "$SCRIPTSdir/exregional_run_prdgen_subpiece.sh $fhr $cyc 2 conus ${DATAprdgen} ${COMOUT} &" >> $DATAprdgen/poescript_${fhr}
echo "$SCRIPTSdir/exregional_run_prdgen_subpiece.sh $fhr $cyc 3 conus ${DATAprdgen} ${COMOUT} &" >> $DATAprdgen/poescript_${fhr}
echo "$SCRIPTSdir/exregional_run_prdgen_subpiece.sh $fhr $cyc 4 conus ${DATAprdgen} ${COMOUT} &" >> $DATAprdgen/poescript_${fhr}
echo "$SCRIPTSdir/exregional_run_prdgen_subpiece.sh $fhr $cyc 1 ak ${DATAprdgen} ${COMOUT} &" >> $DATAprdgen/poescript_${fhr}
echo "$SCRIPTSdir/exregional_run_prdgen_subpiece.sh $fhr $cyc 2 ak ${DATAprdgen} ${COMOUT} &" >> $DATAprdgen/poescript_${fhr}
echo "$SCRIPTSdir/exregional_run_prdgen_subpiece.sh $fhr $cyc 3 ak ${DATAprdgen} ${COMOUT} &" >> $DATAprdgen/poescript_${fhr}
echo "$SCRIPTSdir/exregional_run_prdgen_subpiece.sh $fhr $cyc 4 ak ${DATAprdgen} ${COMOUT} &" >> $DATAprdgen/poescript_${fhr}
echo "$SCRIPTSdir/exregional_run_prdgen_subpiece.sh $fhr $cyc 1 hi ${DATAprdgen} ${COMOUT} &" >> $DATAprdgen/poescript_${fhr}
echo "$SCRIPTSdir/exregional_run_prdgen_subpiece.sh $fhr $cyc 2 hi ${DATAprdgen} ${COMOUT} &" >> $DATAprdgen/poescript_${fhr}
echo "$SCRIPTSdir/exregional_run_prdgen_subpiece.sh $fhr $cyc 1 pr ${DATAprdgen} ${COMOUT} &" >> $DATAprdgen/poescript_${fhr}
echo "$SCRIPTSdir/exregional_run_prdgen_subpiece.sh $fhr $cyc 2 pr ${DATAprdgen} ${COMOUT} &" >> $DATAprdgen/poescript_${fhr}
echo "$SCRIPTSdir/exregional_run_prdgen_subpiece.sh $fhr $cyc 1 namerica ${DATAprdgen} ${COMOUT} &" >> $DATAprdgen/poescript_${fhr}
echo "$SCRIPTSdir/exregional_run_prdgen_subpiece.sh $fhr $cyc 2 namerica ${DATAprdgen} ${COMOUT} &" >> $DATAprdgen/poescript_${fhr}
echo "$SCRIPTSdir/exregional_run_prdgen_subpiece.sh $fhr $cyc 3 namerica ${DATAprdgen} ${COMOUT} &" >> $DATAprdgen/poescript_${fhr}
echo "$SCRIPTSdir/exregional_run_prdgen_subpiece.sh $fhr $cyc 4 namerica ${DATAprdgen} ${COMOUT} &" >> $DATAprdgen/poescript_${fhr}
echo "$SCRIPTSdir/exregional_run_prdgen_subpiece.sh $fhr $cyc 5 namerica ${DATAprdgen} ${COMOUT} &" >> $DATAprdgen/poescript_${fhr}
echo "$SCRIPTSdir/exregional_run_prdgen_subpiece.sh $fhr $cyc 6 namerica ${DATAprdgen} ${COMOUT} &" >> $DATAprdgen/poescript_${fhr}
echo "$SCRIPTSdir/exregional_run_prdgen_subpiece.sh $fhr $cyc 7 namerica ${DATAprdgen} ${COMOUT} &" >> $DATAprdgen/poescript_${fhr}
echo "$SCRIPTSdir/exregional_run_prdgen_subpiece.sh $fhr $cyc 8 namerica ${DATAprdgen} ${COMOUT} &" >> $DATAprdgen/poescript_${fhr}
echo "$SCRIPTSdir/exregional_run_prdgen_subpiece.sh $fhr $cyc 9 namerica ${DATAprdgen} ${COMOUT} &" >> $DATAprdgen/poescript_${fhr}
echo "$SCRIPTSdir/exregional_run_prdgen_subpiece.sh $fhr $cyc 10 namerica ${DATAprdgen} ${COMOUT} &" >> $DATAprdgen/poescript_${fhr}
echo "wait" >> $DATAprdgen/poescript_${fhr}
chmod 775 $DATAprdgen/poescript_${fhr}

#-----------------------------------------
# Execute the script
#-----------------------------------------

PREP_STEP
export CMDFILE=$DATAprdgen/poescript_${fhr}
eval ${RUN_CMD_PRDGEN} ${CMDFILE} ${REDIRECT_OUT_ERR} || print_err_msg_exit "\
Call to parallel prdgen for forecast hour $fhr returned with non-
zero exit code."
POST_STEP

#----------------------------------------
# reassemble the output grids
#----------------------------------------

cat $DATAprdgen/prdgen_conus_1/conus_1.grib2 \
    $DATAprdgen/prdgen_conus_2/conus_2.grib2 \
    $DATAprdgen/prdgen_conus_3/conus_3.grib2 \
    $DATAprdgen/prdgen_conus_4/conus_4.grib2 \
    > ${COMOUT}/rrfs.${cycle}.prslev.f${fhr}.conus_3km.grib2
wgrib2 ${COMOUT}/rrfs.${cycle}.prslev.f${fhr}.conus_3km.grib2 -s > ${COMOUT}/rrfs.${cycle}.prslev.f${fhr}.conus_3km.grib2.idx

cat $DATAprdgen/prdgen_ak_1/ak_1.grib2 \
    $DATAprdgen/prdgen_ak_2/ak_2.grib2 \
    $DATAprdgen/prdgen_ak_3/ak_3.grib2 \
    $DATAprdgen/prdgen_ak_4/ak_4.grib2 \
    > ${COMOUT}/rrfs.${cycle}.prslev.f${fhr}.ak.grib2
wgrib2 ${COMOUT}/rrfs.${cycle}.prslev.f${fhr}.ak.grib2 -s > ${COMOUT}/rrfs.${cycle}.prslev.f${fhr}.ak.grib2.idx

cat $DATAprdgen/prdgen_hi_1/hi_1.grib2 \
    $DATAprdgen/prdgen_hi_2/hi_2.grib2 \
    > ${COMOUT}/rrfs.${cycle}.prslev.f${fhr}.hi.grib2
wgrib2 ${COMOUT}/rrfs.${cycle}.prslev.f${fhr}.hi.grib2 -s > ${COMOUT}/rrfs.${cycle}.prslev.f${fhr}.hi.grib2.idx

cat $DATAprdgen/prdgen_pr_1/pr_1.grib2 \
    $DATAprdgen/prdgen_pr_2/pr_2.grib2 \
    > ${COMOUT}/rrfs.${cycle}.prslev.f${fhr}.pr.grib2
wgrib2 ${COMOUT}/rrfs.${cycle}.prslev.f${fhr}.pr.grib2 -s > ${COMOUT}/rrfs.${cycle}.prslev.f${fhr}.pr.grib2.idx

cat $DATAprdgen/prdgen_namerica_1/namerica_1.grib2 \
    $DATAprdgen/prdgen_namerica_2/namerica_2.grib2 \
    $DATAprdgen/prdgen_namerica_3/namerica_3.grib2 \
    $DATAprdgen/prdgen_namerica_4/namerica_4.grib2 \
    $DATAprdgen/prdgen_namerica_5/namerica_5.grib2 \
    $DATAprdgen/prdgen_namerica_6/namerica_6.grib2 \
    $DATAprdgen/prdgen_namerica_7/namerica_7.grib2 \
    $DATAprdgen/prdgen_namerica_8/namerica_8.grib2 \
    $DATAprdgen/prdgen_namerica_9/namerica_9.grib2 \
    $DATAprdgen/prdgen_namerica_10/namerica_10.grib2 \
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
    for leveltype in prslev natlev ififip testbed
    do
      
      eval grid_specs=\$grid_specs_${grid}
      subdir=${COMOUT}/${grid}_grid
      mkdir -p ${subdir}/${fhr}
      bg_remap=${subdir}/${NET}.${cycle}${dot_ensmem}.${leveltype}.f${fhr}.${POST_OUTPUT_DOMAIN_NAME}.grib2

      # Interpolate fields to new grid
      eval infile=\${leveltype}
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
      cp_vrfy ${bg_remap} ${COMOUT}/${grid}_grid/${NET}.${cycle}${dot_ensmem}.${leveltype}.f${fhr}.${POST_OUTPUT_DOMAIN_NAME}.grib2

      if [ $leveltype = 'prslev' ]; then
         ln_vrfy -fs --relative ${COMOUT}/${grid}_grid/${NET}.${cycle}${dot_ensmem}.${leveltype}.f${fhr}.${POST_OUTPUT_DOMAIN_NAME}.grib2 ${COMOUT}/${net4}.${cycle}.prslev.f${fhr}.${gridname}grib2
         wgrib2 ${COMOUT}/${net4}.${cycle}.prslev.f${fhr}.${gridname}grib2 -s > ${COMOUT}/${net4}.${cycle}.prslev.f${fhr}.${gridname}grib2.idx
      fi

      if [ $leveltype = 'natlev' ]; then
         ln_vrfy -fs --relative ${COMOUT}/${grid}_grid/${NET}.${cycle}${dot_ensmem}.${leveltype}.f${fhr}.${POST_OUTPUT_DOMAIN_NAME}.grib2 ${COMOUT}/${net4}.${cycle}.natlev.f${fhr}.${gridname}grib2
         wgrib2 ${COMOUT}/${net4}.${cycle}.natlev.f${fhr}.${gridname}grib2 -s > ${COMOUT}/${net4}.${cycle}.natlev.f${fhr}.${gridname}grib2.idx
      fi

      if [[ $leveltype = 'ififip' ]] && [[ -f ${COMOUT}/${grid}_grid/${NET}.${cycle}${dot_ensmem}.${leveltype}.f${fhr}.${POST_OUTPUT_DOMAIN_NAME}.grib2  ]]; then
         ln_vrfy -fs --relative ${COMOUT}/${grid}_grid/${NET}.${cycle}${dot_ensmem}.${leveltype}.f${fhr}.${POST_OUTPUT_DOMAIN_NAME}.grib2 ${COMOUT}/${net4}.${cycle}.ififip.f${fhr}.${gridname}grib2
         wgrib2 ${COMOUT}/${net4}.${cycle}.ififip.f${fhr}.${gridname}grib2 -s > ${COMOUT}/${net4}.${cycle}.ififip.f${fhr}.${gridname}grib2.idx
      fi

      if [ $leveltype = 'testbed' ]; then
         ln_vrfy -fs --relative ${COMOUT}/${grid}_grid/${NET}.${cycle}${dot_ensmem}.${leveltype}.f${fhr}.${POST_OUTPUT_DOMAIN_NAME}.grib2 ${COMOUT}/${net4}.${cycle}.testbed.f${fhr}.${gridname}grib2
         wgrib2 ${COMOUT}/${net4}.${cycle}.testbed.f${fhr}.${gridname}grib2 -s > ${COMOUT}/${net4}.${cycle}.testbed.f${fhr}.${gridname}grib2.idx
      fi

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
Product generation for forecast hour $fhr completed successfully.
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
