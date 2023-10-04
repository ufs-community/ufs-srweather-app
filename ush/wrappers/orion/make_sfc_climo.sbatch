#! /bin/sh
#SBATCH --account=epic
#SBATCH --nodes=2-2
#SBATCH --tasks-per-node=24
#SBATCH --partition=orion
#SBATCH --qos=batch
#SBATCH -t 00:20:00
#SBATCH -o make_sfc_climo.log
#SBATCH --job-name=make_sfc_climo
#SBATCH --export=NONE

export GLOBAL_VAR_DEFNS_FP=$PWD'/../var_defns.sh'
export USHdir=$PWD'/../../../ufs-srweather-app/ush'

$USHdir/load_modules_run_task.sh "make_sfc_climo" $USHdir"/../jobs/JREGIONAL_MAKE_SFC_CLIMO"
