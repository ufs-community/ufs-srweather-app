#!/bin/bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions script and the function definitions
# file.
#
#-----------------------------------------------------------------------
#
. $SCRIPT_VAR_DEFNS_FP
. $USHDIR/source_funcs.sh
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
# Set the script name and print out an informational message informing
# the user that we've entered this script.
#
#-----------------------------------------------------------------------
#
script_name=$( basename "$0" )
print_info_msg "\n\
========================================================================
Entering script:  \"${script_name}\"
This is the ex-script for the task that generates surface fields from
climatology.
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
valid_args=( "workdir" )
process_args valid_args "$@"

# If VERBOSE is set to TRUE, print out what each valid argument has been
# set to.
if [ "$VERBOSE" = "TRUE" ]; then
  num_valid_args="${#valid_args[@]}"
  print_info_msg "\n\
The arguments to script/function \"${script_name}\" have been set as 
follows:
"
  for (( i=0; i<$num_valid_args; i++ )); do
    line=$( declare -p "${valid_args[$i]}" )
    printf "  $line\n"
  done
fi
#
#-----------------------------------------------------------------------
#
# Are these machine dependent??
#
#-----------------------------------------------------------------------
#
ulimit -s unlimited
#ulimit -a
#
#-----------------------------------------------------------------------
#
# Change location to the temporary directory.
#
#-----------------------------------------------------------------------
#
cd_vrfy $workdir
#
#-----------------------------------------------------------------------
#
# Set the tile number(s).  The stand-alone regional and global nest are 
# assumed to be tile 7.
#
#-----------------------------------------------------------------------
#
if [[ "$gtype" == "nest" ]] || [[ "$gtype" == "regional" ]]; then
  tiles=("7")
else
  tiles=("1" "2" "3" "4" "5" "6")
fi

prefix="\"${CRES}_oro_data.tile"
#prefix="\"${CRES}.oro_data.tile"
orog_fns=( "${tiles[@]/#/$prefix}" )
suffix=".nc\""
orog_fns=( "${orog_fns[@]/%/$suffix}" )
#
#-----------------------------------------------------------------------
#
# In the directory specified for the namelist variable orog_dir_mdl 
# (which here is set to ${OROG_DIR}; see below), the make_sfc_climo code
# expects there to be a grid file named 
#
#   ${CRES}_grid.tile${tile_num}.nc
#
# for each orography file in that directory named
#
#   ${CRES}_oro_data.tile${tile_num}.nc
#
# where tile_num is the tile number (in our case, tile_num = 7 only).
# Thus, we now create a link in OROG_DIR pointing to the corresponding
# grid file in GRID_DIR.  Note that we the sfc_climo code will be work-
# ing with halo-4 files only.
#
#-----------------------------------------------------------------------
#
grid_fn="${CRES}_grid.tile7.nc"
ln_vrfy -fs --relative ${GRID_DIR}/${grid_fn} ${OROG_DIR}/${grid_fn} 

# Add links in shave directory to the grid and orography files with 4-
# cell-wide halos such that the link names do not contain the halo
# width.  These links are needed by the make_sfc_climo task (which uses
# the sfc_climo_gen code).
#
# NOTE: It would be nice to modify the sfc_climo_gen_code to read in
# files that have the halo size in their names.

tile=7

#ln_vrfy -sf --relative \
#  ${GRID_DIR}/${CRES}_grid.tile${tile}.halo${nh4_T7}.nc \
#  ${OROG_DIR}/${CRES}_grid.tile${tile}.nc

ln_vrfy -fs --relative \
  ${OROG_DIR}/${CRES}_oro_data.tile${tile}.halo${nh4_T7}.nc \
  ${OROG_DIR}/${CRES}_oro_data.tile${tile}.nc
