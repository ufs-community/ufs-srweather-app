#!/usr/bin/env bash
#
# This is a sbatch job card for the srw_ftest.sh script
# and is called by the srw_ftest_wrapper.sh script
# 
#SBATCH --job-name=wrapper_test
#SBATCH --account=${SRW_PROJECT}
#SBATCH --qos=batch
#SBATCH --nodes=1
#SBATCH --tasks-per-node=24
#SBATCH --cpus-per-task=1
#SBATCH -t 00:30:00
#SBATCH -o log_wrap.%j.log
#SBATCH -e err_wrap.%j.err 

bash ${WORKSPACE}/.cicd/scripts/srw_ftest.sh
