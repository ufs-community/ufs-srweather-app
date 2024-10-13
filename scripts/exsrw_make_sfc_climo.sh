#!/usr/bin/env bash

#
#-----------------------------------------------------------------------
#
# This ex-script generates surface climatology files needed to run FV3
# forecasts.
#
# The script runs the sfc_climo_gen UFS Utils program, and links the
# output to the SFC_CLIMO_GEN directory
#
#-----------------------------------------------------------------------
#
set -xue
#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. ${PARMsrw}/source_util_funcs.sh
task_global_vars=( "KMP_AFFINITY_MAKE_SFC_CLIMO" \
  "OMP_NUM_THREADS_MAKE_SFC_CLIMO" "OMP_STACKSIZE_MAKE_SFC_CLIMO" \
  "PREDEF_GRID_NAME" "FIXsfc" "FIXlam" "CRES" "DOT_OR_USCORE" "NH4" \
  "TILE_RGNL" "PRE_TASK_CMDS" "RUN_CMD_UTILS" "GTYPE" "SFC_CLIMO_DIR" \
  "NH0" )
for var in ${task_global_vars[@]}; do
  source_config_for_task ${var} ${GLOBAL_VAR_DEFNS_FP}
done
#
#-----------------------------------------------------------------------
#
# Save current shell options (in a global array).  Then set new options
# for this script/function.
#
#-----------------------------------------------------------------------
#
#{ save_shell_opts; set -xue; } > /dev/null 2>&1
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

This is the ex-script for the task that generates surface fields from
climatology.
========================================================================"
#
#-----------------------------------------------------------------------
#
# Set OpenMP variables.
#
#-----------------------------------------------------------------------
#
export KMP_AFFINITY=${KMP_AFFINITY_MAKE_SFC_CLIMO}
export OMP_NUM_THREADS=${OMP_NUM_THREADS_MAKE_SFC_CLIMO}
export OMP_STACKSIZE=${OMP_STACKSIZE_MAKE_SFC_CLIMO}
#
#-----------------------------------------------------------------------
#
# Create the namelist that the sfc_climo_gen code will read in.
#
#-----------------------------------------------------------------------
#
if [ "${PREDEF_GRID_NAME}" = "RRFS_FIREWX_1.5km" ]; then
  input_substrate_temperature_file="${FIXsfc}/substrate_temperature.gfs.0.5.nc"
  input_soil_type_file="${FIXsfc}/soil_type.bnu.v2.30s.nc"
  input_vegetation_type_file="${FIXsfc}/vegetation_type.viirs.v2.igbp.30s.nc"
  vegsoilt_frac=.true.
else
  input_substrate_temperature_file="${FIXsfc}/substrate_temperature.2.6x1.5.nc"
  input_soil_type_file="${FIXsfc}/soil_type.statsgo.0.05.nc"
  input_vegetation_type_file="${FIXsfc}/vegetation_type.igbp.0.05.nc"
  vegsoilt_frac=.false.
fi

cat << EOF > ./fort.41
&config
input_facsf_file="${FIXsfc}/facsf.1.0.nc"
input_substrate_temperature_file="${input_substrate_temperature_file}"
input_maximum_snow_albedo_file="${FIXsfc}/maximum_snow_albedo.0.05.nc"
input_snowfree_albedo_file="${FIXsfc}/snowfree_albedo.4comp.0.05.nc"
input_slope_type_file="${FIXsfc}/slope_type.1.0.nc"
input_soil_type_file="${input_soil_type_file}"
input_vegetation_type_file="${input_vegetation_type_file}"
input_vegetation_greenness_file="${FIXsfc}/vegetation_greenness.0.144.nc"
mosaic_file_mdl="${FIXlam}/${CRES}${DOT_OR_USCORE}mosaic.halo${NH4}.nc"
orog_dir_mdl="${FIXlam}"
orog_files_mdl="${CRES}${DOT_OR_USCORE}oro_data.tile${TILE_RGNL}.halo${NH4}.nc"
halo=${NH4}
maximum_snow_albedo_method="bilinear"
snowfree_albedo_method="bilinear"
vegetation_greenness_method="bilinear"
fract_vegsoil_type=${vegsoilt_frac}
/
EOF
#
#-----------------------------------------------------------------------
#
# Set the machine-dependent run command.
#
#-----------------------------------------------------------------------
#
eval ${PRE_TASK_CMDS}

if [ -z "${RUN_CMD_UTILS:-}" ] ; then
  print_err_msg_exit "\
  Run command was not set in machine file. \
  Please set RUN_CMD_UTILS for your platform"
else
  print_info_msg "All executables will be submitted with \'${RUN_CMD_UTILS}\'."
fi
#
#-----------------------------------------------------------------------
#
# Generate the surface climatology files.
#
#-----------------------------------------------------------------------
#
export pgm="sfc_climo_gen"
. prep_step

eval ${RUN_CMD_UTILS} ${EXECsrw}/$pgm >>$pgmout 2>errfile
export err=$?; err_chk
#
#-----------------------------------------------------------------------
#
# Move output files out of the temporary directory.
#
#-----------------------------------------------------------------------
#
case "$GTYPE" in

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
      mv $fn ${SFC_CLIMO_DIR}/${CRES}_${fn}
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
      mv $fn ${SFC_CLIMO_DIR}/${CRES}.${bn}.halo${NH4}.nc
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
      mv $fn ${SFC_CLIMO_DIR}/${CRES}.${bn}.halo${NH0}.nc
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
${PARMsrw}/link_fix.py \
  --path-to-defns ${GLOBAL_VAR_DEFNS_FP} \
  --file-group "sfc_climo" || \
print_err_msg_exit "\
Call to function to create links to surface climatology files failed."
#
#-----------------------------------------------------------------------
#
# Print message indicating successful completion of script.
#
#-----------------------------------------------------------------------
#
print_info_msg "
========================================================================
All surface climatology files generated successfully!!!

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
#{ restore_shell_opts; } > /dev/null 2>&1
