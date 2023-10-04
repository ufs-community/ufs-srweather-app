#! /bin/sh
#SBATCH --account=epic
#SBATCH -o run_post.log
#SBATCH --nodes=2-2
#SBATCH --tasks-per-node=24
#SBATCH --partition=orion
#SBATCH --qos=batch
#SBATCH -t 00:15:00
#SBATCH --job-name=run_post
#SBATCH --export=NONE

export GLOBAL_VAR_DEFNS_FP=$PWD'/../var_defns.sh'
export USHdir=$PWD'/../../../ufs-srweather-app/ush'
export PDY='20230912'
export cyc='18'
export SLASH_ENSMEM_SUBDIR='/'
export ENSMEM_INDX='000'
export nprocs='48'
export FCST_LEN_HRS='12'

num_fcst_hrs=${FCST_LEN_HRS}
for (( i=0; i<=$((num_fcst_hrs)); i++ )); do
  export fhr=`printf "%03i" ${i}`
$USHdir/load_modules_run_task.sh "run_post" $USHdir"/../jobs/JREGIONAL_RUN_POST"
done
