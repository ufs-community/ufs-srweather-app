#!/bin/bash
set -x

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. ${GLOBAL_VAR_DEFNS_FP}
. $USHDIR/source_util_funcs.sh
#
#-----------------------------------------------------------------------
#
# Save current shell options (in a global array).  Then set new options
# for this script/function.
#
#-----------------------------------------------------------------------
#
{ save_shell_opts; set -u +x; } > /dev/null 2>&1
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

This is the ex-script for the task that runs METplus for ensemble-stat on
the UPP output files by initialization time for all forecast hours for 
gridded data.
========================================================================"

#
#-----------------------------------------------------------------------
#
# Specify the set of valid argument names for this script/function.  
# Then process the arguments provided to this script/function (which 
# should consist of a set of name-value pairs of the form arg1="value1",
# etc).
#
#-----------------------------------------------------------------------
#
valid_args=( "cycle_dir" )
process_args valid_args "$@"
#
#-----------------------------------------------------------------------
#
# For debugging purposes, print out values of arguments passed to this
# script.  Note that these will be printed out only if VERBOSE is set to
# TRUE.
#
#-----------------------------------------------------------------------
#
print_input_args valid_args

#-----------------------------------------------------------------------
#
# Begin grid-to-grid ensemble vx.
#
#-----------------------------------------------------------------------
#
print_info_msg "$VERBOSE" "Starting ensemble-stat verification"

#
#-----------------------------------------------------------------------
#
# Get the cycle date and hour (in formats of yyyymmdd and hh, respect-
# ively) from CDATE. Read in FHR and create a comma-separated list
# for METplus to run over. Determine the number padding needed based
# on number of ensemble members.
#
#-----------------------------------------------------------------------
#
yyyymmdd=${CDATE:0:8}
hh=${CDATE:8:2}
cyc=$hh
export CDATE
export hh

fhr_last=`echo ${FHR}  | awk '{ print $NF }'`
export fhr_last

fhr_list=`echo ${FHR} | $SED "s/ /,/g"`
export fhr_list

NUM_PAD=${NDIGITS_ENSMEM_NAMES}

#
#-----------------------------------------------------------------------
#
# Create LOG_SUFFIX to read into METplus conf files.
#
#-----------------------------------------------------------------------
#

if [ ${VAR} == "APCP" ]; then
  LOG_SUFFIX=ensgrid_${CDATE}_${VAR}_${ACCUM}h
else
  LOG_SUFFIX=ensgrid_${CDATE}_${VAR}
fi

#
#-----------------------------------------------------------------------
#
# Make sure directories in which output files will be placed exist.
#
#-----------------------------------------------------------------------
#
mkdir_vrfy -p "${EXPTDIR}/${CDATE}/metprd/ensemble_stat"  # Output directory for ensemble_stat tool.

#
# If the variable is accumulated precipitation for a time interval 
# (bucket) other than 1 hour, the MET/METplus tools called below will
# include pcp_combine.  In that case, create (if necessary) directories
# needed by pcp_combine.
#
if [ "${VAR}" = "APCP" ] && [ "${ACCUM: -1}" != "1" ]; then
  mkdir_vrfy -p "${EXPTDIR}/metprd/pcp_combine"           # For observations
  mkdir_vrfy -p "${EXPTDIR}/${CDATE}/metprd/pcp_combine"  # For forecast
fi

#
#-----------------------------------------------------------------------
#
# Export some environment variables passed in by the XML 
#
#-----------------------------------------------------------------------
#
export SCRIPTSDIR
export EXPTDIR
export MET_INSTALL_DIR
export MET_BIN_EXEC
export METPLUS_PATH
export METPLUS_CONF
export MET_CONFIG
export MODEL
export NET
export POST_OUTPUT_DOMAIN_NAME
export NUM_ENS_MEMBERS 
export NUM_PAD
export LOG_SUFFIX

#
#-----------------------------------------------------------------------
#
# Run METplus 
#
#-----------------------------------------------------------------------
#
if [ ${VAR} == "APCP" ]; then
  acc="${ACCUM}h" # for stats output prefix in EnsembleStatConfig
  ${METPLUS_PATH}/ush/run_metplus.py \
    -c ${METPLUS_CONF}/common.conf \
    -c ${METPLUS_CONF}/EnsembleStat_${VAR}${acc}.conf
else
  ${METPLUS_PATH}/ush/run_metplus.py \
    -c ${METPLUS_CONF}/common.conf \
    -c ${METPLUS_CONF}/EnsembleStat_${VAR}.conf
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
METplus ensemble-stat grid completed successfully.

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
