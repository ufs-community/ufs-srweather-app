#! /bin/sh
#SBATCH --account=epic
#SBATCH --nodes=4-4
#SBATCH --tasks-per-node=12
#SBATCH --qos=batch
#SBATCH -t 00:30:00
#SBATCH -o make_ics.log
#SBATCH --job-name=make_ics
#SBATCH --export=NONE

export GLOBAL_VAR_DEFNS_FP=$PWD'/../var_defns.sh'
export USHdir=$PWD'/../../../ufs-srweather-app/ush'
export PDY='20190615'
export cyc='18'
export subcyc='00'
export ENSMEM_INDX='000'
export SLASH_ENSMEM_SUBDIR='/'
export NWGES_DIR='/scratch2/NCEPDEV/fv3-cam/Ratko.Vasic/909/expt_dirs/../nco_dirs/nwges/2019061518'

$USHdir/load_modules_run_task.sh "make_ics" $USHdir"/../jobs/JREGIONAL_MAKE_ICS"
