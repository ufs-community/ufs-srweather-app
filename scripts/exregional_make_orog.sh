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
. $USHDIR/link_fix.sh
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
scrfunc_fp=$( $READLINK -f "${BASH_SOURCE[0]}" )
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

This is the ex-script for the task that generates orography files.
========================================================================"
#
#-----------------------------------------------------------------------
#
# Specify the set of valid argument names for this script/function.  Then
# process the arguments provided to this script/function (which should
# consist of a set of name-value pairs of the form arg1="value1", etc).
#
#-----------------------------------------------------------------------
#
valid_args=()
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
# Set OpenMP variables.  The orog executable runs with OMP. On
# WCOSS (Cray), it is optimized for six threads, which is the default.
#
#-----------------------------------------------------------------------
#
export KMP_AFFINITY=${KMP_AFFINITY_MAKE_OROG}
export OMP_NUM_THREADS=${OMP_NUM_THREADS_MAKE_OROG}
export OMP_STACKSIZE=${OMP_STACKSIZE_MAKE_OROG}
#
#-----------------------------------------------------------------------
#
# Load modules and set various computational parameters and directories.
#
# Note: 
# These module loads should all be moved to modulefiles.  This has been
# done for Hera but must still be done for other machines.
#
#-----------------------------------------------------------------------
#
case "$MACHINE" in

  "WCOSS_CRAY")
    { save_shell_opts; set +x; } > /dev/null 2>&1
    . $MODULESHOME/init/sh
    module load PrgEnv-intel cfp-intel-sandybridge/1.1.0
    module list
    { restore_shell_opts; } > /dev/null 2>&1
    NODES=1
    APRUN="aprun -n 1 -N 1 -j 1 -d 1 -cc depth"
    ulimit -s unlimited
    ulimit -a
    ;;

  "WCOSS_DELL_P3")
    ulimit -s unlimited
    ulimit -a
    APRUN="mpirun"
    ;;

  "HERA")
    ulimit -s unlimited
    ulimit -a
    APRUN="time"
    ;;

  "ORION")
    ulimit -s unlimited
    ulimit -a
    APRUN="time"
    ;;

  "JET")
    ulimit -s unlimited
    ulimit -a
    APRUN="time"
    ;;

  "ODIN")
    APRUN="srun -n 1"
    ulimit -s unlimited
    ulimit -a
    ;;

  "CHEYENNE")
    APRUN="time"
    ;;

  "STAMPEDE")
    APRUN="time"
    ;;

  "MACOS")
    APRUN=time
    ;;

  "LINUX")
    APRUN=time
    ;;

  *)
    print_err_msg_exit "\
Run command has not been specified for this machine:
  MACHINE = \"$MACHINE\""
    ;;

esac
#
#-----------------------------------------------------------------------
#
# Create the (cycle-independent) subdirectories under the experiment
# directory (EXPTDIR) that are needed by the various steps and substeps
# in this script.
#
#-----------------------------------------------------------------------
#
check_for_preexist_dir_file "${OROG_DIR}" "${PREEXISTING_DIR_METHOD}"
mkdir_vrfy -p "${OROG_DIR}"

raw_dir="${OROG_DIR}/raw_topo"
mkdir_vrfy -p "${raw_dir}"

filter_dir="${OROG_DIR}/filtered_topo"
mkdir_vrfy -p "${filter_dir}"

shave_dir="${OROG_DIR}/shave_tmp"
mkdir_vrfy -p "${shave_dir}"
#
#
#-----------------------------------------------------------------------
#
# Preparatory steps before calling raw orography generation code.
#
#-----------------------------------------------------------------------
#
# Set the name and path to the executable that generates the raw orography
# file and make sure that it exists.
#
exec_fn="orog"
exec_fp="$EXECDIR/${exec_fn}"
if [ ! -f "${exec_fp}" ]; then
  print_err_msg_exit "\
The executable (exec_fp) for generating the orography file does not exist:
  exec_fp = \"${exec_fp}\"
