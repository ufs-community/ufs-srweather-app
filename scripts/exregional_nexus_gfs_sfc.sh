#!/bin/bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. $USHdir/source_util_funcs.sh
source_config_for_task "cpl_aqm_parm" ${GLOBAL_VAR_DEFNS_FP}
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

This is the ex-script for the task that copies or fetches GFS surface
data files from disk or HPSS.
========================================================================"
#
#-----------------------------------------------------------------------
#
DATA="${DATA}/tmp_GFS_SFC"
mkdir_vrfy -p "$DATA"
cd_vrfy $DATA
#
#-----------------------------------------------------------------------
#
# Set up variables for call to retrieve_data.py
#
#-----------------------------------------------------------------------
#
yyyymmdd=${GFS_SFC_CDATE:0:8}
yyyymm=${GFS_SFC_CDATE:0:6}
yyyy=${GFS_SFC_CDATE:0:4}
hh=${GFS_SFC_CDATE:8:2}
if [ "${FCST_LEN_HRS}" = "-1" ]; then
  for i_cdate in "${!ALL_CDATES[@]}"; do
    if [ "${ALL_CDATES[$i_cdate]}" = "${PDY}${cyc}" ]; then
      FCST_LEN_HRS="${FCST_LEN_CYCL[$i_cdate]}"
      break
    fi
  done
fi
#
#-----------------------------------------------------------------------
#
# Retrieve GFS surface files to GFS_SFC_STAGING_DIR
#
#-----------------------------------------------------------------------
#
GFS_SFC_TAR_DIR="${NEXUS_GFS_SFC_ARCHV_DIR}/rh${yyyy}/${yyyymm}/${yyyymmdd}"
GFS_SFC_TAR_SUB_DIR="gfs.${yyyymmdd}/${hh}/atmos"

GFS_SFC_LOCAL_DIR="${COMINgfs_BASEDIR}/${GFS_SFC_TAR_SUB_DIR}"
GFS_SFC_DATA_INTVL="3"

# copy files from local directory
if [ -d ${GFS_SFC_LOCAL_DIR} ]; then
  gfs_sfc_fn="gfs.t${hh}z.sfcanl.nc"
  cp_vrfy "${GFS_SFC_LOCAL_DIR}/${gfs_sfc_fn}" ${GFS_SFC_STAGING_DIR}

  for fhr in $(seq -f "%03g" 0 ${GFS_SFC_DATA_INTVL} ${FCST_LEN_HRS}); do
    gfs_sfc_fn="gfs.t${hh}z.sfcf${fhr}.nc"
    if [ -e "${GFS_SFC_LOCAL_DIR}/${gfs_sfc_fn}" ]; then
      cp_vrfy "${GFS_SFC_LOCAL_DIR}/${gfs_sfc_fn}" ${GFS_SFC_STAGING_DIR}
    else
    print_err_msg_exit "\
sfc file does not exist in the directory:
  GFS_SFC_LOCAL_DIR = \"${GFS_SFC_LOCAL_DIR}\"
  gfs_sfc_fn = \"${gfs_sfc_fn}\""
    fi	    
  done
 
# retrieve files from HPSS
else
  if [ "${yyyymmdd}" -lt "20220627" ]; then
    GFS_SFC_TAR_FN_VER="prod"
  elif [ "${yyyymmdd}" -lt "20221129" ]; then
    GFS_SFC_TAR_FN_VER="v16.2"
  else
    GFS_SFC_TAR_FN_VER="v16.3"
  fi
  GFS_SFC_TAR_FN_PREFIX="com_gfs_${GFS_SFC_TAR_FN_VER}_gfs"
  GFS_SFC_TAR_FN_SUFFIX_A="gfs_nca.tar"
  GFS_SFC_TAR_FN_SUFFIX_B="gfs_ncb.tar"

  # Check if the sfcanl file exists in the staging directory
  gfs_sfc_tar_fn="${GFS_SFC_TAR_FN_PREFIX}.${yyyymmdd}_${hh}.${GFS_SFC_TAR_FN_SUFFIX_A}"
  gfs_sfc_tar_fp="${GFS_SFC_TAR_DIR}/${gfs_sfc_tar_fn}"
  gfs_sfc_fns=("gfs.t${hh}z.sfcanl.nc")
  gfs_sfc_fps="./${GFS_SFC_TAR_SUB_DIR}/gfs.t${hh}z.sfcanl.nc"
  if [ "${FCST_LEN_HRS}" -lt "40" ]; then
    ARCHV_LEN_HRS="${FCST_LEN_HRS}"
  else
    ARCHV_LEN_HRS="39"
  fi
  for fhr in $(seq -f "%03g" 0 ${GFS_SFC_DATA_INTVL} ${ARCHV_LEN_HRS}); do
    gfs_sfc_fns+="gfs.t${hh}z.sfcf${fhr}.nc"
    gfs_sfc_fps+=" ./${GFS_SFC_TAR_SUB_DIR}/gfs.t${hh}z.sfcf${fhr}.nc"
  done

  # Retrieve data from A file up to FCST_LEN_HRS=39
  htar_log_fn="log.htar_a_get.${yyyymmdd}_${hh}"
  htar -tvf ${gfs_sfc_tar_fp}
  htar -xvf ${gfs_sfc_tar_fp} ${gfs_sfc_fps} >& ${htar_log_fn} || \
    print_err_msg_exit "\
htar file reading operation (\"htar -xvf ...\") failed.  Check the log 
file htar_log_fn in the staging directory (gfs_sfc_staging_dir) for 
details:
  gfs_sfc_staging_dir = \"${GFS_SFC_STAGING_DIR}\"
  htar_log_fn = \"${htar_log_fn}\""

  # Retireve data from B file when FCST_LEN_HRS>=40
  if [ "${FCST_LEN_HRS}" -ge "40" ]; then
    gfs_sfc_tar_fn="${GFS_SFC_TAR_FN_PREFIX}.${yyyymmdd}_${hh}.${GFS_SFC_TAR_FN_SUFFIX_B}"
    gfs_sfc_tar_fp="${GFS_SFC_TAR_DIR}/${gfs_sfc_tar_fn}"
    gfs_sfc_fns=()
    gfs_sfc_fps=""
    for fhr in $(seq -f "%03g" 42 ${GFS_SFC_DATA_INTVL} ${FCST_LEN_HRS}); do
      gfs_sfc_fns+="gfs.t${hh}z.sfcf${fhr}.nc"
      gfs_sfc_fps+=" ./${GFS_SFC_TAR_SUB_DIR}/gfs.t${hh}z.sfcf${fhr}.nc"  
    done

    htar_log_fn="log.htar_b_get.${yyyymmdd}_${hh}"
    htar -tvf ${gfs_sfc_tar_fp}
    htar -xvf ${gfs_sfc_tar_fp} ${gfs_sfc_fps} >& ${htar_log_fn} || \
    print_err_msg_exit "\
htar file reading operation (\"htar -xvf ...\") failed.  Check the log 
file htar_log_fn in the staging directory (gfs_sfc_staging_dir) for 
details:
  gfs_sfc_staging_dir = \"${GFS_SFC_STAGING_DIR}\"
  htar_log_fn = \"${htar_log_fn}\""

  fi
  # Move retrieved files to staging directory
  mv_vrfy ${DATA}/${GFS_SFC_TAR_SUB_DIR}/gfs.*.nc ${GFS_SFC_STAGING_DIR}

fi  
#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script/function.
#
#-----------------------------------------------------------------------
#
{ restore_shell_opts; } > /dev/null 2>&1
