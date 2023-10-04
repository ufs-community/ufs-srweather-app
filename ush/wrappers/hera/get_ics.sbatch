#! /bin/sh
#SBATCH --account=epic
#SBATCH --nodes=1-1
#SBATCH --tasks-per-node=1
#SBATCH --partition=service
#SBATCH --qos=batch
#SBATCH -t 00:05:00
#SBATCH -o get_extrn_ics.log
#SBATCH --mem=2048
#SBATCH --job-name=get_extrn_ics
#SBATCH --export=NONE

export GLOBAL_VAR_DEFNS_FP=$PWD'/../var_defns.sh'
export USHdir=$PWD'/../../../ufs-srweather-app/ush'
export PDY='20190615'
export cyc='18'
export nprocs='1'
export subcyc='00'
export ENSMEM_INDX='#mem#'
export ICS_OR_LBCS='ICS'

$USHdir/load_modules_run_task.sh "get_extrn_ics" $USHdir"/../jobs/JREGIONAL_GET_EXTRN_MDL_FILES"
