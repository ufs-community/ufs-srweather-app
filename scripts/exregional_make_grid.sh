#!/usr/bin/env bash


#
#-----------------------------------------------------------------------
#
# This script generates NetCDF-formatted grid files required as input
# the FV3 model configured for the regional domain.
#
# The output of this script is placed in a directory defined by GRID_DIR.
#
# More about the grid for regional configurations of FV3:
#
#    a) This script creates grid files for tile 7 (reserved for the
#       regional grid located soewhere within tile 6 of the 6 global
#       tiles.
#
#    b) Regional configurations of FV3 need two grid files, one with 3
#       halo cells and one with 4 halo cells. The width of the halo is
#       the number of cells in the direction perpendicular to the
#       boundary.
#
#    c) The tile 7 grid file that this script creates includes a halo,
#       with at least 4 cells to accommodate this requirement. The halo
#       is made thinner in a subsequent step called "shave".
#
#    d) We will let NHW denote the width of the wide halo that is wider
#       than the required 3- or 4-cell halos. (NHW; N=number of cells,
#       H=halo, W=wide halo)
#
#    e) T7 indicates the cell count on tile 7.
#
#
# This script does the following:
#
#   - Create the ESGgridgrid with the regional_esg_grid executable
#   - Calculate the regional grid's global uniform cubed-sphere grid
#     equivalent resolution with the global_equiv_resol executable
#   - Use the shave executable to reduce the halo to 3 and 4 cells
#   - Call an ush script that runs the make_solo_mosaic executable
#
# Run-time environment variables:
#
#    DATA
#    GLOBAL_VAR_DEFNS_FP
#    REDIRECT_OUT_ERR
#
# Experiment variables
#
#  user:
#    EXECdir
#    USHdir
#
#  platform:
#    PRE_TASK_CMDS
#    RUN_CMD_SERIAL

#  workflow:
#    DOT_OR_USCORE
#    GRID_GEN_METHOD
#    RES_IN_FIXLAM_FILENAMES
#    RGNL_GRID_NML_FN
#    VERBOSE
#
#  task_make_grid:
#    GRID_DIR
#
#  constants:
#    NH3
#    NH4
#    TILE_RGNL
#
#  grid_params:
#    DEL_ANGLE_X_SG
#    DEL_ANGLE_Y_SG
#    LAT_CTR
#    LON_CTR
#    NEG_NX_OF_DOM_WITH_WIDE_HALO
#    NEG_NY_OF_DOM_WITH_WIDE_HALO
#    NHW
#    NX
#    NY
#    PAZI
#
#-----------------------------------------------------------------------
#

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. $USHdir/source_util_funcs.sh
for sect in user nco platform workflow constants grid_params task_make_grid ; do
  source_yaml ${GLOBAL_VAR_DEFNS_FP} ${sect}
done
#
#-----------------------------------------------------------------------
#
# Source other necessary files.
#
#-----------------------------------------------------------------------
#
. $USHdir/make_grid_mosaic_file.sh
#
#-----------------------------------------------------------------------
#
# Save current shell options (in a global array).  Then set new options
# for this script/function.
#
#-----------------------------------------------------------------------
#
{ save_shell_opts; . $USHdir/preamble.sh; } > /dev/null 2>&1
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

This is the ex-script for the task that generates grid files.
========================================================================"
#
#-----------------------------------------------------------------------
#
# Set the machine-dependent run command.  Also, set resource limits as
# necessary.
#
#-----------------------------------------------------------------------
#
eval ${PRE_TASK_CMDS}

if [ -z "${RUN_CMD_SERIAL:-}" ] ; then
  print_err_msg_exit " \
  Run command was not set in machine file. \
  Please set RUN_CMD_SERIAL for your platform"
else
  print_info_msg "$VERBOSE" "
  All executables will be submitted with command \'${RUN_CMD_SERIAL}\'."
