#!/bin/sh -l

#PBS -A gsd-fv3-test
#PBS -e err.regional.$PBS_JOBID
#PBS -o out.regional.$PBS_JOBID
#PBS -N fv3
#PBS -l nodes=20:ppn=24
#PBS -q batch
#PBS -l walltime=03:00:00


#
#-----------------------------------------------------------------------
#
# This script runs one forecast with the FV3SAR model from the external-
# ly specified run directory (RUNDIR).
#
#-----------------------------------------------------------------------
#

#
#-----------------------------------------------------------------------
#
# Source the variable definitions script.
#
#-----------------------------------------------------------------------
#
. $SCRIPT_VAR_DEFNS_FP
#
#-----------------------------------------------------------------------
#
# Source function definition files.
#
#-----------------------------------------------------------------------
#
. $USHDIR/source_funcs.sh
#
#-----------------------------------------------------------------------
#
# Save current shell options (in a global array).  Then set new options
# for this script/function.
#
#-----------------------------------------------------------------------
#
{ save_shell_opts; set -u -x; } > /dev/null 2>&1


RUNDIR="$EXPTDIR/$CDATE"
#
#-----------------------------------------------------------------------
#
# Load modules.
#
#-----------------------------------------------------------------------
#
case $MACHINE in
#
"WCOSS_C" | "WCOSS")
#

if [ "$CCPP" = "true" ]; then

  #Needed to change to the run directory to correctly load necessary modules for CCPP-version of FV3SAR in lines below
  cd_vrfy $RUNDIR

  set +x
  source ./module-setup.sh
  module use $( pwd -P )
  module load modules.fv3
  module list
  set -x

else

  . /apps/lmod/lmod/init/sh
  module purge
  module use /scratch4/NCEPDEV/nems/noscrub/emc.nemspara/soft/modulefiles
  module load intel/16.1.150 impi/5.1.1.109 netcdf/4.3.0 
  module list

fi

  ulimit -s unlimited
  ulimit -a
  APRUN="mpirun -l -np $PE_MEMBER01"
  ;;
#
"THEIA")
#

if [ "$CCPP" = "true" ]; then

  #Needed to change to the run directory to correctly load necessary modules for CCPP-version of FV3SAR in lines below
  cd $RUNDIR

  set +x
  source ./module-setup.sh
  module use $( pwd -P )
  module load modules.fv3
  module list
  set -x

else

  . /apps/lmod/lmod/init/sh
  module purge
  module use /scratch4/NCEPDEV/nems/noscrub/emc.nemspara/soft/modulefiles
  module load intel/16.1.150 impi/5.1.1.109 netcdf/4.3.0 
  module list

fi

  ulimit -s unlimited
  ulimit -a
  APRUN="srun"
  ;;

#
"JET")
#
  . /apps/lmod/lmod/init/sh
  module purge
  module load intel/15.0.3.187
  module load impi/5.1.1.109
  module load szip
  module load hdf5
  module load netcdf4/4.2.1.1
  module list

#  . $USHDIR/set_stack_limit_jet.sh
  ulimit -s unlimited
  ulimit -a
  APRUN="srun"
  ;;
#
"ODIN")
#
  module list

  ulimit -s unlimited
  ulimit -a
  APRUN="srun -n $PE_MEMBER01"
  ;;
#
esac
#
#-----------------------------------------------------------------------
#
# Set and export variables.
#
#-----------------------------------------------------------------------
#
export KMP_AFFINITY=scatter
export OMP_NUM_THREADS=2
export OMP_STACKSIZE=1024m
#
#-----------------------------------------------------------------------
#
# Change location to the run directory.  This is necessary because the
# FV3SAR executable will look for various files in the current directo-
# ry.  Since those files have been staged in the run directory, the cur-
# rent directory must be the run directory.
#
#-----------------------------------------------------------------------
#
cd_vrfy $RUNDIR
#
#-----------------------------------------------------------------------
#
# Remove old files in the run directory (e.g. from a previous unsuccess-
# ful run).
#
#-----------------------------------------------------------------------
#
rm_vrfy -f time_stamp.out
rm_vrfy -f stderr.* stdout.*
rm_vrfy -f PET*
rm_vrfy -f core*
rm_vrfy -f *.nc
rm_vrfy -f logfile.*
rm_vrfy -f nemsusage.xml
rm_vrfy -f fort.*
rm_vrfy -f regional_*.tile7.nc
rm_vrfy -f RESTART/*
#
#-----------------------------------------------------------------------
#
# Run the FV3SAR model.
#
#-----------------------------------------------------------------------
#
$APRUN ./fv3_gfs.x || print_err_msg_exit "\
Call to executable to run FV3SAR forecast returned with nonzero exit code."
#
#-----------------------------------------------------------------------
#
# Print message indicating successful completion of script.
#
#-----------------------------------------------------------------------
#
print_info_msg "\

========================================================================
FV3SAR forecast completed successfully!!!
========================================================================"
#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script/func-
# tion.
#
#-----------------------------------------------------------------------
#
{ restore_shell_opts; } > /dev/null 2>&1


