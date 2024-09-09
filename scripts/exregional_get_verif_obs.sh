#!/usr/bin/env bash

#
#-----------------------------------------------------------------------
#
# The ex-script that checks, pulls, and stages observation data for
# model verification.
#
# Run-time environment variables:
#
#    FHR
#    GLOBAL_VAR_DEFNS_FP
#    OBS_DIR
#    OBTYPE
#    PDY
#    VAR
#
# Experiment variables
#
#   user:
#    USHdir
#    PARMdir
#
#-----------------------------------------------------------------------

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. $USHdir/source_util_funcs.sh
for sect in user workflow nco ; do
  source_yaml ${GLOBAL_VAR_DEFNS_FP} ${sect}
done
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
# This script performs several important tasks for preparing data for
# verification tasks. Depending on the value of the environment variable
# OBTYPE=(CCPA|MRMS|NDAS|NOHRSC), the script will prepare that particular data
# set.
#
# If data is not available on disk (in the location specified by
# CCPA_OBS_DIR, MRMS_OBS_DIR, NDAS_OBS_DIR, or NOHRSC_OBS_DIR respectively),
# the script attempts to retrieve the data from HPSS using the retrieve_data.py
# script. Depending on the data set, there are a few strange quirks and/or
# bugs in the way data is organized; see in-line comments for details.
#
#
# CCPA (Climatology-Calibrated Precipitation Analysis) precipitation accumulation obs
# ----------
# If data is available on disk, it must be in the following
# directory structure and file name conventions expected by verification
# tasks:
#
# {CCPA_OBS_DIR}/{YYYYMMDD}/ccpa.t{HH}z.01h.hrap.conus.gb2
#
# If data is retrieved from HPSS, it will be automatically staged by this
# script.
#
# Notes about the data and how it's used for verification:
#
# 1. Accumulation is currently hardcoded to 01h. The verification will
# use MET/pcp-combine to sum 01h files into desired accumulations.
#
# 2. There is a problem with the valid time in the metadata for files
# valid from 19 - 00 UTC (or files under the '00' directory). This is
# accounted for in this script for data retrieved from HPSS, but if you
# have manually staged data on disk you should be sure this is accounted
# for. See in-line comments below for details.
#
#
# MRMS (Multi-Radar Multi-Sensor) radar observations
# ----------
# If data is available on disk, it must be in the following
# directory structure and file name conventions expected by verification
# tasks:
#
# {MRMS_OBS_DIR}/{YYYYMMDD}/[PREFIX]{YYYYMMDD}-{HH}0000.grib2,
#
# Where [PREFIX] is MergedReflectivityQCComposite_00.50_ for reflectivity
# data and EchoTop_18_00.50_ for echo top data. If data is not available
# at the top of the hour, you should rename the file closest in time to
# your hour(s) of interest to the above naming format. A script
# "ush/mrms_pull_topofhour.py" is provided for this purpose.
#
# If data is retrieved from HPSS, it will automatically staged by this
# this script.
#
#
# NDAS (NAM Data Assimilation System) conventional observations
# ----------
# If data is available on disk, it must be in the following
# directory structure and file name conventions expected by verification
# tasks:
#
# {NDAS_OBS_DIR}/{YYYYMMDD}/prepbufr.ndas.{YYYYMMDDHH}
#
# Note that data retrieved from HPSS and other sources may be in a
# different format: nam.t{hh}z.prepbufr.tm{prevhour}.nr, where hh is
# either 00, 06, 12, or 18, and prevhour is the number of hours prior to
# hh (00 through 05). If using custom staged data, you will have to
# rename the files accordingly.
#
# If data is retrieved from HPSS, it will be automatically staged by this
# this script.
#
#
# NOHRSC  snow accumulation observations
# ----------
# If data is available on disk, it must be in the following
# directory structure and file name conventions expected by verification
# tasks:
#
# {NOHRSC_OBS_DIR}/{YYYYMMDD}/sfav2_CONUS_{AA}h_{YYYYMMDD}{HH}_grid184.grb2
#
# where AA is the 2-digit accumulation duration in hours: 06 or 24
#
# METplus is configured to verify snowfall using 06- and 24-h accumulated
# snowfall from 6- and 12-hourly NOHRSC files, respectively.
#
# If data is retrieved from HPSS, it will automatically staged by this
# this script.
#
#-----------------------------------------------------------------------
#
if [[ ${OBTYPE} == "CCPA" ]]; then
  $USHdir/get_obs_ccpa.sh
elif [[ ${OBTYPE} == "MRMS" ]]; then
  $USHdir/get_obs_mrms.sh
elif [[ ${OBTYPE} == "NDAS" ]]; then
  $USHdir/get_obs_ndas.sh
elif [[ ${OBTYPE} == "NOHRSC" ]]; then
  $USHdir/get_obs_nohrsc.sh
else
  print_err_msg_exit "\
Invalid OBTYPE specified for script:
  OBTYPE = \"${OBTYPE}\"
Valid options are CCPA, MRMS, NDAS, and NOHRSC.
"
fi
#
#-----------------------------------------------------------------------
#
# Create flag file that indicates completion of task.  This is needed by
# the workflow.
#
#-----------------------------------------------------------------------
#
obtype=$(echo_lowercase ${OBTYPE})
mkdir -p ${WFLOW_FLAG_FILES_DIR}
touch "${WFLOW_FLAG_FILES_DIR}/get_obs_${obtype}_${PDY}_complete.txt"
#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script/func-
# tion.
#
#-----------------------------------------------------------------------
#
{ restore_shell_opts; } > /dev/null 2>&1

