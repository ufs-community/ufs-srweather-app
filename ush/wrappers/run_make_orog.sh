#!/usr/bin/env bash
export GLOBAL_VAR_DEFNS_FP="${EXPTDIR}/var_defns.yaml"
. $USHdir/source_util_funcs.sh
for sect in workflow ; do
  source_yaml ${GLOBAL_VAR_DEFNS_FP} ${sect}
done
set -xa

export CDATE=${DATE_FIRST_CYCL}
export CYCLE_DIR=${EXPTDIR}/${CDATE}
${JOBSdir}/JREGIONAL_MAKE_OROG
