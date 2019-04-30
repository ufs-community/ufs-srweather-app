#!/bin/sh -l

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
# by WORKDIR_ICBC_CDATE, defined as
#
#   WORKDIR_ICBC_CDATE="$WORKDIR_ICBC/$CDATE"
#
# where CDATE is the externally specified starting date and cycle hour
# of the current forecast.
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
#
#-----------------------------------------------------------------------
#
# Export select variables.
#
#-----------------------------------------------------------------------
#
export BASEDIR
# Set and export the variable that determines the directory in which 
# chgres looks for the input nemsio files.
export INIDIR="$EXTRN_MDL_FILES_BASEDIR/$CDATE"
export gtype
export ictype
#
#-----------------------------------------------------------------------
#
# Set the file name of the driver script that runs the chgres utility.
#
#-----------------------------------------------------------------------
#
chgres_driver_scr="global_chgres_driver.sh"
#
#-----------------------------------------------------------------------
#
# Set the name of and create the directory in which the ouput from this
# script will be placed (if it doesn't already exist).
#
#-----------------------------------------------------------------------
#
WORKDIR_ICBC_CDATE="$WORKDIR_ICBC/$CDATE"
mkdir_vrfy -p "$WORKDIR_ICBC_CDATE"
#
#-----------------------------------------------------------------------
#
# Set variables needed by chgres_driver_scr.
#
#-----------------------------------------------------------------------
#
export OMP_NUM_THREADS_CH=24              # Default for openMP threads.
export CASE=${CRES}
export LEVS=65
export LSOIL=4
export NTRAC=7
export FIXfv3=${FV3SAR_DIR}/fix/fix_fv3
export GRID_OROG_INPUT_DIR=$WORKDIR_SHVE  # Directory in which input grid and orography files are located.
export OUTDIR=$WORKDIR_ICBC_CDATE         # Directory in which output from chgres_driver_scr is placed.
export HOMEgfs=$FV3SAR_DIR                # Directory in which the "superstructure" fv3sar_workflow code is located.
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
# Note that the variable DATA specifies the temporary (work) directory
# used by chgres_driver_scr.
#
#-----------------------------------------------------------------------
#
export ymd=${CDATE:0:8}

case $MACHINE in
#
"WCOSS_C")
#
  { save_shell_opts; set +x; } > /dev/null 2>&1

  . $MODULESHOME/init/sh 2>>/dev/null
  module load PrgEnv-intel prod_envir cfp-intel-sandybridge/1.1.0 2>>/dev/null
  module list

  { restore_shell_opts; } > /dev/null 2>&1

  export KMP_AFFINITY=disabled
  export DATA=/gpfs/hps/ptmp/${LOGNAME}/wrk.chgres
  export APRUNC="aprun -n 1 -N 1 -j 1 -d $OMP_NUM_THREADS_CH -cc depth"
  ;;
#
"WCOSS")
#
  { save_shell_opts; set +x; } > /dev/null 2>&1

  . /usrx/local/Modules/default/init/sh 2>>/dev/null
  module load ics/12.1 NetCDF/4.2/serial 2>>/dev/null
  module list

  { restore_shell_opts; } > /dev/null 2>&1

  export DATA=/ptmpp2/${LOGNAME}/wrk.chgres
  export APRUNC="time"
  ;;
#
"DELL")
#
  { save_shell_opts; set +x; } > /dev/null 2>&1

  . /usrx/local/prod/lmod/lmod/init/sh
  module load EnvVars/1.0.2 lmod/7.7 settarg/7.7 lsf/10.1 prod_envir/1.0.2
  module use -a /usrx/local/dev/modulefiles
  module load git/2.14.3
  module load ips/18.0.1.163
  module load impi/18.0.1
  module load NetCDF/4.5.0
  module load HDF5-serial/1.10.1
  module list

  { restore_shell_opts; } > /dev/null 2>&1

  export KMP_AFFINITY=disabled
  export APRUN=time
  export DATA=/gpfs/dell3/ptmp/${LOGNAME}/wrk.chgres
#  export BASE_GSM=/gpfs/dell2/emc/modeling/noscrub/${LOGNAME}/fv3gfs
#  export FIXgsm=/gpfs/dell2/emc/modeling/noscrub/emc.glopara/git/fv3gfs/fix/fix_am
#  export home_dir=$LS_SUBCWD/..
#  if [ $ictype = pfv3gfs ]; then
#    hour=`echo $CDATE | cut -c 9-10`
#    export INIDIR=/gpfs/dell3/ptmp/emc.glopara/ROTDIRS/prfv3rt1/gfs.$ymd/$hour
#  else
#    export INIDIR=/gpfs/hps/nco/ops/com/gfs/prod/gfs.$ymd
#  fi
#  export HOMEgfs=$LS_SUBCWD/..
  ;;
#
"THEIA")
#
  { save_shell_opts; set +x; } > /dev/null 2>&1

  . /apps/lmod/lmod/init/sh
  module use -a /scratch3/NCEPDEV/nwprod/lib/modulefiles
  module load intel/16.1.150 netcdf/4.3.0 hdf5/1.8.14 2>>/dev/null
  module list

  { restore_shell_opts; } > /dev/null 2>&1

  export DATA="$WORKDIR_ICBC_CDATE/ICs_work"
  export APRUNC="time"
  ulimit -s unlimited
  ulimit -a
  ;;
#
"JET")
#
  { save_shell_opts; set +x; } > /dev/null 2>&1

  . /apps/lmod/lmod/init/sh
  module purge
  module load newdefaults
  module load intel/15.0.3.187
  module load impi/5.1.1.109
  module load szip
  module load hdf5
  module load netcdf4/4.2.1.1
  module list

  { restore_shell_opts; } > /dev/null 2>&1

  export DATA="$WORKDIR_ICBC_CDATE/ICs_work"
  export APRUNC="time"
#  . $USHDIR/set_stack_limit_jet.sh
  ulimit -a
  ;;
#
"ODIN")
#
  export DATA="$WORKDIR_ICBC_CDATE/ICs_work"
  export APRUNC="srun -n 1"
  ulimit -s unlimited
  ulimit -a
  ;;
#
"CHEYENNE")
#
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

ln_vrfy -sf $WORKDIR_SHVE/${CRES}_grid.tile7.halo${HALO}.nc \
            $GRID_OROG_INPUT_DIR/${CRES}_grid.tile7.nc

ln_vrfy -sf $WORKDIR_SHVE/${CRES}_oro_data.tile7.halo${HALO}.nc \
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
$USHDIR/$chgres_driver_scr || print_err_msg_exit "\
Call to script that generates surface, initial condition, and 0-th hour
boundary condition files returned with nonzero exit code."
#
#-----------------------------------------------------------------------
#
# Print message indicating successful completion of script.
#
#-----------------------------------------------------------------------
#
print_info_msg "\

========================================================================
Surface fields file, initial conditions file, and 0-th hour boundary 
condition file generated successfully!!!
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




