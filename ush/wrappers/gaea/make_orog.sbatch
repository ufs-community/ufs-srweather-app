#! /bin/sh
#SBATCH --account=epic
#SBATCH --nodes=1-1
#SBATCH --tasks-per-node=24
#SBATCH --qos=windfall
#SBATCH -t 00:20:00
#SBATCH -o make_orog.log
#SBATCH --job-name=make_orog
#SBATCH --clusters=c4 --export=NONE

export GLOBAL_VAR_DEFNS_FP=$PWD'/../var_defns.sh'
export USHdir=$PWD'/../../../ufs-srweather-app/ush'
export nprocs='24'

$USHdir/load_modules_run_task.sh "make_orog" $USHdir"/../jobs/JREGIONAL_MAKE_OROG"
