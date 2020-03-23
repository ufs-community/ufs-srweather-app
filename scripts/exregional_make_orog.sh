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

This is the ex-script for the task that generates orography files.
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
# Create the (cycle-independent) subdirectories under the experiment di-
# rectory (EXPTDIR) that are needed by the various steps and substeps in
# this script.
#
#-----------------------------------------------------------------------
#
check_for_preexist_dir ${OROG_DIR} ${PREEXISTING_DIR_METHOD}
mkdir_vrfy -p "${OROG_DIR}"

raw_dir="${OROG_DIR}/raw_topo"
mkdir_vrfy -p "${raw_dir}"

filter_dir="${OROG_DIR}/filtered_topo"
mkdir_vrfy -p "${filter_dir}"

shave_dir="${OROG_DIR}/shave_tmp"
mkdir_vrfy -p "${shave_dir}"

ufs_utils_ushdir="${UFS_UTILS_DIR}/ush"
#
#-----------------------------------------------------------------------
#
# Set the file names of the scripts to use for generating the raw oro-
# graphy files and for filtering the latter to obtain filtered orography
# files.  Also, set the name of the executable file used to "shave" 
# (i.e. remove the halo from) certain orography files.
#
#-----------------------------------------------------------------------
#
orog_gen_scr="fv3gfs_make_orog.sh"
orog_fltr_scr="fv3gfs_filter_topo.sh"
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


"THEIA")
#
  { save_shell_opts; set +x; } > /dev/null 2>&1

  . /apps/lmod/lmod/init/sh
  module purge
  module load intel/16.1.150
  module load impi
  module load hdf5/1.8.14
  module load netcdf/4.3.0
  module list

  { restore_shell_opts; } > /dev/null 2>&1

  export APRUN="time"
  export topo_dir="/scratch4/NCEPDEV/global/save/glopara/svn/fv3gfs/fix/fix_orog"

  ulimit -s unlimited
  ulimit -a
  ;;


"HERA")
  ulimit -s unlimited
  ulimit -a
  export APRUN="time"
  export topo_dir="/scratch1/NCEPDEV/global/glopara/fix/fix_orog"
  ;;


"JET")
  ulimit -s unlimited
  ulimit -a
  export APRUN="time"
  export topo_dir="/lfs3/projects/hpc-wof1/ywang/regional_fv3/fix/fix_orog"
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
# Set and export the variable exec_dir.  This is needed by both the raw
# and filtered orography generation scripts called below (it would be 
# better to pass it in as an argument).
#
#-----------------------------------------------------------------------
#
export exec_dir="$EXECDIR"
#
#-----------------------------------------------------------------------
#
# Extract the resolution from CRES and save it in the local variable 
# res.
#
#-----------------------------------------------------------------------
#
res="${CRES:1}"
#
#-----------------------------------------------------------------------
#
# Generate an orography file corresponding to tile 7 (the regional do-
# main) only.
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
print_info_msg "$VERBOSE" "
Starting orography file generation..."

tmp_dir="${raw_dir}/tmp"

case $MACHINE in


"WCOSS_C" | "WCOSS")
#
# On WCOSS and WCOSS_C, use cfp to run multiple tiles simulatneously for
# the orography.  For now, we have only one tile in the regional case,
# but in the future we will have more.  First, create an input file for
# cfp.
#
  printf "%s\n" "\
${ufs_utils_ushdir}/${orog_gen_scr} \
$res \
${TILE_RGNL} \
${FIXsar} \
${raw_dir} \
${UFS_UTILS_DIR} \
${topo_dir} \
${tmp_dir}" \
  >> ${tmp_dir}/orog.file1

  aprun -j 1 -n 4 -N 4 -d 6 -cc depth cfp ${tmp_dir}/orog.file1
  rm_vrfy ${tmp_dir}/orog.file1
  ;;


"THEIA" | "HERA" | "JET" | "ODIN")
  ${ufs_utils_ushdir}/${orog_gen_scr} \
    $res ${TILE_RGNL} ${FIXsar} ${raw_dir} ${UFS_UTILS_DIR} ${topo_dir} ${tmp_dir} || \
  print_err_msg_exit "\
Call to script that generates raw orography file returned with nonzero
exit code."
  ;;


