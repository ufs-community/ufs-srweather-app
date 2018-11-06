#!/bin/ksh
#
#----WCOSS_CRAY JOBCARD
#
##BSUB -L /bin/sh
#BSUB -P NAM-T2O
#BSUB -o log.chgres.%J
#BSUB -e log.chgres.%J
#BSUB -J chgres_fv3
#BSUB -q "debug"
#BSUB -W 00:30
#BSUB -M 1024
#BSUB -extsched 'CRAYLINUX[]'
#
#----WCOSS JOBCARD
#
##BSUB -L /bin/sh
##BSUB -P FV3GFS-T2O
##BSUB -oo log.chgres.%J
##BSUB -eo log.chgres.%J
##BSUB -J chgres_fv3
##BSUB -q devonprod
##BSUB -x
##BSUB -a openmp
##BSUB -n 24
##BSUB -R span[ptile=24]
#
#----THEIA JOBCARD
#
#PBS -N gen_IC_BC0_files_rgnl
#PBS -A gsd-fv3
#PBS -o out.$PBS_JOBNAME.$PBS_JOBID
#PBS -e err.$PBS_JOBNAME.$PBS_JOBID
#PBS -l nodes=1:ppn=24
#PBS -q debug
#PBS -l walltime=00:30:00
#PBS -W umask=022
#

# 
#-----------------------------------------------------------------------
#
# This script generates:
#
# 1) A NetCDF initial condition (IC) file on a regional grid for the 
#    date/time on which the analysis files in the directory specified by
#    INIDIR are valid.  Note that this file does not include data in the
#    halo of this regional grid (that data is found in the boundary con-
#    dition (BC) files).
#
# 2) A NetCDF surface file on the regional grid.  As with the IC file, 
#    this file does not include data in the halo.
#
# 3) A NetCDF boundary condition (BC) file containing data on the halo
#    of the regional grid at the initial time (i.e. at the same time as
#    the one at which the IC file is valid).
#
# 4) A NetCDF GFS "control" file named gfs_ctrl.nc that contains infor-
#    mation on the vertical coordinate and the number of tracers for 
#    which initial and boundary conditions are provided.
#
# All four of these NetCDF files are placed in the directory specified 
# by WORKDIR_ICBC.
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

export BASEDIR
export INIDIR  # This is the variable that determines the directory in
               # which chgres looks for the input nemsio files.
export gtype
#
#-----------------------------------------------------------------------
#
# Set the file name of the diver script that runs the chgres utility.
#
#-----------------------------------------------------------------------
#
chgres_driver_scr="global_chgres_driver.sh"
#
#-----------------------------------------------------------------------
#
# Create the directory in which the ouput from this script will be 
# placed (if it doesn't already exist).
#
#-----------------------------------------------------------------------
#
mkdir -p $WORKDIR_ICBC
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
export FIXfv3=${FV3SAR_DIR}/fix/fix_fv3
export GRID_OROG_INPUT_DIR=$WORKDIR_SHVE  # Directory in which input grid and orography files are located.
export OUTDIR=$WORKDIR_ICBC               # Directory in which output from chgres_driver_scr is placed.
export HOMEgfs=$FV3SAR_DIR                # Directory in which the "superstructure" fv3gfs code is located.
export nst_anl=.false.                    # false or true to include NST analysis
#
# The following variables do not appear in chgres_driver_scr, but they
# may be needed by other scripts called by chgres_driver_scr.           <-- Maybe not.  Run and see what happens??
#
export CDAS=gfs  # gfs or gdas; may not be needed by chgres_driver_scr, but hard to tell.
export NODES=2
#
#-----------------------------------------------------------------------
#
# Load modules and set machine-dependent parameters.
#
#-----------------------------------------------------------------------
#
export ymd=$YMD

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
  export DATA="$WORKDIR_ICBC/ICs_work"
  export APRUNC="time"
  ulimit -a
  ulimit -s unlimited

else

  echo "$machine not supported, exit"
  exit

fi
#
#-----------------------------------------------------------------------
#
# Create links to the grid and orography files with 4 halo cells.  These
# are needed by chgres to create the boundary data.
#
#-----------------------------------------------------------------------
#
export HALO=${nh4_T7}

ln -fs $WORKDIR_SHVE/${CRES}_grid.tile7.halo${HALO}.nc \
       $GRID_OROG_INPUT_DIR/${CRES}_grid.tile7.nc

ln -fs $WORKDIR_SHVE/${CRES}_oro_data.tile7.halo${HALO}.nc \
       $GRID_OROG_INPUT_DIR/${CRES}_oro_data.tile7.nc
#
#-----------------------------------------------------------------------
#
# Set REGIONAL to 1.  This will cause the chgres_driver_scr script to 
# generate an initial conditions file, a boundary conditions file (con-
# taining field values only in the halo of the regional domain) at the
# initial time, and a surface file.
#
#-----------------------------------------------------------------------
#
export REGIONAL=1
#
#-----------------------------------------------------------------------
#
# Run the chgres driver script.
#
#-----------------------------------------------------------------------
#
$USHDIR/$chgres_driver_scr