Please ensure that you've built this executable."
fi
#
# Create a temporary (work) directory in which to generate the raw orography
# file and change location to it.
#
tmp_dir="${raw_dir}/tmp"
mkdir_vrfy -p "${tmp_dir}"
cd_vrfy "${tmp_dir}"
#
# Copy topography and related data files from the system directory (TOPO_DIR)
# to the temporary directory.
#
cp_vrfy ${TOPO_DIR}/thirty.second.antarctic.new.bin fort.15
cp_vrfy ${TOPO_DIR}/landcover30.fixed .
cp_vrfy ${TOPO_DIR}/gmted2010.30sec.int fort.235
#
#-----------------------------------------------------------------------
#
# The orography filtering code reads in from the grid mosaic file the
# the number of tiles, the name of the grid file for each tile, and the
# dimensions (nx and ny) of each tile.  Next, set the name of the grid
# mosaic file and create a symlink to it in filter_dir.
#
# Note that in the namelist file for the orography filtering code (created
# later below), the mosaic file name is saved in a variable called
# "grid_file".  It would have been better to call this "mosaic_file"
# instead so it doesn't get confused with the grid file for a given tile...
#
#-----------------------------------------------------------------------
#
mosaic_fn="${CRES}${DOT_OR_USCORE}mosaic.halo${NHW}.nc"
mosaic_fp="$FIXLAM/${mosaic_fn}"

grid_fn=$( get_charvar_from_netcdf "${mosaic_fp}" "gridfiles" ) || print_err_msg_exit "\
  get_charvar_from_netcdf function failed."
grid_fp="${FIXLAM}/${grid_fn}"
#
#-----------------------------------------------------------------------
#
# Set input parameters for the orography generation executable and write
# them to a text file.
#
# Note that it doesn't matter what lonb and latb are set to below because
# if we specify an input grid file to the executable read in (which is
# what we do below), then if lonb and latb are not set to the dimensions
# of the grid specified in that file (divided by 2 since the grid file
# specifies a "supergrid"), then lonb and latb effectively get reset to
# the dimensions specified in the grid file.
#
#-----------------------------------------------------------------------
#
mtnres=1
#lonb=$res
#latb=$res
lonb=0
latb=0
jcap=0
NR=0
NF1=0
NF2=0
efac=0
blat=0

input_redirect_fn="INPS"
orogfile="none"

echo $mtnres $lonb $latb $jcap $NR $NF1 $NF2 $efac $blat > "${input_redirect_fn}"
#
# The following two inputs are read in as strings, so they must be quoted
# in the input file.
#
echo "\"${grid_fp}\"" >> "${input_redirect_fn}"
echo "\"$orogfile\"" >> "${input_redirect_fn}"
cat "${input_redirect_fn}"
#
#-----------------------------------------------------------------------
#
# Call the executable to generate the raw orography file corresponding
# to tile 7 (the regional domain) only.
#
# The following will create an orography file named
#
#   oro.${CRES}.tile7.nc
#
# and will place it in OROG_DIR.  Note that this file will include
# orography for a halo of width NHW cells around tile 7.  The follow-
# ing will also create a work directory called tile7 under OROG_DIR.
# This work directory can be removed after the orography file has been
# created (it is currently not deleted).
#
#-----------------------------------------------------------------------
#
print_info_msg "$VERBOSE" "\
Starting orography file generation..."

$APRUN "${exec_fp}" < "${input_redirect_fn}" || \
      print_err_msg_exit "\
Call to executable (exec_fp) that generates the raw orography file returned
with nonzero exit code:
  exec_fp = \"${exec_fp}\""

#
# Change location to the original directory.
#
cd_vrfy -
#
#-----------------------------------------------------------------------
#
# Move the raw orography file from the temporary directory to raw_dir.
# In the process, rename it such that its name includes CRES and the halo
# width.
#
#-----------------------------------------------------------------------
#
raw_orog_fp_orig="${tmp_dir}/out.oro.nc"
raw_orog_fn_prefix="${CRES}${DOT_OR_USCORE}raw_orog"
fn_suffix_with_halo="tile${TILE_RGNL}.halo${NHW}.nc"
raw_orog_fn="${raw_orog_fn_prefix}.${fn_suffix_with_halo}"
raw_orog_fp="${raw_dir}/${raw_orog_fn}"
mv_vrfy "${raw_orog_fp_orig}" "${raw_orog_fp}"
#
#-----------------------------------------------------------------------
#
# Call the code to generate the two orography statistics files (large-
# and small-scale) needed for the drag suite in the FV3_HRRR physics
# suite.
#
#-----------------------------------------------------------------------
#
if [ "${CCPP_PHYS_SUITE}" = "FV3_HRRR" ]; then
  tmp_dir="${OROG_DIR}/temp_orog_data"
  mkdir_vrfy -p ${tmp_dir}
  cd_vrfy ${tmp_dir}
  mosaic_fn_gwd="${CRES}${DOT_OR_USCORE}mosaic.halo${NH4}.nc"
  mosaic_fp_gwd="$FIXLAM/${mosaic_fn_gwd}"
  grid_fn_gwd=$( get_charvar_from_netcdf "${mosaic_fp_gwd}" "gridfiles" ) || \
    print_err_msg_exit "get_charvar_from_netcdf function failed."
  grid_fp_gwd="${FIXLAM}/${grid_fn_gwd}"
  ls_fn="geo_em.d01.lat-lon.2.5m.HGT_M.nc"
  ss_fn="HGT.Beljaars_filtered.lat-lon.30s_res.nc"
  create_symlink_to_file target="${grid_fp_gwd}" symlink="${tmp_dir}/${grid_fn_gwd}" \
                         relative="TRUE"
  create_symlink_to_file target="${FIXam}/${ls_fn}" symlink="${tmp_dir}/${ls_fn}" \
                         relative="TRUE"
  create_symlink_to_file target="${FIXam}/${ss_fn}" symlink="${tmp_dir}/${ss_fn}" \
                         relative="TRUE"

  input_redirect_fn="grid_info.dat"
  cat > "${input_redirect_fn}" <<EOF