esac
#
#-----------------------------------------------------------------------
#
# For clarity, rename the tile 7 orography file such that its new name
# contains the halo size.  Then create a link whose name doesn't contain
# the halo size that points to this file.  This link must be present in 
# order for the filtering script called below to work properly (because
# that script does not allow the user to specify the name of the input
# raw orography file; it takes the resolution (RES) as an argument and
# forms the file name from CRES).
#
#-----------------------------------------------------------------------
#
cd_vrfy ${raw_dir}
mv_vrfy oro.${CRES}.tile${TILE_RGNL}.nc \
        oro.${CRES}.tile${TILE_RGNL}.halo${NHW}.nc
ln_vrfy -sf oro.${CRES}.tile${TILE_RGNL}.halo${NHW}.nc \
            oro.${CRES}.tile${TILE_RGNL}.nc
cd_vrfy -

print_info_msg "$VERBOSE" "
Orography file generation complete."
#
#-----------------------------------------------------------------------
#
# Set paramters used in filtering of the orography.
#
#-----------------------------------------------------------------------
#
print_info_msg "$VERBOSE" "
Setting orography filtering parameters..."

# Need to fix the following (also above).  Then redo to get cell_size_avg.
#cd_vrfy ${GRID_DIR}
#$SORCDIR/regional_grid/regional_grid $RGNL_GRID_NML_FP $CRES || \
#print_err_msg_exit "\ 
#Call to script that generates grid file (Jim Purser version) returned 
#with nonzero exit code."
#${CRES}_grid.tile${TILE_RGNL}.halo${NHW}.nc


#if [ "${GRID_GEN_METHOD}" = "GFDLgrid" ]; then
#  res_eff=$( bc -l <<< "$res*${GFDLgrid_REFINE_RATIO}" )
#elif [ "${GRID_GEN_METHOD}" = "JPgrid" ]; then
#  grid_size_eff=$( "(${JPgrid_DELX} + ${JPgrid_DELY})/2" )
#echo "grid_size_eff = $grid_size_eff"
#  res_eff=$( bc -l <<< "2*$pi_geom*$radius_Earth/(4*$grid_size_eff)" )
#fi
#res_eff=$( printf "%.0f\n" ${res_eff} )
#echo
#echo "res_eff = $res_eff"

# This will work for a JPgrid type of grid because for that case, RES 
# in the variable definitions file gets set to RES_equiv (by the make_-
# grid task), but this won't work for a GFDLgrid type of grid because if
# the stretch factor is not 1 in that case, RES_equiv will not be the 
# same as RES (because RES does not account for the stretch factor).
RES_equiv=$res

# Can also call it the "equivalent" global unstretched resolution.

RES_array=(         "48"    "96"    "192"   "384"   "768"   "1152"  "3072")
cd4_array=(         "0.12"  "0.12"  "0.15"  "0.15"  "0.15"  "0.15"  "0.15")
max_slope_array=(   "0.12"  "0.12"  "0.12"  "0.12"  "0.12"  "0.16"  "0.30")
n_del2_weak_array=( "4"     "8"     "12"    "12"    "16"    "20"    "24")
peak_fac_array=(    "1.1"   "1.1"   "1.05"  "1.0"   "1.0"   "1.0"   "1.0")

# Need to fix this so that the stderr from a failed call to interpol_to_arbit_CRES
# gets sent to the stderr of this script.
var_names=( "cd4" "max_slope" "n_del2_weak" "peak_fac" )
num_vars=${#var_names[@]}
for (( i=0; i<${num_vars}; i++ )); do
  var_name=${var_names[$i]}
  eval ${var_name}=$( interpol_to_arbit_CRES "${RES_equiv}" "RES_array" "${var_name}_array" ) || \
       print_err_msg_exit "\
Call to script that interpolated ${var_name} to the regional grid's equiavlent 
global cubed-sphere resolution (RES_equiv) failed:
  RES_equiv = \"${RES_equiv}\""
  var_value=${!var_name}
  echo "====>>>> ${var_name} = ${var_value}"
done


if [ 0 = 1 ]; then

case "$res" in
  48)
    export cd4=0.12; export max_slope=0.12; export n_del2_weak=4;  export peak_fac=1.1
    ;;
  96)
    export cd4=0.12; export max_slope=0.12; export n_del2_weak=8;  export peak_fac=1.1
    ;;
  192)
    export cd4=0.15; export max_slope=0.12; export n_del2_weak=12; export peak_fac=1.05
    ;;
  384)
    export cd4=0.15; export max_slope=0.12; export n_del2_weak=12; export peak_fac=1.0
    ;;
  768)
    export cd4=0.15; export max_slope=0.12; export n_del2_weak=16; export peak_fac=1.0
    ;;
  1152)
    export cd4=0.15; export max_slope=0.16; export n_del2_weak=20; export peak_fac=1.0
    ;;
  3072)
    export cd4=0.15; export max_slope=0.30; export n_del2_weak=24; export peak_fac=1.0
    ;;
  *)
