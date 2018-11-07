#!/bin/bash


#Source variables from user-defined file
. ${TMPDIR}/../fv3gfs/ush/setup_grid_orog_ICs_BCs.sh

if [ "$machine" = "THEIA" -o "$machine" = "WCOSS" -o "$machine" = "WCOSS_C" ]; then
  module purge
  module load intel/16.1.150 impi/5.1.1.109 netcdf/4.3.0
  module use /scratch4/NCEPDEV/nems/noscrub/emc.nemspara/soft/modulefiles

  module list

  ulimit -s unlimited
  ulimit -a
elif [ "$machine" = "Jet" ]; then
  #module purge
  #module load newdefaults
  #module load intel/15.0.3.187
  #module load impi/5.1.1.109
  #module load szip
  #module load hdf5
  #module load netcdf4/4.2.1.1
  #module list

  # Set the stack limit as high as we can.
  #if [[ $( ulimit -s ) != unlimited ]] ; then
  #    for try_limit in 20000 18000 12000 9000 6000 3000 1500 1000 800 ; do
  #        if [[ ! ( $( ulimit -s ) -gt $(( try_limit * 1000 )) ) ]] ; then
  #              ulimit -s $(( try_limit * 1000 ))
  #        else
  #              break
  #        fi
  #    done
  #fi

  ulimit -a
elif [ "$machine" = "Odin" ]; then
  module list

  ulimit -s unlimited
  ulimit -a
fi

#Run the run.regional script to execute FV3
${TMPDIR}/../run_dirs/${subdir_name}/run.regional


