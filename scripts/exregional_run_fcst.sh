#!/bin/bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions script and the function definitions
# file.
#
#-----------------------------------------------------------------------
#
. ${GLOBAL_VAR_DEFNS_FP}
. $USHDIR/source_util_funcs.sh
#
#-----------------------------------------------------------------------
#
# Save current shell options (in a global array).  Then set new options
# for this script/function.
#
#-----------------------------------------------------------------------
#
{ save_shell_opts; set -u +x; } > /dev/null 2>&1
#
#-----------------------------------------------------------------------
#
# Get the full path to the file in which this script/function is located 
# (scrfunc_fp), the name of that file (scrfunc_fn), and the directory in
# which the file is located (scrfunc_dir).
#
#-----------------------------------------------------------------------
#
scrfunc_fp=$( readlink -f "${BASH_SOURCE[0]}" )
scrfunc_fn=$( basename "${scrfunc_fp}" )
scrfunc_dir=$( dirname "${scrfunc_fp}" )
#
#-----------------------------------------------------------------------
#
# Print message indicating entry into script.
#
#-----------------------------------------------------------------------
#
print_info_msg "
========================================================================
Entering script:  \"${scrfunc_fn}\"
In directory:     \"${scrfunc_dir}\"

This is the ex-script for the task that runs a forecast with FV3 for the
specified cycle.
========================================================================"
#
#-----------------------------------------------------------------------
#
# Specify the set of valid argument names for this script/function.  
# Then process the arguments provided to this script/function (which 
# should consist of a set of name-value pairs of the form arg1="value1",
# etc).
#
#-----------------------------------------------------------------------
#
valid_args=( "CYCLE_DIR" )
process_args valid_args "$@"
#
#-----------------------------------------------------------------------
#
# For debugging purposes, print out values of arguments passed to this
# script.  Note that these will be printed out only if VERBOSE is set to
# TRUE.
#
#-----------------------------------------------------------------------
#
print_input_args valid_args
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

  if [ "${USE_CCPP}" = "TRUE" ]; then
  
# Needed to change to the experiment directory because the module files
# for the CCPP-enabled version of FV3 have been copied to there.

    cd_vrfy ${CYCLE_DIR}
  
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
  APRUN="mpirun -l -np ${PE_MEMBER01}"
  ;;
#
"THEIA")
#

  if [ "${USE_CCPP}" = "TRUE" ]; then
  
# Need to change to the experiment directory to correctly load necessary 
# modules for CCPP-version of FV3SAR in lines below
    cd_vrfy ${EXPTDIR}
  
    set +x
    source ./module-setup.sh
    module use $( pwd -P )
    module load modules.fv3
    module load contrib wrap-mpi
    module list
    set -x
  
  else
  
    . /apps/lmod/lmod/init/sh
    module purge
    module use /scratch4/NCEPDEV/nems/noscrub/emc.nemspara/soft/modulefiles
    module load intel/16.1.150 impi/5.1.1.109 netcdf/4.3.0 
    module load contrib wrap-mpi 
    module list
  
  fi

  ulimit -s unlimited
  ulimit -a
  np=${SLURM_NTASKS}
  APRUN="mpirun -np ${np}"
  ;;
#
"HERA")
  ulimit -s unlimited
  ulimit -a
  APRUN="srun"
  LD_LIBRARY_PATH="${NEMSfv3gfs_DIR}/FV3/ccpp/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
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
  module load contrib wrap-mpi
  module list

#  . $USHDIR/set_stack_limit_jet.sh
  ulimit -s unlimited
  ulimit -a
  np=${SLURM_NTASKS}
  APRUN="mpirun -np ${np}"
  ;;
#
"ODIN")
#
  module list

  ulimit -s unlimited
  ulimit -a
  APRUN="srun -n ${PE_MEMBER01}"
  ;;
#
esac
#
#-----------------------------------------------------------------------
#
# Change location to the INPUT subdirectory of the current cycle's run 
# directory.
#
#-----------------------------------------------------------------------
#
#cd_vrfy ${CYCLE_DIR}/INPUT
#
#-----------------------------------------------------------------------
#
# Create links in the INPUT subdirectory of the current cycle's run di-
# rectory to the grid and (filtered) orography files.
#
#-----------------------------------------------------------------------
#
print_info_msg "$VERBOSE" "
Creating links in the INPUT subdirectory of the current cycle's run di-
rectory to the grid and (filtered) orography files ..."