fi
#
#-----------------------------------------------------------------------
#
# Generate grid file.
#
#-----------------------------------------------------------------------
#
# Set the name and path to the executable that generates the grid file
# and make sure that it exists.
#
exec_fn="regional_esg_grid"

exec_fp="$EXECdir/${exec_fn}"
if [ ! -f "${exec_fp}" ]; then
  print_err_msg_exit "\
The executable (exec_fp) for generating the grid file does not exist:
  exec_fp = \"${exec_fp}\"
Please ensure that you've built this executable."
fi
#
# Change location to the temporary (work) directory.
#
cd "$DATA"

print_info_msg "$VERBOSE" "
Starting grid file generation..."
#
# Generate a ESGgrid-type of grid.
#
# Create the namelist file read in by the ESGgrid-type grid generation
# code in the temporary subdirectory.
#
rgnl_grid_nml_fp="$DATA/${RGNL_GRID_NML_FN}"

print_info_msg "$VERBOSE" "
Creating namelist file (rgnl_grid_nml_fp) to be read in by the grid
generation executable (exec_fp):
  rgnl_grid_nml_fp = \"${rgnl_grid_nml_fp}\"
  exec_fp = \"${exec_fp}\""
#
# Create a multiline variable that consists of a yaml-compliant string
# specifying the values that the namelist variables need to be set to
# (one namelist variable per line, plus a header and footer).  Below,
# this variable will be passed to a python script that will create the
# namelist file.
#
settings="
'regional_grid_nml':
  'plon': ${LON_CTR}
  'plat': ${LAT_CTR}
  'delx': ${DEL_ANGLE_X_SG}
  'dely': ${DEL_ANGLE_Y_SG}
  'lx': ${NEG_NX_OF_DOM_WITH_WIDE_HALO}
  'ly': ${NEG_NY_OF_DOM_WITH_WIDE_HALO}
  'pazi': ${PAZI}
"

# UW takes input from stdin when no -i/--input-config flag is provided
(cat << EOF
$settings
EOF
) | uw config realize \
    --input-format yaml \
    -o ${rgnl_grid_nml_fp} \
    -v \

  err=$?
  if [ $err -ne 0 ]; then
      print_err_msg_exit "\
  Error creating regional_esg_grid namelist.
      Settings for input are:
  $settings"
fi
#
# Call the executable that generates the grid file.
#
PREP_STEP
eval $RUN_CMD_SERIAL ${exec_fp} ${rgnl_grid_nml_fp} ${REDIRECT_OUT_ERR} || \
  print_err_msg_exit "\
Call to executable (exec_fp) that generates a ESGgrid-type regional grid
returned with nonzero exit code:
  exec_fp = \"${exec_fp}\""
POST_STEP
#
# Set the name of the regional grid file generated by the above call.
# This must be the same name as in the regional_esg_grid code.
#
grid_fn="regional_grid.nc"
#
# Set the full path to the grid file generated above.  Then change location
# to the original directory.
#
grid_fp="$DATA/${grid_fn}"
cd -

print_info_msg "$VERBOSE" "
Grid file generation completed successfully."
#
#-----------------------------------------------------------------------
#
# Calculate the regional grid's global uniform cubed-sphere grid equivalent
# resolution.
#
#-----------------------------------------------------------------------
#
exec_fn="global_equiv_resol"
exec_fp="$EXECdir/${exec_fn}"
if [ ! -f "${exec_fp}" ]; then
  print_err_msg_exit "\
The executable (exec_fp) for calculating the regional grid's global uniform
cubed-sphere grid equivalent resolution does not exist:
  exec_fp = \"${exec_fp}\"
Please ensure that you've built this executable."
fi

PREP_STEP
eval $RUN_CMD_SERIAL ${exec_fp} "${grid_fp}" ${REDIRECT_OUT_ERR} || \
print_err_msg_exit "\
Call to executable (exec_fp) that calculates the regional grid's global
uniform cubed-sphere grid equivalent resolution returned with nonzero exit
code:
  exec_fp = \"${exec_fp}\""
