#! /bin/sh
#SBATCH --account=epic
#SBATCH --nodes=1-1
#SBATCH --tasks-per-node=24
#SBATCH --partition=orion
#SBATCH --qos=batch
#SBATCH -t 00:20:00
#SBATCH -o make_grid.log
#SBATCH --job-name=make_grid
#SBATCH --export=NONE

export GLOBAL_VAR_DEFNS_FP=$PWD'/../var_defns.sh'
export USHdir=`grep USHdir $GLOBAL_VAR_DEFNS_FP | cut -d\' -f2`
export JOBSdir=`grep JOBSdir $GLOBAL_VAR_DEFNS_FP | cut -d\' -f2`

$USHdir/load_modules_run_task.sh "make_grid" $JOBSdir/JREGIONAL_MAKE_GRID