# This needs to be fixed - i.e. what to do about regional grids that are
# not based on a parent global cubed-sphere grid.
    export cd4=0.15; export max_slope=0.30; export n_del2_weak=24; export peak_fac=1.0
    ;;
esac

fi

#
#-----------------------------------------------------------------------
#
# Generate a filtered orography file with a wide halo (i.e. with a halo
# width of NHW cells) for tile 7 from the corresponding raw orography
# file.
#
# The following will create a filtered orography file named
#
#   oro.${CRES}.tile7.nc
#
# and will place it in filter_dir.
#
# The orography filtering script orog_fltr_scr copies to filter_dir the
# tile 7 grid file and the grid mosaic file that were created in GRID_-
# DIR by the make_grid task as well as the raw tile 7 orography file 
# (with a wide halo) created above in OROG_DIR.  It also copies the exe-
# cutable that performs the fil-
# tering from EXECDIR to filter_dir and creates a namelist file that
# the executable needs as input.  When run, for each tile listed in the
# mosaic file, the executable replaces the raw orography file
# with its filtered counterpart (i.e. it gives the filtered file the
# same name as the original raw file).  Since in this (i.e.
# GTYPE="regional") case the mosaic file lists only tile 7, a filtered
# orography file is generated only for tile 7.  Thus, the grid files for
# the first 6 tiles that were created above in GRID_DIR are not used
# and thus do not need to be copied from GRID_DIR to filter_dir
# (to get this behavior required a small change to the orog_fltr_scr
# script that GSK has made).
#
#-----------------------------------------------------------------------
#
print_info_msg "$VERBOSE" "
Starting filtering of orography..."

# The script below creates absolute symlinks in $filter_dir.  That's 
# probably necessary for NCO but probably better to create relative 
# links for the community workflow.

# Have to create and export a new variable named gtype because the 
# script called below expects it to be in the environment.
export gtype="$GTYPE"
${ufs_utils_ushdir}/${orog_fltr_scr} \
  $res \
  ${FIXsar} ${raw_dir} ${filter_dir} \
  $cd4 ${peak_fac} ${max_slope} ${n_del2_weak} \
  ${ufs_utils_ushdir} || \
print_err_msg_exit "\
Call to script that generates filtered orography file returned with non-
zero exit code."
#
#-----------------------------------------------------------------------
#
# For clarity, rename the tile 7 filtered orography file in filter_dir
# such that its new name contains the halo size.  Then create a link
# whose name doesn't contain the halo size that points to the file.
#
#-----------------------------------------------------------------------
#
cd_vrfy ${filter_dir}
mv_vrfy oro.${CRES}.tile${TILE_RGNL}.nc \
        oro.${CRES}.tile${TILE_RGNL}.halo${NHW}.nc
#ln_vrfy -sf oro.${CRES}.tile${TILE_RGNL}.halo${NHW}.nc \
#            oro.${CRES}.tile${TILE_RGNL}.nc
cd_vrfy -

print_info_msg "$VERBOSE" "
Filtering of orography complete."
#
#-----------------------------------------------------------------------
#
# Partially "shave" the halo from the (filtered) orography file having a
# wide halo to generate two new orography files -- one without a halo
# and another with a 4-cell-wide halo.  These are needed as inputs by 
# FV3 as well as by the chgres_cube code to generate lateral boundary 
# condtion files.
# also sfc_climo???
#
#-----------------------------------------------------------------------
#

