#! /bin/sh
#SBATCH --account=epic
#SBATCH --qos=normal
#SBATCH -t 02:00:00
#SBATCH -o run_fcst.log
#SBATCH --job-name=run_fcst_mem000
#SBATCH --ntasks=12
#SBATCH --cpus-per-task 1 --exclusive --clusters=c5 --partition=batch --export=NONE

export GLOBAL_VAR_DEFNS_FP=$PWD'/../var_defns.sh'
export USHdir=`grep USHdir $GLOBAL_VAR_DEFNS_FP | cut -d\' -f2`
export JOBSdir=`grep JOBSdir $GLOBAL_VAR_DEFNS_FP | cut -d\' -f2`
export PDY='20190615'
export cyc='18'
export subcyc='00'
export ENSMEM_INDX='000'
export SLASH_ENSMEM_SUBDIR='/'

$USHdir/load_modules_run_task.sh "run_fcst" $JOBSdir/JREGIONAL_RUN_FCST
