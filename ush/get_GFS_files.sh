#!/bin/sh -l

#
#----THEIA JOBCARD
#
# Note that the following PBS directives do not have any effect if this
# script is called via an interactive TORQUE/PBS job (i.e. using the -I
# flag to qsub along with the -x flag to specify this script).  The fol-
# lowing directives are placed here in case this script is called as a
# batch (i.e. non-interactive) job.
#
#PBS -N get_GFS_anl_fcst_files_rgnl
#PBS -A gsd-fv3
#PBS -o out.$PBS_JOBNAME.$PBS_JOBID
#PBS -e err.$PBS_JOBNAME.$PBS_JOBID
#PBS -l nodes=1:ppn=1
#PBS -q service              # The HPSS is accessible only through the service queue (i.e. not the debug or batch queues).
#PBS -l walltime=0:30:00
#PBS -W umask=022
#


#
#-----------------------------------------------------------------------
#
# This script gets (either from disk or from the mass store, aka HPSS)
# the necessary GFS analysis and forecast files (which are in nemsio
# format) needed to generate NetCDF files containing the initial atmo-
# spheric fields, the surface fields, and the boundary conditions that
# are needed to run a forecast with the FV3SAR.  It places these files
# in a directory specified by EXTRN_MDL_FILES_DIR.
#
#-----------------------------------------------------------------------
#

#
#-----------------------------------------------------------------------
#
# Source the variable definitions script.                                                                                                         
#
#-----------------------------------------------------------------------
#
. $SCRIPT_VAR_DEFNS_FP
#
#-----------------------------------------------------------------------
#
# Source function definition files.
#
#-----------------------------------------------------------------------
#
. $USHDIR/source_funcs.sh
#
#-----------------------------------------------------------------------
#
# Save current shell options (in a global array).  Then set new options
# for this script/function.
#
#-----------------------------------------------------------------------
#
{ save_shell_opts; set -u -x; } > /dev/null 2>&1
#
#-----------------------------------------------------------------------
#
# This comment block needs to be updated.
#
# Create the directory EXTRN_MDL_FILES_BASEDIR if it doesn't already ex-
# ist.  This is the directory in which we will create subdirectories for
# each forecast (i.e. for each CDATE) in which to store the analysis and
# forecast files from the specified external model.  The analysis filesi
# are valid at at the initial time specified in CDATE and consist of the
# atmospheric analysis file, the surface analysis file, and the near-
# surface temperature analysis file.  The forecast files are needed at
# each boundary update time (except at the initial time since that is in
# the atmospheric analysis file).  
#
#-----------------------------------------------------------------------
#
mkdir_vrfy -p "$EXTRN_MDL_FILES_BASEDIR"
#
#-----------------------------------------------------------------------
#
# Create the directory specific to the current forecast (whose starting
# date and time is specified in CDATE) in which to store the GFS analy-
# sis and forecast files.  Then change location to that directory.
#
#-----------------------------------------------------------------------
#
EXTRN_MDL_FILES_DIR="$EXTRN_MDL_FILES_BASEDIR/$CDATE"
mkdir_vrfy -p "$EXTRN_MDL_FILES_DIR"
cd_vrfy $EXTRN_MDL_FILES_DIR || print_err_msg_exit "\
Could not change directory to EXTRN_MDL_FILES_DIR:
  EXTRN_MDL_FILES_DIR = \"$EXTRN_MDL_FILES_DIR\""
#
#-----------------------------------------------------------------------
#
# Extract from CDATE the starting year, month, day, and hour of the
# forecast.  These are needed below for various operations.
#
#-----------------------------------------------------------------------
#
YYYY=${CDATE:0:4}
MM=${CDATE:4:2}
DD=${CDATE:6:2}
HH=${CDATE:8:2}
YYYYMMDD=${CDATE:0:8}
#
#-----------------------------------------------------------------------
#
# Set the directory on mass store (HPSS) in which the archived (tar)
# files from which we may need to extract the necessary files are loca-
# ted.  Also, set a prefix that appears in the names of these tar files.
#
#-----------------------------------------------------------------------
#
HPSS_DIR="/NCEPPROD/hpssprod/runhistory/rh${YYYY}/${YYYY}${MM}/${YYYYMMDD}"
prefix_tar_files="gpfs_hps_nco_ops_com_gfs_prod_gfs"
#
#-----------------------------------------------------------------------
#
# Set the system directory (i.e. location on disk, not on HPSS) in which
# all analysis and forecast files needed to generate the input files for
# FV3SAR may be found (if CDATE isn't too long ago).  On theia, these
# directories contain the needed files for the past two days (today and
# yesterday, or yesterday and the day before), while on WCOSS they con-
# tain the needed files for the past two weeks.
#
# If the starting date of the forecast (CDATE) is within this time win-
# dow (i.e. two days on theia and two weeks on WCOSS), the needed files
# may simply be copied over from these system directories to EXTRN_MDL_FILES_DIR.  If
# CDATE is a time that is outside (i.e. older than) this time window,
# then the needed files must be obtained from the mass store (HPSS) and
# placed into EXTRN_MDL_FILES_DIR.
#
#-----------------------------------------------------------------------
#
case $MACHINE in
#
"WCOSS_C")
#
  export INIDIR_SYS="/gpfs/hps/nco/ops/com/gfs/prod/gfs.$YYYYMMDD"
  ;;
