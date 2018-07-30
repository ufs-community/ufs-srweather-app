#!/bin/ksh
#
#----WCOSS_CRAY JOBCARD
#
##BSUB -L /bin/sh
#BSUB -P FV3GFS-T2O
#BSUB -o log.chgres_forBC.%J
#BSUB -e log.chgres_forBC.%J
#BSUB -J chgres_fv3
#BSUB -q debug
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
#PBS -N gen_BC_files_rgnl
#PBS -A gsd-fv3
#PBS -o out.$PBS_JOBNAME.$PBS_JOBID
#PBS -e err.$PBS_JOBNAME.$PBS_JOBID
#PBS -l nodes=1:ppn=24
#PBS -q debug
#PBS -l walltime=00:30:00
##PBS -q batch
##PBS -l walltime=00:40:00
#PBS -W umask=022
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
cd $PBS_O_WORKDIR
#
#-----------------------------------------------------------------------
#
# Source the setup script.
#
#-----------------------------------------------------------------------
#
. ./setup_grid_orog_ICs_BCs.sh 
#
#-----------------------------------------------------------------------
#
# This script is only for a regional grid.  Check for this and exit if
# gtype is not set to "regional".
#
#-----------------------------------------------------------------------
#
if [ "$gtype" != "regional" ]; then
  echo
  echo "This script is meant to be run only for a regional grid (gypte=\"regional\"):"
  echo "  gtype = $gtype"
  echo "Exiting script $0."
  exit 1
fi
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
#
# The following variables do not appear in chgres_driver_scr, but they
# may be needed by other scripts called by chgres_driver_scr.           <-- Maybe not.  Run and see what happens??
#
export CDAS=gfs                        # gfs or gdas; may not be needed by chgres_driver_scr, but hard to tell.



#
#-----------------------------------------------------------------------
#
# Load modules and set machine-dependent parameters.
#
#-----------------------------------------------------------------------
#
export ymd=`echo $CDATE | cut -c 1-8`

if [ "$machine" = "WCOSS_C" ]; then

  export NODES=28
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

#  export NODES=2   # Does this need to be set? It wasn't set in the original version of this script.

  . /apps/lmod/lmod/init/sh
  module use -a /scratch3/NCEPDEV/nwprod/lib/modulefiles
  module load intel/16.1.150 netcdf/4.3.0 hdf5/1.8.14 2>>/dev/null
  module list

# The variable DATA specifies the temporary (work) directory used by 
# chgres_driver_scr.
  export DATA="$TMPDIR/$subdir_name/BCs"
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
export HALO=4
ln -sf $GRID_OROG_INPUT_DIR/${CRES}_grid.tile7.halo${HALO}.nc $GRID_OROG_INPUT_DIR/${CRES}_grid.tile7.nc
ln -sf $GRID_OROG_INPUT_DIR/${CRES}_oro_data.tile7.halo${HALO}.nc $GRID_OROG_INPUT_DIR/${CRES}_oro_data.tile7.nc


#
#-----------------------------------------------------------------------
#
# Loop through the BC times starting with the second (where the first
# BC time is the model initialization time) and generate BCs at each
# time.  We do not generate BCs for the first BC time because that is
# done by another script that also generates the initial conditions.
#
#-----------------------------------------------------------------------
#
curnt_hr=$BC_interval_hrs

while (test "$curnt_hr" -le "$fcst_len_hrs"); do

  HHH=$( printf "%03d" "$curnt_hr" )

  if [ $machine = WCOSS_C ]; then
#
# On WCOSS_C, create an input file for cfp in order to run multiple co-
# pies of chgres_driver_scr simultaneously.  Since we are going to per-
# form the BC generation for all BC times simulataneously, we must use a
# different working directory for each BC time.  Note that here, we only 
# create the cfp input file; we do not call chgres_driver_scr.  That is 
# done later below after exiting the while loop.
#

#
# HALO is not set for WCOSS_C, so it will default to 0 in global_chgrs.sh.  That seems wrong!!!!
# So I set it above for any machine.
#
    BC_DATA=/gpfs/hps3/ptmp/${LOGNAME}/wrk.chgres.$HHH
    echo "env REGIONAL=2 bchour=$HHH DATA=$BC_DATA $BASE_GSM/ush/$chgres_driver_scr >&out.chgres.$HHH" >>bcfile.input

  elif [ $machine = THEIA ]; then
#
# On theia, run the BC generation sequentially for now.
#
    export REGIONAL=2
    export bchour=$HHH
    $BASE_GSM/ush/$chgres_driver_scr

  fi
#
# Increment the current BC time.
#
  curnt_hr=$(( $curnt_hr + BC_interval_hrs ))

done
#
# On WCOSS_C, now run the BC generation for all BC hours simultaneously.
#
if [ $machine = WCOSS_C ]; then
  export APRUNC=time
  export OMP_NUM_THREADS_CH=24      # Default for openMP threads.
  aprun -j 1 -n 28 -N 1 -d 24 -cc depth cfp bcfile.input
  rm bcfile.input
fi
#
#-----------------------------------------------------------------------
#
# Remove the links that were created above for the 4-halo files.
#
#-----------------------------------------------------------------------
#
rm $GRID_OROG_INPUT_DIR/${CRES}_grid.tile7.nc
rm $GRID_OROG_INPUT_DIR/${CRES}_oro_data.tile7.nc



