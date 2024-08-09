#!/usr/bin/env bash
#
# This is a pbs job card for the srw_ftest.sh script
# and is called by the wrapper_srw_ftest.sh script
# 
#PBS -N srw_ftest_run
#PBS -A ${SRW_PROJECT}
#PBS -q main
#PBS -l select=1:ncpus=24:mpiprocs=24:ompthreads=1
#PBS -l walltime=00:30:00
#PBS -V

bash ${WORKSPACE}/${SRW_PLATFORM}/.cicd/scripts/srw_ftest.sh
