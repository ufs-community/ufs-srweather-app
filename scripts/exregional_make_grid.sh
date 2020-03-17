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
. $USHDIR/constants.sh
. $USHDIR/link_fix.sh
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

This is the ex-script for the task that generates grid files.
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
valid_args=( "WORKDIR_LOCAL" )
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
# Set the file name of the script to use for generating the grid files 
# and the name of the executable file used to "shave" (i.e. remove the 
# halo from) certain grid files.
#
#-----------------------------------------------------------------------
#
grid_gen_scr="fv3gfs_make_grid.sh"
shave_exec="shave.x"
#
#-----------------------------------------------------------------------
#
# The orography code runs with threads.  On Cray, the code is optimized
# for six threads.  Do not change.
# Note that OMP_NUM_THREADS and OMP_STACKSIZE only affect the threaded   <== I don't think this is true.  Remove??
# executions on Cray; they don't affect executions on theia.
#
#-----------------------------------------------------------------------
#
export OMP_NUM_THREADS=6
export OMP_STACKSIZE=2048m
#
#-----------------------------------------------------------------------
#
# Load modules and set various computational parameters and directories.
#
# topo_dir specifies the directory in which input files needed for gene-
# rating the orography (topography) files are located.
#
#-----------------------------------------------------------------------
#
case $MACHINE in


"WCOSS_C" | "WCOSS")
#
  { save_shell_opts; set +x; } > /dev/null 2>&1

  . $MODULESHOME/init/sh
  module load PrgEnv-intel cfp-intel-sandybridge/1.1.0
  module list

  { restore_shell_opts; } > /dev/null 2>&1

  export NODES=1
  export APRUN="aprun -n 1 -N 1 -j 1 -d 1 -cc depth"
  export KMP_AFFINITY=disabled
  export topo_dir="/gpfs/hps/emc/global/noscrub/emc.glopara/svn/fv3gfs/fix/fix_orog"

  ulimit -s unlimited
  ulimit -a
  ;;


"HERA")
#
#  { save_shell_opts; set +x; } > /dev/null 2>&1
#
#  . /apps/lmod/lmod/init/sh
#  module purge
#  module load intel/18.0.5.274
##  module load netcdf/4.6.1
##  module load hdf5/1.10.4
#  module load netcdf/4.7.0
#  module load hdf5/1.10.5
#  module list
#
#  { restore_shell_opts; } > /dev/null 2>&1
#
#  export APRUN="time"
  export APRUN="time"
  topo_dir="/scratch1/NCEPDEV/global/glopara/fix/fix_orog"
#
#  ulimit -s unlimited
#  ulimit -a
  ;;
#

"JET")

  export APRUN="time"
  topo_dir="/lfs3/projects/hpc-wof1/ywang/regional_fv3/fix/fix_orog"
  ;;


"ODIN")
#
  export APRUN="srun -n 1"
  export topo_dir="/scratch/ywang/fix/theia_fix/fix_orog"

  ulimit -s unlimited
  ulimit -a
  ;;


esac
#
#-----------------------------------------------------------------------
#
# Set and export the variable exec_dir.  This is needed by some of the 
# scripts called by this script.
#
#-----------------------------------------------------------------------
#
export exec_dir="$EXECDIR"
#
#-----------------------------------------------------------------------
#
# Create the (cycle-independent) subdirectories under the experiment di-
# rectory (EXPTDIR) that are needed by the various steps and substeps in
# this script.
#
#-----------------------------------------------------------------------
#
check_for_preexist_dir ${GRID_DIR} ${PREEXISTING_DIR_METHOD}
mkdir_vrfy -p "${GRID_DIR}"

