#! /bin/sh
#SBATCH --account=epic
#SBATCH --nodes=4-4
#SBATCH --tasks-per-node=12
#SBATCH --qos=batch
#SBATCH -t 00:30:00
#SBATCH -o make_ics.log
#SBATCH --job-name=make_ics
#SBATCH --export=NONE

# Prepared for Hera mchine

#--- For this to work properly, make sure the location of your working directory is correct relative to the var_defns.sh file ---#
export GLOBAL_VAR_DEFNS_FP=$PWD'/../var_defns.sh'
export USHdir=`grep USHdir $GLOBAL_VAR_DEFNS_FP | cut -d\' -f2`
export JOBSdir=`grep JOBSdir $GLOBAL_VAR_DEFNS_FP | cut -d\' -f2`
export PDY=`grep DATE_FIRST_CYCL $GLOBAL_VAR_DEFNS_FP | cut -d\' -f2 | cut -c1-8`
export cyc=`grep DATE_FIRST_CYCL $GLOBAL_VAR_DEFNS_FP | cut -d\' -f2 | cut -c9-10`
export subcyc='00'
export ENSMEM_INDX='000'
export SLASH_ENSMEM_SUBDIR='/'
export NWGES_DIR=$PWD'/../../../nco_dirs/nwges/20190615'

$USHdir/load_modules_run_task.sh "make_ics" $JOBSdir/JREGIONAL_MAKE_ICS

# Gaea differences:
##SBATCH --qos=normal
##SBATCH --clusters=c5 --partition=batch --export=NONE
#export nprocs='48'

# Jet     differences:
##SBATCH --partition=sjet,vjet,kjet,xjet
#export nprocs='48'

# Orion   differences:
##SBATCH --partition=orion
