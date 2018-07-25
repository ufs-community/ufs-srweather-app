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
task1=$( qsub \
-A $ACCOUNT \
-N $job_name \
-q debug \
-l nodes=1:ppn=24 \
-l walltime=00:30:00 \
-o out.$job_name \
-e err.$job_name \
"$BASE_GSM/ush/$script_basename.sh" \
)
#
# Get the PBS job id of the above qsub interactive job from the first 
# line of the file to which stdout was redirected. 
#
#jobid=$( head -1 out.${job_name} | sed -r -n 's/.* ([0-9]+\.[A-Z,a-z,0-9]+) .*/\1/p' )
#
# Rename the stdout and stderr files into which the stdout and stderr of 
# the above qsub command were redirected by appending the job id to the 
# ends of the file names.
#
#mv out.$job_name out.$job_name.$jobid
#mv err.$job_name err.$job_name.$jobid
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
task2=$( qsub \
-A $ACCOUNT \
-N $job_name \
-q service \
-l nodes=1:ppn=1 \
-l walltime=00:30:00 \
-o out.$job_name \
-e err.$job_name \
"$BASE_GSM/ush/$script_basename.sh" \
)
#-W depend=afterok:$task1 \
#
# Get the PBS job id of the above qsub interactive job from the first 
# line of the file to which stdout was redirected. 
#
#jobid=$( head -1 out.${job_name} | sed -r -n 's/.* ([0-9]+\.[A-Z,a-z,0-9]+) .*/\1/p' )
#
# Rename the stdout and stderr files into which the stdout and stderr of 
# the above qsub command were redirected by appending the job id to the 
# ends of the file names.
#
#mv out.$job_name out.$job_name.$jobid
#mv err.$job_name err.$job_name.$jobid
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
task3=$( qsub \
-A $ACCOUNT \
-N $job_name \
-q debug \
-l nodes=1:ppn=24 \
-l walltime=00:30:00 \
-o out.$job_name \
-e err.$job_name \
-W depend=afterok:$task1:$task2 \
"$BASE_GSM/ush/$script_basename.sh" \
)
#
# Get the PBS job id of the above qsub interactive job from the first 
# line of the file to which stdout was redirected. 
#
#jobid=$( head -1 out.${job_name} | sed -r -n 's/.* ([0-9]+\.[A-Z,a-z,0-9]+) .*/\1/p' )
#
# Rename the stdout and stderr files into which the stdout and stderr of 
# the above qsub command were redirected by appending the job id to the 
# ends of the file names.
#
#mv out.$job_name out.$job_name.$jobid
#mv err.$job_name err.$job_name.$jobid

#
#-----------------------------------------------------------------------
#
# Check the number of jobs in the debug queue for the current user that
# do not have the entry "C" (completed) in the status column.  Continue 
# only after this number is less than 2 (since the maximum number of 
# jobs that a user may have in the debug queue is 2).
#
#-----------------------------------------------------------------------
#
REGEXP="^([0-9]+\.[^:]+):([^:]+):([^[:space:]]+)([[:space:]]+)([^[:space:]C]+)(.*)/\1|\2|\3|\4|\5|\6"
num_jobs_debug_queue=$( qstat -u $LOGNAME debug | sed -n -r "s/$REGEXP/p" | wc -l )
while [ $num_jobs_debug_queue -ge 2 ]; do 
  sleep 30s
  num_jobs_debug_queue=$( qstat -u $LOGNAME debug | sed -n -r "s/$REGEXP/p" | wc -l )
done
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
task4=$( qsub \
-A $ACCOUNT \
-N $job_name \
-q debug \
-l nodes=1:ppn=24 \
-l walltime=00:30:00 \
-o out.$job_name \
-e err.$job_name \
-W depend=afterok:$task1:$task2 \
"$BASE_GSM/ush/$script_basename.sh" \
)
#
# Get the PBS job id of the above qsub interactive job from the first 
# line of the file to which stdout was redirected. 
#
#jobid=$( head -1 out.${job_name} | sed -r -n 's/.* ([0-9]+\.[A-Z,a-z,0-9]+) .*/\1/p' )
#
# Rename the stdout and stderr files into which the stdout and stderr of 
# the above qsub command were redirected by appending the job id to the 
# ends of the file names.
#
#mv out.$job_name out.$job_name.$jobid
#mv err.$job_name err.$job_name.$jobid



