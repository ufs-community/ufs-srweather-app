#! /bin/sh
#SBATCH --account=epic
#SBATCH -o run_post.log
#SBATCH --nodes=2-2
#SBATCH --tasks-per-node=24
#SBATCH --qos=batch
#SBATCH -t 00:30:00
#SBATCH --job-name=run_post
#SBATCH --export=NONE

# Prepared for Hera mchine

#--- For this to work properly, make sure the location of your working directory is correct relative to the var_defns.sh file ---#
export GLOBAL_VAR_DEFNS_FP=$PWD'/../var_defns.sh'
export USHdir=`grep USHdir $GLOBAL_VAR_DEFNS_FP | cut -d\' -f2`
export JOBSdir=`grep JOBSdir $GLOBAL_VAR_DEFNS_FP | cut -d\' -f2`
export PDY=`grep DATE_FIRST_CYCL $GLOBAL_VAR_DEFNS_FP | cut -d\' -f2 | cut -c1-8`
export cyc=`grep DATE_FIRST_CYCL $GLOBAL_VAR_DEFNS_FP | cut -d\' -f2 | cut -c9-10`
export SLASH_ENSMEM_SUBDIR='/'
export ENSMEM_INDX='000'
export nprocs='48'

num_fcst_hrs=${FCST_LEN_HRS}
for (( i=0; i<=$((num_fcst_hrs)); i++ )); do
  export fhr=`printf "%03i" ${i}`
$USHdir/load_modules_run_task.sh "run_post" $JOBSdir/JREGIONAL_RUN_POST
done

# Gaea differences:
##SBATCH --qos=normal
##SBATCH --clusters=c5 --partition=batch --export=NONE

# Jet     differences:
##SBATCH --partition=sjet,vjet,kjet,xjet

# Orion   differences:
##SBATCH --partition=orion