POST_STEP

# Make sure 'ncdump' is available before we try to use it
if ! command -v ncdump &> /dev/null
then
  print_err_msg_exit "\
The utility 'ncdump' was not found in the environment. Be sure to add the
netCDF 'bin/' directory to your PATH."
fi

# Make the following (reading of res_equiv) a function in another file
# so that it can be used both here and in the exregional_make_orog.sh
# script.
res_equiv=$( ncdump -h "${grid_fp}" | \
             grep -o ":RES_equiv = [0-9]\+" | grep -o "[0-9]" ) || \
print_err_msg_exit "\
Attempt to extract the equivalent global uniform cubed-sphere grid reso-
lution from the grid file (grid_fp) failed:
  grid_fp = \"${grid_fp}\""
res_equiv=${res_equiv//$'\n'/}
#
#-----------------------------------------------------------------------
#
# Set the string CRES that will be comprise the start of the grid file
# name (and other file names later in other tasks/scripts).  Then set its
# value in the variable definitions file.
#
#-----------------------------------------------------------------------
#
CRES="C${res_equiv}"
# UW takes the update values from stdin when no --update-file flag is
# provided. It needs --update-format to do it correctly, though.
echo "workflow: {CRES: ${CRES}}" | uw config realize \
  --input-file $GLOBAL_VAR_DEFNS_FP \
  --update-format yaml \
  --output-file $GLOBAL_VAR_DEFNS_FP \
  --verbose

#
#-----------------------------------------------------------------------
#
# Move the grid file from the temporary directory to GRID_DIR.  In the
# process, rename it such that its name includes CRES and the halo width.
#
#-----------------------------------------------------------------------
#
grid_fp_orig="${grid_fp}"
grid_fn="${CRES}${DOT_OR_USCORE}grid.tile${TILE_RGNL}.halo${NHW}.nc"
grid_fp="${GRID_DIR}/${grid_fn}"
mv "${grid_fp_orig}" "${grid_fp}"
#
#-----------------------------------------------------------------------
#
# If there are pre-existing orography or climatology files that we will
# be using (i.e. if task_make_grid or task_make_sfc_climo ran in the
# experiment, RES_IN_FIXLAM_FILENAMES will not be set to a null string),
# check that the grid resolution contained in the variable CRES set
# above matches the resolution appearing in the names of the preexisting
# orography and/or surface climatology files.
#
#-----------------------------------------------------------------------
#
if [ ! -z "${RES_IN_FIXLAM_FILENAMES}" ]; then
  res="${CRES:1}"
  if [ "$res" -ne "${RES_IN_FIXLAM_FILENAMES}" ]; then
    print_err_msg_exit "\
The resolution (res) calculated for the grid does not match the resolution
(RES_IN_FIXLAM_FILENAMES) appearing in the names of the orography and/or
surface climatology files:
  res = \"$res\"
  RES_IN_FIXLAM_FILENAMES = \"${RES_IN_FIXLAM_FILENAMES}\""
  fi
fi
#
#-----------------------------------------------------------------------
#
# Partially "shave" the halo from the grid file having a wide halo to
# generate two new grid files -- one with a 3-grid-wide halo and another
# with a 4-cell-wide halo.  These are needed as inputs by the forecast
# model as well as by the code (chgres_cube) that generates the lateral
# boundary condition files.                                             <== Are these also needed by make_sfc_climo???
#
#-----------------------------------------------------------------------
#
# Set the name and path to the executable and make sure that it exists.
#
exec_fn="shave"
exec_fp="$EXECdir/${exec_fn}"
if [ ! -f "${exec_fp}" ]; then
  print_err_msg_exit " \
The executable (exec_fp) for \"shaving\" down the halo in the grid file
does not exist:
  exec_fp = \"${exec_fp}\"
Please ensure that you've built this executable."
fi
#
# Set the full path to the "unshaved" grid file, i.e. the one with a wide
# halo.  This is the input grid file for generating both the grid file
# with a 3-cell-wide halo and the one with a 4-cell-wide halo.
#
unshaved_fp="${grid_fp}"
#
# We perform the work in DATA, so change location to that directory.
# Once it is complete, we will move the resultant file from DATA to
# GRID_DIR.
#
cd "$DATA"
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
shaved_fp="${DATA}/${CRES}${DOT_OR_USCORE}grid.tile${TILE_RGNL}.halo${NH3}.nc"
printf "%s %s %s %s %s\n" \
  $NX $NY ${NH3} \"${unshaved_fp}\" \"${shaved_fp}\" \
  > ${nml_fn}

PREP_STEP
eval $RUN_CMD_SERIAL ${exec_fp} < ${nml_fn} ${REDIRECT_OUT_ERR} || \
print_err_msg_exit "\
Call to executable (exec_fp) to generate a grid file with a ${NH3}-cell-wide
halo from the grid file with a ${NHW}-cell-wide halo returned with nonzero
exit code:
  exec_fp = \"${exec_fp}\"
The namelist file (nml_fn) used in this call is in directory DATA:
  nml_fn = \"${nml_fn}\"
  DATA = \"${DATA}\""
POST_STEP
mv ${shaved_fp} ${GRID_DIR}
#
# Create an input namelist file for the shave executable to generate a
# grid file with a 4-cell-wide halo from the one with a wide halo.  Then
# call the shave executable.  Finally, move the resultant file to the
# GRID_DIR directory.
#
print_info_msg "$VERBOSE" "
\"Shaving\" grid file with wide halo to obtain grid file with ${NH4}-cell-wide
halo..."

nml_fn="input.shave.grid.halo${NH4}"
shaved_fp="${DATA}/${CRES}${DOT_OR_USCORE}grid.tile${TILE_RGNL}.halo${NH4}.nc"
printf "%s %s %s %s %s\n" \
  $NX $NY ${NH4} \"${unshaved_fp}\" \"${shaved_fp}\" \
  > ${nml_fn}

PREP_STEP
eval $RUN_CMD_SERIAL ${exec_fp} < ${nml_fn} ${REDIRECT_OUT_ERR} || \
print_err_msg_exit "\
Call to executable (exec_fp) to generate a grid file with a ${NH4}-cell-wide
halo from the grid file with a ${NHW}-cell-wide halo returned with nonzero
exit code:
  exec_fp = \"${exec_fp}\"
The namelist file (nml_fn) used in this call is in directory DATA:
  nml_fn = \"${nml_fn}\"
  DATA = \"${DATA}\""
POST_STEP
mv ${shaved_fp} ${GRID_DIR}
#
# Create an input namelist file for the shave executable to generate a
# grid file without halo from the one with a wide halo.  Then
# call the shave executable.  Finally, move the resultant file to the
# GRID_DIR directory.
#
print_info_msg "$VERBOSE" "
\"Shaving\" grid file with wide halo to obtain grid file without halo..."

nml_fn="input.shave.grid.halo0"
shaved_fp="${DATA}/${CRES}${DOT_OR_USCORE}grid.tile${TILE_RGNL}.halo0.nc"
printf "%s %s %s %s %s\n" \
  $NX $NY "0" \"${unshaved_fp}\" \"${shaved_fp}\" \
  > ${nml_fn}

PREP_STEP
eval $RUN_CMD_SERIAL ${exec_fp} < ${nml_fn} ${REDIRECT_OUT_ERR} || \
print_err_msg_exit "\
Call to executable (exec_fp) to generate a grid file without halo
from the grid file with a ${NHW}-cell-wide halo returned with nonzero
exit code:
  exec_fp = \"${exec_fp}\"
The namelist file (nml_fn) used in this call is in directory DATA:
  nml_fn = \"${nml_fn}\"
  DATA = \"${DATA}\""
POST_STEP
mv ${shaved_fp} ${GRID_DIR}
#
# Change location to the original directory.
#
cd -
#
#-----------------------------------------------------------------------
#
# Create the grid mosaic file for the grid with a NHW-cell-wide halo.
#
#-----------------------------------------------------------------------
#
make_grid_mosaic_file \
  grid_dir="${GRID_DIR}" \
  grid_fn="${CRES}${DOT_OR_USCORE}grid.tile${TILE_RGNL}.halo${NHW}.nc" \
  mosaic_fn="${CRES}${DOT_OR_USCORE}mosaic.halo${NHW}.nc" \
  run_cmd="${RUN_CMD_SERIAL}" || \
  print_err_msg_exit "\
Call to function to generate the mosaic file for a grid with a ${NHW}-cell-wide
halo failed."
#
#-----------------------------------------------------------------------
#
# Create the grid mosaic file for the grid with a NH3-cell-wide halo.
#
#-----------------------------------------------------------------------
#
make_grid_mosaic_file \
  grid_dir="${GRID_DIR}" \
  grid_fn="${CRES}${DOT_OR_USCORE}grid.tile${TILE_RGNL}.halo${NH3}.nc" \
  mosaic_fn="${CRES}${DOT_OR_USCORE}mosaic.halo${NH3}.nc" \
  run_cmd="${RUN_CMD_SERIAL}" || \
  print_err_msg_exit "\
Call to function to generate the mosaic file for a grid with a ${NH3}-cell-wide
halo failed."
#
#-----------------------------------------------------------------------
#
# Create the grid mosaic file for the grid with a NH4-cell-wide halo.
#
#-----------------------------------------------------------------------
#
make_grid_mosaic_file \
  grid_dir="${GRID_DIR}" \
  grid_fn="${CRES}${DOT_OR_USCORE}grid.tile${TILE_RGNL}.halo${NH4}.nc" \
  mosaic_fn="${CRES}${DOT_OR_USCORE}mosaic.halo${NH4}.nc" \
  run_cmd="${RUN_CMD_SERIAL}" || \
  print_err_msg_exit "\
Call to function to generate the mosaic file for a grid with a ${NH4}-cell-wide
halo failed."
#
#-----------------------------------------------------------------------
#
# Create the grid mosaic file for the grid without halo.
#
#-----------------------------------------------------------------------
#
make_grid_mosaic_file \
  grid_dir="${GRID_DIR}" \
  grid_fn="${CRES}${DOT_OR_USCORE}grid.tile${TILE_RGNL}.halo0.nc" \
  mosaic_fn="${CRES}${DOT_OR_USCORE}mosaic.halo0.nc" \
  run_cmd="${RUN_CMD_SERIAL}" || \
  print_err_msg_exit "\
Call to function to generate the mosaic file for a grid without halo failed."
#
#-----------------------------------------------------------------------
#
# Create symlinks in the FIXlam directory to the grid and mosaic files
# generated above in the GRID_DIR directory.
#
#-----------------------------------------------------------------------
#
python3 $USHdir/link_fix.py \
  --path-to-defns ${GLOBAL_VAR_DEFNS_FP} \
  --file-group "grid" || \
print_err_msg_exit "\
Call to function to create symlinks to the various grid and mosaic files
failed."
#
#-----------------------------------------------------------------------
#
# Call a function (set_fv3nml_sfc_climo_filenames) to set the values of
# those variables in the forecast model's namelist file that specify the
# paths to the surface climatology files.  These files will either already
# be avaialable in a user-specified directory (SFC_CLIMO_DIR) or will be
# generated by the TN_MAKE_SFC_CLIMO task.  They (or symlinks to them)
# will be placed (or wll already exist) in the FIXlam directory.
#
#-----------------------------------------------------------------------
#
python3 $USHdir/set_fv3nml_sfc_climo_filenames.py \
  --path-to-defns ${GLOBAL_VAR_DEFNS_FP} \
    || print_err_msg_exit "\
Call to function to set surface climatology file names in the FV3 namelist
file failed."
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



