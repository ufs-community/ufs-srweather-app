#
#-----------------------------------------------------------------------
#
# This file defines and then calls a function that sets the parameters
# for a grid that is to be generated using the "ESGgrid" grid generation 
# method (i.e. GRID_GEN_METHOD set to "ESGgrid").
#
#-----------------------------------------------------------------------
#
function set_gridparams_ESGgrid() {
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
  local valid_args=( \
"lon_ctr" \
"lat_ctr" \
"nx" \
"ny" \
"halo_width" \
"delx" \
"dely" \
"pazi" \
"output_varname_lon_ctr" \
"output_varname_lat_ctr" \
"output_varname_nx" \
"output_varname_ny" \
"output_varname_pazi" \
"output_varname_halo_width" \
"output_varname_stretch_factor" \
"output_varname_del_angle_x_sg" \
"output_varname_del_angle_y_sg" \
"output_varname_neg_nx_of_dom_with_wide_halo" \
"output_varname_neg_ny_of_dom_with_wide_halo" \
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
# Source the file containing various mathematical, physical, etc constants.
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
  local stretch_factor \
        del_angle_x_sg \
        del_angle_y_sg \
        neg_nx_of_dom_with_wide_halo \
        neg_ny_of_dom_with_wide_halo
#
#-----------------------------------------------------------------------
#
# For a ESGgrid-type grid, the orography filtering is performed by pass-
# ing to the orography filtering the parameters for an "equivalent" glo-
# bal uniform cubed-sphere grid.  These are the parameters that a global
# uniform cubed-sphere grid needs to have in order to have a nominal 
# grid cell size equal to that of the (average) cell size on the region-
# al grid.  These globally-equivalent parameters include a resolution 
# (in units of number of cells in each of the two horizontal directions)
# and a stretch factor.  The equivalent resolution is calculated in the
# script that generates the grid, and the stretch factor needs to be set
# to 1 because we are considering an equivalent globally UNIFORM grid.  
# However, it turns out that with a non-symmetric regional grid (one in
# which nx is not equal to ny), setting stretch_factor to 1 fails be-
# cause the orography filtering program is designed for a global cubed-
# sphere grid and thus assumes that nx and ny for a given tile are equal
# when stretch_factor is exactly equal to 1.                            <-- Why is this?  Seems like symmetry btwn x and y should still hold when the stretch factor is not equal to 1.  
# It turns out that the program will work if we set stretch_factor to a 
# value that is not exactly 1.  This is what we do below. 
#
#-----------------------------------------------------------------------
#
  stretch_factor="0.999"   # Check whether the orography program has been fixed so that we can set this to 1...
#
#-----------------------------------------------------------------------
#
# Set parameters needed as inputs to the regional_grid grid generation
# code.
#
#-----------------------------------------------------------------------
#
  del_angle_x_sg=$( bc -l <<< "(${delx}/(2.0*${radius_Earth}))*${degs_per_radian}" )
  del_angle_x_sg=$( printf "%0.10f\n" ${del_angle_x_sg} )

  del_angle_y_sg=$( bc -l <<< "(${dely}/(2.0*${radius_Earth}))*${degs_per_radian}" )
  del_angle_y_sg=$( printf "%0.10f\n" ${del_angle_y_sg} )

  neg_nx_of_dom_with_wide_halo=$( bc -l <<< "-($nx + 2*${halo_width})" )
  neg_nx_of_dom_with_wide_halo=$( printf "%.0f\n" ${neg_nx_of_dom_with_wide_halo} )

  neg_ny_of_dom_with_wide_halo=$( bc -l <<< "-($ny + 2*${halo_width})" )
  neg_ny_of_dom_with_wide_halo=$( printf "%.0f\n" ${neg_ny_of_dom_with_wide_halo} )
#
#-----------------------------------------------------------------------
#
# Set output variables.
#
#-----------------------------------------------------------------------
#
  eval ${output_varname_lon_ctr}="${lon_ctr}"
  eval ${output_varname_lat_ctr}="${lat_ctr}"
  eval ${output_varname_nx}="${nx}"
  eval ${output_varname_ny}="${ny}"
  eval ${output_varname_halo_width}="${halo_width}"
  eval ${output_varname_stretch_factor}="${stretch_factor}"
  eval ${output_varname_pazi}="${pazi}"
  eval ${output_varname_del_angle_x_sg}="${del_angle_x_sg}"
  eval ${output_varname_del_angle_y_sg}="${del_angle_y_sg}"
  eval ${output_varname_neg_nx_of_dom_with_wide_halo}="${neg_nx_of_dom_with_wide_halo}"
  eval ${output_varname_neg_ny_of_dom_with_wide_halo}="${neg_ny_of_dom_with_wide_halo}"
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

