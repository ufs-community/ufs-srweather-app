#!/bin/bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
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
"HERA")
  ulimit -s unlimited
  ulimit -a
  APRUN="srun"
  LD_LIBRARY_PATH="${UFS_WTHR_MDL_DIR}/FV3/ccpp/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
  ;;
#
"JET")
  ulimit -s unlimited
  ulimit -a
  APRUN="srun"
  LD_LIBRARY_PATH="${UFS_WTHR_MDL_DIR}/FV3/ccpp/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
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
"CHEYENNE")
#
  module list
  nprocs=$(( NNODES_RUN_FCST*PPN_RUN_FCST ))
  APRUN="mpirun -np $nprocs"
  LD_LIBRARY_PATH="${UFS_WTHR_MDL_DIR}/FV3/ccpp/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
  ;;
#
esac
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
#target="${FIXsar}/${CRES}${DOT_OR_USCORE}mosaic.halo${NH4}.nc"   # Should this point to this halo4 file or a halo3 file???
target="${FIXsar}/${CRES}${DOT_OR_USCORE}mosaic.halo${NH3}.nc"   # Should this point to this halo4 file or a halo3 file???
symlink="grid_spec.nc"
if [ -f "${target}" ]; then
  ln_vrfy -sf ${relative_or_null} $target $symlink
else
  print_err_msg_exit "\
Cannot create symlink because target does not exist:
  target = \"$target}\""
fi

## Symlink to halo-3 grid file with "halo3" stripped from name.
#target="${FIXsar}/${CRES}${DOT_OR_USCORE}grid.tile${TILE_RGNL}.halo${NH3}.nc"
#if [ "${RUN_TASK_MAKE_SFC_CLIMO}" = "TRUE" ] && \
#   [ "${GRID_GEN_METHOD}" = "GFDLgrid" ] && \
#   [ "${GFDLgrid_USE_GFDLgrid_RES_IN_FILENAMES}" = "FALSE" ]; then
#  symlink="C${GFDLgrid_RES}${DOT_OR_USCORE}grid.tile${TILE_RGNL}.nc"
#else
#  symlink="${CRES}${DOT_OR_USCORE}grid.tile${TILE_RGNL}.nc"
#fi

# Symlink to halo-3 grid file with "halo3" stripped from name.
mosaic_fn="grid_spec.nc"
grid_fn=$( get_charvar_from_netcdf "${mosaic_fn}" "gridfiles" )

target="${FIXsar}/${grid_fn}"
symlink="${grid_fn}"
if [ -f "${target}" ]; then
  ln_vrfy -sf ${relative_or_null} $target $symlink
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
target="${FIXsar}/${CRES}${DOT_OR_USCORE}grid.tile${TILE_RGNL}.halo${NH4}.nc"
symlink="grid.tile${TILE_RGNL}.halo${NH4}.nc"
if [ -f "${target}" ]; then
  ln_vrfy -sf ${relative_or_null} $target $symlink
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
target="${FIXsar}/${CRES}${DOT_OR_USCORE}oro_data.tile${TILE_RGNL}.halo${NH0}.nc"
symlink="oro_data.nc"
if [ -f "${target}" ]; then
  ln_vrfy -sf ${relative_or_null} $target $symlink
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
target="${FIXsar}/${CRES}${DOT_OR_USCORE}oro_data.tile${TILE_RGNL}.halo${NH4}.nc"
symlink="oro_data.tile${TILE_RGNL}.halo${NH4}.nc"
if [ -f "${target}" ]; then
  ln_vrfy -sf ${relative_or_null} $target $symlink
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
#ln_vrfy -sf gfs_data.tile${TILE_RGNL}.halo${NH0}.nc gfs_data.nc
#ln_vrfy -sf sfc_data.tile${TILE_RGNL}.halo${NH0}.nc sfc_data.nc

relative_or_null=""

target="gfs_data.tile${TILE_RGNL}.halo${NH0}.nc"
symlink="gfs_data.nc"
if [ -f "${target}" ]; then
  ln_vrfy -sf ${relative_or_null} $target $symlink
else
  print_err_msg_exit "\
Cannot create symlink because target does not exist:
  target = \"$target}\""
fi

target="sfc_data.tile${TILE_RGNL}.halo${NH0}.nc"
symlink="sfc_data.nc"
if [ -f "${target}" ]; then
  ln_vrfy -sf ${relative_or_null} $target $symlink
else
  print_err_msg_exit "\
Cannot create symlink because target does not exist:
  target = \"$target}\""