# Create links to fix files in the FIXsar directory.


cd_vrfy ${CYCLE_DIR}/INPUT

relative_or_null=""
if [ "${RUN_TASK_MAKE_GRID}" = "TRUE" ]; then
  relative_or_null="--relative"
fi

# Symlink to mosaic file with a completely different name.
target="${FIXsar}/${CRES}_mosaic.nc"
if [ -f "${target}" ]; then
  ln_vrfy -sf ${relative_or_null} $target grid_spec.nc
else
  print_err_msg_exit "\
Cannot create symlink because target does not exist:
  target = \"$target}\""
fi

# Symlink to halo-3 grid file with "halo4" stripped from name.
target="${FIXsar}/${CRES}_grid.tile${TILE_RGNL}.halo${NH3_T7}.nc"
if [ -f "${target}" ]; then
  ln_vrfy -sf ${relative_or_null} $target ${CRES}_grid.tile${TILE_RGNL}.nc
else
  print_err_msg_exit "\
Cannot create symlink because target does not exist:
  target = \"$target}\""
fi

# Symlink to halo-4 grid file with "${CRES}_" stripped from name.
#
# If this link is not created, then the code hangs with an error message
# like this:
#
#   check netcdf status=           2
#  NetCDF error No such file or directory
# Stopped
#
# Note that even though the message says "Stopped", the task still con-
# sumes core-hours.
#
target="${FIXsar}/${CRES}_grid.tile${TILE_RGNL}.halo${NH4_T7}.nc"
if [ -f "${target}" ]; then
  ln_vrfy -sf $target ${relative_or_null} grid.tile${TILE_RGNL}.halo${NH4_T7}.nc
else
  print_err_msg_exit "\
Cannot create symlink because target does not exist:
  target = \"$target}\""
fi



relative_or_null=""
if [ "${RUN_TASK_MAKE_OROG}" = "TRUE" ]; then
  relative_or_null="--relative"
fi

# Symlink to halo-0 orography file with "${CRES}_" and "halo0" stripped from name.
target="${FIXsar}/${CRES}_oro_data.tile${TILE_RGNL}.halo${NH0_T7}.nc"
if [ -f "${target}" ]; then
  ln_vrfy -sf ${relative_or_null} $target oro_data.nc
else
  print_err_msg_exit "\
Cannot create symlink because target does not exist:
  target = \"$target}\""
fi

#
# Symlink to halo-4 orography file with "${CRES}_" stripped from name.
#
# If this link is not created, then the code hangs with an error message
# like this:
#
#   check netcdf status=           2
#  NetCDF error No such file or directory
# Stopped
#
# Note that even though the message says "Stopped", the task still con-
# sumes core-hours.
#
target="${FIXsar}/${CRES}_oro_data.tile${TILE_RGNL}.halo${NH4_T7}.nc"
if [ -f "${target}" ]; then
  ln_vrfy -sf $target ${relative_or_null} oro_data.tile${TILE_RGNL}.halo${NH4_T7}.nc
else
  print_err_msg_exit "\
Cannot create symlink because target does not exist:
  target = \"$target}\""
fi


#
#-----------------------------------------------------------------------
#
# The FV3 model looks for the following files in the INPUT subdirectory
# of the run directory:
#
#   gfs_data.nc
#   sfc_data.nc
#   gfs_bndy*.nc
#   gfs_ctrl.nc
#
# Some of these files (gfs_ctrl.nc, gfs_bndy*.nc) already exist, but 
# others do not.  Thus, create links with these names to the appropriate
# files (in this case the initial condition and surface files only).
#
#-----------------------------------------------------------------------
#
print_info_msg "$VERBOSE" "
Creating links with names that FV3 looks for in the INPUT subdirectory
of the current cycle's run directory (CYCLE_DIR)..."