tmpdir="${GRID_DIR}/tmp"
mkdir_vrfy -p "$tmpdir"
#
#-----------------------------------------------------------------------
#
# Generate grid files.
#
# The following will create 7 grid files (one per tile, where the 7th
# "tile" is the grid that covers the regional domain) named
#
#   ${CRES}_grid.tileN.nc for N=1,...,7.
#
# It will also create a mosaic file named ${CRES}_mosaic.nc that con-
# tains information only about tile 7 (i.e. it does not have any infor-
# mation on how tiles 1 through 6 are connected or that tile 7 is within
# tile 6).  All these files will be placed in the directory specified by
# GRID_DIR.  Note that the file for tile 7 will include a halo of width
# NHW cells.
#
# Since tiles 1 through 6 are not needed to run the FV3SAR model and are
# not used later on in any other preprocessing steps, it is not clear
# why they are generated.  It might be because it is not possible to di-
# rectly generate a standalone regional grid using the make_hgrid uti-
# lity/executable that grid_gen_scr calls, i.e. it might be because with
# make_hgrid, one has to either create just the 6 global tiles or create
# the 6 global tiles plus the regional (tile 7), and then for the case
# of a regional simulation (i.e. GTYPE="regional", which is always the
# case here) just not use the 6 global tiles.
#
# The grid_gen_scr script called below takes its next-to-last argument
# and passes it as an argument to the --halo flag of the make_hgrid uti-
# lity/executable.  make_hgrid then checks that a regional (or nested)
# grid of size specified by the arguments to its --istart_nest, --iend_-
# nest, --jstart_nest, and --jend_nest flags with a halo around it of
# size specified by the argument to the --halo flag does not extend be-
# yond the boundaries of the parent grid (tile 6).  In this case, since
# the values passed to the --istart_nest, ..., and --jend_nest flags al-
# ready include a halo (because these arguments are 
#
#   ${ISTART_OF_RGNL_DOM_WITH_WIDE_HALO_ON_T6SG}, 
#   ${IEND_OF_RGNL_DOM_WITH_WIDE_HALO_ON_T6SG}, 
#   ${JSTART_OF_RGNL_DOM_WITH_WIDE_HALO_ON_T6SG}, and
#   ${JEND_OF_RGNL_DOM_WITH_WIDE_HALO_ON_T6SG}, 
#
# i.e. they include "WITH_WIDE_HALO_" in their names), it is reasonable
# to pass as the argument to --halo a zero.  However, make_hgrid re-
# quires that the argument to --halo be at least 1, so below, we pass a
# 1 as the next-to-last argument to grid_gen_scr.
#
# More information on make_hgrid:
# ------------------------------
#
# The grid_gen_scr called below in turn calls the make_hgrid executable
# as follows:
#
#   make_hgrid \
#   --grid_type gnomonic_ed \
#   --nlon 2*${RES} \
#   --grid_name C${RES}_grid \
#   --do_schmidt --stretch_factor ${STRETCH_FAC} \
#   --target_lon ${LON_CTR} 
#   --target_lat ${LAT_CTR} \
#   --nest_grid --parent_tile 6 --refine_ratio ${GFDLgrid_REFINE_RATIO} \
#   --istart_nest ${ISTART_OF_RGNL_DOM_WITH_WIDE_HALO_ON_T6SG} \
#   --jstart_nest ${JSTART_OF_RGNL_DOM_WITH_WIDE_HALO_ON_T6SG} \
#   --iend_nest ${IEND_OF_RGNL_DOM_WITH_WIDE_HALO_ON_T6SG} \
#   --jend_nest ${JEND_OF_RGNL_DOM_WITH_WIDE_HALO_ON_T6SG} \
#   --halo ${NH3} \
#   --great_circle_algorithm
#
# This creates the 7 grid files ${CRES}_grid.tileN.nc for N=1,...,7.
# The 7th file ${CRES}_grid.tile7.nc represents the regional grid, and
# the extents of the arrays in that file do not seem to include a halo,
# i.e. they are based only on the values passed via the four flags
#
#   --istart_nest ${ISTART_OF_RGNL_DOM_WITH_WIDE_HALO_ON_T6SG}
#   --jstart_nest ${JSTART_OF_RGNL_DOM_WITH_WIDE_HALO_ON_T6SG}
#   --iend_nest ${IEND_OF_RGNL_DOM_WITH_WIDE_HALO_ON_T6SG}
#   --jend_nest ${JEND_OF_RGNL_DOM_WITH_WIDE_HALO_ON_T6SG}
#
# According to Rusty Benson of GFDL, the flag
#
#   --halo ${NH3}
#
# only checks to make sure that the nested or regional grid combined
# with the specified halo lies completely within the parent tile.  If
# so, make_hgrid issues a warning and exits.  Thus, the --halo flag is
# not meant to be used to add a halo region to the nested or regional
# grid whose limits are specified by the flags --istart_nest, --iend_-
# nest, --jstart_nest, and --jend_nest.
#
# Note also that make_hgrid has an --out_halo option that, according to
# the documentation, is meant to output extra halo cells around the
# nested or regional grid boundary in the file generated by make_hgrid.
# However, according to Rusty Benson of GFDL, this flag was originally
# created for a special purpose and is limited to only outputting at
# most 1 extra halo point.  Thus, it should not be used.
#
#-----------------------------------------------------------------------
#
print_info_msg "$VERBOSE" "
Starting grid file generation..."

