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
. $USHDIR/set_FV3nml_stoch_params.sh
#
#-----------------------------------------------------------------------
#
# Source other necessary files.
#
#-----------------------------------------------------------------------
#
. $USHDIR/create_model_configure_file.sh
. $USHDIR/create_diag_table_file.sh
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
# Set OpenMP variables.
#
#-----------------------------------------------------------------------
#
export KMP_AFFINITY=${KMP_AFFINITY_RUN_FCST}
export OMP_NUM_THREADS=${OMP_NUM_THREADS_RUN_FCST}
export OMP_STACKSIZE=${OMP_STACKSIZE_RUN_FCST}
#
#-----------------------------------------------------------------------
#
# Load modules.
#
#-----------------------------------------------------------------------
#
case "$MACHINE" in

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

#
# For experiments in which the MAKE_GRID_TN task is run, we make the 
# symlinks to the grid files relative because those files wlll be located 
# within the experiment directory.  This keeps the experiment directory 
# more portable and the symlinks more readable.  However, for experiments 
# in which the MAKE_GRID_TN task is not run, pregenerated grid files will
# be used, and those will be located in an arbitrary directory (specified 
# by the user) that is somwehere outside the experiment directory.  Thus, 
# in this case, there isn't really an advantage to using relative symlinks, 
# so we use symlinks with absolute paths.
#
if [ "${RUN_TASK_MAKE_GRID}" = "TRUE" ]; then
  relative_link_flag="TRUE"
else
  relative_link_flag="FALSE"
fi

# Symlink to mosaic file with a completely different name.
#target="${FIXLAM}/${CRES}${DOT_OR_USCORE}mosaic.halo${NH4}.nc"   # Should this point to this halo4 file or a halo3 file???
target="${FIXLAM}/${CRES}${DOT_OR_USCORE}mosaic.halo${NH3}.nc"   # Should this point to this halo4 file or a halo3 file???
symlink="grid_spec.nc"
create_symlink_to_file target="$target" symlink="$symlink" \
                       relative="${relative_link_flag}"

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
create_symlink_to_file target="$target" symlink="$symlink" \
                       relative="${relative_link_flag}"

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
create_symlink_to_file target="$target" symlink="$symlink" \
                       relative="${relative_link_flag}"


#
# As with the symlinks grid files above, when creating the symlinks to
# the orography files, use relative paths if running the MAKE_OROG_TN
# task and absolute paths otherwise.
#
if [ "${RUN_TASK_MAKE_OROG}" = "TRUE" ]; then
  relative_link_flag="TRUE"
else
  relative_link_flag="FALSE"
fi

# Symlink to halo-0 orography file with "${CRES}_" and "halo0" stripped from name.
target="${FIXLAM}/${CRES}${DOT_OR_USCORE}oro_data.tile${TILE_RGNL}.halo${NH0}.nc"
symlink="oro_data.nc"
create_symlink_to_file target="$target" symlink="$symlink" \
                       relative="${relative_link_flag}"
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
create_symlink_to_file target="$target" symlink="$symlink" \
                       relative="${relative_link_flag}"
#
# If using the FV3_HRRR physics suite, there are two files (that contain 
# statistics of the orography) that are needed by the gravity wave drag 
# parameterization in that suite.  Below, create symlinks to these files
# in the run directory.  Note that the symlinks must have specific names 
# that the FV3 model is hardcoded to recognize, and those are the names 
# we use below.
#
if [ "${CCPP_PHYS_SUITE}" = "FV3_HRRR" ]; then

  fileids=( "ss" "ls" )
  for fileid in "${fileids[@]}"; do
    target="${FIXLAM}/${CRES}${DOT_OR_USCORE}oro_data_${fileid}.tile${TILE_RGNL}.halo${NH0}.nc"
    symlink="oro_data_${fileid}.nc"
    create_symlink_to_file target="$target" symlink="$symlink" \
                           relative="${relative_link_flag}"
  done

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
#
# The symlinks to be created point to files in the same directory (INPUT),
# so it's most straightforward to use relative paths.
#
relative_link_flag="TRUE"

target="gfs_data.tile${TILE_RGNL}.halo${NH0}.nc"
symlink="gfs_data.nc"
create_symlink_to_file target="$target" symlink="$symlink" \
                       relative="${relative_link_flag}"

target="sfc_data.tile${TILE_RGNL}.halo${NH0}.nc"
symlink="sfc_data.nc"
create_symlink_to_file target="$target" symlink="$symlink" \
                       relative="${relative_link_flag}"
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
#
# For experiments that are run in "community" mode, the FIXam directory
# is an actual directory (i.e. not a symlink) located under the experiment 
# directory containing actual files (i.e. not symlinks).  In this case,
# we use relative paths for the symlinks in order to keep the experiment
# directory more portable and the symlinks more readable.  However, for
# experiments that are run in "nco" mode, the FIXam directory is a symlink
# under the experiment directory that points to an arbitrary (user specified)
# location outside the experiment directory.  Thus, in this case, there 
# isn't really an advantage to using relative symlinks, so we use symlinks 
# with absolute paths.
#
if [ "${RUN_ENVIR}" != "nco" ]; then
  relative_link_flag="TRUE"
else
  relative_link_flag="FALSE"
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
  create_symlink_to_file target="$target" symlink="$symlink" \
                         relative="${relative_link_flag}"

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
#
# For experiments that are run in "community" mode, the model input files
# to which the symlinks will point are under the experiment directory.
# Thus, in this case, we use relative paths for the symlinks in order to 
# keep the experiment directory more portable and the symlinks more readable.  
# However, for experiments that are run in "nco" mode, the experiment
# directory in which the model input files are located is in general 
# completely different than the run directory in which the symlinks will
# be created.  Thus, in this case, there isn't really an advantage to 
# using relative symlinks, so we use symlinks with absolute paths.
#
if [ "${RUN_ENVIR}" != "nco" ]; then
  relative_link_flag="TRUE"