cd_vrfy ${CYCLE_DIR}/INPUT
ln_vrfy -sf gfs_data.tile${TILE_RGNL}.halo${NH0_T7}.nc gfs_data.nc
ln_vrfy -sf sfc_data.tile${TILE_RGNL}.halo${NH0_T7}.nc sfc_data.nc
#
#-----------------------------------------------------------------------
#
# Create links in the current cycle's run directory to "fix" files in 
# the main experiment directory.
#
#-----------------------------------------------------------------------
#
cd_vrfy ${CYCLE_DIR}

print_info_msg "$VERBOSE" "
Creating links in the current cycle's run directory to static (fix) 
files in the FIXam directory..."
#
# If running in "nco" mode, FIXam is simply a symlink under the workflow
# directory that points to the system directory containing the fix 
# files.  The files in this system directory are named as listed in the
# FIXam_FILES_SYSDIR array.  Thus, that is the array to use to form the
# names of the link targets, but the names of the symlinks themselves
# must be as specified in the FIXam_FILES_EXPTDIR array (because that 
# array contains the file names that FV3 looks for).
#
if [ "${RUN_ENVIR}" = "nco" ]; then

  for (( i=0; i<${NUM_FIXam_FILES}; i++ )); do
    ln_vrfy -sf $FIXam/${FIXam_FILES_SYSDIR[$i]} ${CYCLE_DIR}/${FIXam_FILES_EXPTDIR[$i]}
  done
#
# If not running in "nco" mode, FIXam is an actual directory (not a sym-
# link) in the experiment directory that contains the same files as the
# system fix directory except that the files have renamed to the file
# names that FV3 looks for.  Thus, when creating links to the files in
# this directory, both the target and symlink names should be the ones
# specified in the FIXam_FILES_EXPTDIR array (because that array con-
# tains the file names that FV3 looks for).
#
else

  for (( i=0; i<${NUM_FIXam_FILES}; i++ )); do
    ln_vrfy -sf --relative $FIXam/${FIXam_FILES_EXPTDIR[$i]} ${CYCLE_DIR}
  done

fi
#
#-----------------------------------------------------------------------
#
# If running this cycle more than once (e.g. using rocotoboot), remove
# any time stamp file that may exist from the previous attempt.
#
#-----------------------------------------------------------------------
#
cd_vrfy ${CYCLE_DIR}
rm_vrfy -f time_stamp.out
#
#-----------------------------------------------------------------------
#
# Create links in the current cycle's run directory to cycle-independent
# model input files in the main experiment directory.
#
#-----------------------------------------------------------------------
#
print_info_msg "$VERBOSE" "
Creating links in the current cycle's run directory to cycle-independent
model input files in the main experiment directory..."

ln_vrfy -sf -t ${CYCLE_DIR} $EXPTDIR/${FV3_NML_FN}
ln_vrfy -sf -t ${CYCLE_DIR} $EXPTDIR/${DATA_TABLE_FN}
ln_vrfy -sf -t ${CYCLE_DIR} $EXPTDIR/${FIELD_TABLE_FN}
ln_vrfy -sf -t ${CYCLE_DIR} $EXPTDIR/${NEMS_CONFIG_FN}

if [ "${USE_CCPP}" = "TRUE" ]; then
  if [ "${CCPP_PHYS_SUITE}" = "GSD" ]; then
    ln_vrfy -sf -t ${CYCLE_DIR} $EXPTDIR/suite_FV3_GSD_v0.xml
  elif [ "${CCPP_PHYS_SUITE}" = "GFS" ]; then
    ln_vrfy -sf -t ${CYCLE_DIR} $EXPTDIR/suite_FV3_GFS_2017_gfdlmp.xml
  fi
  if [ "${CCPP_PHYS_SUITE}" = "GSD" ]; then
    ln_vrfy -sf -t ${CYCLE_DIR} $EXPTDIR/CCN_ACTIVATE.BIN
  fi
fi
#
#-----------------------------------------------------------------------
#
# Copy templates of cycle-dependent model input files from the templates
# directory to the current cycle's run directory.
#
#-----------------------------------------------------------------------
#
print_info_msg "$VERBOSE" "
Copying cycle-independent model input files from the templates directory 
to the current cycle's run directory..." 

cp_vrfy ${TEMPLATE_DIR}/${MODEL_CONFIG_FN} ${CYCLE_DIR}