#
"WCOSS")
#
  export INIDIR_SYS=""  # Not sure how these should be set on WCOSS.
  ;;
#
"THEIA")
#
  export INIDIR_SYS="/scratch4/NCEPDEV/rstprod/com/gfs/prod/gfs.$YYYYMMDD"
  ;;
#
"JET")
#
  export INIDIR_SYS="/lfs3/projects/hpc-wof1/ywang/regional_fv3/gfs/$YYYYMMDD"
  ;;
#
"ODIN")
#
  export INIDIR_SYS="/scratch/ywang/test_runs/FV3_regional/gfs/$YYYYMMDD"
  ;;
#
esac
#
#-----------------------------------------------------------------------
#
# First, obtain (i.e. place into EXTRN_MDL_FILES_DIR) the analysis files needed to
# run a forecast with the FV3SAR.  These files are needed in order to
# generate the initial condition (IC), surface, and 0th hour boundary
# condtion (BC) files (in NetCDF format) that are inputs to the FV3SAR.
#
#-----------------------------------------------------------------------
#
# Set a convenience variable indicating whether we are considering ana-
# lysis or forecast files.
#
anl_or_fcst="analysis"
#
# Set the names of the analysis files needed to generate the IC and the
# first (i.e. 0th forecast hour) BC NetCDF files.
#
temp="gfs.t${HH}z."
# For now, don't get analysis file for near-surface temperature.
#anl_files=( ${temp}atmanl.nemsio ${temp}nstanl.nemsio ${temp}sfcanl.nemsio )
anl_files=( ${temp}atmanl.nemsio ${temp}sfcanl.nemsio )
#
# Set the number of needed analysis files.
#
num_files_needed="${#anl_files[@]}"
#
# Set the name of the tar file in HPSS that is supposed to contain the
# needed analysis files.  This file will only be needed if the analysis
# files cannot be found on disk.
#
ANL_TAR_FILE="${prefix_tar_files}.${CDATE}.anl.tar"
#
# Set the name of the directory within the tar in which the needed ana-
# lysis files should be located.  This will only be used if the analysis
# files aren't already available on disk.
#
ARCHIVE_DIR="."
#
# Set variables containing the analysis file names (including paths)
# that can be used below to either copy the analysis files from INIDIR_-
# SYS or to extract them from a tar file in HPSS.
#
files_to_copy=""
files_to_extract=""
for anl_file in "${anl_files[@]}"; do
  files_to_copy="${files_to_copy} $INIDIR_SYS/$anl_file"
  files_to_extract="${files_to_extract} $ARCHIVE_DIR/$anl_file"
done
#
#-----------------------------------------------------------------------
#
# We first need to check whether the needed analysis files all exist in
# the system directory INIDIR_SYS specified above.  We perform this
# check by counting the number of needed analysis files that actually
# exist in INIDIR_SYS (num_files_found).  If that number is equal to the
# number of needed analysis files (num_files_needed), it means all the
# needed analysis files exist in INIDIR_SYS.  In this case, we will sim-
# ply copy them from INIDIR_SYS to EXTRN_MDL_FILES_DIR.  If the number of files found
# is not equal to the number needed, then all the needed analysis files
# are not in INIDIR_SYS.  In this case, we will have to get them from
# HPSS and place them in EXTRN_MDL_FILES_DIR.
#
#-----------------------------------------------------------------------
#
num_files_found=0
for f in $files_to_copy; do
  if [ -f "$f" ]; then
    num_files_found=$(( $num_files_found + 1 ))
  fi
