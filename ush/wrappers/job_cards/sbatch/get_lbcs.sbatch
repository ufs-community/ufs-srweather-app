#! /bin/sh
#SBATCH --account=epic
#SBATCH --nodes=1-1
#SBATCH --tasks-per-node=1
#SBATCH --partition=service
#SBATCH --qos=batch
#SBATCH -t 00:05:00
#SBATCH -o get_extrn_lbcs.log
#SBATCH --mem=2048
#SBATCH --job-name=get_extrn_lbcs
#SBATCH --export=NONE

# Prepared for Hera mchine

#--- For this to work properly, make sure the location of your working directory is correct relative to the var_defns.sh file ---#
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

# Gaea differences:
##SBATCH --qos=normal
##SBATCH --clusters=es --partition=eslogin_c5 --export=NONE
