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



#
#-----------------------------------------------------------------------
#
# This script generates NetCDF boundary condition (BC) files that con-
# tain data for the halo region of a regional grid.  One file is genera-
# ted for each boundary time AFTER the initial time up until the final 
# forecast time.  For example, if the boundary is to be updated every 3 
# hours (this update interval is determined by the variable BC_update_-
# intvl_hrs) and the forecast is to run for 24 hours (the forecast 
# length is determined by the variable fcst_len_hrs), then a file is ge-
# nerated for forecast hours 3, 6, 9, 12, 15, 18, and 24 (but not hour 
# 0 since that is handled by the script that generates the initial con-
# dition file).  All the generated NetCDF BC files are placed in the di-
# rectory specified by WORKDIR_ICBC.
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
# Set the file name of the diver script that runs chgres.
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
export OMP_NUM_THREADS_CH=24              # Default for openMP threads.
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
export CDAS=gfs                        # gfs or gdas; may not be needed by chgres_driver_scr, but hard to tell.
#
#-----------------------------------------------------------------------
#
# Load modules and set machine-dependent parameters.
#
# Note that the variable DATA specifies the temporary (work) directory 
# used by chgres_driver_scr.
#
#-----------------------------------------------------------------------
#
export ymd=$YMD

case $MACHINE in
#
"WCOSS_C")
#
  export NODES=28
  . $MODULESHOME/init/sh 2>>/dev/null
  module load PrgEnv-intel prod_envir cfp-intel-sandybridge/1.1.0 2>>/dev/null
  module list

  export KMP_AFFINITY=disabled
  export DATA=/gpfs/hps/ptmp/${LOGNAME}/wrk.chgres
  export APRUNC="aprun -n 1 -N 1 -j 1 -d $OMP_NUM_THREADS_CH -cc depth"
  ;;
#
"WCOSS")
#
  . /usrx/local/Modules/default/init/sh 2>>/dev/null
  module load ics/12.1 NetCDF/4.2/serial 2>>/dev/null
  module list

  export APRUNC="time"
  ;;
#
"THEIA")
#
  . /apps/lmod/lmod/init/sh
  module use -a /scratch3/NCEPDEV/nwprod/lib/modulefiles
  module load intel/16.1.150 netcdf/4.3.0 hdf5/1.8.14 2>>/dev/null
  module list

  export DATA="$WORKDIR_ICBC/BCs_work"
  export APRUNC="time"
  ulimit -s unlimited
  ulimit -a
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

  export DATA="$WORKDIR_ICBC/BCs_work"
  export APRUNC="time"
#  . $USHDIR/set_stack_limit_jet.sh
  ulimit -a
  ;;
#
"ODIN")
#
  export DATA="$WORKDIR_ICBC/BCs_work"
  export APRUNC="srun -n 1"
  ulimit -s unlimited
  ulimit -a
  ;;
#
esac
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
# Set REGIONAL to 2.  This will cause the chgres_driver_scr script to 
# generate a boundary conditions file (containing field values only in
# the halo of the regional domain) for each boundary time after the ini-
# tial time (e.g. hours 3, 6, 9, etc but not hour 0 since that is done 
# in the script that generates the initial conditions and surface 
# files).
#
#-----------------------------------------------------------------------
#
export REGIONAL=2
#
#-----------------------------------------------------------------------
#
# Loop through the BC update times starting with the second (where the 
# first BC update time is the model initialization time) and generate 
# BCs at each time.  We do not generate BCs for the first BC update 
# time because that is done by another script that also generates the 
# surface fields and initial conditions.
#
#-----------------------------------------------------------------------
#
curnt_hr=$BC_update_intvl_hrs

while (test "$curnt_hr" -le "$fcst_len_hrs"); do

  HHH=$( printf "%03d" "$curnt_hr" )

  case $MACHINE in
#
  "WCOSS_C")
#
# On WCOSS_C, create an input file for cfp in order to run multiple co-
# pies of chgres_driver_scr simultaneously.  Since we are going to per-
# form the BC generation for all BC update times simulataneously, we 
# must use a different working directory for each time.  Note that here, 
# we only create the cfp input file; we do not call chgres_driver_scr.  
# That is done later below after exiting the while loop.
#
    BC_DATA=/gpfs/hps3/ptmp/${LOGNAME}/wrk.chgres.$HHH
    echo "env REGIONAL=2 bchour=$HHH DATA=$BC_DATA $USHDIR/$chgres_driver_scr >&out.chgres.$HHH" >>bcfile.input
    ;;
#
  "WCOSS")
#
    echo
    echo "Not sure what to do for WCOSS."
    echo "Exiting script."
    exit 1
    ;;
#
  "THEIA" | "JET" | "ODIN")
#
# On theia and odin, run the BC generation sequentially for now.
#
    export bchour=$HHH
    $USHDIR/$chgres_driver_scr
    ;;
#
  esac
#
# Increment the current BC update time.
#
  curnt_hr=$(( $curnt_hr + BC_update_intvl_hrs ))

done
#
#-----------------------------------------------------------------------
#
# On WCOSS_C, now run the BC generation for all BC update times simul-
# taneously.
#
#-----------------------------------------------------------------------
#
if [ "$MACHINE" = "WCOSS_C" ]; then
  export APRUNC=time
  export OMP_NUM_THREADS_CH=24      # Default for openMP threads.
  aprun -j 1 -n 28 -N 1 -d 24 -cc depth cfp bcfile.input
  rm bcfile.input
fi


