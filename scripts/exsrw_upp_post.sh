#!/usr/bin/env bash

set -xue
#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. ${PARMsrw}/source_util_funcs.sh
task_global_vars=( "CPL_AQM" "CUSTOM_POST_CONFIG_FP" "DO_SMOKE_DUST" \
  "DT_ATMOS" "FIXcrtm" "FIXupp" "NUMX" "OMP_NUM_THREADS_UPP_POST" \
  "POST_OUTPUT_DOMAIN_NAME" "PRE_TASK_CMDS" "PREDEF_GRID_NAME" \
  "RUN_CMD_POST" "SUB_HOURLY_POST" "USE_CRTM" "USE_CUSTOM_POST_CONFIG_FILE" )
for var in ${task_global_vars[@]}; do
  source_config_for_task ${var} ${GLOBAL_VAR_DEFNS_FP}
done
#
#-----------------------------------------------------------------------
#
# Save current shell options (in a global array).  Then set new options
# for this script/function.
#
#-----------------------------------------------------------------------
#
#{ save_shell_opts; set -xue; } > /dev/null 2>&1
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
export KMP_AFFINITY="scatter"
export OMP_NUM_THREADS=${OMP_NUM_THREADS_UPP_POST}
export OMP_STACKSIZE="1024m"
#
#-----------------------------------------------------------------------
#
# Load modules.
#
#-----------------------------------------------------------------------
#
eval ${PRE_TASK_CMDS}

if [ -z "${RUN_CMD_POST:-}" ] ; then
  print_err_msg_exit "\
  Run command was not set in machine file. \
  Please set RUN_CMD_POST for your platform"
else
  print_info_msg "All executables will be submitted with \'${RUN_CMD_POST}\'."
fi
#
#-----------------------------------------------------------------------
#
# Make sure that fhr is a non-empty string consisting of only digits.
#
#-----------------------------------------------------------------------
#
export fhr=$( printf "%s" "${fhr}" | $SED -n -r -e "s/^([0-9]+)$/\1/p" )
if [ -z "$fhr" ]; then
  print_err_msg_exit "\
The forecast hour (fhr) must be a non-empty string consisting of only
digits:
  fhr = \"${fhr}\""
fi
if [ $(boolify "${SUB_HOURLY_POST}") != "TRUE" ]; then
  export fmn="00"
fi
#
#-----------------------------------------------------------------------
#
# Stage necessary files in the working directory.
#
#-----------------------------------------------------------------------
#
cp -p ${PARMsrw}/upp_parm/nam_micro_lookup.dat ./eta_micro_lookup.dat
if [ $(boolify ${USE_CUSTOM_POST_CONFIG_FILE}) = "TRUE" ]; then
  post_config_fp="${CUSTOM_POST_CONFIG_FP}"
  print_info_msg "
====================================================================
Copying the user-defined file specified by CUSTOM_POST_CONFIG_FP:
  CUSTOM_POST_CONFIG_FP = \"${CUSTOM_POST_CONFIG_FP}\"
===================================================================="
else
  if [ $(boolify "${CPL_AQM}") = "TRUE" ]; then
    post_config_fp="${PARMsrw}/upp_parm/postxconfig-NT-AQM.txt"
  else
    post_config_fp="${PARMsrw}/upp_parm/postxconfig-NT-fv3lam_rrfs.txt"
  fi
  print_info_msg "
====================================================================
Copying the default post flat file specified by post_config_fp:
  post_config_fp = \"${post_config_fp}\"
===================================================================="
fi
cp -p ${post_config_fp} ./postxconfig-NT.txt
cp -p ${PARMsrw}/upp_parm/params_grib2_tbl_new .