${TILE_RGNL}
${CRES:1}
${NH4}
EOF

  exec_fn="orog_gsl"
  exec_fp="$EXECDIR/${exec_fn}"
  if [ ! -f "${exec_fp}" ]; then
    print_err_msg_exit "\
The executable (exec_fp) for generating the GSL orography GWD data files
does not exist:
  exec_fp = \"${exec_fp}\"
Please ensure that you've built this executable."
  fi

  print_info_msg "$VERBOSE" "
Starting orography file generation..."

  $APRUN "${exec_fp}" < "${input_redirect_fn}" || \
      print_err_msg_exit "\
Call to executable (exec_fp) that generates the GSL orography GWD data files
returned with nonzero exit code:
  exec_fp = \"${exec_fp}\""

  mv_vrfy "${CRES}${DOT_OR_USCORE}oro_data_ss.tile${TILE_RGNL}.halo${NH0}.nc" \
          "${CRES}${DOT_OR_USCORE}oro_data_ls.tile${TILE_RGNL}.halo${NH0}.nc" \
          "${OROG_DIR}"
 
fi
#
#-----------------------------------------------------------------------
#
# Note that the orography filtering code assumes that the regional grid
# is a GFDLgrid type of grid; it is not designed to handle ESGgrid type
# regional grids.  If the flag "regional" in the orography filtering
# namelist file is set to .TRUE. (which it always is will be here; see
# below), then filtering code will first calculate a resolution (i.e.
# number of grid points) value named res_regional for the assumed GFDLgrid
# type regional grid using the formula
#
#   res_regional = res*stretch_fac*real(refine_ratio)
#
# Here res, stretch_fac, and refine_ratio are the values passed to the
# code via the namelist.  res and stretch_fac are assumed to be the
# resolution (in terms of number of grid points) and the stretch factor
# of the (GFDLgrid type) regional grid's parent global cubed-sphere grid,
# and refine_ratio is the ratio of the number of grid cells on the regional
# grid to a single cell on tile 6 of the parent global grid.  After
# calculating res_regional, the code interpolates/extrapolates between/
# beyond a set of (currently 7) resolution values for which the four
# filtering parameters (n_del2_weak, cd4, max_slope, peak_fac) are provided
# (by GFDL) to obtain the corresponding values of these parameters at a
# resolution of res_regional.  These interpolated/extrapolated values are
# then used to perform the orography filtering.
#
# The above approach works for a GFDLgrid type of grid.  To handle ESGgrid
# type grids, we set res in the namelist to the orography filtering code
# the equivalent global uniform cubed-sphere resolution of the regional
# grid, we set stretch_fac to 1 (since the equivalent resolution assumes
# a uniform global grid), and we set refine_ratio to 1.  This will cause
# res_regional above to be set to the equivalent global uniform cubed-
# sphere resolution, so the filtering parameter values will be interpolated/
# extrapolated to that resolution value.
#
#-----------------------------------------------------------------------
#
if [ "${GRID_GEN_METHOD}" = "GFDLgrid" ]; then

# Note:
# It is also possible to use the equivalent global uniform cubed-sphere
# resolution when filtering on a GFDLgrid type grid by setting the namelist
# parameters as follows:
#
#  res="${CRES:1}"
#  stretch_fac="1" (or "0.999" if "1" makes it crash)
#  refine_ratio="1"
#
# Really depends on what EMC wants to do.

  res="${GFDLgrid_RES}"
