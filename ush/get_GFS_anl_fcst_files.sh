#!/bin/bash
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



#set -eux
set -ux
# 
#-----------------------------------------------------------------------
#
# When this script is run using the qsub command, its default working 
# directory is the user's home directory (unless another one is speci-
# fied  via qsub's -d flag; the -d flag sets the environment variable 
# PBS_O_INITDIR, which is by default undefined).  Here, we change direc-
# tory to the one in which the qsub command is issued, and that directo-
# ry is specified in the environment variable PBS_O_WORKDIR.  This must
# be done to be able to source the setup script.
# 
#-----------------------------------------------------------------------
#
#cd $PBS_O_WORKDIR
#
#-----------------------------------------------------------------------
#
# Source the setup script.
#
#-----------------------------------------------------------------------
#
. $TMPDIR/../fv3gfs/ush/setup_grid_orog_ICs_BCs.sh

#
#-----------------------------------------------------------------------
#
# Change location to INIDIR.  This is the directory in which we will 
# store the analysis (at the initial time CDATE) and forecasts (at the
# boundary condition times) files.
#
#-----------------------------------------------------------------------
#
cd $INIDIR
#
#-----------------------------------------------------------------------
#
# Set the directory on mass store (HPSS) in which the archive (tar) 
# files that we may need to extract files from are located.  Also, set
# a prefix that appears in the names of these tar files.
#
#-----------------------------------------------------------------------
#
HPSS_DIR="/NCEPPROD/hpssprod/runhistory/rh${YYYY}/${YYYY}${MM}/${YMD}"
prefix_tar_files="gpfs_hps_nco_ops_com_gfs_prod_gfs"
#
#-----------------------------------------------------------------------
#
# Set the system directory in which all analysis and forecast files 
# needed to run a forecast MAY be found.  On theia, these directories
# contain the needed files for the past two days (today and yesterday,
# or yesterday and the day before), while on WCOSS they contain the 
# needed files for the past two weeks.  
#
# If the starting date of the forecast (CDATE) is within this time per-
# iod (i.e two days on theia and two weeks on WCOSS), the needed files
# may simply be copied over from these system directories to INIDIR.  If
# CDATE is a time that goes back beyond this time period, then the need-
# ed files must be obtained from the mass store (HPSS) and placed into
# INIDIR.
#
#-----------------------------------------------------------------------
#
if [ "$machine" = "WCOSS_C" ]; then
  export INIDIR_SYS="/gpfs/hps/nco/ops/com/gfs/prod/gfs.$YMD"
elif [ "$machine" = "WCOSS" ]; then
  export INIDIR_SYS=""  # Not sure how these should be set on WCOSS.
elif [ "$machine" = "THEIA" ]; then
#  export COMROOTp2="/scratch4/NCEPDEV/rstprod/com"   # Does this really need to be exported??
#  export INIDIR_SYS="$COMROOTp2/gfs/prod/gfs.$YMD"
  export INIDIR_SYS="/scratch4/NCEPDEV/rstprod/com/gfs/prod/gfs.$YMD"
elif [ "$machine" = "Odin" ]; then
  export INIDIR_SYS="/scratch/ywang/test_runs/FV3_regional/gfs/$YMD"
fi
#
#-----------------------------------------------------------------------
#
# First, obtain (i.e. place into INIDIR) the analysis files needed to 
# run a simulation.  These are needed in order to generate the initial
# condition (IC) file and the 0th hour boundary condtion (BC) file.
#
#-----------------------------------------------------------------------
#
# Set a convenience variable indicating whether we are considering ana-
# lysis or forecast files.
#
anl_or_fcst="analysis"
#
# Set the names of the analysis files needed to generate the initial 
# condition file and the first (0th forecast hour) boundary condition
# file.
#
temp="gfs.t${HH}z."
#anl_files=( ${temp}atmanl.nemsio ${temp}nstanl.nemsio ${temp}sfcanl.nemsio )
anl_files=( ${temp}atmanl.nemsio ${temp}sfcanl.nemsio )
#
# Set the number of needed analysis files.
#
num_files_needed="${#anl_files[@]}"
#
# Set the name of the tar file that is supposed to contain the needed
# analysis files.
#
ANL_TAR_FILE="${prefix_tar_files}.${CDATE}.anl.tar"
#
# Set the name of the directory within the archive in which the needed
# analysis files should be located.
#
ARCHIVE_DIR="."
#
# Set variables containing the analysis file names with the appropriate
# paths that can be used below to either copy the analysis files from 
# INIDIR_SYS or to extract them from a tar file in HPSS.
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
# exist in INIDIR_SYS (num_files_found).  If that number is the same as
# the number of needed analysis files (num_files_needed), it means all 
# the needed analysis files exist in INIDIR_SYS (in which case we will
# simply copy them over to INIDIR).  If that number is different, then
# all the needed analysis files are not in INIDIR_SYS (in which case we
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
# Check whether the needed analysis files all exist in the system di-
# rectory INIDIR_SYS.  If so, copy them over to INIDIR.  
#
#-----------------------------------------------------------------------
#
if [ "$num_files_found" -eq "$num_files_needed" ]; then

  cp $files_to_copy $INIDIR
