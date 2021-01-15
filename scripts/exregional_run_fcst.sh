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
# Source other necessary files.
#
#-----------------------------------------------------------------------
#
. $USHDIR/create_model_configure_file.sh
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
valid_args=( \
"cdate" \
"cycle_dir" \
"ensmem_indx" \
"slash_ensmem_subdir" \
)
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

  "WCOSS_CRAY")
    ulimit -s unlimited
    ulimit -a

    if [ ${PE_MEMBER01} -gt 24 ];then
      APRUN="aprun -b -j1 -n${PE_MEMBER01} -N24 -d1 -cc depth"
    else
      APRUN="aprun -b -j1 -n24 -N24 -d1 -cc depth"
    fi
    ;;

  "WCOSS_DELL_P3")
    ulimit -s unlimited
    ulimit -a
    APRUN="mpirun -l -np ${PE_MEMBER01}"
    ;;

  "HERA")
    ulimit -s unlimited
    ulimit -a
    APRUN="srun"
    OMP_NUM_THREADS=4
    ;;

  "ORION")
    ulimit -s unlimited
    ulimit -a
    APRUN="srun"
    ;;

  "JET")
    ulimit -s unlimited
    ulimit -a
    APRUN="srun"
    OMP_NUM_THREADS=4
    ;;

  "ODIN")
    module list
    ulimit -s unlimited
    ulimit -a
    APRUN="srun -n ${PE_MEMBER01}"
    ;;

  "CHEYENNE")
    module list
    nprocs=$(( NNODES_RUN_FCST*PPN_RUN_FCST ))
    APRUN="mpirun -np $nprocs"
    ;;

  "STAMPEDE")
    module list
    APRUN="ibrun -np ${PE_MEMBER01}"
    ;;

  *)
    print_err_msg_exit "\
Run command has not been specified for this machine:
  MACHINE = \"$MACHINE\"
  APRUN = \"$APRUN\""
    ;;

esac
#
#-----------------------------------------------------------------------
#
# Set the forecast run directory.
#
#-----------------------------------------------------------------------
#
run_dir="${cycle_dir}${slash_ensmem_subdir}"
#
#-----------------------------------------------------------------------
#
# Create links in the INPUT subdirectory of the current run directory to
# the grid and (filtered) orography files.
#
#-----------------------------------------------------------------------
#
print_info_msg "$VERBOSE" "
Creating links in the INPUT subdirectory of the current run directory to
the grid and (filtered) orography files ..."


# Create links to fix files in the FIXLAM directory.


cd_vrfy ${run_dir}/INPUT

relative_or_null=""
if [ "${RUN_TASK_MAKE_GRID}" = "TRUE" ] && [ "${MACHINE}" != "WCOSS_CRAY" ]; then
  relative_or_null="--relative"
fi

# Symlink to mosaic file with a completely different name.
#target="${FIXLAM}/${CRES}${DOT_OR_USCORE}mosaic.halo${NH4}.nc"   # Should this point to this halo4 file or a halo3 file???
target="${FIXLAM}/${CRES}${DOT_OR_USCORE}mosaic.halo${NH3}.nc"   # Should this point to this halo4 file or a halo3 file???
symlink="grid_spec.nc"
if [ -f "${target}" ]; then
  ln_vrfy -sf ${relative_or_null} $target $symlink
else
  print_err_msg_exit "\
Cannot create symlink because target does not exist:
  target = \"$target\""
fi

## Symlink to halo-3 grid file with "halo3" stripped from name.
#target="${FIXLAM}/${CRES}${DOT_OR_USCORE}grid.tile${TILE_RGNL}.halo${NH3}.nc"
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

target="${FIXLAM}/${grid_fn}"
symlink="${grid_fn}"
if [ -f "${target}" ]; then
  ln_vrfy -sf ${relative_or_null} $target $symlink
else
  print_err_msg_exit "\
Cannot create symlink because target does not exist:
  target = \"$target\""
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
target="${FIXLAM}/${CRES}${DOT_OR_USCORE}grid.tile${TILE_RGNL}.halo${NH4}.nc"
symlink="grid.tile${TILE_RGNL}.halo${NH4}.nc"
if [ -f "${target}" ]; then
  ln_vrfy -sf ${relative_or_null} $target $symlink
else
  print_err_msg_exit "\
Cannot create symlink because target does not exist:
  target = \"$target\""
fi



relative_or_null=""
if [ "${RUN_TASK_MAKE_OROG}" = "TRUE" ] && [ "${MACHINE}" != "WCOSS_CRAY" ] ; then
  relative_or_null="--relative"
fi

# Symlink to halo-0 orography file with "${CRES}_" and "halo0" stripped from name.
target="${FIXLAM}/${CRES}${DOT_OR_USCORE}oro_data.tile${TILE_RGNL}.halo${NH0}.nc"
symlink="oro_data.nc"
if [ -f "${target}" ]; then
  ln_vrfy -sf ${relative_or_null} $target $symlink
else
  print_err_msg_exit "\
Cannot create symlink because target does not exist:
  target = \"$target\""
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
target="${FIXLAM}/${CRES}${DOT_OR_USCORE}oro_data.tile${TILE_RGNL}.halo${NH4}.nc"
symlink="oro_data.tile${TILE_RGNL}.halo${NH4}.nc"
if [ -f "${target}" ]; then
  ln_vrfy -sf ${relative_or_null} $target $symlink