#  stretch_fac="${GFDLgrid_STRETCH_FAC}"
  refine_ratio="${GFDLgrid_REFINE_RATIO}"

elif [ "${GRID_GEN_METHOD}" = "ESGgrid" ]; then

  res="${CRES:1}"
#  stretch_fac="${STRETCH_FAC}"
  refine_ratio="1"

fi
#
# Set the name and path to the executable and make sure that it exists.
#
exec_fn="filter_topo"
exec_fp="$EXECDIR/${exec_fn}"
if [ ! -f "${exec_fp}" ]; then
  print_err_msg_exit "\
The executable (exec_fp) for filtering the raw orography does not exist:
  exec_fp = \"${exec_fp}\"
Please ensure that you've built this executable."
fi
#
# The orography filtering executable replaces the contents of the given
# raw orography file with a file containing the filtered orography.  The
# name of the input raw orography file is in effect specified by the
# namelist variable topo_file; the orography filtering code assumes that
# this name is constructed by taking the value of topo_file and appending
# to it the string ".tile${N}.nc", where N is the tile number (which for
# a regional grid, is always 7).  (Note that topo_file may start with a
# a path to the orography file that the filtering code will read in and
# replace.) Thus, we now copy the raw orography file (whose full path is
# specified by raw_orog_fp) to filter_dir and in the process rename it
# such that its new name:
#
# (1) indicates that it contains filtered orography data (because that
#     is what it will contain once the orography filtering executable
#     successfully exits); and
# (2) ends with the string ".tile${N}.nc" expected by the orography
#     filtering code.
#
fn_suffix_without_halo="tile${TILE_RGNL}.nc"
filtered_orog_fn_prefix="${CRES}${DOT_OR_USCORE}filtered_orog"
filtered_orog_fp_prefix="${filter_dir}/${filtered_orog_fn_prefix}"
filtered_orog_fp="${filtered_orog_fp_prefix}.${fn_suffix_without_halo}"
cp_vrfy "${raw_orog_fp}" "${filtered_orog_fp}"
#
# The orography filtering executable looks for the grid file specified
# in the grid mosaic file (more specifically, specified by the gridfiles
# variable in the mosaic file) in the directory in which the executable
# is running.  Recall that above, we already extracted the name of the
# grid file from the mosaic file and saved it in the variable grid_fn,
# and we saved the full path to this grid file in the variable grid_fp.
# Thus, we now create a symlink in the filter_dir directory (where the
# filtering executable will run) with the same name as the grid file and
# point it to the actual grid file specified by grid_fp.
#
create_symlink_to_file target="${grid_fp}" symlink="${filter_dir}/${grid_fn}" \
                       relative="TRUE"
#
# Create the namelist file (in the filter_dir directory) that the orography
# filtering executable will read in.
#
cat > "${filter_dir}/input.nml" <<EOF
&filter_topo_nml
  grid_file = "${mosaic_fp}"
  topo_file = "${filtered_orog_fp_prefix}"
  mask_field = "land_frac"
  regional = .true.
  stretch_fac = ${STRETCH_FAC}
  res = $res
/
EOF
#
# Change location to the filter_dir directory.  This must be done because
# the orography filtering executable looks for a namelist file named
# input.nml in the directory in which it is running (not the directory
# in which it is located).  Thus, since above we created the input.nml
# file in filter_dir, we must also run the executable out of this directory.
#
cd_vrfy "${filter_dir}"
#
# Run the orography filtering executable.
#
print_info_msg "$VERBOSE" "
Starting filtering of orography..."

$APRUN "${exec_fp}" || \
  print_err_msg_exit "\
Call to executable that generates filtered orography file returned with
non-zero exit code."
#
# For clarity, rename the filtered orography file in filter_dir
# such that its new name contains the halo size.
#
filtered_orog_fn_orig=$( basename "${filtered_orog_fp}" )
filtered_orog_fn="${filtered_orog_fn_prefix}.${fn_suffix_with_halo}"
filtered_orog_fp=$( dirname "${filtered_orog_fp}" )"/${filtered_orog_fn}"
mv_vrfy "${filtered_orog_fn_orig}" "${filtered_orog_fn}"
#
# Change location to the original directory.
#
cd_vrfy -

