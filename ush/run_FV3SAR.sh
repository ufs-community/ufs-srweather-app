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
# This script runs the FV3SAR model from the run directory (RUNDIR).
#
#-----------------------------------------------------------------------
#

#
#-----------------------------------------------------------------------
#
# Change shell behavior with "set" with these flags:
#
# -a
# This will cause the script to automatically export all variables and
# functions which are modified or created to the environments of subse-
# quent commands.
#
# -e
# This will cause the script to exit as soon as any line in the script
# fails (with some exceptions; see manual).  Apparently, it is a bad
# idea to use "set -e".  See here:
#   http://mywiki.wooledge.org/BashFAQ/105
#
# -u
# This will cause the script to exit if an undefined variable is encoun-
# tered.
#
# -x
# This will cause all executed commands in the script to be printed to
# the terminal (used for debugging).
#
#-----------------------------------------------------------------------
#
set -eux
#
#-----------------------------------------------------------------------
#
# Source the script that defines the necessary shell environment varia-
# bles.
#
#-----------------------------------------------------------------------
#
. $SCRIPT_VAR_DEFNS_FP
#
#-----------------------------------------------------------------------
#
# Load modules.
#
#-----------------------------------------------------------------------
#
case $MACHINE in
#
"WCOSS_C" | "WCOSS" | "THEIA")
#
  . /apps/lmod/lmod/init/sh
  module purge
  module load intel/16.1.150 impi/5.1.1.109 netcdf/4.3.0
  module use /scratch4/NCEPDEV/nems/noscrub/emc.nemspara/soft/modulefiles
  module list

  ulimit -s unlimited
  ulimit -a
  APRUN="mpirun -l -np"
  ;;
#
"JET")
#
  . /apps/lmod/lmod/init/sh
  module purge
  module load newdefaults
  module load intel/15.0.3.187
  module load impi/5.1.1.109
  module load szip
  module load hdf5
  module load netcdf4/4.2.1.1
  module list

#  . $USHDIR/set_stack_limit_jet.sh
  ulimit -a
  APRUN="mpirun -np"
  ;;
#
"ODIN")
#
  module list

  ulimit -s unlimited
  ulimit -a
  APRUN="srun -n"
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
cd $RUNDIR
#
#-----------------------------------------------------------------------
#
# Remove old files in the run directory (e.g. from a previous unsuccess-
# ful run).
#
#-----------------------------------------------------------------------
#
rm -f time_stamp.out
rm -f stderr.* stdout.*
rm -f PET*
rm -f core*
rm -f *.nc
rm -f logfile.*
rm -f nemsusage.xml
rm -f fort.*
rm -f regional_*.tile7.nc
rm -f RESTART/*
#
#-----------------------------------------------------------------------
#
# Run the FV3SAR model.
#
#-----------------------------------------------------------------------
#
$APRUN $PE_MEMBER01 fv3_gfs.x