#
#-----------------------------------------------------------------------
#
# If the needed analysis files are not found in INIDIR_SYS, try to ex-
# tract them from HPSS and into INIDIR.
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
  module load hpss
#
#-----------------------------------------------------------------------
#
# Get a list of those needed analysis files that also exist in the tar
# file.  This is simply a check to make sure that the tar file in HPSS
# actually contains tne needed analysis files.
#
#-----------------------------------------------------------------------
#
  htar_stdout_fn="htar_stdout_anl.txt"
  htar -tvf $HPSS_DIR/$ANL_TAR_FILE $files_to_extract > $htar_stdout_fn
#
# Count the number of needed analysis files that exist in the tar file.  
# If this is not equal to the number of analysis files needed (num_-
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
    echo
    echo "The needed ${anl_or_fcst} files are not all available in HPSS."
    echo
    echo "  num_files_found = ${num_files_found} (number of ${anl_or_fcst} files found in HPSS)"
    echo "  num_files_needed = ${num_files_needed} (number of ${anl_or_fcst} files needed)"
    echo
    echo "See the output of the htar command in the file ${htar_stdout_fn} in the directory"
    echo
    echo "  pwd = "$(pwd)
    echo
    echo "for the list of files found."
    echo "Exiting script."
    exit 1
  else
    rm $htar_stdout_fn
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
    echo
    echo "htar extract operation failed."
    echo "Exiting script."
    exit 1
  fi  
#
# Count the number of analysis files extracted.  If this is not equal to
# the number of analysis files needed (num_files_needed), print out a
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
    echo
    echo "The htar operation was not able to extract all needed ${anl_or_fcst} files from HPSS:"
    echo
    echo "  num_files_found = ${num_files_found} (number of ${anl_or_fcst} files extracted)"
    echo "  num_files_needed = ${$num_files_needed} (number of ${anl_or_fcst} files needed)"
    echo
    echo "See the output of the htar command in the file ${htar_stdout_fn} in the directory"
    echo
    echo "  pwd = "$(pwd)
    echo
    echo "for the list of files extracted."
    echo "Exiting script."
    exit 1
  else
    rm $htar_stdout_fn
  fi 
