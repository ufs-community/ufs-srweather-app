#!/bin/sh

# Stand-alone script to run grid-to-point verification
export GLOBAL_VAR_DEFNS_FP="${EXPTDIR}/var_defns.sh"
set -x
source ${GLOBAL_VAR_DEFNS_FP}
export CDATE=${DATE_FIRST_CYCL}${CYCL_HRS}
export CYCLE_DIR=${EXPTDIR}/${CDATE}
export cyc=${CYCL_HRS}
export PDY=${DATE_FIRST_CYCL}
export SLASH_ENSMEM_SUBDIR="" # When running with do_ensemble = true, need to run for each member, e.g., "/mem1"
export OBS_DIR=${NDAS_OBS_DIR}

export FHR=`echo $(seq 0 1 ${FCST_LEN_HRS})`

${JOBSDIR}/JREGIONAL_RUN_VX_POINTSTAT

