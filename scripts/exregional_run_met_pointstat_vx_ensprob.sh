#!/bin/bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. $USHdir/source_util_funcs.sh
source_config_for_task "task_run_vx_enspoint_prob|task_run_post" ${GLOBAL_VAR_DEFNS_FP}
#
#-----------------------------------------------------------------------
#
# Source files defining auxiliary functions for verification.
#
#-----------------------------------------------------------------------
#
. $USHdir/set_vx_params.sh
. $USHdir/set_vx_fhr_list.sh
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

#
#-----------------------------------------------------------------------
#
# Begin grid-to-point vx on ensemble output.
#
#-----------------------------------------------------------------------
#
print_info_msg "$VERBOSE" "Starting point-stat verification"

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
#
#-----------------------------------------------------------------------
#
# Pick a directory structure for METplus output files
#
#-----------------------------------------------------------------------
#
if [ $RUN_ENVIR = "nco" ]; then
    export INPUT_BASE=$COMOUT/metout/${CDATE}/metprd/EnsembleStat
    export OUTPUT_BASE=$COMOUT/metout
    export MEM_BASE=$OUTPUT_BASE
    export LOG_DIR=$LOGDIR

    export POSTPRD=
    export MEM_STAR=
    export MEM_CUSTOM=
    export DOT_MEM_CUSTOM=".{custom?fmt=%s}"
else
    export INPUT_BASE=${EXPTDIR}/${CDATE}/metprd/EnsembleStat
    export OUTPUT_BASE=$EXPTDIR
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
LOG_SUFFIX="PointStat"

#
#-----------------------------------------------------------------------
#
# Set the array of forecast hours for which to run the MET/METplus tool.
#
#-----------------------------------------------------------------------
#
export OBS_INPUT_DIR="${VX_OUTPUT_BASEDIR}/metprd/Pb2nc_obs"
OBS_INPUT_FN_TEMPLATE=$( eval echo ${OBS_NDAS_SFCorUPA_FN_METPROC_TEMPLATE} )

set_vx_fhr_list \
  cdate="${CDATE}" \
  fcst_len_hrs="${FCST_LEN_HRS}" \
  field="$VAR" \
  accum_hh="${ACCUM_HH}" \
  base_dir="${OBS_INPUT_DIR}" \
  fn_template="${OBS_INPUT_FN_TEMPLATE}" \
  check_hourly_files="FALSE" \
  outvarname_fhr_list="FHR_LIST"
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
export FHR_LIST

${METPLUS_PATH}/ush/run_metplus.py \
  -c ${METPLUS_CONF}/common.conf \
  -c ${METPLUS_CONF}/PointStat_ensprob_${VAR}.conf
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
