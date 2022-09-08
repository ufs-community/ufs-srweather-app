#!/bin/sh
export GLOBAL_VAR_DEFNS_FP="${EXPTDIR}/var_defns.sh"
set -x
source ${GLOBAL_VAR_DEFNS_FP}
export CDATE=${DATE_FIRST_CYCL}${CYCL_HRS}
export CYCLE_DIR=${EXPTDIR}/${CDATE}
export cyc=${CYCL_HRS}
export SLASH_ENSMEM_SUBDIR=""
export ENSMEM_INDX=""

num_fcst_hrs=${FCST_LEN_HRS}
for (( i=0; i<=$((num_fcst_hrs)); i++ )); do
  export fhr=`printf "%03i" ${i}`
  ${JOBSDIR}/JREGIONAL_RUN_POST
done