print_info_msg "$VERBOSE" "
Filtering of orography complete."
#
#-----------------------------------------------------------------------
#
# Partially "shave" the halo from the (filtered) orography file having a
# wide halo to generate two new orography files -- one without a halo and
# another with a 4-cell-wide halo.  These are needed as inputs by the
# surface climatology file generation code (sfc_climo; if it is being
# run), the initial and boundary condition generation code (chgres_cube),
# and the forecast model.
#
#-----------------------------------------------------------------------
#
# Set the name and path to the executable and make sure that it exists.
#
exec_fn="shave"
exec_fp="$EXECDIR/${exec_fn}"
if [ ! -f "${exec_fp}" ]; then
  print_err_msg_exit "\
The executable (exec_fp) for \"shaving\" down the halo in the orography
file does not exist:
  exec_fp = \"${exec_fp}\"
Please ensure that you've built this executable."
fi
#
# Set the full path to the "unshaved" orography file, i.e. the one with
# a wide halo.  This is the input orography file for generating both the
# orography file without a halo and the one with a 4-cell-wide halo.
#
unshaved_fp="${filtered_orog_fp}"
#
# We perform the work in shave_dir, so change location to that directory.
# Once it is complete, we move the resultant file from shave_dir to OROG_DIR.
#
cd_vrfy "${shave_dir}"
#
# Create an input namelist file for the shave executable to generate an
# orography file without a halo from the one with a wide halo.  Then call
# the shave executable.  Finally, move the resultant file to the OROG_DIR
# directory.
#
print_info_msg "$VERBOSE" "
\"Shaving\" filtered orography file with a ${NHW}-cell-wide halo to obtain
a filtered orography file with a ${NH0}-cell-wide halo..."

nml_fn="input.shave.orog.halo${NH0}"
shaved_fp="${shave_dir}/${CRES}${DOT_OR_USCORE}oro_data.tile${TILE_RGNL}.halo${NH0}.nc"
printf "%s %s %s %s %s\n" \
  $NX $NY ${NH0} \"${unshaved_fp}\" \"${shaved_fp}\" \
  > ${nml_fn}

$APRUN ${exec_fp} < ${nml_fn} || \
print_err_msg_exit "\
Call to executable (exec_fp) to generate a (filtered) orography file with
a ${NH0}-cell-wide halo from the orography file with a {NHW}-cell-wide halo
returned with nonzero exit code:
  exec_fp = \"${exec_fp}\"
The namelist file (nml_fn) used in this call is in directory shave_dir:
  nml_fn = \"${nml_fn}\"
  shave_dir = \"${shave_dir}\""
mv_vrfy ${shaved_fp} ${OROG_DIR}
#
# Create an input namelist file for the shave executable to generate an
# orography file with a 4-cell-wide halo from the one with a wide halo.
# Then call the shave executable.  Finally, move the resultant file to
# the OROG_DIR directory.
#
print_info_msg "$VERBOSE" "
\"Shaving\" filtered orography file with a ${NHW}-cell-wide halo to obtain
a filtered orography file with a ${NH4}-cell-wide halo..."

nml_fn="input.shave.orog.halo${NH4}"
shaved_fp="${shave_dir}/${CRES}${DOT_OR_USCORE}oro_data.tile${TILE_RGNL}.halo${NH4}.nc"
printf "%s %s %s %s %s\n" \
  $NX $NY ${NH4} \"${unshaved_fp}\" \"${shaved_fp}\" \
  > ${nml_fn}

$APRUN ${exec_fp} < ${nml_fn} || \
print_err_msg_exit "\
Call to executable (exec_fp) to generate a (filtered) orography file with
a ${NH4}-cell-wide halo from the orography file with a {NHW}-cell-wide halo
returned with nonzero exit code:
  exec_fp = \"${exec_fp}\"
The namelist file (nml_fn) used in this call is in directory shave_dir:
  nml_fn = \"${nml_fn}\"
  shave_dir = \"${shave_dir}\""
mv_vrfy "${shaved_fp}" "${OROG_DIR}"
#
# Change location to the original directory.
#
cd_vrfy -
#
#-----------------------------------------------------------------------
#
# Add link in ORIG_DIR directory to the orography file with a 4-cell-wide
# halo such that the link name do not contain the halo width.  These links
# are needed by the make_sfc_climo task.
#
# NOTE: It would be nice to modify the sfc_climo_gen_code to read in
# files that have the halo size in their names.
#
#-----------------------------------------------------------------------
#
link_fix \
  verbose="$VERBOSE" \
  file_group="orog" || \
print_err_msg_exit "\
Call to function to create links to orography files failed."
#
#-----------------------------------------------------------------------
#
# Print message indicating successful completion of script.
#
#-----------------------------------------------------------------------
#
print_info_msg "
========================================================================
Orography files with various halo widths generated successfully!!!

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


