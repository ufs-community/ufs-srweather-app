#!/usr/bin/env bash
export GLOBAL_VAR_DEFNS_FP="${EXPTDIR}/var_defns.yaml"
. $USHdir/source_util_funcs.sh
for sect in workflow task_get_extrn_ics ; do
  source_yaml ${GLOBAL_VAR_DEFNS_FP} ${sect}
done
set -xa
export CDATE=${DATE_FIRST_CYCL}
export CYCLE_DIR=${EXPTDIR}/${CDATE}
export cyc=${DATE_FIRST_CYCL:8:2}
export PDY=${DATE_FIRST_CYCL:0:8}

# get the ICS files
export ICS_OR_LBCS="ICS"
export EXTRN_MDL_NAME=${EXTRN_MDL_NAME_ICS}
${JOBSdir}/JREGIONAL_GET_EXTRN_MDL_FILES

