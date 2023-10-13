#! /bin/sh
#SBATCH --account=epic
#SBATCH --nodes=2-2
#SBATCH --tasks-per-node=24
#SBATCH --qos=batch
#SBATCH -t 00:20:00
#SBATCH -o make_sfc_climo.log
#SBATCH --job-name=make_sfc_climo
#SBATCH --export=NONE

export GLOBAL_VAR_DEFNS_FP=$PWD'/../var_defns.sh'
export USHdir=`grep USHdir $GLOBAL_VAR_DEFNS_FP | cut -d\' -f2`
export JOBSdir=`grep JOBSdir $GLOBAL_VAR_DEFNS_FP | cut -d\' -f2`

$USHdir/load_modules_run_task.sh "make_sfc_climo" $JOBSdir/JREGIONAL_MAKE_SFC_CLIMO
