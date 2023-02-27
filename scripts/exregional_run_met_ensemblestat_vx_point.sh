#!/bin/bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. $USHdir/source_util_funcs.sh
source_config_for_task "task_run_vx_enspoint|task_run_post" ${GLOBAL_VAR_DEFNS_FP}
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

This is the ex-script for the task that runs METplus for point-stat on
the UPP output files by initialization time for all forecast hours.
========================================================================"

#-----------------------------------------------------------------------
#
# Begin grid-to-point ensemble vx.
#
#-----------------------------------------------------------------------
#
print_info_msg "$VERBOSE" "Starting point-based ensemble-stat verification"

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
    export INPUT_BASE=${VX_FCST_INPUT_BASEDIR}                           
    export OUTPUT_BASE=$EXPTDIR
    export MEM_BASE=$EXPTDIR/$CDATE
    export LOG_DIR=${EXPTDIR}/log

    export POSTPRD="postprd/"
    export MEM_STAR="mem*/"
    export MEM_CUSTOM="{custom?fmt=%s}/"
    export DOT_MEM_CUSTOM=
#
# Construct variable that contains a METplus template of the paths to
# the forecast files that are inputs to the EnsembleStat tool.  This
# variable will be exported to the environment and read by the METplus
# configuration files.
#
    NDIGITS_ENSMEM_NAMES=3
    time_lag=0

    FCST_INPUT_FN_TEMPLATE=""
    for (( i=0; i<${NUM_ENS_MEMBERS}; i++ )); do

      mem_indx=$(($i+1))
      mem_indx_fmt=$(printf "%0${NDIGITS_ENSMEM_NAMES}d" "${mem_indx}")
#      time_lag=$(( ${ENS_TIME_LAG_HRS[$i]}*${secs_per_hour} ))

      SLASH_ENSMEM_SUBDIR_OR_NULL="/mem${mem_indx_fmt}"
      template="${CDATE}${SLASH_ENSMEM_SUBDIR_OR_NULL}/postprd/${FCST_FN_TEMPLATE}"

      if [ -z "${FCST_INPUT_FN_TEMPLATE}" ]; then
        FCST_INPUT_FN_TEMPLATE="  $(eval echo ${template})"
      else
        FCST_INPUT_FN_TEMPLATE="\
${FCST_INPUT_FN_TEMPLATE},
  $(eval echo ${template})"
      fi

    done

fi
export DOT_ENSMEM=${dot_ensmem}

#
#-----------------------------------------------------------------------
#
# Create LOG_SUFFIX to read into METplus conf files.
#
#-----------------------------------------------------------------------
#
LOG_SUFFIX="EnsembleStat"

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
fi

#
#-----------------------------------------------------------------------
#
# Export some environment variables passed in by the XML and run METplus
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
export NUM_ENS_MEMBERS
export FCST_INPUT_FN_TEMPLATE

${METPLUS_PATH}/ush/run_metplus.py \
  -c ${METPLUS_CONF}/common.conf \
  -c ${METPLUS_CONF}/EnsembleStat_SFC.conf

${METPLUS_PATH}/ush/run_metplus.py \
  -c ${METPLUS_CONF}/common.conf \
  -c ${METPLUS_CONF}/EnsembleStat_UPA.conf

#
#-----------------------------------------------------------------------
#
# Print message indicating successful completion of script.
#
#-----------------------------------------------------------------------
#
print_info_msg "
========================================================================
METplus ensemble-stat completed successfully.

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
