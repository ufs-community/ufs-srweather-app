#!/bin/bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. $USHdir/source_util_funcs.sh
source_config_for_task "task_run_vx_gridstat|task_run_post" ${GLOBAL_VAR_DEFNS_FP}
#
#-----------------------------------------------------------------------
#
# Save current shell options (in a global array).  Then set new options
# for this script/function.
#
#-----------------------------------------------------------------------
#
{ save_shell_opts; . $USHdir/preamble.sh; } > /dev/null 2>&1
#
#-----------------------------------------------------------------------
#
# Get the full path to the file in which this script/function is located 
# (scrfunc_fp), the name of that file (scrfunc_fn), and the directory in
# which the file is located (scrfunc_dir).
#
#-----------------------------------------------------------------------
#
scrfunc_fp=$( $READLINK -f "${BASH_SOURCE[0]}" )
scrfunc_fn=$( basename "${scrfunc_fp}" )
scrfunc_dir=$( dirname "${scrfunc_fp}" )
#
#-----------------------------------------------------------------------
#
# Print message indicating entry into script.
#
#-----------------------------------------------------------------------
#
print_info_msg "
========================================================================
Entering script:  \"${scrfunc_fn}\"
In directory:     \"${scrfunc_dir}\"

This is the ex-script for the task that runs METplus for grid-stat on
the UPP output files by initialization time for all forecast hours.
========================================================================"

#
#-----------------------------------------------------------------------
#
# Get the cycle date and hour (in formats of yyyymmdd and hh, respect-
# ively) from CDATE. Also read in FHR and create a comma-separated list
# for METplus to run over.
#
#-----------------------------------------------------------------------
#
yyyymmdd=${PDY}
hh=${cyc}
export CDATE
export hh

fhr_last=`echo ${FHR}  | awk '{ print $NF }'`
export fhr_last

fhr_list=`echo ${FHR} | $SED "s/ /,/g"`
export fhr_list

#
#-----------------------------------------------------------------------
#
# Pick a directory structure for METplus output files
#
#-----------------------------------------------------------------------
#
if [ $RUN_ENVIR = "nco" ]; then
    export INPUT_BASE=$COMIN
    export OUTPUT_BASE=$COMOUT/metout
    export MEM_BASE=$OUTPUT_BASE
    export LOG_DIR=$LOGDIR

    export POSTPRD=
    export MEM_STAR=
    export MEM_CUSTOM=
    export DOT_MEM_CUSTOM=".{custom?fmt=%s}"
else
    if [[ ${DO_ENSEMBLE} == "FALSE" ]]; then
      export INPUT_BASE=${VX_FCST_INPUT_BASEDIR}/${CDATE}/postprd
      export OUTPUT_BASE=${EXPTDIR}/${CDATE}
    else
      export INPUT_BASE=${VX_FCST_INPUT_BASEDIR}/${CDATE}${SLASH_ENSMEM_SUBDIR}/postprd
      export OUTPUT_BASE=${EXPTDIR}/${CDATE}${SLASH_ENSMEM_SUBDIR}
    fi
    export MEM_BASE=$EXPTDIR/$CDATE
    export LOG_DIR=${EXPTDIR}/log

    export POSTPRD="postprd/"
    export MEM_STAR="mem*/"
    export MEM_CUSTOM="{custom?fmt=%s}/"
    export DOT_MEM_CUSTOM=
fi
export DOT_ENSMEM=${dot_ensmem}

#
#-----------------------------------------------------------------------
#
# Create INPUT_BASE and LOG_SUFFIX to read into METplus conf files.
#
#-----------------------------------------------------------------------
#
if [ ${VAR} == "APCP" ]; then
  LOG_SUFFIX=GridStat_${VAR}${ACCUM}h${USCORE_ENSMEM_NAME_OR_NULL}_${CDATE}
else
  LOG_SUFFIX=GridStat_${VAR}${USCORE_ENSMEM_NAME_OR_NULL}_${CDATE}
fi

if [[ ${DO_ENSEMBLE} == "TRUE" ]]; then
  ENSMEM=`echo ${SLASH_ENSMEM_SUBDIR} | cut -d"/" -f2`
  VX_FCST_MODEL_NAME=${VX_FCST_MODEL_NAME}_${ENSMEM}
fi

#
#-----------------------------------------------------------------------
#
# Check for existence of top-level OBS_DIR 
#
#-----------------------------------------------------------------------
#
if [[ ! -d "$OBS_DIR" ]]; then
  print_err_msg_exit "\
  Exiting: OBS_DIR does not exist."
  exit
fi

#
#-----------------------------------------------------------------------
#
# Export some environment variables passed in by the XML 
#
#-----------------------------------------------------------------------
#
export LOG_SUFFIX
export MET_INSTALL_DIR
export MET_BIN_EXEC
export METPLUS_PATH
export METPLUS_CONF
export MET_CONFIG
export VX_FCST_MODEL_NAME
export NET
export POST_OUTPUT_DOMAIN_NAME

#
#-----------------------------------------------------------------------
#
# Run METplus 
#
#-----------------------------------------------------------------------
#
if [ ${VAR} == "APCP" ]; then
  export acc="${ACCUM}h" # for stats output prefix in GridStatConfig
  ${METPLUS_PATH}/ush/run_metplus.py \
    -c ${METPLUS_CONF}/common.conf \
    -c ${METPLUS_CONF}/GridStat_${VAR}${acc}.conf
else
  ${METPLUS_PATH}/ush/run_metplus.py \
    -c ${METPLUS_CONF}/common.conf \
    -c ${METPLUS_CONF}/GridStat_${VAR}.conf
fi

#
#-----------------------------------------------------------------------
#
# Print message indicating successful completion of script.
#
#-----------------------------------------------------------------------
#
print_info_msg "
========================================================================
METplus grid-stat completed successfully.

Exiting script:  \"${scrfunc_fn}\"
In directory:    \"${scrfunc_dir}\"
========================================================================"
#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script/func-
# tion.
#
#-----------------------------------------------------------------------
#
{ restore_shell_opts; } > /dev/null 2>&1