#
# If ARCHIVE_DIR is not set to the current directory (i.e. "."), then 
# the htar command will have created the subdirectory ./$ARCHIVE_DIR un-
# der the current directory and placed the extracted files there.  We 
# now move these extracted files back to the current directory and then
# remove the subdirectory created by htar.
#
  if [ "$ARCHIVE_DIR" != "." ]; then
    mv .$ARCHIVE_DIR/* .
# Get the first subdirectory in ARCHIVE_DIR (i.e. the directory after 
# the first forward slash).
    subdir_to_remove=$( echo ${ARCHIVE_DIR} | sed -r 's|^\/([^/]*).*|\1|' )
    rm -rf ./$subdir_to_remove
  fi 

fi 
#
#-----------------------------------------------------------------------
#
# Next, obtain (i.e. place into INIDIR) the forecast files needed to run
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
num_BC_times="${#BC_times_hrs[@]}"
#
# Calculate the number of needed forecast files.  This is equal to one 
# less than the number of BC times because the number of BC times in-
# cludes the initial time (corresponding to a forecast time of 0 hrs).  
# The 0th hour BC file will be generated from the analysis files ob-
# tained above (which are also used to generate the IC file) and thus is
# not needed here.
#
num_files_needed=$(( $num_BC_times - 1 ))
echo
echo "num_files_needed = $num_files_needed"
#
# Set the name of the tar file that is supposed to contain the needed
# forecast files.
#
SIGMA_TAR_FILE="${prefix_tar_files}.${CDATE}.sigma.tar"
#
# Set the name of the directory within the archive in which the needed
# forecast files should be located.
#
temp=$( echo ${prefix_tar_files} | sed -r 's|_|\/|g' )  # Use sed to replace underscores with forward slashes.
ARCHIVE_DIR="/${temp}.${YMD}"
#
# Set variables containing the forecast file names with the appropriate
# paths that can be used below to either copy the forecast files from 
# INIDIR_SYS or to extract them from a tar file in HPSS.
#
files_to_copy=""
files_to_extract=""
for BC_time in "${BC_times_hrs[@]:1}"; do  # Note that the :1 causes the loop to start with the 2nd element of BC_times_hrs.
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
# simply copy them over to INIDIR).  If that number is different, then
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
# rectory INIDIR_SYS.  If so, copy them over to INIDIR.  
#
#-----------------------------------------------------------------------
#
if [ "$num_files_found" -eq "$num_files_needed" ]; then

  cp $files_to_copy $INIDIR
#
#-----------------------------------------------------------------------
#
# If the needed forecast files are not found in INIDIR_SYS, try to ex-
# tract them from HPSS and into INIDIR.
#
#-----------------------------------------------------------------------
#
else
#
# If the BC time interval (BC_interval_hrs) is less than the frequency 
# with which the forecast is saved in HPSS (given below by BC_interval_-
# hrs_HPSS_min), then some of the forecast files needed to generate the
# BC files will not be found in HPSS.  In this case, issue a warning.
#
  BC_interval_hrs_HPSS_min=6
  if [ "$BC_interval_hrs" -lt "$BC_interval_hrs_HPSS_min" ]; then
    echo
    echo "CAUTION:"
    echo
    echo "As of 07/182018, the forecast files in the mass store (HPSS) are available"
    echo "only every BC_interval_hrs_HPSS_min=${BC_interval_hrs_HPSS_min} hours."
    echo
    echo "Since BC_interval_hrs is set to a value smaller than this, some of the"
    echo "forecast files needed to generate BC files will not be found in HPSS."
    echo
    echo "  BC_interval_hrs_HPSS_min = $BC_interval_hrs_HPSS_min"
    echo "  BC_interval_hrs = $BC_interval_hrs"
    echo
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
    echo
    echo "The needed ${anl_or_fcst} files are not all available in HPSS."
    echo
    echo "  num_files_found = ${num_files_found} (number of forecast files found in HPSS)"
    echo "  num_files_needed = {$num_files_needed} (number of forecast files needed)"
    echo
    echo "See the output of the htar command in the file ${htar_stdout_fn} in the directory"
    echo
    echo "  pwd = "$(pwd)
    echo
    echo "for the list of files found."
    echo "Exiting script."
    exit 1
  else
    rm $htar_stdout_fn
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
    echo
    echo "htar extract operation failed."
    echo "Exiting script."
    exit 1
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
    echo
    echo "The htar operation was not able to extract all needed ${anl_or_fcst} files from HPSS:"
    echo
    echo "  num_files_found = ${num_files_found} (number of ${anl_or_fcst} files extracted)"
    echo "  num_files_needed = ${$num_files_needed} (number of ${anl_or_fcst} files needed)"
    echo
    echo "See the output of the htar command in the file ${htar_stdout_fn} in the directory"
    echo
    echo "  pwd = "$(pwd)
    echo
    echo "for the list of files extracted."
    echo "Exiting script."
    exit 1
  else
    rm $htar_stdout_fn
  fi 
#
# If ARCHIVE_DIR is not set to the current directory (i.e. "."), then 
# the htar command will have created the subdirectory ./$ARCHIVE_DIR un-
# der the current directory and placed the extracted files there.  We 
# now move these extracted files back to the current directory and then
# remove the subdirectory created by htar.
#
  if [ "$ARCHIVE_DIR" != "." ]; then
    mv .$ARCHIVE_DIR/* .
# Get the first subdirectory in ARCHIVE_DIR (i.e. the directory after 
# the first forward slash).
    subdir_to_remove=$( echo ${ARCHIVE_DIR} | sed -r 's|^\/([^/]*).*|\1|' )
    rm -rf ./$subdir_to_remove
  fi 

fi
