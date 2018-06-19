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
#PBS -N fetch_GFSanl_from_HPSS
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
cd $PBS_O_WORKDIR 
#
#-----------------------------------------------------------------------
#
# Source the setup script.
#
#-----------------------------------------------------------------------
#
. ./setup_grid_orog_ICs_BCs.sh
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
# If INIDIR exists and is not empty, just exit this script because in
# that case, the GFS analysis file (specified by TAR_FILE) has already
# been fetched from HPSS and extracted.  If INIDIR doesn't exist, or if
# it exists but is emtpy, try to fetch a new copy of the GFS analysis
# file from HPSS.
#
# Note that the bash test operator [ ] without any arguments between the
# brackets returns a false.  Thus, if the directory INIDIR is empty, 
# then the "ls -A" command in the second set of square brackets in the
# if-statement below returns an emtpy string.  This causes the argument 
# of the if-statment to evaluate to false, which in turn causes the re-
# mainder of this script to execute.
#
#-----------------------------------------------------------------------
#
if [ -d "$INIDIR" ] && \
   [ "$(ls -A $INIDIR)" ]; then
  echo
  echo "The GFS analysis directory"
  echo
  echo "  INIDIR = $INIDIR"
  echo
  echo "already exists on disk and is not emtpy."
  echo "Thus, there is no need to fetch the archived analysis file from HPSS."
  echo "Exiting script."
  exit
fi
#
#-----------------------------------------------------------------------
#
# Create the directory in which we will save the tar archive file that
# we will fetch from mass store (HPSS) (if it doesn't already exist).
# Then change location to that directory.
#
#-----------------------------------------------------------------------
#
mkdir -p $INIDIR
cd $INIDIR
#
#-----------------------------------------------------------------------
#
# Check whether the tar file to extract from HPSS actually exists.  If
# not, exit the script.
#
#-----------------------------------------------------------------------
#
hsi "ls -l ${HPSS_DIR}/${TAR_FILE}"
tar_file_exists=$?
if [ $tar_file_exists != "0" ]; then
  echo
  echo "File $TAR_FILE does not exist on HPSS."
  echo "Exiting script."
  exit 1
fi
#
#-----------------------------------------------------------------------
#
# Get the tar file from HPSS.  If the get operation fails, exit the 
# script.
#
#-----------------------------------------------------------------------
#
hsi "cd $HPSS_DIR; get $TAR_FILE"
hsi_get_result=$?
if [ "$hsi_get_result" != "0" ]; then
  echo
  echo "hsi \"get\" operation failed."
  echo "Exiting script."
  exit 1
fi  
#
#-----------------------------------------------------------------------
#
# Extract the atmosphere, near-sea-surface temperature, and surface ana-
# lysis files from the tar file.
# Why are these at 00z?  Are these actually at $HH, so they should be renamed???
#
#-----------------------------------------------------------------------
#
tar -xvf $INIDIR/$TAR_FILE --directory=$INIDIR ./pgrba/cmc_gespr.t00z.pgrbaf336 ./pgrba/cmc_gespr.t00z.pgrbaf342  # <-- Couple of dummy files to extract from the dummy tar file.
tar_extract_result=$?
# The following are the actual files to extract (once I have rstprod group membership).
#  ./gfs.t00z.atmanl.nemsio \
#  ./gfs.t00z.nstanl.nemsio \
#  ./gfs.t00z.sfcanl.nemsio
if [ "$tar_extract_result" != "0" ]; then
  echo
  echo "tar extract archive operation failed."
  echo "Exiting script."
  exit 1
fi
#
#-----------------------------------------------------------------------
#
# Delete the tar file since it is usually very large.
#
#-----------------------------------------------------------------------
#
rm $INIDIR/$TAR_FILE 



