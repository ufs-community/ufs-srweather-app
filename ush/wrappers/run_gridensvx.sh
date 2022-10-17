#!/bin/sh

# Stand-alone script to run grid-to-grid ensemble verification
export GLOBAL_VAR_DEFNS_FP="${EXPTDIR}/var_defns.sh"
set -x
source ${GLOBAL_VAR_DEFNS_FP}
export CDATE=${DATE_FIRST_CYCL}
export CYCLE_DIR=${EXPTDIR}/${CDATE}
export cyc=${DATE_FIRST_CYCL:8:2}
export PDY=${DATE_FIRST_CYCL}
export OBS_DIR=${MRMS_OBS_DIR} # CCPA_OBS_DIR MRMS_OBS_DIR
export VAR="REFC" # APCP REFC RETOP
export ACCUM="" # 01 03 06 24 --> leave empty for REFC and RETOP

export FHR=`echo $(seq 0 ${ACCUM} ${FCST_LEN_HRS}) | cut -d" " -f2-`

${JOBSdir}/JREGIONAL_RUN_VX_ENSGRID

${JOBSdir}/JREGIONAL_RUN_VX_ENSGRID_MEAN

${JOBSdir}/JREGIONAL_RUN_VX_ENSGRID_PROB

