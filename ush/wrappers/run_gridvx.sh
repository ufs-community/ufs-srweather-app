#!/bin/sh

# Stand-alone script to run grid-to-grid verification
export GLOBAL_VAR_DEFNS_FP="${EXPTDIR}/var_defns.sh"
set -x
source ${GLOBAL_VAR_DEFNS_FP}
export CDATE=${DATE_FIRST_CYCL}${CYCL_HRS}
export CYCLE_DIR=${EXPTDIR}/${CDATE}
export cyc=${CYCL_HRS}
export PDY=${DATE_FIRST_CYCL}
export SLASH_ENSMEM_SUBDIR="" # When running with do_ensemble = true, need to run for each member, e.g., "/mem1"
export OBS_DIR=${CCPA_OBS_DIR} # CCPA_OBS_DIR MRMS_OBS_DIR
export VAR="APCP" # APCP REFC RETOP
export ACCUM="06" # 01 03 06 24 --> leave empty for REFC and RETOP

export FHR=`echo $(seq 0 ${ACCUM} ${FCST_LEN_HRS}) | cut -d" " -f2-`

${JOBSDIR}/JREGIONAL_RUN_VX_GRIDSTAT