if [ $(boolify ${DO_SMOKE_DUST}) = "TRUE" ] || [ $(boolify ${USE_CRTM}) = "TRUE" ]; then
  ln -nsf ${FIXcrtm}/Nalli.IRwater.EmisCoeff.bin .
  ln -nsf ${FIXcrtm}/FAST*.bin .
  ln -nsf ${FIXcrtm}/NPOESS.IRland.EmisCoeff.bin .
  ln -nsf ${FIXcrtm}/NPOESS.IRsnow.EmisCoeff.bin .
  ln -nsf ${FIXcrtm}/NPOESS.IRice.EmisCoeff.bin .
  ln -nsf ${FIXcrtm}/AerosolCoeff.bin .
  ln -nsf ${FIXcrtm}/CloudCoeff.bin .
  ln -nsf ${FIXcrtm}/*.SpcCoeff.bin .
  ln -nsf ${FIXcrtm}/*.TauCoeff.bin .
  print_info_msg "
====================================================================
Copying the CRTM fix files from FIXcrtm:
  FIXcrtm = \"${FIXcrtm}\"
===================================================================="
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
#
#-----------------------------------------------------------------------
#
# Create the namelist file (itag) containing arguments to pass to the post-
# processor's executable.
#
#-----------------------------------------------------------------------
#
# Set the variable (mnts_secs_str) that determines the suffix in the names
# of the forecast model's write-component output files that specifies the
# minutes and seconds of the corresponding output forecast time.
#
# Note that if the forecast model is instructed to output at some hourly
# interval (via the output_fh parameter in the MODEL_CONFIG_FN file,
# with nsout set to a non-positive value), then the write-component
# output file names will not contain any suffix for the minutes and seconds.
# For this reason, when SUB_HOURLY_POST is not set to "TRUE", mnts_sec_str
# must be set to a null string.
#
mnts_secs_str=""
if [ $(boolify "${SUB_HOURLY_POST}") = "TRUE" ]; then
  if [ ${fhr}${fmn} = "00000" ]; then
    mnts_secs_str=":"$( $DATE_UTIL --utc --date "${yyyymmdd} ${hh} UTC + ${DT_ATMOS} seconds" "+%M:%S" )
  else
    mnts_secs_str=":${fmn}:00"
  fi
fi
#
# Set namelist of upp.
#
if [ $(boolify "${CPL_AQM}") = "TRUE" ] || [ $(boolify "${DO_SMOKE_DUST}") = "TRUE" ]; then
  dyn_file="${COMIN}/${NET}.${cycle}${dot_ensmem}.dyn.f${fhr}.${POST_OUTPUT_DOMAIN_NAME}.nc"
  phy_file="${COMIN}/${NET}.${cycle}${dot_ensmem}.phy.f${fhr}.${POST_OUTPUT_DOMAIN_NAME}.nc"
else
  dyn_file="${COMIN}/dynf${fhr}${mnts_secs_str}.nc"
  phy_file="${COMIN}/phyf${fhr}${mnts_secs_str}.nc"
fi

post_time=$( $DATE_UTIL --utc --date "${yyyymmdd} ${hh} UTC + ${fhr} hours + ${fmn} minutes" "+%Y%m%d%H%M" )
post_yyyy=${post_time:0:4}
post_mm=${post_time:4:2}
post_dd=${post_time:6:2}
post_hh=${post_time:8:2}
post_mn=${post_time:10:2}

if [ $(boolify "${CPL_AQM}") = "TRUE" ] && [ $(boolify "${DO_SMOKE_DUST}") = "FALSE" ]; then
  post_itag_add="aqf_on=.true.,"
elif [ $(boolify "${DO_SMOKE_DUST}") = "TRUE" ]; then
  post_itag_add="slrutah_on=.true.,gtg_on=.true."
else
  post_itag_add=""
fi
cat > itag <<EOF
&model_inputs
fileName='${dyn_file}'
IOFORM='netcdf'
grib='grib2'
DateStr='${post_yyyy}-${post_mm}-${post_dd}_${post_hh}:${post_mn}:00'
MODELNAME='FV3R'
fileNameFlux='${phy_file}'
/

 &NAMPGB
 KPO=47,PO=1000.,975.,950.,925.,900.,875.,850.,825.,800.,775.,750.,725.,700.,675.,650.,625.,600.,575.,550.,525.,500.,475.,450.,425.,400.,375.,350.,325.,300.,275.,250.,225.,200.,175.,150.,125.,100.,70.,50.,30.,20.,10.,7.,5.,3.,2.,1.,${post_itag_add},numx=${NUMX}
 /
EOF

if [ $(boolify "${DO_SMOKE_DUST}") = "TRUE" ]; then
  if [ ${PREDEF_GRID_NAME} = "RRFS_CONUS_3km" ]; then
    grid_specs_rrfs="lambert:-97.5:38.500000 237.280472:1799:3000 21.138115:1059:3000"
  elif [ ${PREDEF_GRID_NAME} = "RRFS_NA_3km" ]; then
    grid_specs_rrfs="rot-ll:247.000000:-35.000000:0.000000 299.000000:4881:0.025000 -37.0000000:2961:0.025000"
  fi
  if [ ${PREDEF_GRID_NAME} = "RRFS_CONUS_3km" ] || [ ${PREDEF_GRID_NAME} = "RRFS_NA_3km" ]; then
    for ayear in 100y 10y 5y 2y ; do
      for ahour in 01h 03h 06h 12h 24h; do
        if [ -f ${FIXupp}/${PREDEF_GRID_NAME}/ari${ayear}_${ahour}.grib2 ]; then
          ln -snf ${FIXupp}/${PREDEF_GRID_NAME}/ari${ayear}_${ahour}.grib2 ari${ayear}_${ahour}.grib2
        fi
      done
    done
  fi
fi
#
#-----------------------------------------------------------------------
#
# Run the UPP executable.
#
#-----------------------------------------------------------------------
#
export pgm="upp.x"

. prep_step
eval ${RUN_CMD_POST} ${EXECsrw}/$pgm < itag >>$pgmout 2>errfile
export err=$?; err_chk
if [ $err -ne 0 ]; then
  message_txt="upp.x failed with return code $err"
  err_exit "${message_txt}"
  print_err_msg_exit "${message_txt}"
fi
#
#-----------------------------------------------------------------------
#
# A separate ${post_fhr} forecast hour variable is required for the post
# files, since they may or may not be three digits long, depending on the
# length of the forecast.
#
# A separate ${subh_fhr} is needed for subhour post.
#-----------------------------------------------------------------------
#
# get the length of the fhr string to decide format of forecast time stamp.
# 9 is sub-houry forecast and 3 is full hour forecast only.
len_fhr=${#fhr}
if [ ${len_fhr} -eq 9 ]; then
  post_min=${fhr:4:2}
  if [ ${post_min} -lt ${nsout_min} ]; then
    post_min=00
  fi
else
  post_min=00
fi

subh_fhr=${fhr}
if [ ${len_fhr} -eq 2 ]; then
  post_fhr=${fhr}
elif [ ${len_fhr} -eq 3 ]; then
  if [ "${fhr:0:1}" = "0" ]; then
    post_fhr="${fhr:1}"
  else
    post_fhr=${fhr}
  fi
elif [ ${len_fhr} -eq 9 ]; then
  if [ "${fhr:0:1}" = "0" ]; then
    if [ ${post_min} -eq 00 ]; then
      post_fhr="${fhr:1:2}"
      subh_fhr="${fhr:0:3}"
    else
      post_fhr="${fhr:1:2}.${fhr:4:2}"
    fi
  else
    if [ ${post_min} -eq 00 ]; then
      post_fhr="${fhr:0:3}"
      subh_fhr="${fhr:0:3}"
    else
      post_fhr="${fhr:0:3}.${fhr:4:2}"
    fi
  fi
else
  err_exit "\
The \${fhr} variable contains too few or too many characters:
  fhr = \"$fhr\""
fi

# replace fhr with subh_fhr
echo "fhr=${fhr} and subh_fhr=${subh_fhr}"
fhr=${subh_fhr}

if [ $(boolify "${DO_SMOKE_DUST}") = "TRUE" ]; then
  bgdawp=${NET}.${cycle}.prslev.f${fhr}.${POST_OUTPUT_DOMAIN_NAME}.grib2
  bgrd3d=${NET}.${cycle}.natlev.f${fhr}.${POST_OUTPUT_DOMAIN_NAME}.grib2
  bgifi=${NET}.${cycle}.ififip.f${fhr}.${POST_OUTPUT_DOMAIN_NAME}.grib2
  bgavi=${NET}.${cycle}.aviati.f${fhr}.${POST_OUTPUT_DOMAIN_NAME}.grib2

  if [ -f "PRSLEV.GrbF${post_fhr}" ]; then
    wgrib2 PRSLEV.GrbF${post_fhr} -set center 7 -grib ${bgdawp} >>$pgmout 2>>errfile
  fi
  if [ -f "NATLEV.GrbF${post_fhr}" ]; then
    wgrib2 NATLEV.GrbF${post_fhr} -set center 7 -grib ${bgrd3d} >>$pgmout 2>>errfile
  fi
  if [ -f "IFIFIP.GrbF${post_fhr}" ]; then
    wgrib2 IFIFIP.GrbF${post_fhr} -set center 7 -grib ${bgifi} >>$pgmout 2>>errfile
  fi
  if [ -f "AVIATI.GrbF${post_fhr}" ]; then
    wgrib2 AVIATI.GrbF${post_fhr} -set center 7 -grib ${bgavi} >>$pgmout 2>>errfile
  fi

  cp -p ${bgdawp} ${COMOUT}
  cp -p ${bgrd3d} ${COMOUT}
  cp -p ${bgifi} ${COMOUT}
  cp -p ${bgavi} ${COMOUT}

else

  post_mn_or_null=""
  dot_post_mn_or_null=""
  if [ "${post_mn}" != "00" ]; then
    post_mn_or_null="${post_mn}"
    dot_post_mn_or_null=".${post_mn}"
  fi
  post_fn_suffix="GrbF${post_fhr}${dot_post_mn_or_null}"
  post_renamed_fn_suffix="f${fhr}${post_mn_or_null}.${POST_OUTPUT_DOMAIN_NAME}.grib2"
  basetime=$( $DATE_UTIL --date "$yyyymmdd $hh" +%y%j%H%M )
  symlink_suffix="${dot_ensmem}.${basetime}f${fhr}${post_mn}"
  if [ $(boolify "${CPL_AQM}") = "TRUE" ]; then
    fids=( "cmaq" )
  else
    fids=( "prslev" "natlev" )
  fi
  for fid in "${fids[@]}"; do
    FID=$(echo_uppercase $fid)
    post_orig_fn="${FID}.${post_fn_suffix}"
    post_renamed_fn="${NET}.${cycle}${dot_ensmem}.${fid}.${post_renamed_fn_suffix}"
    mv ${post_orig_fn} ${post_renamed_fn}
    cp -p ${post_renamed_fn} ${COMOUT}
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
UPP post-processing has successfully generated output files for $fhr !!!!

Exiting script:  \"${scrfunc_fn}\"
In directory:    \"${scrfunc_dir}\"
========================================================================"
#
#-----------------------------------------------------------------------
#
#{ restore_shell_opts; } > /dev/null 2>&1