else
  print_err_msg_exit "\
Cannot create symlink because target does not exist:
  target = \"$target\""
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
of the current run directory (run_dir), where
  run_dir = \"${run_dir}\"
..."

cd_vrfy ${run_dir}/INPUT
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
  target = \"$target\""
fi

target="sfc_data.tile${TILE_RGNL}.halo${NH0}.nc"
symlink="sfc_data.nc"
if [ -f "${target}" ]; then
  ln_vrfy -sf ${relative_or_null} $target $symlink
else
  print_err_msg_exit "\
Cannot create symlink because target does not exist:
  target = \"$target\""
fi
#
#-----------------------------------------------------------------------
#
# Create links in the current run directory to fixed (i.e. static) files
# in the FIXam directory.  These links have names that are set to the
# names of files that the forecast model expects to exist in the current
# working directory when the forecast model executable is called (and
# that is just the run directory).
#
#-----------------------------------------------------------------------
#
cd_vrfy ${run_dir}

print_info_msg "$VERBOSE" "
Creating links in the current run directory (run_dir) to fixed (i.e.
static) files in the FIXam directory:
  FIXam = \"${FIXam}\"
  run_dir = \"${run_dir}\""

relative_or_null=""
if [ "${RUN_ENVIR}" != "nco" ] && [ "${MACHINE}" != "WCOSS_CRAY" ] ; then
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

  symlink="${run_dir}/$symlink"
  target="$FIXam/$target"
  if [ -f "${target}" ]; then
    ln_vrfy -sf ${relative_or_null} $target $symlink
  else
    print_err_msg_exit "\
  Cannot create symlink because target does not exist:
    target = \"$target\""
  fi

done
#
#-----------------------------------------------------------------------
#
# If running this cycle/ensemble member combination more than once (e.g.
# using rocotoboot), remove any time stamp file that may exist from the
# previous attempt.
#
#-----------------------------------------------------------------------
#
cd_vrfy ${run_dir}
rm_vrfy -f time_stamp.out
#
#-----------------------------------------------------------------------
#
# Create links in the current run directory to cycle-independent (and
# ensemble-member-independent) model input files in the main experiment
# directory.
#
#-----------------------------------------------------------------------
#
print_info_msg "$VERBOSE" "
Creating links in the current run directory to cycle-independent model
input files in the main experiment directory..."

relative_or_null=""
if [ "${RUN_ENVIR}" != "nco" ] && [ "${MACHINE}" != "WCOSS_CRAY" ] ; then
  relative_or_null="--relative"
fi

ln_vrfy -sf ${relative_or_null} ${DATA_TABLE_FP} ${run_dir}
ln_vrfy -sf ${relative_or_null} ${FIELD_TABLE_FP} ${run_dir}
ln_vrfy -sf ${relative_or_null} ${NEMS_CONFIG_FP} ${run_dir}

if [ "${DO_ENSEMBLE}" = TRUE ]; then
  ln_vrfy -sf ${relative_or_null} "${FV3_NML_ENSMEM_FPS[$(( 10#${ensmem_indx}-1 ))]}" ${run_dir}/${FV3_NML_FN}
else
  ln_vrfy -sf ${relative_or_null} ${FV3_NML_FP} ${run_dir}
fi
#
#-----------------------------------------------------------------------
#
# Call the function that creates the model configuration file within each
# cycle directory.
#
#-----------------------------------------------------------------------
#
create_model_configure_file \
  cdate="$cdate" \
  nthreads=${OMP_NUM_THREADS:-1} \
  run_dir="${run_dir}" || print_err_msg_exit "\
Call to function to create a model configuration file for the current
cycle's (cdate) run directory (run_dir) failed:
  cdate = \"${cdate}\"
  run_dir = \"${run_dir}\""
#
#-----------------------------------------------------------------------
#
# If running ensemble forecasts, create a link to the cycle-specific
# diagnostic tables file in the cycle directory.  Note that this link
# should not be made if not running ensemble forecasts because in that
# case, the cycle directory is the run directory (and we would be creating
# a symlink with the name of a file that already exists).
#
#-----------------------------------------------------------------------
#
if [ "${DO_ENSEMBLE}" = "TRUE" ]; then
  if [ "${MACHINE}" = "WCOSS_CRAY" ]; then
    relative_or_null=""
  else
    relative_or_null="--relative"
  fi
  diag_table_fp="${cycle_dir}/${DIAG_TABLE_FN}"
  ln_vrfy -sf ${relative_or_null} ${diag_table_fp} ${run_dir}
fi
#
#-----------------------------------------------------------------------
#
# Set and export variables.
#
#-----------------------------------------------------------------------
#
export KMP_AFFINITY=scatter
export OMP_NUM_THREADS=${OMP_NUM_THREADS:-1} #Needs to be 1 for dynamic build of CCPP with GFDL fast physics, was 2 before.
export OMP_STACKSIZE=1024m

#
#-----------------------------------------------------------------------
#
# Run the FV3-LAM model.  Note that we have to launch the forecast from
# the current cycle's directory because the FV3 executable will look for
# input files in the current directory.  Since those files have been
# staged in the cycle directory, the current directory must be the cycle
# directory (which it already is).
#
#-----------------------------------------------------------------------
#
$APRUN ${FV3_EXEC_FP} || print_err_msg_exit "\
Call to executable to run FV3-LAM forecast returned with nonzero exit
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

