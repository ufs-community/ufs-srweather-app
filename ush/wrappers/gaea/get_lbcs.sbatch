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
export USHdir=$PWD'/../../../ufs-srweather-app/ush'
export PDY='20190615'
export cyc='18'
export nprocs='1'
export subcyc='00'
export LOGDIR='/lustre/f2/dev/ncep/Ratko.Vasic/909/expt_dirs/test_community/log'
export ENSMEM_INDX='#mem#'
export ICS_OR_LBCS='LBCS'

$USHdir/load_modules_run_task.sh "get_extrn_lbcs" $USHdir"/../jobs/JREGIONAL_GET_EXTRN_MDL_FILES"
