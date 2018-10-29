#!/bin/bash

# Load modules.
module purge
module load intel/16.1.150 impi/5.1.1.109 netcdf/4.3.0
module use /scratch4/NCEPDEV/nems/noscrub/emc.nemspara/soft/modulefiles

module list

ulimit -s unlimited
ulimit -a

# Source the script that defines the necessary shell environment varia-
# bles.
. $RUNDIR/var_defns.sh

# Run the run.regional script to execute FV3.
$RUNDIR/run.regional

