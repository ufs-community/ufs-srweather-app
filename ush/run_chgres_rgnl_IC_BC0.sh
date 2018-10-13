#!/bin/ksh

# 
#-----------------------------------------------------------------------
#
# This script generates an initial conditions (ICs) file and a surface
# file on a given grid at a specified date.  The ICs file contains For a regional grid, it al-
# so generates a boundary file at the initial time 
# on the grid
# specified by the parameters in  
# 
#-----------------------------------------------------------------------
#


set -eux
# 
#-----------------------------------------------------------------------
#
# When this script is run using the qsub command, its default working 
# directory is the user's home directory (unless another one is speci-
# fied  via qsub's -d flag; the -d flag sets the environment variable 
# PBS_O_INITDIR, which is by default undefined).  Here, we change direc-
# tory to the one in which the qsub command is issued, and that directo-
# ry is specified in the environment variable PBS_O_WORKDIR.  This must
# be done to be able to source the setup script below.
# 
#-----------------------------------------------------------------------
#
#cd $PBS_O_WORKDIR
#
#-----------------------------------------------------------------------
#
# Source the setup script.
#
#-----------------------------------------------------------------------
#
. ${TMPDIR}/../fv3gfs/ush/setup_grid_orog_ICs_BCs.sh 
#
#-----------------------------------------------------------------------
#
# Set the file name of the diver script that runs chgres.
#
#-----------------------------------------------------------------------
#
chgres_driver_scr="global_chgres_driver.sh"
#
#-----------------------------------------------------------------------
#
# Set variables needed by chgres_driver_scr.
#
#-----------------------------------------------------------------------
#
export OMP_NUM_THREADS_CH=24           # Default for openMP threads.
export CASE=${CRES}
export LEVS=64
export LSOIL=4
export FIXfv3=${BASE_GSM}/fix/fix_fv3
export GRID_OROG_INPUT_DIR=${out_dir}  # Directory in which input grid and orography files are located.
export OUTDIR=${out_dir}               # Directory in which output from chgres_driver_scr is placed.
export HOMEgfs=$BASE_GSM               # Directory in which the "superstructure" fv3gfs code is located.
export nst_anl=.false.                 # false or true to include NST analysis

# This is something that needs to go somewhere earlier, like right after
# the repo is cloned.
# ln -fs /scratch4/NCEPDEV/global/save/glopara/git/fv3gfs/fix/fix_am  ${BASE_GSM}/fix

#
# The following variables do not appear in chgres_driver_scr, but they
# may be needed by other scripts called by chgres_driver_scr.           <-- Maybe not.  Run and see what happens??
#
export CDAS=gfs                        # gfs or gdas; may not be needed by chgres_driver_scr, but hard to tell.
export NODES=2


#
#-----------------------------------------------------------------------
#
# Load modules and set machine-dependent parameters.
#
#-----------------------------------------------------------------------
#
export ymd=`echo $CDATE | cut -c 1-8`

if [ "$machine" = "WCOSS_C" ]; then

  . $MODULESHOME/init/sh 2>>/dev/null
  module load PrgEnv-intel prod_envir cfp-intel-sandybridge/1.1.0 2>>/dev/null
  module list

  export KMP_AFFINITY=disabled
  export DATA=/gpfs/hps/ptmp/${LOGNAME}/wrk.chgres
  export APRUNC="aprun -n 1 -N 1 -j 1 -d $OMP_NUM_THREADS_CH -cc depth"

elif [ "$machine" = "WCOSS" ]; then

  . /usrx/local/Modules/default/init/sh 2>>/dev/null
  module load ics/12.1 NetCDF/4.2/serial 2>>/dev/null
  module list

  export APRUNC="time"

elif [ "$machine" = "THEIA" ]; then

  . /apps/lmod/lmod/init/sh
  module use -a /scratch3/NCEPDEV/nwprod/lib/modulefiles
  module load intel/16.1.150 netcdf/4.3.0 hdf5/1.8.14 2>>/dev/null
  module list

# The variable DATA specifies the temporary (work) directory used by 
# chgres_driver_scr.
  export DATA="$TMPDIR/$subdir_name/ICs"
  export APRUNC="time"
  ulimit -a
  ulimit -s unlimited

elif [ "$machine" = "Odin" ]; then
  export DATA="$TMPDIR/$subdir_name/ICs"
  export APRUNC="srun -n 1"
  ulimit -a
  ulimit -s unlimited

else

  echo "$machine not supported, exit"
  exit

fi
#
#-----------------------------------------------------------------------
#
# Perform grid-type dependent tasks.
#
#-----------------------------------------------------------------------
#
if [ "$gtype" = "regional" ]; then
#
# For gtype set to "regional", set REGIONAL to 1.  This will cause 
# chgres_driver_scr to generate an initial conditions file only on the 
# regional grid (tile 7) and to generate a boundary conditions file 
# (which contains field values only in the halo of the regional domain)
# only at the initial time.
#
  export REGIONAL=1
#
# Create links to the grid and orography files with 4 halo cells.  These
# are needed by chgres to create the boundary data.
#
  export HALO=4
  ln -sf $GRID_OROG_INPUT_DIR/${CRES}_grid.tile7.halo${HALO}.nc $GRID_OROG_INPUT_DIR/${CRES}_grid.tile7.nc
  ln -sf $GRID_OROG_INPUT_DIR/${CRES}_oro_data.tile7.halo${HALO}.nc $GRID_OROG_INPUT_DIR/${CRES}_oro_data.tile7.nc

else
#
# For gtype set to "uniform", "stretch", or "nest", set REGIONAL to 0.  
# This will cause chgres_driver_scr to generate global initial condi-
# tions.
#
  export REGIONAL=0

fi
#
#-----------------------------------------------------------------------
#
# Run the chgres driver script.
#
#-----------------------------------------------------------------------
#
$BASE_GSM/ush/$chgres_driver_scr
#
#-----------------------------------------------------------------------
#
# For a regional grid, remove the links that were created above for the 
# 4-halo files.
#
#-----------------------------------------------------------------------
#
#if [ "$gtype" = "regional" ]; then
#  rm $GRID_OROG_INPUT_DIR/${CRES}_grid.tile7.nc
#  rm $GRID_OROG_INPUT_DIR/${CRES}_oro_data.tile7.nc
#fi
