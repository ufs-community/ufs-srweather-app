#!/usr/bin/env bash
export GLOBAL_VAR_DEFNS_FP="${EXPTDIR}/var_defns.yaml"
. $USHdir/source_util_funcs.sh
for sect in workflow ; do
  source_yaml ${GLOBAL_VAR_DEFNS_FP} ${sect}
done
set -xa
export CDATE=${DATE_FIRST_CYCL}
export CYCLE_DIR=${EXPTDIR}/${CDATE}
export cyc=${DATE_FIRST_CYCL:8:2}
export PDY=${DATE_FIRST_CYCL:0:8}
export SLASH_ENSMEM_SUBDIR=""
export NWGES_DIR=${NWGES_BASEDIR}/${DATE_FIRST_CYCL:0:8}
# Declare Intel library variable for Azure
if [ ${PW_CSP} == "azure" ]; then
    export FI_PROVIDER=tcp
fi

${JOBSdir}/JREGIONAL_MAKE_ICS