if [ "${USE_CCPP}" = "TRUE" ]; then
  if [ "${CCPP_PHYS_SUITE}" = "GFS" ]; then
    cp_vrfy ${TEMPLATE_DIR}/${DIAG_TABLE_FN} ${CYCLE_DIR}
  elif [ "${CCPP_PHYS_SUITE}" = "GSD" ]; then
    cp_vrfy ${TEMPLATE_DIR}/${DIAG_TABLE_CCPP_GSD_FN} ${CYCLE_DIR}/${DIAG_TABLE_FN}
  fi
else
  cp_vrfy ${TEMPLATE_DIR}/${DIAG_TABLE_FN} ${CYCLE_DIR}
fi
#
#-----------------------------------------------------------------------
#
# Extract from CDATE the starting year, month, day, and hour of the
# forecast.  These are needed below for various operations.
#
#-----------------------------------------------------------------------
#
YYYY=${CDATE:0:4}
MM=${CDATE:4:2}
DD=${CDATE:6:2}
HH=${CDATE:8:2}
YYYYMMDD=${CDATE:0:8}
#
#-----------------------------------------------------------------------
#
# Set the full path to the model configuration file.  Then set parame-
# ters in that file.
#
#-----------------------------------------------------------------------
#
MODEL_CONFIG_FP="${CYCLE_DIR}/${MODEL_CONFIG_FN}"

print_info_msg "$VERBOSE" "
Setting parameters in file:
  MODEL_CONFIG_FP = \"${MODEL_CONFIG_FP}\""

dot_quilting_dot="."${QUILTING,,}"."

set_file_param "${MODEL_CONFIG_FP}" "PE_MEMBER01" "${PE_MEMBER01}"
set_file_param "${MODEL_CONFIG_FP}" "dt_atmos" "${DT_ATMOS}"
set_file_param "${MODEL_CONFIG_FP}" "start_year" "$YYYY"
set_file_param "${MODEL_CONFIG_FP}" "start_month" "$MM"
set_file_param "${MODEL_CONFIG_FP}" "start_day" "$DD"
set_file_param "${MODEL_CONFIG_FP}" "start_hour" "$HH"
set_file_param "${MODEL_CONFIG_FP}" "nhours_fcst" "${FCST_LEN_HRS}"
set_file_param "${MODEL_CONFIG_FP}" "ncores_per_node" "${NCORES_PER_NODE}"
set_file_param "${MODEL_CONFIG_FP}" "quilting" "${dot_quilting_dot}"
set_file_param "${MODEL_CONFIG_FP}" "print_esmf" "${PRINT_ESMF}"
#
#-----------------------------------------------------------------------
#
# If the write component is to be used, then a set of parameters, in-
# cluding those that define the write component's output grid, need to
# be specified in the model configuration file (MODEL_CONFIG_FP).  This
# is done by appending a template file (in which some write-component
# parameters are set to actual values while others are set to placehol-
# ders) to MODEL_CONFIG_FP and then replacing the placeholder values in
# the (new) MODEL_CONFIG_FP file with actual values.  The full path of
# this template file is specified in the variable WRTCMP_PA RAMS_TEMP-
# LATE_FP.
#
#-----------------------------------------------------------------------
#
if [ "$QUILTING" = "TRUE" ]; then

  cat ${WRTCMP_PARAMS_TEMPLATE_FP} >> ${MODEL_CONFIG_FP}

  set_file_param "${MODEL_CONFIG_FP}" "write_groups" "$WRTCMP_write_groups"
  set_file_param "${MODEL_CONFIG_FP}" "write_tasks_per_group" "$WRTCMP_write_tasks_per_group"

  set_file_param "${MODEL_CONFIG_FP}" "output_grid" "\'$WRTCMP_output_grid\'"
  set_file_param "${MODEL_CONFIG_FP}" "cen_lon" "$WRTCMP_cen_lon"
  set_file_param "${MODEL_CONFIG_FP}" "cen_lat" "$WRTCMP_cen_lat"
  set_file_param "${MODEL_CONFIG_FP}" "lon1" "$WRTCMP_lon_lwr_left"
  set_file_param "${MODEL_CONFIG_FP}" "lat1" "$WRTCMP_lat_lwr_left"

  if [ "${WRTCMP_output_grid}" = "rotated_latlon" ]; then
    set_file_param "${MODEL_CONFIG_FP}" "lon2" "$WRTCMP_lon_upr_rght"
    set_file_param "${MODEL_CONFIG_FP}" "lat2" "$WRTCMP_lat_upr_rght"
    set_file_param "${MODEL_CONFIG_FP}" "dlon" "$WRTCMP_dlon"
    set_file_param "${MODEL_CONFIG_FP}" "dlat" "$WRTCMP_dlat"
  elif [ "${WRTCMP_output_grid}" = "lambert_conformal" ]; then
    set_file_param "${MODEL_CONFIG_FP}" "stdlat1" "$WRTCMP_stdlat1"
    set_file_param "${MODEL_CONFIG_FP}" "stdlat2" "$WRTCMP_stdlat2"
    set_file_param "${MODEL_CONFIG_FP}" "nx" "$WRTCMP_nx"
    set_file_param "${MODEL_CONFIG_FP}" "ny" "$WRTCMP_ny"
    set_file_param "${MODEL_CONFIG_FP}" "dx" "$WRTCMP_dx"
    set_file_param "${MODEL_CONFIG_FP}" "dy" "$WRTCMP_dy"
  fi

