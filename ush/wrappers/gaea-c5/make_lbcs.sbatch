#! /bin/sh
#SBATCH --account=epic
#SBATCH --nodes=4-4
#SBATCH --tasks-per-node=12
#SBATCH --qos=normal
#SBATCH -t 00:30:00
#SBATCH -o make_lbcs.log
#SBATCH --job-name=make_lbcs_mem000
#SBATCH --clusters=c5 --partition=batch --export=NONE

export GLOBAL_VAR_DEFNS_FP=$PWD'/../var_defns.sh'
export USHdir=`grep USHdir $GLOBAL_VAR_DEFNS_FP | cut -d\' -f2`
export JOBSdir=`grep JOBSdir $GLOBAL_VAR_DEFNS_FP | cut -d\' -f2`
export PDY='20190615'
export cyc='18'
export subcyc='00'
export ENSMEM_INDX='000'
export SLASH_ENSMEM_SUBDIR='/'
export nprocs='48'
export bcgrp='00'
export bcgrpnum='1'

$USHdir/load_modules_run_task.sh "make_lbcs" $JOBSdir/JREGIONAL_MAKE_LBCS
