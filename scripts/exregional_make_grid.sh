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
# Source file containing definitions of mathematical and physical con-
# stants.
#
#-----------------------------------------------------------------------
#
. ${USHDIR}/constants.sh
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
  APRUN="time"
  topo_dir="/scratch1/NCEPDEV/global/glopara/fix/fix_orog"
#
#  ulimit -s unlimited
#  ulimit -a
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

  export APRUN="time"
  export topo_dir="/lfs3/projects/hpc-wof1/ywang/regional_fv3/fix/fix_orog"
#  . $USHDIR/set_stack_limit_jet.sh
  ulimit -a
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
# GRID_DIR.  Note that the file for tile 7 will include a halo of
# width NHW_T7 cells.
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
# ready include a halo (because these arguments are $istart_rgnl_with_-
# halo_T6SG, $iend_rgnl_wide_halo_T6SG, $jstart_rgnl_wide_halo_T6SG, and
# $jend_rgnl_wide_halo_T6SG), it is reasonable to pass as the argument
# to --halo a zero.  However, make_hgrid requires that the argument to
# --halo be at least 1, so below, we pass a 1 as the next-to-last argu-
# ment to grid_gen_scr.
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
#   --target_lon ${LON_CTR_T6} --target_lat ${LAT_CTR_T6} \
#   --nest_grid --parent_tile 6 --refine_ratio ${REFINE_RATIO} \
#   --istart_nest ${istart_rgnl_wide_halo_T6SG} \
#   --jstart_nest ${jstart_rgnl_wide_halo_T6SG} \
#   --iend_nest ${iend_rgnl_wide_halo_T6SG} \
#   --jend_nest ${jend_rgnl_wide_halo_T6SG} \
#   --halo ${NH3_T7} \
#   --great_circle_algorithm
#
# This creates the 7 grid files ${CRES}_grid.tileN.nc for N=1,...,7.
# The 7th file ${CRES}_grid.tile7.nc represents the regional grid, and
# the extents of the arrays in that file do not seem to include a halo,
# i.e. they are based only on the values passed via the four flags
#
#   --istart_nest ${istart_rgnl_wide_halo_T6SG}
#   --jstart_nest ${jstart_rgnl_wide_halo_T6SG}
#   --iend_nest ${iend_rgnl_wide_halo_T6SG}
#   --jend_nest ${jend_rgnl_wide_halo_T6SG}
#
# According to Rusty Benson of GFDL, the flag
#
#   --halo ${NH3_T7}
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

