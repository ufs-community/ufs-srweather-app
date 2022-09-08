#!/bin/sh

# Stand-alone script to run grid-to-point ensemble verification
export GLOBAL_VAR_DEFNS_FP="${EXPTDIR}/var_defns.sh"
set -x
source ${GLOBAL_VAR_DEFNS_FP}
export CDATE=${DATE_FIRST_CYCL}${CYCL_HRS}
export CYCLE_DIR=${EXPTDIR}/${CDATE}
export cyc=${CYCL_HRS}
export PDY=${DATE_FIRST_CYCL}
export OBS_DIR=${NDAS_OBS_DIR}

export FHR=`echo $(seq 0 1 ${FCST_LEN_HRS})`

${JOBSDIR}/JREGIONAL_RUN_VX_ENSPOINT

${JOBSDIR}/JREGIONAL_RUN_VX_ENSPOINT_MEAN

${JOBSDIR}/JREGIONAL_RUN_VX_ENSPOINT_PROB

