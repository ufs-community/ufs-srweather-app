#!/bin/bash
#
set -eux
#
# This utility is to replace configuration template with production settings before running ecflow workflow
# Usage:
#       cd $HOMEaqm/parm/config
#       vi aqm_nco_config.sh and modify General parameter
#       sh aqm_nco_config.sh
#
# General parameters must be modified by NCEP/NCO/SPA
#   Remove the remark and modify with running environment
## OPSROOT="/lfs/h2/emc/ptmp/jianping.huang/ecflow_aqm/para"
## COMROOT="/lfs/h2/emc/ptmp/jianping.huang/ecflow_aqm/para/com"
WARMSTART_PDY="20240128"
#
#####################################################################################
# No need to modify any line below
#####################################################################################
#
# Target files to modify
File_to_modify_source="var_defns.sh"
#
# Source run.ver
source "$HOMEaqm/versions/run.ver" || { echo "Failed to source run.ver"; exit 1; }
#
# Assign COMaqm using production utility
## COMROOT=${COMROOT:-"${OPSROOT}/com"}
OPSROOT=$(realpath ${COMROOT}/..)
COMaqm=$(compath.py -o "aqm/${aqm_ver}") || { echo "Failed to assign COMaqm"; exit 1; }
COMINgefs=$(compath.py "gefs/${gefs_ver}") || { echo "Failed to assign COMINgefs"; exit 1; }
MODEL_VER_DFV=${COMaqm:(-4)}
#
# Replace special characters 
OPSROOT=$(printf '%q' "$OPSROOT")
HOMEaqm=$(printf '%q' "$HOMEaqm")
COMROOT=$(printf '%q' "$COMROOT")
DCOMROOT=$(printf '%q' "$DCOMROOT")
COMaqm=$(printf '%q' "$COMaqm")
COMINgefs=$(printf '%q' "$COMINgefs")
DATA=$(printf '%q' "$DATA")
MODEL_VER_DFV=$(printf '%q' "$MODEL_VER_DFV")
#
# Dynamically generate target files
cd "$DATA" || { echo "Failed to change directory to $DATA"; exit 1; }
#
for file_in in ${File_to_modify_source}; do
  cp "$HOMEaqm/parm/config/${file_in}.template" .
  file_src="${file_in}.template"
  file_tmp=$(mktemp -p .) || { echo "Failed to create temporary file"; exit 1; }
  cp "$file_src" "$file_tmp" || { echo "Failed to copy $file_src to $file_tmp"; exit 1; }
  sed -i -e "s|@HOMEaqm@|${HOMEaqm}|g"             "$file_tmp"
  sed -i -e "s|@COMaqm@|${COMaqm}|g"               "$file_tmp"
  sed -i -e "s|@WARMSTART_PDY@|${WARMSTART_PDY}|g" "$file_tmp"
  sed -i -e "s|@OPSROOT@|${OPSROOT}|g"             "$file_tmp"
  sed -i -e "s|@COMINgefs@|${COMINgefs}|g"         "$file_tmp"
  sed -i -e "s|@DCOMROOT@|${DCOMROOT}|g"         "$file_tmp"
  sed -i -e "s|@DATA@|${DATA}|g"                   "$file_tmp"
  sed -i -e "s|@MODEL_VER_DFV@|${MODEL_VER_DFV}|g"                   "$file_tmp"
#
  mv "$file_tmp" "$file_in" || { echo "Failed to move $file_tmp to $file_in"; exit 1; }
done
. $DATA/var_defns.sh 