done
#
#-----------------------------------------------------------------------
#
# Check whether the needed analysis files all exist in the system di-
# rectory INIDIR_SYS.  If so, copy them over to EXTRN_MDL_FILES_DIR.
#
#-----------------------------------------------------------------------
#
if [ "$num_files_found" -eq "$num_files_needed" ]; then

  cp_vrfy $files_to_copy $EXTRN_MDL_FILES_DIR
#
#-----------------------------------------------------------------------
#
# If the needed analysis files are not all found in INIDIR_SYS, try to
# extract them from HPSS and into EXTRN_MDL_FILES_DIR.
#
#-----------------------------------------------------------------------
#
else
#
#-----------------------------------------------------------------------
#
# Load the HPSS module.
#
#-----------------------------------------------------------------------
#
  { save_shell_opts; set +x; } > /dev/null 2>&1
  module load hpss
  { restore_shell_opts; } > /dev/null 2>&1
#
#-----------------------------------------------------------------------
#
# Calculate the number of needed analysis files that exist in the tar
# file (num_files found).  If this is not equal to the number of analy-
# sis files needed (num_files_needed), print out a message and exit the
# script.  This is simply a check to make sure that the tar file in HPSS
# actually contains tne needed analysis files.
#
#-----------------------------------------------------------------------
#
# Get a list of those needed analysis files that also exist in the tar
# file.  This list (plus 2 informational lines) are stored in the file
# specified by htar_stdout_fn.
#
  htar_stdout_fn="htar_stdout_anl.txt"
  htar -tvf $HPSS_DIR/$ANL_TAR_FILE $files_to_extract > $htar_stdout_fn
  num_lines=$( wc -l < $htar_stdout_fn )
#
# The file specified by htar_stdout_fn will contain one line per file
# found plus two trailing informational lines.  Thus, to obtain the num-
# ber of files found, we simply subtract 2 from the number of lines in
# the file.
#
  num_files_found=$(( $num_lines - 2 ))
  if [ "$num_files_found" -ne "$num_files_needed" ]; then

    print_err_msg_exit "\
The necessary ${anl_or_fcst} files are not all available in HPSS:

  num_files_found = ${num_files_found} (number of ${anl_or_fcst} files found in HPSS)
  num_files_needed = ${num_files_needed} (number of ${anl_or_fcst} files needed)

See the output of the htar command in the file ${htar_stdout_fn} in the directory

  pwd = \"$(pwd)\"

for the list of files found."

  else

    rm_vrfy $htar_stdout_fn

  fi
#
#-----------------------------------------------------------------------
#
# Extract the needed analysis files from the tar file.
#
#-----------------------------------------------------------------------
#
  htar_stdout_fn="htar_stdout_anl.txt"
  htar -xvf $HPSS_DIR/$ANL_TAR_FILE $files_to_extract > $htar_stdout_fn
  htar_result=$?
  if [ "$htar_result" -ne "0" ]; then
    print_err_msg_exit "htar extract operation failed."
  fi
#
# Calculate the number of analysis files extracted from the tar file.
# If this is not equal to the number of analysis files needed (num_-
# files_needed), print out a message and exit the script.
#
  num_lines=$( wc -l < $htar_stdout_fn )
#
# In the file htar_stdout_fn into which the output from the htar command
# to stdout is redirected, there will be one line per extracted file
# plus two trailing informational lines.  Thus, to obtain the number of
# extracted files, we simply subtract 2 from the number of lines.
#
  num_files_found=$(( $num_lines - 2 ))
  if [ "$num_files_found" -ne "$num_files_needed" ]; then

    print_err_msg_exit "\
The htar operation was not able to extract all necessary ${anl_or_fcst} files from HPSS:

  num_files_found = ${num_files_found} (number of ${anl_or_fcst} files extracted)
  num_files_needed = ${$num_files_needed} (number of ${anl_or_fcst} files needed)

See the output of the htar command in the file ${htar_stdout_fn} in the directory

  pwd = \"$(pwd)\"

for the list of files extracted."

  else

    rm_vrfy $htar_stdout_fn

  fi
