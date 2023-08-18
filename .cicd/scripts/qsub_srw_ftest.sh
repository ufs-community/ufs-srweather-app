#!/usr/bin/env bash
#
# This is a pbs job card for the srw_ftest.sh script
# and is called by the wrapper_srw_ftest.sh script
# 
#PBS -N srw_ftest_run
#PBS -A ${SRW_PROJECT}
#PBS -q batch
#PBS -l nodes=1:ppn=24
#PBS -l walltime=00:30:00
#PBS -o log_wrap.%j.log
#PBS -e err_wrap.%j.err 

bash ${WORKSPACE}/.cicd/scripts/srw_ftest.sh