fi
#
#-----------------------------------------------------------------------
#
# Set the full path to the file that specifies the fields to output.
# Then set parameters in that file.
#
#-----------------------------------------------------------------------
#
DIAG_TABLE_FP="${CYCLE_DIR}/${DIAG_TABLE_FN}"

print_info_msg "$VERBOSE" "
Setting parameters in file:
  DIAG_TABLE_FP = \"${DIAG_TABLE_FP}\""

set_file_param "${DIAG_TABLE_FP}" "CRES" "$CRES"
set_file_param "${DIAG_TABLE_FP}" "YYYY" "$YYYY"
set_file_param "${DIAG_TABLE_FP}" "MM" "$MM"
set_file_param "${DIAG_TABLE_FP}" "DD" "$DD"
set_file_param "${DIAG_TABLE_FP}" "HH" "$HH"
set_file_param "${DIAG_TABLE_FP}" "YYYYMMDD" "$YYYYMMDD"
#
#-----------------------------------------------------------------------
#
# Copy the FV3SAR executable to the run directory.
#
#-----------------------------------------------------------------------
#
if [ "${USE_CCPP}" = "TRUE" ]; then
  FV3SAR_EXEC="${NEMSfv3gfs_DIR}/tests/fv3.exe"
else
  FV3SAR_EXEC="${NEMSfv3gfs_DIR}/tests/fv3_32bit.exe"
fi

if [ -f $FV3SAR_EXEC ]; then
  print_info_msg "$VERBOSE" "
Copying the FV3SAR executable to the run directory..."
  cp_vrfy ${FV3SAR_EXEC} ${CYCLE_DIR}/fv3_gfs.x
else
  print_err_msg_exit "\
The FV3SAR executable specified in FV3SAR_EXEC does not exist:
  FV3SAR_EXEC = \"$FV3SAR_EXEC\"
Build FV3SAR and rerun."
fi
#
#-----------------------------------------------------------------------
#
# Set and export variables.
#
#-----------------------------------------------------------------------
#
export KMP_AFFINITY=scatter
export OMP_NUM_THREADS=1 #Needs to be 1 for dynamic build of CCPP with GFDL fast physics, was 2 before.
export OMP_STACKSIZE=1024m
#
#-----------------------------------------------------------------------
#
# Run the FV3SAR model.  Note that we have to launch the forecast from
# the current cycle's run directory because the FV3 executable will look
# for input files in the current directory.  Since those files have been 
# staged in the run directory, the current directory must be the run di-
# rectory (which it already is).
#
#-----------------------------------------------------------------------
#
$APRUN ./fv3_gfs.x || print_err_msg_exit "\
Call to executable to run FV3SAR forecast returned with nonzero exit 
code."
#
#-----------------------------------------------------------------------
#
# Print message indicating successful completion of script.
#
#-----------------------------------------------------------------------
#
print_info_msg "
========================================================================
FV3 forecast completed successfully!!!

Exiting script:  \"${scrfunc_fn}\"
In directory:    \"${scrfunc_dir}\"
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

