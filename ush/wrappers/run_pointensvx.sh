#!/bin/sh

# Stand-alone script to run grid-to-point ensemble verification
export GLOBAL_VAR_DEFNS_FP="${EXPTDIR}/var_defns.sh"
set -x
source ${GLOBAL_VAR_DEFNS_FP}
export CDATE=${DATE_FIRST_CYCL}
export CYCLE_DIR=${EXPTDIR}/${CDATE}
export cyc=${DATE_FIRST_CYCL:8:2}
export PDY=${DATE_FIRST_CYCL}
export OBS_DIR=${NDAS_OBS_DIR}

export FHR=`echo $(seq 0 1 ${FCST_LEN_HRS})`

${JOBSdir}/JREGIONAL_RUN_VX_ENSPOINT

${JOBSdir}/JREGIONAL_RUN_VX_ENSPOINT_MEAN

${JOBSdir}/JREGIONAL_RUN_VX_ENSPOINT_PROB

