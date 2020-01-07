#
#-----------------------------------------------------------------------
#
# This file defines and then calls a function that sets the parameters
# for a grid that is to be generated using the "JPgrid" grid generation 
# method (i.e. GRID_GEN_METHOD set to "JPgrid").
#
#-----------------------------------------------------------------------
#
function set_gridparams_JPgrid() {
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
  local scrfunc_fp=$( readlink -f "${BASH_SOURCE[0]}" )
  local scrfunc_fn=$( basename "${scrfunc_fp}" )
  local scrfunc_dir=$( dirname "${scrfunc_fp}" )
#
#-----------------------------------------------------------------------
#
# Get the name of this function.
#
#-----------------------------------------------------------------------
#
  local func_name="${FUNCNAME[0]}"
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
"jpgrid_lon_ctr" \
"jpgrid_lat_ctr" \
"jpgrid_nx" \
"jpgrid_ny" \
"jpgrid_nhw" \
"jpgrid_delx" \
"jpgrid_dely" \
"jpgrid_alpha" \
"jpgrid_kappa" \
"output_varname_lon_ctr" \
"output_varname_lat_ctr" \
"output_varname_nx" \
"output_varname_ny" \
"output_varname_nhw" \
"output_varname_del_angle_x_sg" \
"output_varname_del_angle_y_sg" \
"output_varname_mns_nx_pls_wide_halo" \
"output_varname_mns_ny_pls_wide_halo" \
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
# Source the file containing various mathematical, physical, etc cons-
# tants.
#
#-----------------------------------------------------------------------
#
  . ${USHDIR}/constants.sh
#
#-----------------------------------------------------------------------
#
# Declare local variables.
#
#-----------------------------------------------------------------------
#
  local del_angle_x_sg \
        del_angle_y_sg \
        mns_nx_pls_wide_halo \
        mns_ny_pls_wide_halo
#
#-----------------------------------------------------------------------
#
# Set parameters needed as inputs to the regional_grid grid generation
# code.
#
#-----------------------------------------------------------------------
#
  del_angle_x_sg=$( bc -l <<< "(${jpgrid_delx}/(2.0*${radius_Earth}))*${degs_per_radian}" )
  del_angle_x_sg=$( printf "%0.10f\n" ${del_angle_x_sg} )

  del_angle_y_sg=$( bc -l <<< "(${jpgrid_dely}/(2.0*${radius_Earth}))*${degs_per_radian}" )
  del_angle_y_sg=$( printf "%0.10f\n" ${del_angle_y_sg} )

  mns_nx_pls_wide_halo=$( bc -l <<< "-(${JPgrid_NX} + 2*${JPgrid_WIDE_HALO_WIDTH})" )
  mns_nx_pls_wide_halo=$( printf "%.0f\n" ${mns_nx_pls_wide_halo} )

  mns_ny_pls_wide_halo=$( bc -l <<< "-(${JPgrid_NY} + 2*${JPgrid_WIDE_HALO_WIDTH})" )
  mns_ny_pls_wide_halo=$( printf "%.0f\n" ${mns_ny_pls_wide_halo} )
#
#-----------------------------------------------------------------------
#
# Set output variables.
#
#-----------------------------------------------------------------------
#
  eval ${output_varname_lon_ctr}="${jpgrid_lon_ctr}"
  eval ${output_varname_lat_ctr}="${jpgrid_lat_ctr}"
  eval ${output_varname_nx}="${jpgrid_nx}"
  eval ${output_varname_ny}="${jpgrid_ny}"
  eval ${output_varname_nhw}="${jpgrid_nhw}"
  eval ${output_varname_del_angle_x_sg}="${del_angle_x_sg}"
  eval ${output_varname_del_angle_y_sg}="${del_angle_y_sg}"
  eval ${output_varname_mns_nx_pls_wide_halo}="${mns_nx_pls_wide_halo}"
  eval ${output_varname_mns_ny_pls_wide_halo}="${mns_ny_pls_wide_halo}"
#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script/func-
# tion.
#
#-----------------------------------------------------------------------
#
  { restore_shell_opts; } > /dev/null 2>&1

}