#
#-----------------------------------------------------------------------
#
# Create the namelist that the sfc_climo_gen code will read in.
#
# Question: Should this instead be created from a template file?
#
#-----------------------------------------------------------------------
#
cat << EOF > ./fort.41
&config
input_facsf_file="${SFC_CLIMO_INPUT_DIR}/facsf.1.0.nc"
input_substrate_temperature_file="${SFC_CLIMO_INPUT_DIR}/substrate_temperature.2.6x1.5.nc"
input_maximum_snow_albedo_file="${SFC_CLIMO_INPUT_DIR}/maximum_snow_albedo.0.05.nc"
input_snowfree_albedo_file="${SFC_CLIMO_INPUT_DIR}/snowfree_albedo.4comp.0.05.nc"
input_slope_type_file="${SFC_CLIMO_INPUT_DIR}/slope_type.1.0.nc"
input_soil_type_file="${SFC_CLIMO_INPUT_DIR}/soil_type.statsgo.0.05.nc"
input_vegetation_type_file="${SFC_CLIMO_INPUT_DIR}/vegetation_type.igbp.0.05.nc"
input_vegetation_greenness_file="${SFC_CLIMO_INPUT_DIR}/vegetation_greenness.0.144.nc"
mosaic_file_mdl="${GRID_DIR}/${CRES}_mosaic.nc"
orog_dir_mdl="${OROG_DIR}"
orog_files_mdl=${orog_fns}
halo=${nh4_T7}
maximum_snow_albedo_method="bilinear"
snowfree_albedo_method="bilinear"
vegetation_greenness_method="bilinear"
/
EOF
#
#-----------------------------------------------------------------------
#
# Set the run machine-dependent run command.
#
#-----------------------------------------------------------------------
#
case $MACHINE in

"WCOSS_C")
# This could be wrong.  Just a guess since I don't have access to this machine.
  APRUN_SFC=${APRUN_SFC:-"aprun -j 1 -n 6 -N 6"}
  ;;

"WCOSS")
# This could be wrong.  Just a guess since I don't have access to this machine.
  APRUN_SFC=${APRUN_SFC:-"aprun -j 1 -n 6 -N 6"}
  ;;

"THEIA")
# Need to load intel/15.1.133.  This and all other module loads should go into a module file.
  module load intel/15.1.133
  module list
  APRUN_SFC="mpirun -np ${SLURM_NTASKS}"
  ;;

"HERA")
  module purge
  module load intel/18.0.5.274
  module load impi/2018.0.4
  module load netcdf/4.6.1
  module use /scratch1/NCEPDEV/nems/emc.nemspara/soft/modulefiles
  module load esmf/7.1.0r
  module contrib wrap-mpi
  module list
  APRUN_SFC="mpirun -np ${SLURM_NTASKS}"
  ;;

*)
  print_err_msg_exit "${script_name}" "\
Run command has not been specified for this machine:
  MACHINE = \"$MACHINE\"
  APRUN_SFC = \"$APRUN_SFC\""
  ;;

esac
#
#-----------------------------------------------------------------------
#
# Run the code.
#
#-----------------------------------------------------------------------
#
$APRUN_SFC ${EXECDIR}/sfc_climo_gen || print_err_msg_exit "${script_name}" "\
Call to executable that generates surface climatology files returned 
with nonzero exit code."
#
#-----------------------------------------------------------------------
#
# Move output files out of the temporary directory.
#
#-----------------------------------------------------------------------
#
case "$gtype" in

#
# Consider, global, stetched, and nested grids.
#
"global" | "stretch" | "nested")
#
# Move all files ending with ".nc" to the SFC_CLIMO_DIR directory.
# In the process, rename them so that the file names start with the C-
# resolution (followed by an underscore).
#
  for fn in *.nc; do
    if [[ -f $fn ]]; then
      mv_vrfy $fn ${SFC_CLIMO_DIR}/${CRES}_${fn}
    fi
  done
  ;;

#
# Consider regional grids.
#
"regional")
#
# Move all files ending with ".halo.nc" (which are the files for a grid
# that includes the specified non-zero-width halo) to the WORKDIR_SFC_-
# CLIMO directory.  In the process, rename them so that the file names
# start with the C-resolution (followed by a dot) and contain the (non-
# zero) halo width (in units of number of grid cells).
#
  for fn in *.halo.nc; do
    if [ -f $fn ]; then
      bn="${fn%.halo.nc}"
      mv_vrfy $fn ${SFC_CLIMO_DIR}/${CRES}.${bn}.halo${nh4_T7}.nc
    fi
  done