fi
#
#-----------------------------------------------------------------------
#
# Create links in the current cycle directory to fixed (i.e. static) files
# in the FIXam directory.  These links have names that are set to the 
# names of files that the forecast model expects to exist in the current
# working directory when the forecast model executable is called (and 
# that is just the cycle directory).
#
#-----------------------------------------------------------------------
#
cd_vrfy ${CYCLE_DIR}

print_info_msg "$VERBOSE" "
Creating links in the current cycle directory (CYCLE_DIR) to fixed (i.e.
static) files in the FIXam directory:
  FIXam = \"${FIXam}\"
  CYCLE_DIR = \"${CYCLE_DIR}\""

relative_or_null=""
if [ "${RUN_ENVIR}" != "nco" ]; then
  relative_or_null="--relative"
fi

regex_search="^[ ]*([^| ]+)[ ]*[|][ ]*([^| ]+)[ ]*$"
num_symlinks=${#CYCLEDIR_LINKS_TO_FIXam_FILES_MAPPING[@]}
for (( i=0; i<${num_symlinks}; i++ )); do

  mapping="${CYCLEDIR_LINKS_TO_FIXam_FILES_MAPPING[$i]}"
  symlink=$( printf "%s\n" "$mapping" | \
             sed -n -r -e "s/${regex_search}/\1/p" )
  target=$( printf "%s\n" "$mapping" | \
            sed -n -r -e "s/${regex_search}/\2/p" )

  symlink="${CYCLE_DIR}/$symlink"
  target="$FIXam/$target"
  if [ -f "${target}" ]; then
    ln_vrfy -sf ${relative_or_null} $target $symlink
  else
    print_err_msg_exit "\
  Cannot create symlink because target does not exist:
    target = \"$target}\""
  fi

done
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

relative_or_null=""
if [ "${RUN_ENVIR}" != "nco" ]; then
  relative_or_null="--relative"
fi

ln_vrfy -sf ${relative_or_null} ${DATA_TABLE_FP} ${CYCLE_DIR}
ln_vrfy -sf ${relative_or_null} ${FIELD_TABLE_FP} ${CYCLE_DIR}
ln_vrfy -sf ${relative_or_null} ${FV3_NML_FP} ${CYCLE_DIR}
ln_vrfy -sf ${relative_or_null} ${NEMS_CONFIG_FP} ${CYCLE_DIR}

if [ "${USE_CCPP}" = "TRUE" ]; then

  ln_vrfy -sf ${relative_or_null} ${CCPP_PHYS_SUITE_FP} ${CYCLE_DIR} 

  if [ "${CCPP_PHYS_SUITE}" = "FV3_GSD_v0" ] || \
     [ "${CCPP_PHYS_SUITE}" = "FV3_GSD_SAR_v1" ] || \
     [ "${CCPP_PHYS_SUITE}" = "FV3_GSD_SAR" ]; then
    ln_vrfy -sf ${relative_or_null} $EXPTDIR/CCN_ACTIVATE.BIN ${CYCLE_DIR}
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
Copying cycle-dependent model input files from the templates directory 
to the current cycle's run directory..." 

print_info_msg "$VERBOSE" "
  Copying the template diagnostics table file to the current cycle's run
  directory..."
diag_table_fp="${CYCLE_DIR}/${DIAG_TABLE_FN}"
cp_vrfy "${DIAG_TABLE_TMPL_FP}" "${diag_table_fp}"

print_info_msg "$VERBOSE" "
  Copying the template model configuration file to the current cycle's
  run directory..."
model_config_fp="${CYCLE_DIR}/${MODEL_CONFIG_FN}"
cp_vrfy "${MODEL_CONFIG_TMPL_FP}" "${model_config_fp}"
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
# Set parameters in the diagnostics table file.
#
#-----------------------------------------------------------------------
#
print_info_msg "$VERBOSE" "
Setting parameters in file:
  diag_table_fp = \"${diag_table_fp}\""

set_file_param "${diag_table_fp}" "CRES" "$CRES"
set_file_param "${diag_table_fp}" "YYYY" "$YYYY"
set_file_param "${diag_table_fp}" "MM" "$MM"
set_file_param "${diag_table_fp}" "DD" "$DD"
set_file_param "${diag_table_fp}" "HH" "$HH"
set_file_param "${diag_table_fp}" "YYYYMMDD" "$YYYYMMDD"
#
#-----------------------------------------------------------------------
#
# Set parameters in the model configuration file.
#
#-----------------------------------------------------------------------
#
print_info_msg "$VERBOSE" "
Setting parameters in file:
  model_config_fp = \"${model_config_fp}\""

dot_quilting_dot="."${QUILTING,,}"."
dot_print_esmf_dot="."${PRINT_ESMF,,}"."

set_file_param "${model_config_fp}" "PE_MEMBER01" "${PE_MEMBER01}"
set_file_param "${model_config_fp}" "dt_atmos" "${DT_ATMOS}"
set_file_param "${model_config_fp}" "start_year" "$YYYY"
set_file_param "${model_config_fp}" "start_month" "$MM"
set_file_param "${model_config_fp}" "start_day" "$DD"
set_file_param "${model_config_fp}" "start_hour" "$HH"
set_file_param "${model_config_fp}" "nhours_fcst" "${FCST_LEN_HRS}"
set_file_param "${model_config_fp}" "ncores_per_node" "${NCORES_PER_NODE}"
set_file_param "${model_config_fp}" "quilting" "${dot_quilting_dot}"
set_file_param "${model_config_fp}" "print_esmf" "${dot_print_esmf_dot}"
#
#-----------------------------------------------------------------------
#
# If the write component is to be used, then a set of parameters, in-
# cluding those that define the write component's output grid, need to
# be specified in the model configuration file (model_config_fp).  This
# is done by appending a template file (in which some write-component
# parameters are set to actual values while others are set to placehol-
# ders) to model_config_fp and then replacing the placeholder values in
# the (new) model_config_fp file with actual values.  The full path of
# this template file is specified in the variable WRTCMP_PA RAMS_TEMP-
# LATE_FP.
#
#-----------------------------------------------------------------------
#
if [ "$QUILTING" = "TRUE" ]; then

  cat ${WRTCMP_PARAMS_TMPL_FP} >> ${model_config_fp}

  set_file_param "${model_config_fp}" "write_groups" "$WRTCMP_write_groups"
  set_file_param "${model_config_fp}" "write_tasks_per_group" "$WRTCMP_write_tasks_per_group"

  set_file_param "${model_config_fp}" "output_grid" "\'$WRTCMP_output_grid\'"
  set_file_param "${model_config_fp}" "cen_lon" "$WRTCMP_cen_lon"
  set_file_param "${model_config_fp}" "cen_lat" "$WRTCMP_cen_lat"
  set_file_param "${model_config_fp}" "lon1" "$WRTCMP_lon_lwr_left"
  set_file_param "${model_config_fp}" "lat1" "$WRTCMP_lat_lwr_left"

  if [ "${WRTCMP_output_grid}" = "rotated_latlon" ]; then
    set_file_param "${model_config_fp}" "lon2" "$WRTCMP_lon_upr_rght"
    set_file_param "${model_config_fp}" "lat2" "$WRTCMP_lat_upr_rght"
    set_file_param "${model_config_fp}" "dlon" "$WRTCMP_dlon"
    set_file_param "${model_config_fp}" "dlat" "$WRTCMP_dlat"
  elif [ "${WRTCMP_output_grid}" = "lambert_conformal" ]; then
    set_file_param "${model_config_fp}" "stdlat1" "$WRTCMP_stdlat1"
    set_file_param "${model_config_fp}" "stdlat2" "$WRTCMP_stdlat2"
    set_file_param "${model_config_fp}" "nx" "$WRTCMP_nx"
    set_file_param "${model_config_fp}" "ny" "$WRTCMP_ny"
    set_file_param "${model_config_fp}" "dx" "$WRTCMP_dx"
    set_file_param "${model_config_fp}" "dy" "$WRTCMP_dy"
  elif [ "${WRTCMP_output_grid}" = "regional_latlon" ]; then
    set_file_param "${model_config_fp}" "lon2" "$WRTCMP_lon_upr_rght"
    set_file_param "${model_config_fp}" "lat2" "$WRTCMP_lat_upr_rght"
    set_file_param "${model_config_fp}" "dlon" "$WRTCMP_dlon"
    set_file_param "${model_config_fp}" "dlat" "$WRTCMP_dlat"
  fi

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
# the current cycle's directory because the FV3 executable will look for 
# input files in the current directory.  Since those files have been 
# staged in the cycle directory, the current directory must be the cycle
# directory (which it already is).
#
#-----------------------------------------------------------------------
#
$APRUN ${FV3_EXEC_FP} || print_err_msg_exit "\
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