if [ "${GRID_GEN_METHOD}" = "GFDLgrid" ]; then

  $USHDIR/$grid_gen_scr \
    $RES \
    $tmpdir \
    ${STRETCH_FAC} ${LON_CTR_T6} ${LAT_CTR_T6} ${REFINE_RATIO} \
    ${istart_rgnl_wide_halo_T6SG} ${jstart_rgnl_wide_halo_T6SG} \
    ${iend_rgnl_wide_halo_T6SG} ${jend_rgnl_wide_halo_T6SG} \
    1 $USHDIR || \
  print_err_msg_exit "\
Call to script that generates grid files returned with nonzero exit 
code."

  tile_rgnl=7
  grid_fp="$tmpdir/${CRES}_grid.tile${tile_rgnl}.nc"
  $EXECDIR/global_equiv_resol "${grid_fp}" || \
  print_err_msg_exit "\
Call to executable that calculates equivalent global uniform cubed 
sphere resolution returned with nonzero exit code."

  RES_equiv=$( ncdump -h "${grid_fp}" | grep -o ":RES_equiv = [0-9]\+" | grep -o "[0-9]")
  RES_equiv=${RES_equiv//$'\n'/}
printf "%s\n" "RES_equiv = $RES_equiv"
  CRES_equiv="C${RES_equiv}"
printf "%s\n" "CRES_equiv = $CRES_equiv"

elif [ "${GRID_GEN_METHOD}" = "JPgrid" ]; then
#
#-----------------------------------------------------------------------
#
# Set the full path to the namelist file for the executable that gene-
# rates a regional grid using Jim Purser's method.  Then set parameters
# in that file.
#
#-----------------------------------------------------------------------
#
  RGNL_GRID_NML_FP="$tmpdir/${RGNL_GRID_NML_FN}"
  cp_vrfy ${TEMPLATE_DIR}/${RGNL_GRID_NML_FN} ${RGNL_GRID_NML_FP}

  print_info_msg "$VERBOSE" "
Setting parameters in file:
  RGNL_GRID_NML_FP = \"${RGNL_GRID_NML_FP}\""
#
# Set parameters.
#
  set_file_param "${RGNL_GRID_NML_FP}" "plon" "${LON_RGNL_CTR}"
  set_file_param "${RGNL_GRID_NML_FP}" "plat" "${LAT_RGNL_CTR}"
  set_file_param "${RGNL_GRID_NML_FP}" "delx" "${DEL_ANGLE_X_SG}"
  set_file_param "${RGNL_GRID_NML_FP}" "dely" "${DEL_ANGLE_Y_SG}"
  set_file_param "${RGNL_GRID_NML_FP}" "lx" "${MNS_NX_T7_PLS_WIDE_HALO}"
  set_file_param "${RGNL_GRID_NML_FP}" "ly" "${MNS_NY_T7_PLS_WIDE_HALO}"
  set_file_param "${RGNL_GRID_NML_FP}" "a" "${ALPHA_JPGRID_PARAM}"
  set_file_param "${RGNL_GRID_NML_FP}" "k" "${KAPPA_JPGRID_PARAM}"

  cd_vrfy $tmpdir

  $EXECDIR/regional_grid ${RGNL_GRID_NML_FP} || \
  print_err_msg_exit "\
Call to executable that generates grid file (Jim Purser version) re-
turned with nonzero exit code."

  tile_rgnl=7
  grid_fp="$tmpdir/regional_grid.nc"
  $EXECDIR/global_equiv_resol "${grid_fp}" || \
  print_err_msg_exit "\
Call to executable that calculates equivalent global uniform cubed 
sphere resolution returned with nonzero exit code."

  RES_equiv=$( ncdump -h "${grid_fp}" | grep -o ":RES_equiv = [0-9]\+" | grep -o "[0-9]" ) # Need error checking here.
  RES_equiv=${RES_equiv//$'\n'/}
printf "%s\n" "RES_equiv = $RES_equiv"
  CRES_equiv="C${RES_equiv}"
printf "%s\n" "CRES_equiv = $CRES_equiv"

  grid_fp_orig="${grid_fp}"
  grid_fp="$tmpdir/${CRES_equiv}_grid.tile${tile_rgnl}.nc"
  mv_vrfy ${grid_fp_orig} ${grid_fp}

  $EXECDIR/mosaic_file $CRES_equiv || \
  print_err_msg_exit "\
Call to executable that creates a grid mosaic file returned with nonzero
exit code."
#
# RES and CRES need to be set here in order for the rest of the script
# (that was originally written for a grid with GRID_GEN_METHOD set to 
# "GFDLgrid") to work for a grid with GRID_GEN_METHOD set to "JPgrid".
#
  RES="$RES_equiv"
  CRES="$CRES_equiv"

  set_file_param "${GLOBAL_VAR_DEFNS_FP}" "RES" "$RES"
  set_file_param "${GLOBAL_VAR_DEFNS_FP}" "CRES" "$CRES"

fi
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
        ${CRES}_grid.tile${TILE_RGNL}.halo${NHW_T7}.nc
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
unshaved_fp="$tmpdir/${CRES}_grid.tile${TILE_RGNL}.halo${NHW_T7}.nc"
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
\"Shaving\" grid file with wide halo to obtain grid file with ${NH3_T7}-cell-wide
halo..."

nml_fn="input.shave.grid.halo${NH3_T7}"
shaved_fp="${tmpdir}/${CRES}_grid.tile${TILE_RGNL}.halo${NH3_T7}.nc"
printf "%s %s %s %s %s\n" \
  ${NX_T7} ${NY_T7} ${NH3_T7} \"${unshaved_fp}\" \"${shaved_fp}\" \
  > ${nml_fn}

$APRUN $EXECDIR/${shave_exec} < ${nml_fn} || \
print_err_msg_exit "\
Call to executable \"${shave_exec}\" to generate a grid file with a ${NH3_T7}-cell-wide
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
\"Shaving\" grid file with wide halo to obtain grid file with ${NH4_T7}-cell-wide
halo..."

nml_fn="input.shave.grid.halo${NH4_T7}"
shaved_fp="${tmpdir}/${CRES}_grid.tile${TILE_RGNL}.halo${NH4_T7}.nc"
printf "%s %s %s %s %s\n" \
  ${NX_T7} ${NY_T7} ${NH4_T7} \"${unshaved_fp}\" \"${shaved_fp}\" \
  > ${nml_fn}

$APRUN $EXECDIR/${shave_exec} < ${nml_fn} || \
print_err_msg_exit "\
Call to executable \"${shave_exec}\" to generate a grid file with a ${NH4_T7}-cell-wide
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
$USHDIR/link_fix.sh \
  verbose="FALSE" \
  global_var_defns_fp="${GLOBAL_VAR_DEFNS_FP}" \
  file_group="grid" || \
print_err_msg_exit "\
Call to script to create links to grid files failed."
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



