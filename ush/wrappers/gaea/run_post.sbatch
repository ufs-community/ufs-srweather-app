#! /bin/sh
#SBATCH --account=epic
#SBATCH -o run_post.log
#SBATCH --nodes=2-2
#SBATCH --tasks-per-node=24
#SBATCH --qos=windfall
#SBATCH -t 00:15:00
#SBATCH --job-name=run_post
#SBATCH --clusters=c4 --export=NONE

export GLOBAL_VAR_DEFNS_FP=$PWD'/../var_defns.sh'
export USHdir=`grep USHdir $GLOBAL_VAR_DEFNS_FP | cut -d\' -f2`
export JOBSdir=`grep JOBSdir $GLOBAL_VAR_DEFNS_FP | cut -d\' -f2`
export PDY=`grep DATE_FIRST_CYCL $GLOBAL_VAR_DEFNS_FP | cut -d\' -f2 | cut -c1-8`
export cyc=`grep DATE_FIRST_CYCL $GLOBAL_VAR_DEFNS_FP | cut -d\' -f2 | cut -c9-10`
export SLASH_ENSMEM_SUBDIR='/'
export ENSMEM_INDX='000'
export nprocs='48'

export FCST_LEN_HRS='12'

num_fcst_hrs=${FCST_LEN_HRS}
for (( i=0; i<=$((num_fcst_hrs)); i++ )); do
  export fhr=`printf "%03i" ${i}`
$USHdir/load_modules_run_task.sh "run_post" $JOBSdir/JREGIONAL_RUN_POST
done
