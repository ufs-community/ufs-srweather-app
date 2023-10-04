#! /bin/sh
#SBATCH --account=epic
#SBATCH --nodes=4-4
#SBATCH --tasks-per-node=12
#SBATCH --partition=orion
#SBATCH --qos=batch
#SBATCH -t 00:30:00
#SBATCH -o make_lbcs.log
#SBATCH --job-name=make_lbcs
#SBATCH --export=NONE

export GLOBAL_VAR_DEFNS_FP=$PWD'/../var_defns.sh'
export USHdir=$PWD'/../../../ufs-srweather-app/ush'
export PDY='20230912'
export cyc='18'
export subcyc='00'
export ENSMEM_INDX='000'
export SLASH_ENSMEM_SUBDIR='/'
export bcgrp='00'
export bcgrpnum='1'

$USHdir/load_modules_run_task.sh "make_lbcs" $USHdir"/../jobs/JREGIONAL_MAKE_LBCS"
