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
#cd $PBS_O_WORKDIR 
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
#if [ -d "$INIDIR" ] && \
#   [ "$(ls -A $INIDIR)" ]; then
#  echo
#  echo "The GFS analysis directory"
#  echo
#  echo "  INIDIR = $INIDIR"
#  echo
#  echo "already exists on disk and is not emtpy."
#  echo "Thus, there is no need to fetch the archived analysis file from HPSS."
#  echo "Exiting script."
#  exit
#fi
if [ -f "$INIDIR/$atmanl_file" ] && \
   [ -f "$INIDIR/$nstanl_file" ] && \
   [ -f "$INIDIR/$sfcanl_file" ]; then
  echo
  echo "The nemsio analysis files needed for initialization already exist in INIDIR:"
  echo
  echo "  INIDIR = $INIDIR"
  echo "  atmanl_file = $atmanl_file"
  echo "  nstanl_file = $nstanl_file"
  echo "  sfcanl_file = $sfcanl_file"
  echo
  echo "Thus, there is no need to fetch the archived analysis (tar) file from HPSS."
  echo "Exiting script."
  exit
fi


# Get list of BC times (in hours since the beginning of the forecast).
# First, check that 
#[ $var =~ ^[-+]?[0-9]+$ ]
#BC_files=$BC_times
#${CDUMP}.t${HH}z.atmf${bchour}.nemsio
#printf "gfs.t${HH}z.atmf%s.nemsio" "${BC_times[@]}"

#printf "foo %s bar\n" "${a[@]}"

file_names="aaaa"
curnt_hr=$BC_interval_hrs
while (test "$curnt_hr" -le "$fcst_len_hrs"); do
  fcst_HHH=$( printf "%03d" "$curnt_hr" )
  file_names="${file_names} gfs.t${HH}z.atmf${fcst_HHH}.nemsio"
  curnt_hr=$(( $curnt_hr + BC_interval_hrs ))
done

exit
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
# Set the directory on mass store (HPSS) in which the tarred archive 
# file that we want to fetch is located.
#
#-----------------------------------------------------------------------
#
export HPSS_DIR="/NCEPPROD/hpssprod/runhistory/rh$YYYY/${YYYY}${MM}/${YMD}"
#
#-----------------------------------------------------------------------
#
# Set the name of the tar file we want to fetch.  Note that the user
# must be a member of the rstprod group to be able to "get" this file
# using hsi.
#
#-----------------------------------------------------------------------
#
export TAR_FILE="gpfs_hps_nco_ops_com_gfs_prod_gfs.${YYYY}${MM}${DD}${HH}.anl.tar"
#
#-----------------------------------------------------------------------
#
# Check whether the tar file to extract from HPSS actually exists in 
# HPSS.  If not, exit the script.
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
#
#-----------------------------------------------------------------------
#
#tar -xvf $INIDIR/$TAR_FILE --directory=$INIDIR \
#  ./$atmanl_file ./$nstanl_file ./$sfcanl_file
tar -xvf $INIDIR/$TAR_FILE --directory=$INIDIR 
tar_extract_result=$?
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
#rm $INIDIR/$TAR_FILE 