else
  relative_link_flag="FALSE"
fi

create_symlink_to_file target="${DATA_TABLE_FP}" \
                       symlink="${run_dir}/${DATA_TABLE_FN}" \
                       relative="${relative_link_flag}"

create_symlink_to_file target="${FIELD_TABLE_FP}" \
                       symlink="${run_dir}/${FIELD_TABLE_FN}" \
                       relative="${relative_link_flag}"

create_symlink_to_file target="${NEMS_CONFIG_FP}" \
                       symlink="${run_dir}/${NEMS_CONFIG_FN}" \
                       relative="${relative_link_flag}"

create_symlink_to_file target="${FIELD_DICT_FP}" \
                       symlink="${run_dir}/${FIELD_DICT_FN}" \
                       relative="${relative_link_flag}"

if [ ${WRITE_DOPOST} = "TRUE" ]; then
  cp_vrfy ${EMC_POST_DIR}/parm/nam_micro_lookup.dat ./eta_micro_lookup.dat
  if [ ${USE_CUSTOM_POST_CONFIG_FILE} = "TRUE" ]; then
    post_config_fp="${CUSTOM_POST_CONFIG_FP}"
    print_info_msg "
====================================================================
  CUSTOM_POST_CONFIG_FP = \"${CUSTOM_POST_CONFIG_FP}\"
===================================================================="
  else
    post_config_fp="${EMC_POST_DIR}/parm/postxconfig-NT-fv3lam.txt"
    print_info_msg "
====================================================================
  post_config_fp = \"${post_config_fp}\"
===================================================================="
  fi
  cp_vrfy ${post_config_fp} ./postxconfig-NT_FH00.txt
  cp_vrfy ${post_config_fp} ./postxconfig-NT.txt
  cp_vrfy ${EMC_POST_DIR}/parm/params_grib2_tbl_new .
fi

if [ "${DO_ENSEMBLE}" = TRUE ]; then
  set_FV3nml_stoch_params cdate="$cdate" || print_err_msg_exit "\
Call to function to create the ensemble-based namelist for the current
cycle's (cdate) run directory (run_dir) failed:
  cdate = \"${cdate}\"
  run_dir = \"${run_dir}\""
else
  create_symlink_to_file target="${FV3_NML_FP}" \
                         symlink="${run_dir}/${FV3_NML_FN}" \
                         relative="${relative_link_flag}"
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
  nthreads=${OMP_NUM_THREADS} \
  run_dir="${run_dir}" \
  sub_hourly_post="${SUB_HOURLY_POST}" \
  dt_subhourly_post_mnts="${DT_SUBHOURLY_POST_MNTS}" \
  dt_atmos="${DT_ATMOS}" || print_err_msg_exit "\
Call to function to create a model configuration file for the current
cycle's (cdate) run directory (run_dir) failed:
  cdate = \"${cdate}\"
  run_dir = \"${run_dir}\""
#
#-----------------------------------------------------------------------
#
# Call the function that creates the diag_table file within each cycle 
# directory.
#
#-----------------------------------------------------------------------
#
create_diag_table_file \
  run_dir="${run_dir}" || print_err_msg_exit "\
Call to function to create a diag table file for the current cycle's 
(cdate) run directory (run_dir) failed:
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
  create_symlink_to_file target="${cycle_dir}/${DIAG_TABLE_FN}" \
                         symlink="${run_dir}/${DIAG_TABLE_FN}" \
                         relative="${relative_link_flag}"
fi
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
# If doing inline post, create the directory in which the post-processing 
# output will be stored (postprd_dir).
#
#-----------------------------------------------------------------------
#
if [ ${WRITE_DOPOST} = "TRUE" ]; then

  yyyymmdd=${cdate:0:8}
  hh=${cdate:8:2}
  cyc=$hh
  tmmark="tm00"
  fmn="00"

  if [ "${RUN_ENVIR}" = "nco" ]; then
    COMOUT="${COMOUT_BASEDIR}/$RUN.$PDY/$cyc${SLASH_ENSMEM_SUBDIR}"
    postprd_dir="$COMOUT"
  else
    postprd_dir="${run_dir}/postprd"
  fi
  mkdir_vrfy -p "${postprd_dir}"

  cd_vrfy ${postprd_dir}

  for fhr in $(seq -f "%03g" 0 ${FCST_LEN_HRS}); do

    if [ ${fhr:0:1} = "0" ]; then
      fhr_d=${fhr:1:2}
    else
      fhr_d=${fhr}
    fi

    post_time=$( date --utc --date "${yyyymmdd} ${hh} UTC + ${fhr_d} hours + ${fmn} minutes" "+%Y%m%d%H%M" )
    post_mn=${post_time:10:2}
    post_mn_or_null=""
    post_fn_suffix="GrbF${fhr_d}"
    post_renamed_fn_suffix="f${fhr}${post_mn_or_null}.${tmmark}.grib2"

    basetime=$( date --date "$yyyymmdd $hh" +%y%j%H%M )
    symlink_suffix="_${basetime}f${fhr}${post_mn}"
    fids=( "bgdawp" "bgrd3d" )
    for fid in "${fids[@]}"; do
      FID="${fid^^}"
      post_orig_fn="${FID}.${post_fn_suffix}"
      post_renamed_fn="${NET}.t${cyc}z.${fid}${post_renamed_fn_suffix}"
      mv_vrfy ${run_dir}/${post_orig_fn} ${post_renamed_fn}
      ln_vrfy -fs ${post_renamed_fn} ${FID}${symlink_suffix}
    done
  done

fi
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

