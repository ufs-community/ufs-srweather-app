#! /bin/sh
#SBATCH --account=epic
#SBATCH --partition=sjet,vjet,kjet,xjet
#SBATCH --qos=batch
#SBATCH -t 02:00:00
#SBATCH -o run_fcst.log
#SBATCH --job-name=run_fcst
#SBATCH --ntasks=12
#SBATCH --cpus-per-task 1 --exclusive --export=NONE

export GLOBAL_VAR_DEFNS_FP=$PWD'/../var_defns.sh'
export USHdir=$PWD'/../../../ufs-srweather-app/ush'
export PDY='20190615'
export cyc='18'
export subcyc='00'
export ENSMEM_INDX='000'
export SLASH_ENSMEM_SUBDIR='/'

$USHdir/load_modules_run_task.sh "run_fcst" $USHdir"/../jobs/JREGIONAL_RUN_FCST"