#
# If ARCHIVE_DIR is not set to the current directory (i.e. "."), then
# the htar command will have created the subdirectory ./$ARCHIVE_DIR un-
# der the current directory and placed the extracted files there.  We
# now move these extracted files back to the current directory and then
# remove the subdirectory created by htar.
#
  if [ "$ARCHIVE_DIR" != "." ]; then
    mv_vrfy .$ARCHIVE_DIR/* .
# Get the first subdirectory in ARCHIVE_DIR (i.e. the directory after
# the first forward slash).
    subdir_to_remove=$( printf "%s" "${ARCHIVE_DIR}" | sed -r 's|^\/([^/]*).*|\1|' )
    rm_vrfy -rf ./$subdir_to_remove
  fi

fi
#
#-----------------------------------------------------------------------
#
# Next, obtain (i.e. place into EXTRN_MDL_FILES_DIR) the forecast files needed to run
# a simulation.  These are needed to generate the boundary condition
# (BC) files at BC times after the 0th forecast hour (e.g. hour 3, hour
# 6, etc).
#
#-----------------------------------------------------------------------
#
# Set a convenience variable indicating whether we are considering ana-
# lysis or forecast files.
#
anl_or_fcst="forecast"
#
# Get the number of BC times.  This includes the initial time (i.e.
# hour 0 of the forecast).
#
num_BC_times="${#BC_update_times_hrs[@]}"
#
# Calculate the number of needed forecast files.  This is equal to one
# less than the number of BC times because the number of BC times in-
# cludes the initial time (corresponding to a forecast time of 0 hrs).
# The 0th hour BC file will be generated from the analysis files ob-
# tained above (which are also used to generate the IC file) and thus is
# not needed here.
#
num_files_needed=$(( $num_BC_times - 1 ))
print_info_msg_verbose "\
The number of BC files needed (not including at the initial time) are:
  num_files_needed = $num_files_needed"
#
# Set the name of the tar file that is supposed to contain the needed
# forecast files.
#
SIGMA_TAR_FILE="${prefix_tar_files}.${CDATE}.sigma.tar"
#
# Set the name of the directory within the archive in which the needed
# forecast files should be located.
#
temp=$( printf "%s" "${prefix_tar_files}" | sed -r 's|_|\/|g' )  # Use sed to replace underscores with forward slashes.
ARCHIVE_DIR="/${temp}.${YYYYMMDD}"
#
# Set variables containing the forecast file names with the appropriate
# paths that can be used below to either copy the forecast files from
# INIDIR_SYS or to extract them from a tar file in HPSS.
#
files_to_copy=""
files_to_extract=""
for BC_time in "${BC_update_times_hrs[@]:1}"; do  # Note that the :1 causes the loop to start with the 2nd element of BC_update_times_hrs.
  fcst_HHH=$( printf "%03d" "$BC_time" )
  curnt_file="gfs.t${HH}z.atmf${fcst_HHH}.nemsio"
  files_to_copy="${files_to_copy} $INIDIR_SYS/$curnt_file"
  files_to_extract="${files_to_extract} $ARCHIVE_DIR/$curnt_file"
done
#
#-----------------------------------------------------------------------
#
# We first need to check whether the needed forecast files all exist in
# the system directory INIDIR_SYS specified above.  We perform this
# check by counting the number of needed forecast files that actually
# exist in INIDIR_SYS (num_files_found).  If that number is the same as
# the number of needed forecast files (num_files_needed), it means all
# the needed forecast files exist in INIDIR_SYS (in which case we will
# simply copy them over to EXTRN_MDL_FILES_DIR).  If that number is different, then
# all the needed forecast files are not in INIDIR_SYS (in which case we
# will have to get them from HPSS.
#
#-----------------------------------------------------------------------
#
num_files_found=0
for f in $files_to_copy; do
  if [ -f "$f" ]; then
    num_files_found=$(( $num_files_found + 1 ))
  fi
done
#
#-----------------------------------------------------------------------
#
# Check whether the needed forecast files all exist in the system di-
# rectory INIDIR_SYS.  If so, copy them over to EXTRN_MDL_FILES_DIR.
#
#-----------------------------------------------------------------------
#
if [ "$num_files_found" -eq "$num_files_needed" ]; then

  cp_vrfy $files_to_copy $EXTRN_MDL_FILES_DIR
#
#-----------------------------------------------------------------------
#
# If the needed forecast files are not found in INIDIR_SYS, try to ex-
# tract them from HPSS and into EXTRN_MDL_FILES_DIR.
#
#-----------------------------------------------------------------------
#
else
#
# If the BC update interval (BC_update_intvl_hrs) is less than the fre-
# quency with which the forecast is saved in HPSS (given below by BC_up-
# date_intvl_hrs_HPSS_min), then some of the forecast files needed to
# generate the BC files will not be found in HPSS.  In this case, issue
# a warning.
#
  BC_update_intvl_hrs_HPSS_min=6
  if [ "$BC_update_intvl_hrs" -lt "$BC_update_intvl_hrs_HPSS_min" ]; then
    print_info_msg "\
CAUTION:

As of 07/182018, the forecast files in the mass store (HPSS) are available
only every BC_update_intvl_hrs_HPSS_min=${BC_update_intvl_hrs_HPSS_min} hours.

Since BC_update_intvl_hrs is set to a value smaller than this, some of the
forecast files needed to generate BC files will not be found in HPSS:

  BC_update_intvl_hrs_HPSS_min = $BC_update_intvl_hrs_HPSS_min
  BC_update_intvl_hrs = $BC_update_intvl_hrs"
  fi
#
#-----------------------------------------------------------------------
#
# Get a list of those needed forecast files that also exist in the tar
# file.  This is simply a check to make sure that the tar file in HPSS
# actually contains tne needed forecast files.
#
#-----------------------------------------------------------------------
#
  htar_stdout_fn="htar_stdout_fcst.txt"
  htar -tvf $HPSS_DIR/$SIGMA_TAR_FILE $files_to_extract > $htar_stdout_fn
#
# Count the number of needed forecast files that exist in the tar file.
# If this is not equal to the number of forecast files needed (num_-
# files_needed), print out a message and exit the script.
#
  num_lines=$( wc -l < $htar_stdout_fn )
#
# In the file htar_stdout_fn into which the stdout from the htar command
# is redirected, there will be one line per file found plus two trailing
# informational lines.  Thus, to obtain the number of files found, we
# simply subtract 2 from the number of lines.
#
  num_files_found=$(( $num_lines - 2 ))
  if [ "$num_files_found" -ne "$num_files_needed" ]; then

    print_err_msg_exit "\
The necessary ${anl_or_fcst} files are not all available in HPSS:

  num_files_found = ${num_files_found} (number of forecast files found in HPSS)
  num_files_needed = ${$num_files_needed} (number of forecast files needed)

See the output of the htar command in the file ${htar_stdout_fn} in the directory

  pwd = $(pwd)

for the list of files found."

  else

    rm_vrfy $htar_stdout_fn

  fi
#
#-----------------------------------------------------------------------
#
# Extract the needed forecast files from the tar file.
#
#-----------------------------------------------------------------------
#
  htar_stdout_fn="htar_stdout_fcst.txt"
  htar -xvf $HPSS_DIR/$SIGMA_TAR_FILE $files_to_extract > $htar_stdout_fn
  htar_result=$?
  if [ "$htar_result" -ne "0" ]; then
    print_err_msg_exit "htar extract operation failed."
  fi
#
# Count the number of forecast files extracted.  If this is not equal to
# the number of forecast files needed (num_files_needed), print out a
# message and exit the script.
#
  num_lines=$( wc -l < $htar_stdout_fn )
#
# In the file htar_stdout_fn into which the stdout from the htar command
# is redirected, there will be one line per extracted file plus two
# trailing informational lines.  Thus, to obtain the number of extractedi
# files, we simply subtract 2 from the number of lines.
#
  num_files_found=$(( $num_lines - 2 ))
  if [ "$num_files_found" -ne "$num_files_needed" ]; then

    print_err_msg_exit "\
The htar operation was not able to extract all necessary ${anl_or_fcst} files from HPSS:

  num_files_found = ${num_files_found} (number of ${anl_or_fcst} files extracted)
  num_files_needed = ${$num_files_needed} (number of ${anl_or_fcst} files needed)

See the output of the htar command in the file ${htar_stdout_fn} in the directory

  pwd = $(pwd)

for the list of files extracted."

  else

    rm_vrfy $htar_stdout_fn

  fi
#
# If ARCHIVE_DIR is not set to the current directory (i.e. "."), then
# the htar command will have created the subdirectory ./$ARCHIVE_DIR un-
# der the current directory and placed the extracted files there.  We
# now move these extracted files back to the current directory and then
# remove the subdirectory created by htar.
#
  if [ "$ARCHIVE_DIR" != "." ]; then
    mv_vrfy .$ARCHIVE_DIR/* .
# Get the first subdirectory in ARCHIVE_DIR (i.e. the directory after
# the first forward slash).
    subdir_to_remove=$( printf "%s" "${ARCHIVE_DIR}" | sed -r 's|^\/([^/]*).*|\1|' )
    rm_vrfy -rf ./$subdir_to_remove
  fi

fi
#
#-----------------------------------------------------------------------
#
# Print message indicating successful completion of script.
#
#-----------------------------------------------------------------------
#
print_info_msg "\

========================================================================
GFS analysis and forecast files obtained successfully!!!
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



