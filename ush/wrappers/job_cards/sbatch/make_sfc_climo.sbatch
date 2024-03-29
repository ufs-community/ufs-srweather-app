#! /bin/sh
#SBATCH --account=epic
#SBATCH --nodes=2-2
#SBATCH --tasks-per-node=24
#SBATCH --qos=batch
#SBATCH -t 00:20:00
#SBATCH -o make_sfc_climo.log
#SBATCH --job-name=make_sfc_climo
#SBATCH --export=NONE

# Prepared for Hera mchine

#--- For this to work properly, make sure the location of your working directory is correct relative to the var_defns.sh file ---#
export GLOBAL_VAR_DEFNS_FP=$PWD'/../var_defns.sh'
export USHdir=`grep USHdir $GLOBAL_VAR_DEFNS_FP | cut -d\' -f2`
export JOBSdir=`grep JOBSdir $GLOBAL_VAR_DEFNS_FP | cut -d\' -f2`

$USHdir/load_modules_run_task.sh "make_sfc_climo" $JOBSdir/JREGIONAL_MAKE_SFC_CLIMO

# Gaea differences:
##SBATCH --qos=normal
##SBATCH --clusters=c5 --partition=batch --export=NONE
#export nprocs='48'

# Jet     differences:
##SBATCH --partition=sjet,vjet,kjet,xjet
#export nprocs='48'

# Orion   differences:
##SBATCH --partition=orion