#
# Move all remaining files ending with ".nc" (which are the files for a
# grid that doesn't include a halo) to the SFC_CLIMO_DIR directory.  
# In the process, rename them so that the file names start with the C-
# resolution (followed by a dot) and contain the string "halo0" to indi-
# cate that the grids in these files do not contain a halo.
#
  for fn in *.nc; do
    if [ -f $fn ]; then
      bn="${fn%.nc}"
      mv_vrfy $fn ${SFC_CLIMO_DIR}/${CRES}.${bn}.halo${nh0_T7}.nc
    fi
  done
  ;;

esac
#
#-----------------------------------------------------------------------
#
# Can these be moved to stage_static if this script is called before
# stage_static.sh????
# These have been moved.  Can delete the following after testing.
#
#-----------------------------------------------------------------------
#
#cd_vrfy ${SFC_CLIMO_DIR}
#
#suffix=".halo${nh4_T7}.nc"
#for fn in *${suffix}; do
#  bn="${fn%.halo${nh4_T7}.nc}"
#  ln_vrfy -fs ${bn}${suffix} ${bn}.nc
#done
#
#-----------------------------------------------------------------------
#
# 
#
#-----------------------------------------------------------------------
#
cd_vrfy ${SFC_CLIMO_DIR}
fn_pattern="${CRES}.*.nc"
sfc_climo_files=$( ls -1 $fn_pattern ) || print_err_msg_exit "${script_name}" "\
The \"ls\" command returned with a nonzero exit status."
#
# Place the list of surface climatology files in an array.
#
file_list=()
i=0
while read crnt_file; do
  file_list[$i]="${crnt_file}"
  i=$((i+1))
done <<< "${sfc_climo_files}"
#
# Create symlinks in the FIXsar directory to the surface climatology files.
#
#cd $FIXsar
for fn in "${file_list[@]}"; do
#
# Check that each target file exists before attempting to create sym-
# links.  This is because the "ln" command will create symlinks to non-
# existent targets without returning with a nonzero exit code.
#
  if [ -f "${SFC_CLIMO_DIR}/$fn" ]; then
# Should links be made relative or absolute?  Maybe relative in community
# mode and absolute in nco mode?
    if [ "${RUN_ENVIR}" = "nco" ]; then
      ln_vrfy -sf ${SFC_CLIMO_DIR}/$fn $FIXsar
    else
      ln_vrfy --relative -sf ${SFC_CLIMO_DIR}/$fn $FIXsar
    fi
  else
    print_err_msg_exit "${script_name}" "\
Cannot create symlink because target file (fn) in directory SFC_CLIMO_DIR
does not exist:
  SFC_CLIMO_DIR = \"${SFC_CLIMO_DIR}\"
  fn = \"${fn}\""
  fi

done
#
#-----------------------------------------------------------------------
#
# Create symlinks in the INPUT subdirectory of the experiment directory 
# to the halo-4 surface climatology files such that the link names do 
# not include a string specifying the halo width (e.g. "halo##", where 
# ## is the halo width in units of grid cells).  These links may be 
# needed by the chgres_cube code.
#
#-----------------------------------------------------------------------
#
cd_vrfy $FIXsar
suffix=".halo${nh4_T7}.nc"
for fn in *${suffix}; do
  bn="${fn%.halo${nh4_T7}.nc}"
  ln_vrfy -fs ${bn}${suffix} ${bn}.nc
done

#
#-----------------------------------------------------------------------
#
# GSK 20190430:
# This is to make rocoto aware that the make_sfc_climo task has completed
# (so that other tasks can be launched).  This should be done through 
# rocoto's dependencies, but not sure how to do it yet.
#
#-----------------------------------------------------------------------
#
cd_vrfy $EXPTDIR
touch "make_sfc_climo_files_task_complete.txt"
#
#-----------------------------------------------------------------------
#
# Print message indicating successful completion of script.
#
#-----------------------------------------------------------------------
#
print_info_msg "\n\
========================================================================
All surface climatology files generated successfully!!!
Exiting script:  \"${script_name}\"
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
