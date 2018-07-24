#!/bin/sh

set -eux

#
# Source the configuration file to obtain user-defined parameters.
#
. ./config.sh
#
#-----------------------------------------------------------------------
#
# Task 1: Generate grid and orography files.
#
#-----------------------------------------------------------------------
#
echo
echo "Generating grid and (unfiltered and filtered) orography files..."

script_basename="fv3gfs_driver_grid_regional"
job_name="$script_basename"
#
# Submit as an interactive job (using the -I flag along with the -x flag
# to specify the script to run) so that the system waits until the job 
# is complete before moving on with the rest of this script.  Note that
# the -o and -e flags do not work with interactive jobs, so the stdout
# and stderr of the job must be redirected to files.
#
qsub \
-A $ACCOUNT \
-N $job_name \
-q debug \
-l nodes=1:ppn=24 \
-l walltime=00:30:00 \
-I \
-x "$BASE_GSM/ush/$script_basename.sh" \
| sed -r -e 's/\r//g' \
1>out.$job_name  2>err.$job_name 
#
# Get the PBS job id of the above qsub interactive job from the first 
# line of the file to which stdout was redirected. 
#
jobid=$( head -1 out.${job_name} | sed -r -n 's/.* ([0-9]+\.[A-Z,a-z,0-9]+) .*/\1/p' )
#
# Rename the stdout and stderr files into which the stdout and stderr of 
# the above qsub command were redirected by appending the job id to the 
# ends of the file names.
#
mv out.$job_name out.$job_name.$jobid
mv err.$job_name err.$job_name.$jobid
#
#-----------------------------------------------------------------------
#
# Task 2: Copy GFS analysis and forecast files needed for generating IC
# and BC input files.
#
#-----------------------------------------------------------------------
#
echo
echo "Copying GFS analysis and forecast files needed for IC and BC generation..."

script_basename="get_GFS_anl_fcst_files"
job_name="$script_basename"
#
# Submit as an interactive job (using the -I flag along with the -x flag
# to specify the script to run) so that the system waits until the job 
# is complete before moving on with the rest of this script.  Note that
# the -o and -e flags do not work with interactive jobs, so the stdout
# and stderr of the job must be redirected to files.
#
qsub \
-A $ACCOUNT \
-N $job_name \
-q service \
-l nodes=1:ppn=1 \
-l walltime=00:30:00 \
-I \
-x "$BASE_GSM/ush/$script_basename.sh" \
| sed -r -e 's/\r//g' \
1>out.$job_name  2>err.$job_name 
#
# Get the PBS job id of the above qsub interactive job from the first 
# line of the file to which stdout was redirected. 
#
jobid=$( head -1 out.${job_name} | sed -r -n 's/.* ([0-9]+\.[A-Z,a-z,0-9]+) .*/\1/p' )
#
# Rename the stdout and stderr files into which the stdout and stderr of 
# the above qsub command were redirected by appending the job id to the 
# ends of the file names.
#
mv out.$job_name out.$job_name.$jobid
mv err.$job_name err.$job_name.$jobid
#
#-----------------------------------------------------------------------
#
# Task 3: Generate ICs file and BCs file at initial time.
#
#-----------------------------------------------------------------------
#
echo
echo "Generating ICs file and BCs file at initial time..."

script_basename="run_chgres_rgnl_IC_BC0"
job_name="$script_basename"
#
# Submit as an interactive job (using the -I flag along with the -x flag
# to specify the script to run) so that the system waits until the job 
# is complete before moving on with the rest of this script.  Note that
# the -o and -e flags do not work with interactive jobs, so the stdout
# and stderr of the job must be redirected to files.
#
qsub \
-A $ACCOUNT \
-N $job_name \
-q debug \
-l nodes=1:ppn=24 \
-l walltime=00:30:00 \
-I \
-x "$BASE_GSM/ush/$script_basename.sh" \
| sed -r -e 's/\r//g' \
1>out.$job_name  2>err.$job_name 
#
# Get the PBS job id of the above qsub interactive job from the first 
# line of the file to which stdout was redirected. 
#
jobid=$( head -1 out.${job_name} | sed -r -n 's/.* ([0-9]+\.[A-Z,a-z,0-9]+) .*/\1/p' )
#
# Rename the stdout and stderr files into which the stdout and stderr of 
# the above qsub command were redirected by appending the job id to the 
# ends of the file names.
#
mv out.$job_name out.$job_name.$jobid
mv err.$job_name err.$job_name.$jobid
#
#-----------------------------------------------------------------------
#
# Task 4: Generate BCs file at all boundary times after the initial time.
#
#-----------------------------------------------------------------------
#
echo
echo "Generating BCs files at all boundary times after the initial time..."

script_basename="run_chgres_rgnl_BCs"
job_name="$script_basename"
#
# Submit as an interactive job (using the -I flag along with the -x flag
# to specify the script to run) so that the system waits until the job 
# is complete before moving on with the rest of this script.  Note that
# the -o and -e flags do not work with interactive jobs, so the stdout
# and stderr of the job must be redirected to files.
#
qsub \
-A $ACCOUNT \
-N $job_name \
-q debug \
-l nodes=1:ppn=24 \
-l walltime=00:30:00 \
-I \
-x "$BASE_GSM/ush/$script_basename.sh" \
| sed -r -e 's/\r//g' \
1>out.$job_name  2>err.$job_name 
#
# Get the PBS job id of the above qsub interactive job from the first 
# line of the file to which stdout was redirected. 
#
jobid=$( head -1 out.${job_name} | sed -r -n 's/.* ([0-9]+\.[A-Z,a-z,0-9]+) .*/\1/p' )
#
# Rename the stdout and stderr files into which the stdout and stderr of 
# the above qsub command were redirected by appending the job id to the 
# ends of the file names.
#
mv out.$job_name out.$job_name.$jobid
mv err.$job_name err.$job_name.$jobid