tile_rgnl=7
res=""
#
#-----------------------------------------------------------------------
#
# Consider a GFDLgrid-type of grid.
#
#-----------------------------------------------------------------------
#
if [ "${GRID_GEN_METHOD}" = "GFDLgrid" ]; then

  $USHDIR/${grid_gen_scr} \
    ${GFDLgrid_RES} \
    $tmpdir \
    ${STRETCH_FAC} ${LON_CTR} ${LAT_CTR} ${GFDLgrid_REFINE_RATIO} \
    ${ISTART_OF_RGNL_DOM_WITH_WIDE_HALO_ON_T6SG} \
    ${JSTART_OF_RGNL_DOM_WITH_WIDE_HALO_ON_T6SG} \
    ${IEND_OF_RGNL_DOM_WITH_WIDE_HALO_ON_T6SG} \
    ${JEND_OF_RGNL_DOM_WITH_WIDE_HALO_ON_T6SG} \
    1 $USHDIR || \
  print_err_msg_exit "\
Call to script that generates grid files returned with nonzero exit 
code."

  if [ "${GFDLgrid_USE_GFDLgrid_RES_IN_FILENAMES}" = "TRUE" ]; then

    res=${GFDLgrid_RES}
    CRES="C$res"

  else

    grid_fp="$tmpdir/C${GFDLgrid_RES}_grid.tile${tile_rgnl}.nc"
    $EXECDIR/global_equiv_resol "${grid_fp}" || \
    print_err_msg_exit "\
Call to executable that calculates equivalent global uniform cubed 
sphere resolution returned with nonzero exit code."

    res=$( ncdump -h "${grid_fp}" | grep -o ":RES_equiv = [0-9]\+" | grep -o "[0-9]" ) || \
    print_err_msg_exit "\
Attempt to extract the equivalent global uniform cubed-sphere grid reso-
lution from the file specified by grid_fp faild:
  grid_fp = \"${grid_fp}\""
    res=${res//$'\n'/}
    CRES="C$res"

    grid_fp_orig="${grid_fp}"
    grid_fp="$tmpdir/${CRES}_grid.tile${tile_rgnl}.nc"
    mv_vrfy ${grid_fp_orig} ${grid_fp}

    mosaic_fp_orig="$tmpdir/C${GFDLgrid_RES}_mosaic.nc"
    mosaic_fp="$tmpdir/${CRES}_mosaic.nc"
    mv_vrfy ${mosaic_fp_orig} ${mosaic_fp}

  fi

printf "%s\n" "res = $res"
printf "%s\n" "CRES = $CRES"
#
#-----------------------------------------------------------------------
#
# Consider a JPgrid-type of grid.
#
#-----------------------------------------------------------------------
#
elif [ "${GRID_GEN_METHOD}" = "JPgrid" ]; then
#
# Copy the template namelist file for the JPgrid-type grid generation
# code to the temporary subdirectory.  Then replace the placeholders in
# that file with actual values.
#
  rgnl_grid_nml_fp="$tmpdir/${RGNL_GRID_NML_FN}"
  cp_vrfy ${TEMPLATE_DIR}/${RGNL_GRID_NML_FN} ${rgnl_grid_nml_fp}

  print_info_msg "$VERBOSE" "
Setting parameters in file:
  rgnl_grid_nml_fp = \"${rgnl_grid_nml_fp}\""

  set_file_param "${rgnl_grid_nml_fp}" "plon" "${LON_CTR}"
  set_file_param "${rgnl_grid_nml_fp}" "plat" "${LAT_CTR}"
  set_file_param "${rgnl_grid_nml_fp}" "delx" "${DEL_ANGLE_X_SG}"
  set_file_param "${rgnl_grid_nml_fp}" "dely" "${DEL_ANGLE_Y_SG}"
  set_file_param "${rgnl_grid_nml_fp}" "lx" "${NEG_NX_OF_DOM_WITH_WIDE_HALO}"
  set_file_param "${rgnl_grid_nml_fp}" "ly" "${NEG_NY_OF_DOM_WITH_WIDE_HALO}"
  set_file_param "${rgnl_grid_nml_fp}" "a" "${JPgrid_ALPHA_PARAM}"
  set_file_param "${rgnl_grid_nml_fp}" "k" "${JPgrid_KAPPA_PARAM}"

  cd_vrfy $tmpdir

  $EXECDIR/regional_grid ${rgnl_grid_nml_fp} || \
  print_err_msg_exit "\
Call to executable that generates grid file (Jim Purser version) re-
turned with nonzero exit code."

  grid_fp="$tmpdir/regional_grid.nc"
  $EXECDIR/global_equiv_resol "${grid_fp}" || \
  print_err_msg_exit "\
Call to executable that calculates equivalent global uniform cubed 
sphere resolution returned with nonzero exit code."

  res=$( ncdump -h "${grid_fp}" | grep -o ":RES_equiv = [0-9]\+" | grep -o "[0-9]" ) || \
  print_err_msg_exit "\
Attempt to extract the equivalent global uniform cubed-sphere grid reso-
lution from the file specified by grid_fp faild:
  grid_fp = \"${grid_fp}\""
  res=${res//$'\n'/}
  CRES="C$res"

  grid_fp_orig="${grid_fp}"
  grid_fp="$tmpdir/${CRES}_grid.tile${tile_rgnl}.nc"
  mv_vrfy ${grid_fp_orig} ${grid_fp}

printf "%s\n" "res = $res"
printf "%s\n" "CRES = $CRES"
#
# Create a grid mosaic file that relates the tiles of the cubed-sphere
# grid.  Note that there are no "tiles" in the case of a JPgrid-type 
# grid, but this file must nevertheless exist because the forecast mo-
# del code looks for it.
#
  $EXECDIR/mosaic_file $CRES || \
  print_err_msg_exit "\
Call to executable that creates a grid mosaic file returned with nonzero
exit code."

fi
#
#-----------------------------------------------------------------------
#
# If there are pre-existing orography or climatology files we will be 
# using (i.e. if RUN_TASK_MAKE_OROG or RUN_TASK_MAKE_SURF_CLIMO is set
# to "FALSE", in which case RES_IN_FIXSAR_FILENAMES will not be set to a
# null string), check that the grid resolution (res) calculated above 
# matches the resolution appearing in the names of the preexisting oro-
# graphy or surface climatology files.
#
#-----------------------------------------------------------------------
#
if [ ! -z "${RES_IN_FIXSAR_FILENAMES}" ]; then
  if [ "$res" -ne "${RES_IN_FIXSAR_FILENAMES}" ]; then
    print_err_msg_exit "\
The resolution (res) calculated for the grid does not match the resolu-
tion (RES_IN_FIXSAR_FILENAMES) appearing in the names of the orography 
and/or surface climatology files:
  res = $res
  RES_IN_FIXSAR_FILENAMES = \"${RES_IN_FIXSAR_FILENAMES}\""
  fi
fi
#
#-----------------------------------------------------------------------
#
# Set CRES in the variable definitions file.
#
#-----------------------------------------------------------------------
#
set_file_param "${GLOBAL_VAR_DEFNS_FP}" "CRES" "\"$CRES\""
#
#-----------------------------------------------------------------------
#
# For clarity, rename the tile 7 grid file such that its new name con-
# tains the halo size.  Then create a link whose name doesn't contain
# the halo size that points to this file.
#
#-----------------------------------------------------------------------
#
cd_vrfy $tmpdir
mv_vrfy ${CRES}_grid.tile${TILE_RGNL}.nc \
        ${CRES}_grid.tile${TILE_RGNL}.halo${NHW}.nc
mv_vrfy ${CRES}_mosaic.nc ${GRID_DIR}
cd_vrfy -

print_info_msg "$VERBOSE" "
Grid file generation complete."
#
#-----------------------------------------------------------------------
#
# Partially "shave" the halo from the grid file having a wide halo to 
# to generate two new grid files -- one with a 3-grid-wide halo and ano-
# ther with a 4-cell-wide halo.  These are needed as inputs by FV3 as 
# well as by the chgres_cube code to generate lateral boundary condition
# files.  
# also sfc_climo???
#
#-----------------------------------------------------------------------
#

#
# Set the full path to the "unshaved" grid file, i.e. the one with a 
# wide halo.  This is the input grid file for generating both the grid
# file with a 3-cell-wide halo and the one with a 4-cell-wide halo.
#
unshaved_fp="$tmpdir/${CRES}_grid.tile${TILE_RGNL}.halo${NHW}.nc"
#
# We perform the work in tmpdir, so change location to that directory.  
# Once it is complete, we move the resultant file from tmpdir to GRID_-
# DIR.
#
cd_vrfy $tmpdir
#
# Create an input namelist file for the shave executable to generate a
# grid file with a 3-cell-wide halo from the one with a wide halo.  Then 
# call the shave executable.  Finally, move the resultant file to the 
# GRID_DIR directory.
#
print_info_msg "$VERBOSE" "
\"Shaving\" grid file with wide halo to obtain grid file with ${NH3}-cell-wide
halo..."

nml_fn="input.shave.grid.halo${NH3}"
shaved_fp="${tmpdir}/${CRES}_grid.tile${TILE_RGNL}.halo${NH3}.nc"
printf "%s %s %s %s %s\n" \
  $NX $NY ${NH3} \"${unshaved_fp}\" \"${shaved_fp}\" \
  > ${nml_fn}

$APRUN $EXECDIR/${shave_exec} < ${nml_fn} || \
print_err_msg_exit "\
Call to executable \"${shave_exec}\" to generate a grid file with a ${NH3}-cell-wide
halo returned with nonzero exit code.  The namelist file nml_fn is in 
directory tmpdir: 
  tmpdir = \"${tmpdir}\"
  nml_fn = \"${nml_fn}\""
mv_vrfy ${shaved_fp} ${GRID_DIR}
#
# Create an input namelist file for the shave executable to generate an
# grid file with a 4-cell-wide halo from the one with a wide halo.  Then 
# call the shave executable.  Finally, move the resultant file to the 
# GRID_DIR directory.
#
print_info_msg "$VERBOSE" "
\"Shaving\" grid file with wide halo to obtain grid file with ${NH4}-cell-wide
halo..."

nml_fn="input.shave.grid.halo${NH4}"
shaved_fp="${tmpdir}/${CRES}_grid.tile${TILE_RGNL}.halo${NH4}.nc"
printf "%s %s %s %s %s\n" \
  $NX $NY ${NH4} \"${unshaved_fp}\" \"${shaved_fp}\" \
  > ${nml_fn}

$APRUN $EXECDIR/${shave_exec} < ${nml_fn} || \
print_err_msg_exit "\
Call to executable \"${shave_exec}\" to generate a grid file with a ${NH4}-cell-wide
halo returned with nonzero exit code.  The namelist file nml_fn is in 
directory tmpdir: 
  tmpdir = \"${tmpdir}\"
  nml_fn = \"${nml_fn}\""
mv_vrfy ${shaved_fp} ${GRID_DIR}
#
# Change location back to the directory before tmpdir.
#
cd_vrfy -
#
#-----------------------------------------------------------------------
#
# Create link in GRID_DIR to the grid file with 4-cell-wide halos such
# that the link name does not contain the halo width.  This link is 
# needed by the make_orog task (and possibly others).
#
#-----------------------------------------------------------------------
#
link_fix \
  verbose="$VERBOSE" \
  file_group="grid" || \
print_err_msg_exit "\
Call to function to create links to grid files failed."
#
#-----------------------------------------------------------------------
#
# Print message indicating successful completion of script.
#
#-----------------------------------------------------------------------
#
print_info_msg "
========================================================================
Grid files with various halo widths generated successfully!!!

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



