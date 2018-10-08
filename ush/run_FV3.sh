#!/bin/bash

module purge
module load intel/16.1.150 impi/5.1.1.109 netcdf/4.3.0
module use /scratch4/NCEPDEV/nems/noscrub/emc.nemspara/soft/modulefiles

module list

ulimit -s unlimited
ulimit -a

#Source variables from user-defined file
. ${TMPDIR}/../fv3gfs/ush/setup_grid_orog_ICs_BCs.sh

#Run the run.regional script to execute FV3
${TMPDIR}/../run_dirs/${subdir_name}/run.regional

#Move config.sh script from $TMPDIR to $RUNDIR
mv ${TMPDIR}/config.sh ${RUNDIR}/config.sh