#
# Set the full path to the "unshaved" orography file, i.e. the one with
# a wide halo.  This is the input orography file for generating both the 
# orography file without a halo and the one with a 4-cell-wide halo.
#
#unshaved_fp="${filter_dir}/oro.${CRES}.tile${TILE_RGNL}.nc"
unshaved_fp="${filter_dir}/oro.${CRES}.tile${TILE_RGNL}.halo${NHW}.nc"
#
# We perform the work in shave_dir, so change location to that directo-
# ry.  Once it is complete, we move the resultant file from shave_dir to
# OROG_DIR.
#
cd_vrfy ${shave_dir}
#
# Create an input namelist file for the shave executable to generate an
# orography file without a halo from the one with a wide halo.  Then 
# call the shave executable.  Finally, move the resultant file to the 
# OROG_DIR directory.
#
print_info_msg "$VERBOSE" "
\"Shaving\" orography file with wide halo to obtain orography file with 
${NH0}-cell-wide halo..."

nml_fn="input.shave.orog.halo${NH0}"
shaved_fp="${shave_dir}/${CRES}_oro_data.tile${TILE_RGNL}.halo${NH0}.nc"
printf "%s %s %s %s %s\n" \
  $NX $NY ${NH0} \"${unshaved_fp}\" \"${shaved_fp}\" \
  > ${nml_fn}

$APRUN $EXECDIR/${shave_exec} < ${nml_fn} || \
print_err_msg_exit "\
Call to \"shave\" executable to generate (filtered) orography file with
a 4-cell wide halo returned with nonzero exit code.  The namelist file 
nml_fn is in directory shave_dir:
  shave_dir = \"${shave_dir}\"
  nml_fn = \"${nml_fn}\""
mv_vrfy ${shaved_fp} ${OROG_DIR}
#
# Create an input namelist file for the shave executable to generate an
# orography file with a 4-cell-wide halo from the one with a wide halo.  
# Then call the shave executable.  Finally, move the resultant file to
# the OROG_DIR directory.
#
print_info_msg "$VERBOSE" "
\"Shaving\" orography file with wide halo to obtain orography file with 
${NH4}-cell-wide halo..."

nml_fn="input.shave.orog.halo${NH4}"
shaved_fp="${shave_dir}/${CRES}_oro_data.tile${TILE_RGNL}.halo${NH4}.nc"
printf "%s %s %s %s %s\n" \
  $NX $NY ${NH4} \"${unshaved_fp}\" \"${shaved_fp}\" \
  > ${nml_fn}

$APRUN $EXECDIR/${shave_exec} < ${nml_fn} || \
print_err_msg_exit "\
Call to \"shave\" executable to generate (filtered) orography file with
a 4-cell wide halo returned with nonzero exit code.  The namelist file 
nml_fn is in directory shave_dir:
  shave_dir = \"${shave_dir}\"
  nml_fn = \"${nml_fn}\""
mv_vrfy ${shaved_fp} ${OROG_DIR}
#
# Change location back to the directory before shave_dir.
#
cd_vrfy -
#
#-----------------------------------------------------------------------
#
# Add links in ORIG_DIR directory to the orography file with a 4-cell-
# wide halo such that the link name do not contain the halo width.  
# These links are needed by the make_sfc_climo task.
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

# Moved the following to exregional_make_sfc_climo.sh script since it 
# needs to be done only if the make_sfc_climo task is run.

#print_info_msg "$VERBOSE" "
#Creating links needed by the make_sfc_climo task to the 4-halo grid and
#orography files..."
#
if [ 0 = 1 ]; then
cd_vrfy ${OROG_DIR}
ln_vrfy -sf ${CRES}_oro_data.tile${TILE_RGNL}.halo${NH4}.nc \
            ${CRES}_oro_data.tile${TILE_RGNL}.nc
fi


#
#-----------------------------------------------------------------------
#
# Create symlinks in the FIXSAR directory pointing to the orography 
# files.  These symlinks are needed by the make_orog, make_sfc_climo, 
# make_ic, make_lbc, and/or run_fcst tasks.
#
#-----------------------------------------------------------------------
#
if [ 0 = 1 ]; then
cd_vrfy ${FIXsar}

filename="${CRES}_oro_data.tile${TILE_RGNL}.halo${NH0}.nc"
ln_vrfy --relative -sf ${OROG_DIR}/$filename $FIXsar
ln_vrfy -sf $filename oro_data.nc

filename="${CRES}_oro_data.tile${TILE_RGNL}.halo${NH4}.nc"
ln_vrfy --relative -sf ${OROG_DIR}/$filename $FIXsar
ln_vrfy -sf $filename oro_data.tile${TILE_RGNL}.halo${NH4}.nc
ln_vrfy -sf $filename oro_data.tile${TILE_RGNL}.nc
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


