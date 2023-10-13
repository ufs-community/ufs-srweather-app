#! /bin/sh
#SBATCH --account=epic
#SBATCH --nodes=1-1
#SBATCH --tasks-per-node=1
#SBATCH --qos=windfall
#SBATCH -t 01:30:00
#SBATCH -o get_extrn_lbcs.log
#SBATCH --job-name=get_extrn_lbcs
#SBATCH --clusters=es --export=NONE

export GLOBAL_VAR_DEFNS_FP=$PWD'/../var_defns.sh'
export USHdir=`grep USHdir $GLOBAL_VAR_DEFNS_FP | cut -d\' -f2`
export JOBSdir=`grep JOBSdir $GLOBAL_VAR_DEFNS_FP | cut -d\' -f2`
export PDY=`grep DATE_FIRST_CYCL $GLOBAL_VAR_DEFNS_FP | cut -d\' -f2 | cut -c1-8`
export cyc=`grep DATE_FIRST_CYCL $GLOBAL_VAR_DEFNS_FP | cut -d\' -f2 | cut -c9-10`
export nprocs='1'
export subcyc='00'
export ENSMEM_INDX='#mem#'
export ICS_OR_LBCS='LBCS'

$USHdir/load_modules_run_task.sh "get_extrn_lbcs" $JOBSdir/JREGIONAL_GET_EXTRN_MDL_FILES
