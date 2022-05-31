#
#-----------------------------------------------------------------------
#
# This file defines and then calls a function that sets grid parameters
# for the specified predefined grid.
#
#-----------------------------------------------------------------------
#
function set_predef_grid_params() {
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
  local scrfunc_fp=$( $READLINK -f "${BASH_SOURCE[0]}" )
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
# Set directories.
#
#-----------------------------------------------------------------------
#
  local homerrfs=${scrfunc_dir%/*}
  local ushdir="$homerrfs/ush"
#
#-----------------------------------------------------------------------
#
# Source the file containing various mathematical, physical, etc constants.
#
#-----------------------------------------------------------------------
#
  . $ushdir/constants.sh
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
    "predef_grid_name" \
    "dt_atmos" \
    "layout_x" \
    "layout_y" \
    "blocksize" \
    "quilting" \
    "outvarname_grid_gen_method" \
    "outvarname_esggrid_lon_ctr" \
    "outvarname_esggrid_lat_ctr" \
    "outvarname_esggrid_delx" \
    "outvarname_esggrid_dely" \
    "outvarname_esggrid_nx" \
    "outvarname_esggrid_ny" \
    "outvarname_esggrid_pazi" \
    "outvarname_esggrid_wide_halo_width" \
    "outvarname_gfdlgrid_lon_t6_ctr" \
    "outvarname_gfdlgrid_lat_t6_ctr" \
    "outvarname_gfdlgrid_stretch_fac" \
    "outvarname_gfdlgrid_res" \
    "outvarname_gfdlgrid_refine_ratio" \
    "outvarname_gfdlgrid_istart_of_rgnl_dom_on_t6g" \
    "outvarname_gfdlgrid_iend_of_rgnl_dom_on_t6g" \
    "outvarname_gfdlgrid_jstart_of_rgnl_dom_on_t6g" \
    "outvarname_gfdlgrid_jend_of_rgnl_dom_on_t6g" \
    "outvarname_gfdlgrid_use_gfdlgrid_res_in_filenames" \
    "outvarname_dt_atmos" \
    "outvarname_layout_x" \
    "outvarname_layout_y" \
    "outvarname_blocksize" \
    "outvarname_wrtcmp_write_groups" \
    "outvarname_wrtcmp_write_tasks_per_group" \
    "outvarname_wrtcmp_output_grid" \
    "outvarname_wrtcmp_cen_lon" \
    "outvarname_wrtcmp_cen_lat" \
    "outvarname_wrtcmp_stdlat1" \
    "outvarname_wrtcmp_stdlat2" \
    "outvarname_wrtcmp_nx" \
    "outvarname_wrtcmp_ny" \
    "outvarname_wrtcmp_lon_lwr_left" \
    "outvarname_wrtcmp_lat_lwr_left" \
    "outvarname_wrtcmp_lon_upr_rght" \
    "outvarname_wrtcmp_lat_upr_rght" \
    "outvarname_wrtcmp_dx" \
    "outvarname_wrtcmp_dy" \
    "outvarname_wrtcmp_dlon" \
    "outvarname_wrtcmp_dlat" \
    )
  process_args "valid_args" "$@"
#
#-----------------------------------------------------------------------
#
# Declare and initialize local variables.
#
#-----------------------------------------------------------------------
#
  local __grid_gen_method__="" \
        __esggrid_lon_ctr__="" \
        __esggrid_lat_ctr__="" \
        __esggrid_delx__="" \
        __esggrid_dely__="" \
        __esggrid_nx__="" \
        __esggrid_ny__="" \
        __esggrid_pazi__="" \
        __esggrid_wide_halo_width__="" \
        __gfdlgrid_lon_t6_ctr__="" \
        __gfdlgrid_lat_t6_ctr__="" \
        __gfdlgrid_stretch_fac__="" \
        __gfdlgrid_res__="" \
        __gfdlgrid_refine_ratio__="" \
        __gfdlgrid_istart_of_rgnl_dom_on_t6g__="" \
        __gfdlgrid_iend_of_rgnl_dom_on_t6g__="" \
        __gfdlgrid_jstart_of_rgnl_dom_on_t6g__="" \
        __gfdlgrid_jend_of_rgnl_dom_on_t6g__="" \
        __gfdlgrid_use_gfdlgrid_res_in_filenames__="" \
        __dt_atmos__="" \
        __layout_x__="" \
        __layout_y__="" \
        __blocksize__="" \
        __wrtcmp_write_groups__="" \
        __wrtcmp_write_tasks_per_group__="" \
        __wrtcmp_output_grid__="" \
        __wrtcmp_cen_lon__="" \
        __wrtcmp_cen_lat__="" \
        __wrtcmp_stdlat1__="" \
        __wrtcmp_stdlat2__="" \
        __wrtcmp_nx__="" \
        __wrtcmp_ny__="" \
        __wrtcmp_lon_lwr_left__="" \
        __wrtcmp_lat_lwr_left__="" \
        __wrtcmp_lon_upr_rght__="" \
        __wrtcmp_lat_upr_rght__="" \
        __wrtcmp_dx__="" \
        __wrtcmp_dy__="" \
        __wrtcmp_dlon__="" \
        __wrtcmp_dlat__="" \
        num_margin_cells_T6_left="" \
        num_margin_cells_T6_right="" \
        num_margin_cells_T6_bottom="" \
        num_margin_cells_T6_top=""
#
#-----------------------------------------------------------------------
#
# For debugging purposes, print out values of arguments passed to this
# script.  Note that these will be printed out only if VERBOSE is set to
# TRUE.
#
#-----------------------------------------------------------------------
#
#  print_input_args valid_args
#
#-----------------------------------------------------------------------
#
# Make sure that the input argument "quilting" is set to a valid value.
#
#-----------------------------------------------------------------------
#
  check_var_valid_value "quilting" "valid_vals_BOOLEAN"
  quilting=$(boolify "$quilting")
#
#-----------------------------------------------------------------------
#
# Set grid and other parameters according to the value of the predefined
# domain (predef_grid_name).  Note that the code will enter this script
# only if predef_grid_name has a valid (and non-empty) value.
#
####################
# The following comments need to be updated:
####################
#
# 1) Reset the experiment title (expt_title).
# 2) Reset the grid parameters.
# 3) If the write component is to be used (i.e. "quilting" is set to
#    "TRUE") and the variable WRTCMP_PARAMS_TMPL_FN containing the name
#    of the write-component template file is unset or empty, set that
#    filename variable to the appropriate preexisting template file.
#
# For the predefined domains, we determine the starting and ending indi-
# ces of the regional grid within tile 6 by specifying margins (in units
# of number of cells on tile 6) between the boundary of tile 6 and that
# of the regional grid (tile 7) along the left, right, bottom, and top
# portions of these boundaries.  Note that we do not use "west", "east",
# "south", and "north" here because the tiles aren't necessarily orient-
# ed such that the left boundary segment corresponds to the west edge,
# etc.  The widths of these margins (in units of number of cells on tile
# 6) are specified via the parameters
#
#   num_margin_cells_T6_left
#   num_margin_cells_T6_right
#   num_margin_cells_T6_bottom
#   num_margin_cells_T6_top
#
# where the "_T6" in these names is used to indicate that the cell count
# is on tile 6, not tile 7.
#
# Note that we must make the margins wide enough (by making the above
# four parameters large enough) such that a region of halo cells around
# the boundary of the regional grid fits into the margins, i.e. such
# that the halo does not overrun the boundary of tile 6.  (The halo is
# added later in another script; its function is to feed in boundary
# conditions to the regional grid.)  Currently, a halo of 5 regional
# grid cells is used around the regional grid.  Setting num_margin_-
# cells_T6_... to at least 10 leaves enough room for this halo.
#
#-----------------------------------------------------------------------
#
  case "${predef_grid_name}" in
#
#-----------------------------------------------------------------------
#
# The RRFS CONUS domain with ~25km cells.
#
#-----------------------------------------------------------------------
#
  "RRFS_CONUS_25km")

    __grid_gen_method__="ESGgrid"

    __esggrid_lon_ctr__="-97.5"
    __esggrid_lat_ctr__="38.5"

    __esggrid_delx__="25000.0"
    __esggrid_dely__="25000.0"

    __esggrid_nx__="219"
    __esggrid_ny__="131"

    __esggrid_pazi__="0.0"

    __esggrid_wide_halo_width__="6"

    __dt_atmos__="${dt_atmos:-40}"

    __layout_x__="${layout_x:-5}"
    __layout_y__="${layout_y:-2}"
    __blocksize__="${blocksize:-40}"

    if [ "$quilting" = "TRUE" ]; then
      __wrtcmp_write_groups__="1"
      __wrtcmp_write_tasks_per_group__="2"
      __wrtcmp_output_grid__="lambert_conformal"
      __wrtcmp_cen_lon__="${__esggrid_lon_ctr__}"
      __wrtcmp_cen_lat__="${__esggrid_lat_ctr__}"
      __wrtcmp_stdlat1__="${__esggrid_lat_ctr__}"
      __wrtcmp_stdlat2__="${__esggrid_lat_ctr__}"
      __wrtcmp_nx__="217"
      __wrtcmp_ny__="128"
      __wrtcmp_lon_lwr_left__="-122.719528"
      __wrtcmp_lat_lwr_left__="21.138123"
      __wrtcmp_dx__="${__esggrid_delx__}"
      __wrtcmp_dy__="${__esggrid_dely__}"
    fi
    ;;
#
#-----------------------------------------------------------------------
#
# The RRFS CONUS domain with ~25km cells that can be initialized from
# the HRRR.
#
#-----------------------------------------------------------------------
#
  "RRFS_CONUScompact_25km")

    __grid_gen_method__="ESGgrid"

    __esggrid_lon_ctr__="-97.5"
    __esggrid_lat_ctr__="38.5"

    __esggrid_delx__="25000.0"
    __esggrid_dely__="25000.0"

    __esggrid_nx__="202"
    __esggrid_ny__="116"

    __esggrid_pazi__="0.0"

    __esggrid_wide_halo_width__="6"

    __dt_atmos__="${dt_atmos:-40}"

    __layout_x__="${layout_x:-5}"
    __layout_y__="${layout_y:-2}"
    __blocksize__="${blocksize:-40}"

    if [ "$quilting" = "TRUE" ]; then
      __wrtcmp_write_groups__="1"
      __wrtcmp_write_tasks_per_group__="2"
      __wrtcmp_output_grid__="lambert_conformal"
      __wrtcmp_cen_lon__="${__esggrid_lon_ctr__}"
      __wrtcmp_cen_lat__="${__esggrid_lat_ctr__}"
      __wrtcmp_stdlat1__="${__esggrid_lat_ctr__}"
      __wrtcmp_stdlat2__="${__esggrid_lat_ctr__}"
      __wrtcmp_nx__="199"
      __wrtcmp_ny__="111"
      __wrtcmp_lon_lwr_left__="-121.23349066"
      __wrtcmp_lat_lwr_left__="23.41731593"
      __wrtcmp_dx__="${__esggrid_delx__}"
      __wrtcmp_dy__="${__esggrid_dely__}"
    fi
    ;;
#
#-----------------------------------------------------------------------
#
# The RRFS CONUS domain with ~13km cells.
#
#-----------------------------------------------------------------------
#
  "RRFS_CONUS_13km")

    __grid_gen_method__="ESGgrid"

    __esggrid_lon_ctr__="-97.5"
    __esggrid_lat_ctr__="38.5"

    __esggrid_delx__="13000.0"
    __esggrid_dely__="13000.0"

    __esggrid_nx__="420"
    __esggrid_ny__="252"

    __esggrid_pazi__="0.0"

    __esggrid_wide_halo_width__="6"

    __dt_atmos__="${dt_atmos:-45}"

    __layout_x__="${layout_x:-16}"
    __layout_y__="${layout_y:-10}"
    __blocksize__="${blocksize:-32}"

    if [ "$quilting" = "TRUE" ]; then
      __wrtcmp_write_groups__="1"
      __wrtcmp_write_tasks_per_group__=$(( 1*__layout_y__ ))
      __wrtcmp_output_grid__="lambert_conformal"
      __wrtcmp_cen_lon__="${__esggrid_lon_ctr__}"
      __wrtcmp_cen_lat__="${__esggrid_lat_ctr__}"
      __wrtcmp_stdlat1__="${__esggrid_lat_ctr__}"
      __wrtcmp_stdlat2__="${__esggrid_lat_ctr__}"
      __wrtcmp_nx__="416"
      __wrtcmp_ny__="245"
      __wrtcmp_lon_lwr_left__="-122.719528"
      __wrtcmp_lat_lwr_left__="21.138123"
      __wrtcmp_dx__="${__esggrid_delx__}"
      __wrtcmp_dy__="${__esggrid_dely__}"
    fi
    ;;
#
#-----------------------------------------------------------------------
#
# The RRFS CONUS domain with ~13km cells that can be initialized from the HRRR.
#
#-----------------------------------------------------------------------
#
  "RRFS_CONUScompact_13km")

    __grid_gen_method__="ESGgrid"

    __esggrid_lon_ctr__="-97.5"
    __esggrid_lat_ctr__="38.5"

    __esggrid_delx__="13000.0"
    __esggrid_dely__="13000.0"

    __esggrid_nx__="396"
    __esggrid_ny__="232"

    __esggrid_pazi__="0.0"

    __esggrid_wide_halo_width__="6"

    __dt_atmos__="${dt_atmos:-45}"

    __layout_x__="${layout_x:-16}"
    __layout_y__="${layout_y:-10}"
    __blocksize__="${blocksize:-32}"

    if [ "$quilting" = "TRUE" ]; then
      __wrtcmp_write_groups__="1"
      __wrtcmp_write_tasks_per_group__=$(( 1*__layout_y__ ))
      __wrtcmp_output_grid__="lambert_conformal"
      __wrtcmp_cen_lon__="${__esggrid_lon_ctr__}"
      __wrtcmp_cen_lat__="${__esggrid_lat_ctr__}"
      __wrtcmp_stdlat1__="${__esggrid_lat_ctr__}"
      __wrtcmp_stdlat2__="${__esggrid_lat_ctr__}"
      __wrtcmp_nx__="393"
      __wrtcmp_ny__="225"
      __wrtcmp_lon_lwr_left__="-121.70231097"
      __wrtcmp_lat_lwr_left__="22.57417972"
      __wrtcmp_dx__="${__esggrid_delx__}"
      __wrtcmp_dy__="${__esggrid_dely__}"
    fi
    ;;
#
#-----------------------------------------------------------------------
#
# The RRFS CONUS domain with ~3km cells.
#
#-----------------------------------------------------------------------
#
  "RRFS_CONUS_3km")

    __grid_gen_method__="ESGgrid"

    __esggrid_lon_ctr__="-97.5"
    __esggrid_lat_ctr__="38.5"

    __esggrid_delx__="3000.0"
    __esggrid_dely__="3000.0"

    __esggrid_nx__="1820"
    __esggrid_ny__="1092"

    __esggrid_pazi__="0.0"

    __esggrid_wide_halo_width__="6"

    __dt_atmos__="${dt_atmos:-36}"

    __layout_x__="${layout_x:-28}"
    __layout_y__="${layout_y:-28}"
    __blocksize__="${blocksize:-29}"

    if [ "$quilting" = "TRUE" ]; then
      __wrtcmp_write_groups__="1"
      __wrtcmp_write_tasks_per_group__=$(( 1*__layout_y__ ))
      __wrtcmp_output_grid__="lambert_conformal"
      __wrtcmp_cen_lon__="${__esggrid_lon_ctr__}"
      __wrtcmp_cen_lat__="${__esggrid_lat_ctr__}"
      __wrtcmp_stdlat1__="${__esggrid_lat_ctr__}"
      __wrtcmp_stdlat2__="${__esggrid_lat_ctr__}"
      __wrtcmp_nx__="1799"
      __wrtcmp_ny__="1059"
      __wrtcmp_lon_lwr_left__="-122.719528"
      __wrtcmp_lat_lwr_left__="21.138123"
      __wrtcmp_dx__="${__esggrid_delx__}"
      __wrtcmp_dy__="${__esggrid_dely__}"
    fi
    ;;
#
#-----------------------------------------------------------------------
#
# The RRFS CONUS domain with ~3km cells that can be initialized from
# the HRRR.
#
#-----------------------------------------------------------------------
#
  "RRFS_CONUScompact_3km")

    __grid_gen_method__="ESGgrid"

    __esggrid_lon_ctr__="-97.5"
    __esggrid_lat_ctr__="38.5"

    __esggrid_delx__="3000.0"
    __esggrid_dely__="3000.0"

    __esggrid_nx__="1748"
    __esggrid_ny__="1038"

    __esggrid_pazi__="0.0"

    __esggrid_wide_halo_width__="6"

    __dt_atmos__="${dt_atmos:-40}"

    __layout_x__="${layout_x:-30}"
    __layout_y__="${layout_y:-16}"
    __blocksize__="${blocksize:-32}"

    if [ "$quilting" = "TRUE" ]; then
      __wrtcmp_write_groups__="1"
      __wrtcmp_write_tasks_per_group__=$(( 1*__layout_y__ ))
      __wrtcmp_output_grid__="lambert_conformal"
      __wrtcmp_cen_lon__="${__esggrid_lon_ctr__}"
      __wrtcmp_cen_lat__="${__esggrid_lat_ctr__}"
      __wrtcmp_stdlat1__="${__esggrid_lat_ctr__}"
      __wrtcmp_stdlat2__="${__esggrid_lat_ctr__}"
      __wrtcmp_nx__="1746"
      __wrtcmp_ny__="1014"
      __wrtcmp_lon_lwr_left__="-122.17364391"
      __wrtcmp_lat_lwr_left__="21.88588562"
      __wrtcmp_dx__="${__esggrid_delx__}"
      __wrtcmp_dy__="${__esggrid_dely__}"
    fi
    ;;
#
#-----------------------------------------------------------------------
#
# The RRFS SUBCONUS domain with ~3km cells.
#
#-----------------------------------------------------------------------
#
  "RRFS_SUBCONUS_3km")

    __grid_gen_method__="ESGgrid"

    __esggrid_lon_ctr__="-97.5"
    __esggrid_lat_ctr__="35.0"

    __esggrid_delx__="3000.0"
    __esggrid_dely__="3000.0"

    __esggrid_nx__="840"
    __esggrid_ny__="600"

    __esggrid_pazi__="0.0"

    __esggrid_wide_halo_width__="6"

    __dt_atmos__="${dt_atmos:-40}"

    __layout_x__="${layout_x:-30}"
    __layout_y__="${layout_y:-24}"
    __blocksize__="${blocksize:-35}"

    if [ "$quilting" = "TRUE" ]; then
      __wrtcmp_write_groups__="1"
      __wrtcmp_write_tasks_per_group__=$(( 1*__layout_y__ ))
      __wrtcmp_output_grid__="lambert_conformal"
      __wrtcmp_cen_lon__="${__esggrid_lon_ctr__}"
      __wrtcmp_cen_lat__="${__esggrid_lat_ctr__}"
      __wrtcmp_stdlat1__="${__esggrid_lat_ctr__}"
      __wrtcmp_stdlat2__="${__esggrid_lat_ctr__}"
      __wrtcmp_nx__="837"
      __wrtcmp_ny__="595"
      __wrtcmp_lon_lwr_left__="-109.97410429"
      __wrtcmp_lat_lwr_left__="26.31459843"
      __wrtcmp_dx__="${__esggrid_delx__}"
      __wrtcmp_dy__="${__esggrid_dely__}"
    fi
    ;;
#
#-----------------------------------------------------------------------
#
# A subconus domain over Indianapolis, Indiana with ~3km cells.  This is
# mostly for testing on a 3km grid with a much small number of cells than
# on the full CONUS.
#
#-----------------------------------------------------------------------
#
  "SUBCONUS_Ind_3km")

    __grid_gen_method__="ESGgrid"

    __esggrid_lon_ctr__="-86.16"
    __esggrid_lat_ctr__="39.77"

    __esggrid_delx__="3000.0"
    __esggrid_dely__="3000.0"

    __esggrid_nx__="200"
    __esggrid_ny__="200"

    __esggrid_pazi__="0.0"

    __esggrid_wide_halo_width__="6"

    __dt_atmos__="${dt_atmos:-40}"

    __layout_x__="${layout_x:-5}"
    __layout_y__="${layout_y:-5}"
    __blocksize__="${blocksize:-40}"

    if [ "$quilting" = "TRUE" ]; then
      __wrtcmp_write_groups__="1"
      __wrtcmp_write_tasks_per_group__=$(( 1*__layout_y__ ))
      __wrtcmp_output_grid__="lambert_conformal"
      __wrtcmp_cen_lon__="${__esggrid_lon_ctr__}"
      __wrtcmp_cen_lat__="${__esggrid_lat_ctr__}"
      __wrtcmp_stdlat1__="${__esggrid_lat_ctr__}"
      __wrtcmp_stdlat2__="${__esggrid_lat_ctr__}"
      __wrtcmp_nx__="197"
      __wrtcmp_ny__="197"
      __wrtcmp_lon_lwr_left__="-89.47120417"
      __wrtcmp_lat_lwr_left__="37.07809642"
      __wrtcmp_dx__="${__esggrid_delx__}"
      __wrtcmp_dy__="${__esggrid_dely__}"
    fi
    ;;
#
#-----------------------------------------------------------------------
#
# The RRFS Alaska domain with ~13km cells.
#
# Note:
# This grid has not been thoroughly tested (as of 20201027).
#
#-----------------------------------------------------------------------
#
  "RRFS_AK_13km")

    __grid_gen_method__="ESGgrid"

    __esggrid_lon_ctr__="-161.5"
    __esggrid_lat_ctr__="63.0"

    __esggrid_delx__="13000.0"
    __esggrid_dely__="13000.0"

    __esggrid_nx__="320"
    __esggrid_ny__="240"

    __esggrid_pazi__="0.0"

    __esggrid_wide_halo_width__="6"

#    __dt_atmos__="${dt_atmos:-50}"
    __dt_atmos__="${dt_atmos:-10}"

    __layout_x__="${layout_x:-16}"
    __layout_y__="${layout_y:-12}"
    __blocksize__="${blocksize:-40}"

    if [ "$quilting" = "TRUE" ]; then
      __wrtcmp_write_groups__="1"
      __wrtcmp_write_tasks_per_group__=$(( 1*__layout_y__ ))
      __wrtcmp_output_grid__="lambert_conformal"
      __wrtcmp_cen_lon__="${__esggrid_lon_ctr__}"
      __wrtcmp_cen_lat__="${__esggrid_lat_ctr__}"
      __wrtcmp_stdlat1__="${__esggrid_lat_ctr__}"
      __wrtcmp_stdlat2__="${__esggrid_lat_ctr__}"

# The following works.  The numbers were obtained using the NCL scripts
# but only after manually modifying the longitutes of two of the four
# corners of the domain to add 360.0 to them.  Need to automate that
# procedure.
      __wrtcmp_nx__="318"
      __wrtcmp_ny__="234"
#      __wrtcmp_lon_lwr_left__="-187.76660836"
      __wrtcmp_lon_lwr_left__="172.23339164"
      __wrtcmp_lat_lwr_left__="45.77691870"

      __wrtcmp_dx__="${__esggrid_delx__}"
      __wrtcmp_dy__="${__esggrid_dely__}"
    fi

# The following rotated_latlon coordinate system parameters were obtained
# using the NCL code and work.
#      if [ "$quilting" = "TRUE" ]; then
#        __wrtcmp_write_groups__="1"
#        __wrtcmp_write_tasks_per_group__=$(( 1*__layout_y__ ))
#        __wrtcmp_output_grid__="rotated_latlon"
#        __wrtcmp_cen_lon__="${__esggrid_lon_ctr__}"
#        __wrtcmp_cen_lat__="${__esggrid_lat_ctr__}"
#        __wrtcmp_lon_lwr_left__="-18.47206579"
#        __wrtcmp_lat_lwr_left__="-13.56176982"
#        __wrtcmp_lon_upr_rght__="18.47206579"
#        __wrtcmp_lat_upr_rght__="13.56176982"
##        __wrtcmp_dlon__="0.11691181"
##        __wrtcmp_dlat__="0.11691181"
#        __wrtcmp_dlon__=$( printf "%.9f" $( bc -l <<< "(${esggrid_delx}/${radius_Earth})*${degs_per_radian}" ) )
#        __wrtcmp_dlat__=$( printf "%.9f" $( bc -l <<< "(${esggrid_dely}/${radius_Earth})*${degs_per_radian}" ) )
#      fi
    ;;
#
#-----------------------------------------------------------------------
#
# The RRFS Alaska domain with ~3km cells.
#
# Note:
# This grid has not been thoroughly tested (as of 20201027).
#
#-----------------------------------------------------------------------
#
  "RRFS_AK_3km")

#    if [ "${grid_gen_method}" = "GFDLgrid" ]; then
#
#      __gfdlgrid_lon_t6_ctr__="-160.8"
#      __gfdlgrid_lat_t6_ctr__="63.0"
#      __gfdlgrid_stretch_fac__="1.161"
#      __gfdlgrid_res__="768"
#      __gfdlgrid_refine_ratio__="4"
#
#      num_margin_cells_T6_left="204"
#      __gfdlgrid_istart_of_rgnl_dom_on_t6g__=$(( num_margin_cells_T6_left + 1 ))
#
#      num_margin_cells_T6_right="204"
#      __gfdlgrid_iend_of_rgnl_dom_on_t6g__=$(( __gfdlgrid_res__ - num_margin_cells_T6_right ))
#
#      num_margin_cells_T6_bottom="249"
#      __gfdlgrid_jstart_of_rgnl_dom_on_t6g__=$(( num_margin_cells_T6_bottom + 1 ))
#
#      num_margin_cells_T6_top="249"
#      __gfdlgrid_jend_of_rgnl_dom_on_t6g__=$(( __gfdlgrid_res__ - num_margin_cells_T6_top ))
#
#      __gfdlgrid_use_gfdlgrid_res_in_filenames__="FALSE"
#
#      __dt_atmos__="${dt_atmos:-18}"
#
#      __layout_x__="${layout_x:-24}"
#      __layout_y__="${layout_y:-24}"
#      __blocksize__="${blocksize:-15}"
#
#      if [ "$quilting" = "TRUE" ]; then
#        __wrtcmp_write_groups__="1"
#        __wrtcmp_write_tasks_per_group__="2"
#        __wrtcmp_output_grid__="lambert_conformal"
#        __wrtcmp_cen_lon__="${__gfdlgrid_lon_t6_ctr__}"
#        __wrtcmp_cen_lat__="${__gfdlgrid_lat_t6_ctr__}"
#        __wrtcmp_stdlat1__="${__gfdlgrid_lat_t6_ctr__}"
#        __wrtcmp_stdlat2__="${__gfdlgrid_lat_t6_ctr__}"
#        __wrtcmp_nx__="1320"
#        __wrtcmp_ny__="950"
#        __wrtcmp_lon_lwr_left__="173.734"
#        __wrtcmp_lat_lwr_left__="46.740347"
#        __wrtcmp_dx__="3000.0"
#        __wrtcmp_dy__="3000.0"
#      fi
#
#    elif [ "${grid_gen_method}" = "ESGgrid" ]; then

    __grid_gen_method__="ESGgrid"

    __esggrid_lon_ctr__="-161.5"
    __esggrid_lat_ctr__="63.0"

    __esggrid_delx__="3000.0"
    __esggrid_dely__="3000.0"

    __esggrid_nx__="1380"
    __esggrid_ny__="1020"

    __esggrid_pazi__="0.0"

    __esggrid_wide_halo_width__="6"

#    __dt_atmos__="${dt_atmos:-50}"
    __dt_atmos__="${dt_atmos:-10}"

    __layout_x__="${layout_x:-30}"
    __layout_y__="${layout_y:-17}"
    __blocksize__="${blocksize:-40}"

    if [ "$quilting" = "TRUE" ]; then
      __wrtcmp_write_groups__="1"
      __wrtcmp_write_tasks_per_group__=$(( 1*__layout_y__ ))
      __wrtcmp_output_grid__="lambert_conformal"
      __wrtcmp_cen_lon__="${__esggrid_lon_ctr__}"
      __wrtcmp_cen_lat__="${__esggrid_lat_ctr__}"
      __wrtcmp_stdlat1__="${__esggrid_lat_ctr__}"
      __wrtcmp_stdlat2__="${__esggrid_lat_ctr__}"
      __wrtcmp_nx__="1379"
      __wrtcmp_ny__="1003"
      __wrtcmp_lon_lwr_left__="-187.89737923"
      __wrtcmp_lat_lwr_left__="45.84576053"
      __wrtcmp_dx__="${__esggrid_delx__}"
      __wrtcmp_dy__="${__esggrid_dely__}"
    fi
    ;;
#
#-----------------------------------------------------------------------
#
# The WoFS domain with ~3km cells.
#
# Note:
# The WoFS domain will generate a 301 x 301 output grid (WRITE COMPONENT) and
# will eventually be movable (esggrid_lon_ctr/esggrid_lat_ctr). A python script
# python_utils/fv3write_parms_lambert will be useful to determine
# wrtcmp_lon_lwr_left and wrtcmp_lat_lwr_left locations (only for Lambert map
# projection currently) of the quilting output when the domain location is
# moved. Later, it should be integrated into the workflow.
#
#-----------------------------------------------------------------------
#
  "WoFS_3km")

    __grid_gen_method__="ESGgrid"

    __esggrid_lon_ctr__="-97.5"
    __esggrid_lat_ctr__="38.5"

    __esggrid_delx__="3000.0"
    __esggrid_dely__="3000.0"

    __esggrid_nx__="361"
    __esggrid_ny__="361"

    __esggrid_pazi__="0.0"

    __esggrid_wide_halo_width__="6"

    __dt_atmos__="${dt_atmos:-20}"

    __layout_x__="${layout_x:-18}"
    __layout_y__="${layout_y:-12}"
    __blocksize__="${blocksize:-30}"

    if [ "$quilting" = "TRUE" ]; then
      __wrtcmp_write_groups__="1"
      __wrtcmp_write_tasks_per_group__=$(( 1*__layout_y__ ))
      __wrtcmp_output_grid__="lambert_conformal"
      __wrtcmp_cen_lon__="${__esggrid_lon_ctr__}"
      __wrtcmp_cen_lat__="${__esggrid_lat_ctr__}"
      __wrtcmp_stdlat1__="${__esggrid_lat_ctr__}"
      __wrtcmp_stdlat2__="${__esggrid_lat_ctr__}"
      __wrtcmp_nx__="301"
      __wrtcmp_ny__="301"
      __wrtcmp_lon_lwr_left__="-102.3802487"
      __wrtcmp_lat_lwr_left__="34.3407918"
      __wrtcmp_dx__="${__esggrid_delx__}"
      __wrtcmp_dy__="${__esggrid_dely__}"
    fi
    ;;
#
#-----------------------------------------------------------------------
#
# A CONUS domain of GFDLgrid type with ~25km cells.
#
# Note:
# This grid is larger than the HRRRX domain and thus cannot be initialized
# using the HRRRX.
#
#-----------------------------------------------------------------------
#
  "CONUS_25km_GFDLgrid")

    __grid_gen_method__="GFDLgrid"

    __gfdlgrid_lon_t6_ctr__="-97.5"
    __gfdlgrid_lat_t6_ctr__="38.5"
    __gfdlgrid_stretch_fac__="1.4"
    __gfdlgrid_res__="96"
    __gfdlgrid_refine_ratio__="3"

    num_margin_cells_T6_left="12"
    __gfdlgrid_istart_of_rgnl_dom_on_t6g__=$(( num_margin_cells_T6_left + 1 ))

    num_margin_cells_T6_right="12"
    __gfdlgrid_iend_of_rgnl_dom_on_t6g__=$(( __gfdlgrid_res__ - num_margin_cells_T6_right ))

    num_margin_cells_T6_bottom="16"
    __gfdlgrid_jstart_of_rgnl_dom_on_t6g__=$(( num_margin_cells_T6_bottom + 1 ))

    num_margin_cells_T6_top="16"
    __gfdlgrid_jend_of_rgnl_dom_on_t6g__=$(( __gfdlgrid_res__ - num_margin_cells_T6_top ))

    __gfdlgrid_use_gfdlgrid_res_in_filenames__="TRUE"

    __dt_atmos__="${dt_atmos:-225}"

    __layout_x__="${layout_x:-6}"
    __layout_y__="${layout_y:-4}"
    __blocksize__="${blocksize:-36}"

    if [ "$quilting" = "TRUE" ]; then
      __wrtcmp_write_groups__="1"
      __wrtcmp_write_tasks_per_group__=$(( 1*__layout_y__ ))
      __wrtcmp_output_grid__="rotated_latlon"
      __wrtcmp_cen_lon__="${__gfdlgrid_lon_t6_ctr__}"
      __wrtcmp_cen_lat__="${__gfdlgrid_lat_t6_ctr__}"
      __wrtcmp_lon_lwr_left__="-24.40085141"
      __wrtcmp_lat_lwr_left__="-19.65624142"
      __wrtcmp_lon_upr_rght__="24.40085141"
      __wrtcmp_lat_upr_rght__="19.65624142"
      __wrtcmp_dlon__="0.22593381"
      __wrtcmp_dlat__="0.22593381"
    fi
    ;;
#
#-----------------------------------------------------------------------
#
# A CONUS domain of GFDLgrid type with ~3km cells.
#
# Note:
# This grid is larger than the HRRRX domain and thus cannot be initialized
# using the HRRRX.
#
#-----------------------------------------------------------------------
#
  "CONUS_3km_GFDLgrid")

    __grid_gen_method__="GFDLgrid"

    __gfdlgrid_lon_t6_ctr__="-97.5"
    __gfdlgrid_lat_t6_ctr__="38.5"
    __gfdlgrid_stretch_fac__="1.5"
    __gfdlgrid_res__="768"
    __gfdlgrid_refine_ratio__="3"

    num_margin_cells_T6_left="69"
    __gfdlgrid_istart_of_rgnl_dom_on_t6g__=$(( num_margin_cells_T6_left + 1 ))

    num_margin_cells_T6_right="69"
    __gfdlgrid_iend_of_rgnl_dom_on_t6g__=$(( __gfdlgrid_res__ - num_margin_cells_T6_right ))

    num_margin_cells_T6_bottom="164"
    __gfdlgrid_jstart_of_rgnl_dom_on_t6g__=$(( num_margin_cells_T6_bottom + 1 ))

    num_margin_cells_T6_top="164"
    __gfdlgrid_jend_of_rgnl_dom_on_t6g__=$(( __gfdlgrid_res__ - num_margin_cells_T6_top ))

    __gfdlgrid_use_gfdlgrid_res_in_filenames__="TRUE"

    __dt_atmos__="${dt_atmos:-18}"

    __layout_x__="${layout_x:-30}"
    __layout_y__="${layout_y:-22}"
    __blocksize__="${blocksize:-35}"

    if [ "$quilting" = "TRUE" ]; then
      __wrtcmp_write_groups__="1"
      __wrtcmp_write_tasks_per_group__=$(( 1*__layout_y__ ))
      __wrtcmp_output_grid__="rotated_latlon"
      __wrtcmp_cen_lon__="${__gfdlgrid_lon_t6_ctr__}"
      __wrtcmp_cen_lat__="${__gfdlgrid_lat_t6_ctr__}"
      __wrtcmp_lon_lwr_left__="-25.23144805"
      __wrtcmp_lat_lwr_left__="-15.82130419"
      __wrtcmp_lon_upr_rght__="25.23144805"
      __wrtcmp_lat_upr_rght__="15.82130419"
      __wrtcmp_dlon__="0.02665763"
      __wrtcmp_dlat__="0.02665763"
    fi
    ;;
#
#-----------------------------------------------------------------------
#
# EMC's Alaska grid.
#
#-----------------------------------------------------------------------
#
  "EMC_AK")

#    if [ "${grid_gen_method}" = "GFDLgrid" ]; then

# Values from an EMC script.

### rocoto items
#
#fcstnodes=68
#bcnodes=11
#postnodes=2
#goespostnodes=5
#goespostthrottle=6
#sh=06
#eh=18
#
### namelist items
#
#task_layout_x=16
#task_layout_y=48
#npx=1345
#npy=1153
#target_lat=61.0
#target_lon=-153.0
#
### model config items
#
#write_groups=2
#write_tasks_per_group=24
#cen_lon=$target_lon
#cen_lat=$target_lat
#lon1=-18.0
#lat1=-14.79
#lon2=18.0
#lat2=14.79
#dlon=0.03
#dlat=0.03

#      __gfdlgrid_lon_t6_ctr__="-153.0"
#      __gfdlgrid_lat_t6_ctr__="61.0"
#      __gfdlgrid_stretch_fac__="1.0"  # ???
#      __gfdlgrid_res__="768"
#      __gfdlgrid_refine_ratio__="3"   # ???
#
#      num_margin_cells_T6_left="61"
#      __gfdlgrid_istart_of_rgnl_dom_on_t6g__=$(( num_margin_cells_T6_left + 1 ))
#
#      num_margin_cells_T6_right="67"
#      __gfdlgrid_iend_of_rgnl_dom_on_t6g__=$(( __gfdlgrid_res__ - num_margin_cells_T6_right ))
#
#      num_margin_cells_T6_bottom="165"
#      __gfdlgrid_jstart_of_rgnl_dom_on_t6g__=$(( num_margin_cells_T6_bottom + 1 ))
#
#      num_margin_cells_T6_top="171"
#      __gfdlgrid_jend_of_rgnl_dom_on_t6g__=$(( __gfdlgrid_res__ - num_margin_cells_T6_top ))
#
#      __gfdlgrid_use_gfdlgrid_res_in_filenames__="TRUE"
#
#      __dt_atmos__="${dt_atmos:-18}"
#
#      __layout_x__="${layout_x:-16}"
#      __layout_y__="${layout_y:-48}"
#      __wrtcmp_write_groups__="2"
#      __wrtcmp_write_tasks_per_group__="24"
#      __blocksize__="${blocksize:-32}"
#
#    elif [ "${grid_gen_method}" = "ESGgrid" ]; then

    __grid_gen_method__="ESGgrid"

# Values taken from pre-generated files in /scratch4/NCEPDEV/fv3-cam/save/Benjamin.Blake/regional_workflow/fix/fix_sar
# With move to Hera, those files were lost; a backup can be found here: /scratch2/BMC/det/kavulich/fix/fix_sar

# Longitude and latitude for center of domain
    __esggrid_lon_ctr__="-153.0"
    __esggrid_lat_ctr__="61.0"

# Projected grid spacing in meters...in the static files (e.g. "C768_grid.tile7.nc"), the "dx" is actually the resolution
# of the supergrid, which is HALF of this dx
    __esggrid_delx__="3000.0"
    __esggrid_dely__="3000.0"

# Number of x and y points for your domain (halo not included);
# Divide "supergrid" values from /scratch2/BMC/det/kavulich/fix/fix_sar/ak/C768_grid.tile7.halo4.nc by 2 and subtract 8 to eliminate halo
    __esggrid_nx__="1344" # Supergrid value 2704
    __esggrid_ny__="1152" # Supergrid value 2320

# Rotation of the ESG grid in degrees.
    __esggrid_pazi__="0.0"

# Number of halo points for a wide grid (before trimming)...this should almost always be 6 for now
# Within the model we actually have a 4-point halo and a 3-point halo
    __esggrid_wide_halo_width__="6"

# Side note: FV3 is lagrangian and vertical coordinates are dynamically remapped during model integration
# 'ksplit' is the factor that determines the timestep for this process (divided

# Physics timestep in seconds, actual dynamics timestep can be a subset of this.
# This is the time step for the largest atmosphere model loop.  It corresponds to the frequency with which the
# top-level routine in the dynamics is called as well as the frequency with which the physics is called.
#
# Preliminary standard values: 18 for 3-km runs, 90 for 13-km runs per config_defaults.sh

    __dt_atmos__="${dt_atmos:-18}"

#Factors for MPI decomposition. esggrid_nx must be divisible by layout_x, esggrid_ny must be divisible by layout_y
    __layout_x__="${layout_x:-28}"
    __layout_y__="${layout_y:-16}"

#Take number of points on a tile (nx/lx*ny/ly), must divide by block size to get an integer.
#This integer must be small enough to fit into a processor's cache, so it is machine-dependent magic
# For Theia, must be ~40 or less
# Check setup.sh for more details
    __blocksize__="${blocksize:-24}"

#This section is all for the write component, which you need for output during model integration
    if [ "$quilting" = "TRUE" ]; then
#Write component reserves MPI tasks for writing output. The number of "groups" is usually 1, but if you have a case where group 1 is not done writing before the next write step, you need group 2, etc.
      __wrtcmp_write_groups__="1"
#Number of tasks per write group. Ny must be divisible my this number. layout_y is usually a good value
      __wrtcmp_write_tasks_per_group__="24"
#lambert_conformal or rotated_latlon. lambert_conformal not well tested and probably doesn't work for our purposes
      __wrtcmp_output_grid__="lambert_conformal"
#These should always be set the same as compute grid
      __wrtcmp_cen_lon__="${__esggrid_lon_ctr__}"
      __wrtcmp_cen_lat__="${__esggrid_lat_ctr__}"
      __wrtcmp_stdlat1__="${__esggrid_lat_ctr__}"
      __wrtcmp_stdlat2__="${__esggrid_lat_ctr__}"
#Write component grid must always be <= compute grid (without haloes)
      __wrtcmp_nx__="1344"
      __wrtcmp_ny__="1152"
#Lower left latlon (southwest corner)
      __wrtcmp_lon_lwr_left__="-177.0"
      __wrtcmp_lat_lwr_left__="42.5"
      __wrtcmp_dx__="${__esggrid_delx__}"
      __wrtcmp_dy__="${__esggrid_dely__}"
    fi
    ;;
#
#-----------------------------------------------------------------------
#
# EMC's Hawaii grid.
#
#-----------------------------------------------------------------------
#
  "EMC_HI")

    __grid_gen_method__="ESGgrid"

# Values taken from pre-generated files in /scratch4/NCEPDEV/fv3-cam/save/Benjamin.Blake/regional_workflow/fix/fix_sar/hi/C768_grid.tile7.nc
# With move to Hera, those files were lost; a backup can be found here: /scratch2/BMC/det/kavulich/fix/fix_sar
# Longitude and latitude for center of domain
    __esggrid_lon_ctr__="-157.0"
    __esggrid_lat_ctr__="20.0"

# Projected grid spacing in meters...in the static files (e.g. "C768_grid.tile7.nc"), the "dx" is actually the resolution
# of the supergrid, which is HALF of this dx (plus or minus some grid stretch factor)
    __esggrid_delx__="3000.0"
    __esggrid_dely__="3000.0"

# Number of x and y points for your domain (halo not included);
# Divide "supergrid" values from /scratch2/BMC/det/kavulich/fix/fix_sar/hi/C768_grid.tile7.halo4.nc by 2 and subtract 8 to eliminate halo
    __esggrid_nx__="432" # Supergrid value 880
    __esggrid_ny__="360" # Supergrid value 736

# Rotation of the ESG grid in degrees.
    __esggrid_pazi__="0.0"

# Number of halo points for a wide grid (before trimming)...this should almost always be 6 for now
# Within the model we actually have a 4-point halo and a 3-point halo
    __esggrid_wide_halo_width__="6"

# Side note: FV3 is lagrangian and vertical coordinates are dynamically remapped during model integration
# 'ksplit' is the factor that determines the timestep for this process (divided

# Physics timestep in seconds, actual dynamics timestep can be a subset of this.
# This is the time step for the largest atmosphere model loop.  It corresponds to the frequency with which the
# top-level routine in the dynamics is called as well as the frequency with which the physics is called.
#
# Preliminary standard values: 18 for 3-km runs, 90 for 13-km runs per config_defaults.sh

    __dt_atmos__="${dt_atmos:-18}"

#Factors for MPI decomposition. esggrid_nx must be divisible by layout_x, esggrid_ny must be divisible by layout_y
    __layout_x__="${layout_x:-8}"
    __layout_y__="${layout_y:-8}"
#Take number of points on a tile (nx/lx*ny/ly), must divide by block size to get an integer.
#This integer must be small enough to fit into a processor's cache, so it is machine-dependent magic
# For Theia, must be ~40 or less
# Check setup.sh for more details
    __blocksize__="${blocksize:-27}"

#This section is all for the write component, which you need for output during model integration
    if [ "$quilting" = "TRUE" ]; then
#Write component reserves MPI tasks for writing output. The number of "groups" is usually 1, but if you have a case where group 1 is not done writing before the next write step, you need group 2, etc.
      __wrtcmp_write_groups__="1"
#Number of tasks per write group. Ny must be divisible my this number. layout_y is usually a good value
      __wrtcmp_write_tasks_per_group__="8"
#lambert_conformal or rotated_latlon. lambert_conformal not well tested and probably doesn't work for our purposes
      __wrtcmp_output_grid__="lambert_conformal"
#These should usually be set the same as compute grid
      __wrtcmp_cen_lon__="${__esggrid_lon_ctr__}"
      __wrtcmp_cen_lat__="${__esggrid_lat_ctr__}"
      __wrtcmp_stdlat1__="${__esggrid_lat_ctr__}"
      __wrtcmp_stdlat2__="${__esggrid_lat_ctr__}"
#Write component grid should be close to the ESGgrid values unless you are doing something weird
      __wrtcmp_nx__="420"
      __wrtcmp_ny__="348"

#Lower left latlon (southwest corner)
      __wrtcmp_lon_lwr_left__="-162.8"
      __wrtcmp_lat_lwr_left__="15.2"
      __wrtcmp_dx__="${__esggrid_delx__}"
      __wrtcmp_dy__="${__esggrid_dely__}"
    fi
    ;;
#
#-----------------------------------------------------------------------
#
# EMC's Puerto Rico grid.
#
#-----------------------------------------------------------------------
#
  "EMC_PR")

    __grid_gen_method__="ESGgrid"

# Values taken from pre-generated files in /scratch4/NCEPDEV/fv3-cam/save/Benjamin.Blake/regional_workflow/fix/fix_sar/pr/C768_grid.tile7.nc
# With move to Hera, those files were lost; a backup can be found here: /scratch2/BMC/det/kavulich/fix/fix_sar
# Longitude and latitude for center of domain
    __esggrid_lon_ctr__="-69.0"
    __esggrid_lat_ctr__="18.0"

# Projected grid spacing in meters...in the static files (e.g. "C768_grid.tile7.nc"), the "dx" is actually the resolution
# of the supergrid, which is HALF of this dx (plus or minus some grid stretch factor)
    __esggrid_delx__="3000.0"
    __esggrid_dely__="3000.0"

# Number of x and y points for your domain (halo not included);
# Divide "supergrid" values from /scratch2/BMC/det/kavulich/fix/fix_sar/pr/C768_grid.tile7.halo4.nc by 2 and subtract 8 to eliminate halo
    __esggrid_nx__="576" # Supergrid value 1168
    __esggrid_ny__="432" # Supergrid value 880

# Rotation of the ESG grid in degrees.
    __esggrid_pazi__="0.0"

# Number of halo points for a wide grid (before trimming)...this should almost always be 6 for now
# Within the model we actually have a 4-point halo and a 3-point halo
    __esggrid_wide_halo_width__="6"

# Side note: FV3 is lagrangian and vertical coordinates are dynamically remapped during model integration
# 'ksplit' is the factor that determines the timestep for this process (divided

# Physics timestep in seconds, actual dynamics timestep can be a subset of this.
# This is the time step for the largest atmosphere model loop.  It corresponds to the frequency with which the
# top-level routine in the dynamics is called as well as the frequency with which the physics is called.
#
# Preliminary standard values: 18 for 3-km runs, 90 for 13-km runs per config_defaults.sh

    __dt_atmos__="${dt_atmos:-18}"

#Factors for MPI decomposition. esggrid_nx must be divisible by layout_x, esggrid_ny must be divisible by layout_y
    __layout_x__="${layout_x:-16}"
    __layout_y__="${layout_y:-8}"

#Take number of points on a tile (nx/lx*ny/ly), must divide by block size to get an integer.
#This integer must be small enough to fit into a processor's cache, so it is machine-dependent magic
# For Theia, must be ~40 or less
# Check setup.sh for more details
    __blocksize__="${blocksize:-24}"

#This section is all for the write component, which you need for output during model integration
    if [ "$quilting" = "TRUE" ]; then
#Write component reserves MPI tasks for writing output. The number of "groups" is usually 1, but if you have a case where group 1 is not done writing before the next write step, you need group 2, etc.
      __wrtcmp_write_groups__="1"
#Number of tasks per write group. Ny must be divisible my this number. layout_y is usually a good value
      __wrtcmp_write_tasks_per_group__="24"
#lambert_conformal or rotated_latlon. lambert_conformal not well tested and probably doesn't work for our purposes
      __wrtcmp_output_grid__="lambert_conformal"
#These should always be set the same as compute grid
      __wrtcmp_cen_lon__="${__esggrid_lon_ctr__}"
      __wrtcmp_cen_lat__="${__esggrid_lat_ctr__}"
      __wrtcmp_stdlat1__="${__esggrid_lat_ctr__}"
      __wrtcmp_stdlat2__="${__esggrid_lat_ctr__}"
#Write component grid must always be <= compute grid (without haloes)
      __wrtcmp_nx__="576"
      __wrtcmp_ny__="432"
#Lower left latlon (southwest corner)
      __wrtcmp_lon_lwr_left__="-77"
      __wrtcmp_lat_lwr_left__="12"
      __wrtcmp_dx__="${__esggrid_delx__}"
      __wrtcmp_dy__="${__esggrid_dely__}"
    fi
    ;;
#
#-----------------------------------------------------------------------
#
# EMC's Guam grid.
#
#-----------------------------------------------------------------------
#
  "EMC_GU")

    __grid_gen_method__="ESGgrid"

# Values taken from pre-generated files in /scratch4/NCEPDEV/fv3-cam/save/Benjamin.Blake/regional_workflow/fix/fix_sar/guam/C768_grid.tile7.nc
# With move to Hera, those files were lost; a backup can be found here: /scratch2/BMC/det/kavulich/fix/fix_sar
# Longitude and latitude for center of domain
    __esggrid_lon_ctr__="146.0"
    __esggrid_lat_ctr__="15.0"

# Projected grid spacing in meters...in the static files (e.g. "C768_grid.tile7.nc"), the "dx" is actually the resolution
# of the supergrid, which is HALF of this dx (plus or minus some grid stretch factor)
    __esggrid_delx__="3000.0"
    __esggrid_dely__="3000.0"

# Number of x and y points for your domain (halo not included);
# Divide "supergrid" values from /scratch2/BMC/det/kavulich/fix/fix_sar/guam/C768_grid.tile7.halo4.nc by 2 and subtract 8 to eliminate halo
    __esggrid_nx__="432" # Supergrid value 880
    __esggrid_ny__="360" # Supergrid value 736

# Rotation of the ESG grid in degrees.
    __esggrid_pazi__="0.0"

# Number of halo points for a wide grid (before trimming)...this should almost always be 6 for now
# Within the model we actually have a 4-point halo and a 3-point halo
    __esggrid_wide_halo_width__="6"

# Side note: FV3 is lagrangian and vertical coordinates are dynamically remapped during model integration
# 'ksplit' is the factor that determines the timestep for this process (divided

# Physics timestep in seconds, actual dynamics timestep can be a subset of this.
# This is the time step for the largest atmosphere model loop.  It corresponds to the frequency with which the
# top-level routine in the dynamics is called as well as the frequency with which the physics is called.
#
# Preliminary standard values: 18 for 3-km runs, 90 for 13-km runs per config_defaults.sh

    __dt_atmos__="${dt_atmos:-18}"

#Factors for MPI decomposition. esggrid_nx must be divisible by layout_x, esggrid_ny must be divisible by layout_y
    __layout_x__="${layout_x:-16}"
    __layout_y__="${layout_y:-12}"
#Take number of points on a tile (nx/lx*ny/ly), must divide by block size to get an integer.
#This integer must be small enough to fit into a processor's cache, so it is machine-dependent magic
# For Theia, must be ~40 or less
# Check setup.sh for more details
    __blocksize__="${blocksize:-27}"

#This section is all for the write component, which you need for output during model integration
    if [ "$quilting" = "TRUE" ]; then
#Write component reserves MPI tasks for writing output. The number of "groups" is usually 1, but if you have a case where group 1 is not done writing before the next write step, you need group 2, etc.
      __wrtcmp_write_groups__="1"
#Number of tasks per write group. Ny must be divisible my this number. layout_y is usually a good value
      __wrtcmp_write_tasks_per_group__="24"
#lambert_conformal or rotated_latlon. lambert_conformal not well tested and probably doesn't work for our purposes
      __wrtcmp_output_grid__="lambert_conformal"
#These should always be set the same as compute grid
      __wrtcmp_cen_lon__="${__esggrid_lon_ctr__}"
      __wrtcmp_cen_lat__="${__esggrid_lat_ctr__}"
      __wrtcmp_stdlat1__="${__esggrid_lat_ctr__}"
      __wrtcmp_stdlat2__="${__esggrid_lat_ctr__}"
#Write component grid must always be <= compute grid (without haloes)
      __wrtcmp_nx__="420"
      __wrtcmp_ny__="348"
#Lower left latlon (southwest corner) Used /scratch2/NCEPDEV/fv3-cam/Dusan.Jovic/dbrowse/fv3grid utility to find best value
      __wrtcmp_lon_lwr_left__="140"
      __wrtcmp_lat_lwr_left__="10"
      __wrtcmp_dx__="${__esggrid_delx__}"
      __wrtcmp_dy__="${__esggrid_dely__}"
    fi
    ;;
#
#-----------------------------------------------------------------------
#
# Emulation of the HAFS v0.A grid at 25 km.
#
#-----------------------------------------------------------------------
#
  "GSL_HAFSV0.A_25km")

    __grid_gen_method__="ESGgrid"

    __esggrid_lon_ctr__="-62.0"
    __esggrid_lat_ctr__="22.0"

    __esggrid_delx__="25000.0"
    __esggrid_dely__="25000.0"

    __esggrid_nx__="345"
    __esggrid_ny__="230"

    __esggrid_pazi__="0.0"

    __esggrid_wide_halo_width__="6"

    __dt_atmos__="${dt_atmos:-300}"

    __layout_x__="${layout_x:-5}"
    __layout_y__="${layout_y:-5}"
    __blocksize__="${blocksize:-6}"

    if [ "$quilting" = "TRUE" ]; then
      __wrtcmp_write_groups__="1"
      __wrtcmp_write_tasks_per_group__="32"
      __wrtcmp_output_grid__="regional_latlon"
      __wrtcmp_cen_lon__="${__esggrid_lon_ctr__}"
      __wrtcmp_cen_lat__="25.0"
      __wrtcmp_lon_lwr_left__="-114.5"
      __wrtcmp_lat_lwr_left__="-5.0"
      __wrtcmp_lon_upr_rght__="-9.5"
      __wrtcmp_lat_upr_rght__="55.0"
      __wrtcmp_dlon__="0.25"
      __wrtcmp_dlat__="0.25"
    fi
    ;;
#
#-----------------------------------------------------------------------
#
# Emulation of the HAFS v0.A grid at 13 km.
#
#-----------------------------------------------------------------------
#
  "GSL_HAFSV0.A_13km")

    __grid_gen_method__="ESGgrid"

    __esggrid_lon_ctr__="-62.0"
    __esggrid_lat_ctr__="22.0"

    __esggrid_delx__="13000.0"
    __esggrid_dely__="13000.0"

    __esggrid_nx__="665"
    __esggrid_ny__="444"

    __esggrid_pazi__="0.0"

    __esggrid_wide_halo_width__="6"

    __dt_atmos__="${dt_atmos:-180}"

    __layout_x__="${layout_x:-19}"
    __layout_y__="${layout_y:-12}"
    __blocksize__="${blocksize:-35}"

    if [ "$quilting" = "TRUE" ]; then
      __wrtcmp_write_groups__="1"
      __wrtcmp_write_tasks_per_group__="32"
      __wrtcmp_output_grid__="regional_latlon"
      __wrtcmp_cen_lon__="${__esggrid_lon_ctr__}"
      __wrtcmp_cen_lat__="25.0"
      __wrtcmp_lon_lwr_left__="-114.5"
      __wrtcmp_lat_lwr_left__="-5.0"
      __wrtcmp_lon_upr_rght__="-9.5"
      __wrtcmp_lat_upr_rght__="55.0"
      __wrtcmp_dlon__="0.13"
      __wrtcmp_dlat__="0.13"
    fi
    ;;
#
#-----------------------------------------------------------------------
#
# Emulation of the HAFS v0.A grid at 3 km.
#
#-----------------------------------------------------------------------
#
  "GSL_HAFSV0.A_3km")

    __grid_gen_method__="ESGgrid"

    __esggrid_lon_ctr__="-62.0"
    __esggrid_lat_ctr__="22.0"

    __esggrid_delx__="3000.0"
    __esggrid_dely__="3000.0"

    __esggrid_nx__="2880"
    __esggrid_ny__="1920"

    __esggrid_pazi__="0.0"

    __esggrid_wide_halo_width__="6"

    __dt_atmos__="${dt_atmos:-40}"

    __layout_x__="${layout_x:-32}"
    __layout_y__="${layout_y:-24}"
    __blocksize__="${blocksize:-32}"

    if [ "$quilting" = "TRUE" ]; then
      __wrtcmp_write_groups__="1"
      __wrtcmp_write_tasks_per_group__="32"
      __wrtcmp_output_grid__="regional_latlon"
      __wrtcmp_cen_lon__="${__esggrid_lon_ctr__}"
      __wrtcmp_cen_lat__="25.0"
      __wrtcmp_lon_lwr_left__="-114.5"
      __wrtcmp_lat_lwr_left__="-5.0"
      __wrtcmp_lon_upr_rght__="-9.5"
      __wrtcmp_lat_upr_rght__="55.0"
      __wrtcmp_dlon__="0.03"
      __wrtcmp_dlat__="0.03"
    fi
    ;;
#
#-----------------------------------------------------------------------
#
# 50-km HRRR Alaska grid.
#
#-----------------------------------------------------------------------
#
  "GSD_HRRR_AK_50km")

    __grid_gen_method__="ESGgrid"

    __esggrid_lon_ctr__="-163.5"
    __esggrid_lat_ctr__="62.8"

    __esggrid_delx__="50000.0"
    __esggrid_dely__="50000.0"

    __esggrid_nx__="74"
    __esggrid_ny__="51"

    __esggrid_pazi__="0.0"

    __esggrid_wide_halo_width__="6"

    __dt_atmos__="${dt_atmos:-600}"

    __layout_x__="${layout_x:-2}"
    __layout_y__="${layout_y:-3}"
    __blocksize__="${blocksize:-37}"

    if [ "$quilting" = "TRUE" ]; then
      __wrtcmp_write_groups__="1"
      __wrtcmp_write_tasks_per_group__="1"
      __wrtcmp_output_grid__="lambert_conformal"
      __wrtcmp_cen_lon__="${__esggrid_lon_ctr__}"
      __wrtcmp_cen_lat__="${__esggrid_lat_ctr__}"
      __wrtcmp_stdlat1__="${__esggrid_lat_ctr__}"
      __wrtcmp_stdlat2__="${__esggrid_lat_ctr__}"
      __wrtcmp_nx__="70"
      __wrtcmp_ny__="45"
      __wrtcmp_lon_lwr_left__="172.0"
      __wrtcmp_lat_lwr_left__="49.0"
      __wrtcmp_dx__="${__esggrid_delx__}"
      __wrtcmp_dy__="${__esggrid_dely__}"
    fi
    ;;
#
#-----------------------------------------------------------------------
#
# Emulation of GSD's RAP domain with ~13km cell size.
#
#-----------------------------------------------------------------------
#
  "RRFS_NA_13km")

    __grid_gen_method__="ESGgrid"

    __esggrid_lon_ctr__="-112.5"
    __esggrid_lat_ctr__="55.0"

    __esggrid_delx__="13000.0"
    __esggrid_dely__="13000.0"

    __esggrid_nx__="912"
    __esggrid_ny__="623"

    __esggrid_pazi__="0.0"

    __esggrid_wide_halo_width__="6"

    __dt_atmos__="${dt_atmos:-50}"

    __layout_x__="${layout_x:-16}"
    __layout_y__="${layout_y:-16}"
    __blocksize__="${blocksize:-30}"

    if [ "$quilting" = "TRUE" ]; then
      __wrtcmp_write_groups__="1"
      __wrtcmp_write_tasks_per_group__="16"
      __wrtcmp_output_grid__="rotated_latlon"
      __wrtcmp_cen_lon__="-113.0" #"${__esggrid_lon_ctr__}"
      __wrtcmp_cen_lat__="55.0" #"${__esggrid_lat_ctr__}"
      __wrtcmp_lon_lwr_left__="-61.0"
      __wrtcmp_lat_lwr_left__="-37.0"
      __wrtcmp_lon_upr_rght__="61.0"
      __wrtcmp_lat_upr_rght__="37.0"
      __wrtcmp_dlon__=$( printf "%.9f" $( bc -l <<< "(${__esggrid_delx__}/${radius_Earth})*${degs_per_radian}" ) )
      __wrtcmp_dlat__=$( printf "%.9f" $( bc -l <<< "(${__esggrid_dely__}/${radius_Earth})*${degs_per_radian}" ) )
    fi
    ;;
#
#-----------------------------------------------------------------------
#
# Future operational RRFS domain with ~3km cell size.
#
#-----------------------------------------------------------------------
#
  "RRFS_NA_3km")

    __grid_gen_method__="ESGgrid"

    __esggrid_lon_ctr__=-112.5
    __esggrid_lat_ctr__=55.0

    __esggrid_delx__="3000.0"
    __esggrid_dely__="3000.0"

    __esggrid_nx__="3950"
    __esggrid_ny__="2700"

    __esggrid_pazi__="0.0"

    __esggrid_wide_halo_width__="6"

    __dt_atmos__="${dt_atmos:-36}"

    __layout_x__="${layout_x:-20}"   # 40 - EMC operational configuration
    __layout_y__="${layout_y:-35}"   # 45 - EMC operational configuration
    __blocksize__="${blocksize:-28}"

    if [ "$quilting" = "TRUE" ]; then
      __wrtcmp_write_groups__="1"
      __wrtcmp_write_tasks_per_group__="144"
      __wrtcmp_output_grid__="rotated_latlon"
      __wrtcmp_cen_lon__="-113.0" #"${__esggrid_lon_ctr__}"
      __wrtcmp_cen_lat__="55.0" #"${__esggrid_lat_ctr__}"
      __wrtcmp_lon_lwr_left__="-61.0"
      __wrtcmp_lat_lwr_left__="-37.0"
      __wrtcmp_lon_upr_rght__="61.0"
      __wrtcmp_lat_upr_rght__="37.0"
      __wrtcmp_dlon__="0.025" #$( printf "%.9f" $( bc -l <<< "(${__esggrid_delx__}/${radius_Earth})*${degs_per_radian}" ) )
      __wrtcmp_dlat__="0.025" #$( printf "%.9f" $( bc -l <<< "(${__esggrid_dely__}/${radius_Earth})*${degs_per_radian}" ) )
    fi
    ;;

  esac
#
#-----------------------------------------------------------------------
#
# Use the printf utility with the -v flag to set this function's output
# variables.  Note that each of these is set only if the corresponding
# input variable specifying the name to use for the output variable is
# not empty.
#
#-----------------------------------------------------------------------
#
  if [ ! -z "${outvarname_grid_gen_method}" ]; then
    printf -v ${outvarname_grid_gen_method} "%s" "${__grid_gen_method__}"
  fi

  if [ ! -z "${outvarname_esggrid_lon_ctr}" ]; then
    printf -v ${outvarname_esggrid_lon_ctr} "%s" "${__esggrid_lon_ctr__}"
  fi

  if [ ! -z "${outvarname_esggrid_lat_ctr}" ]; then
    printf -v ${outvarname_esggrid_lat_ctr} "%s" "${__esggrid_lat_ctr__}"
  fi

  if [ ! -z "${outvarname_esggrid_delx}" ]; then
    printf -v ${outvarname_esggrid_delx} "%s" "${__esggrid_delx__}"
  fi

  if [ ! -z "${outvarname_esggrid_dely}" ]; then
    printf -v ${outvarname_esggrid_dely} "%s" "${__esggrid_dely__}"
  fi

  if [ ! -z "${outvarname_esggrid_nx}" ]; then
    printf -v ${outvarname_esggrid_nx} "%s" "${__esggrid_nx__}"
  fi

  if [ ! -z "${outvarname_esggrid_ny}" ]; then
    printf -v ${outvarname_esggrid_ny} "%s" "${__esggrid_ny__}"
  fi

  if [ ! -z "${outvarname_esggrid_pazi}" ]; then
    printf -v ${outvarname_esggrid_pazi} "%s" "${__esggrid_pazi__}"
  fi

  if [ ! -z "${outvarname_esggrid_wide_halo_width}" ]; then
    printf -v ${outvarname_esggrid_wide_halo_width} "%s" "${__esggrid_wide_halo_width__}"
  fi

  if [ ! -z "${outvarname_gfdlgrid_lon_t6_ctr}" ]; then
    printf -v ${outvarname_gfdlgrid_lon_t6_ctr} "%s" "${__gfdlgrid_lon_t6_ctr__}"
  fi

  if [ ! -z "${outvarname_gfdlgrid_lat_t6_ctr}" ]; then
    printf -v ${outvarname_gfdlgrid_lat_t6_ctr} "%s" "${__gfdlgrid_lat_t6_ctr__}"
  fi

  if [ ! -z "${outvarname_gfdlgrid_stretch_fac}" ]; then
    printf -v ${outvarname_gfdlgrid_stretch_fac} "%s" "${__gfdlgrid_stretch_fac__}"
  fi

  if [ ! -z "${outvarname_gfdlgrid_res}" ]; then
    printf -v ${outvarname_gfdlgrid_res} "%s" "${__gfdlgrid_res__}"
  fi

  if [ ! -z "${outvarname_gfdlgrid_refine_ratio}" ]; then
    printf -v ${outvarname_gfdlgrid_refine_ratio} "%s" "${__gfdlgrid_refine_ratio__}"
  fi

  if [ ! -z "${outvarname_gfdlgrid_istart_of_rgnl_dom_on_t6g}" ]; then
    printf -v ${outvarname_gfdlgrid_istart_of_rgnl_dom_on_t6g} "%s" "${__gfdlgrid_istart_of_rgnl_dom_on_t6g__}"
  fi

  if [ ! -z "${outvarname_gfdlgrid_iend_of_rgnl_dom_on_t6g}" ]; then
    printf -v ${outvarname_gfdlgrid_iend_of_rgnl_dom_on_t6g} "%s" "${__gfdlgrid_iend_of_rgnl_dom_on_t6g__}"
  fi

  if [ ! -z "${outvarname_gfdlgrid_jstart_of_rgnl_dom_on_t6g}" ]; then
    printf -v ${outvarname_gfdlgrid_jstart_of_rgnl_dom_on_t6g} "%s" "${__gfdlgrid_jstart_of_rgnl_dom_on_t6g__}"
  fi

  if [ ! -z "${outvarname_gfdlgrid_jend_of_rgnl_dom_on_t6g}" ]; then
    printf -v ${outvarname_gfdlgrid_jend_of_rgnl_dom_on_t6g} "%s" "${__gfdlgrid_jend_of_rgnl_dom_on_t6g__}"
  fi

  if [ ! -z "${outvarname_gfdlgrid_use_gfdlgrid_res_in_filenames}" ]; then
    printf -v ${outvarname_gfdlgrid_use_gfdlgrid_res_in_filenames} "%s" "${__gfdlgrid_use_gfdlgrid_res_in_filenames__}"
  fi

  if [ ! -z "${outvarname_dt_atmos}" ]; then
    printf -v ${outvarname_dt_atmos} "%s" "${__dt_atmos__}"
  fi

  if [ ! -z "${outvarname_layout_x}" ]; then
    printf -v ${outvarname_layout_x} "%s" "${__layout_x__}"
  fi

  if [ ! -z "${outvarname_layout_y}" ]; then
    printf -v ${outvarname_layout_y} "%s" "${__layout_y__}"
  fi

  if [ ! -z "${outvarname_blocksize}" ]; then
    printf -v ${outvarname_blocksize} "%s" "${__blocksize__}"
  fi

  if [ ! -z "${outvarname_wrtcmp_write_groups}" ]; then
    printf -v ${outvarname_wrtcmp_write_groups} "%s" "${__wrtcmp_write_groups__}"
  fi

  if [ ! -z "${outvarname_wrtcmp_write_tasks_per_group}" ]; then
    printf -v ${outvarname_wrtcmp_write_tasks_per_group} "%s" "${__wrtcmp_write_tasks_per_group__}"
  fi

  if [ ! -z "${outvarname_wrtcmp_output_grid}" ]; then
    printf -v ${outvarname_wrtcmp_output_grid} "%s" "${__wrtcmp_output_grid__}"
  fi

  if [ ! -z "${outvarname_wrtcmp_cen_lon}" ]; then
    printf -v ${outvarname_wrtcmp_cen_lon} "%s" "${__wrtcmp_cen_lon__}"
  fi

  if [ ! -z "${outvarname_wrtcmp_cen_lat}" ]; then
    printf -v ${outvarname_wrtcmp_cen_lat} "%s" "${__wrtcmp_cen_lat__}"
  fi

  if [ ! -z "${outvarname_wrtcmp_stdlat1}" ]; then
    printf -v ${outvarname_wrtcmp_stdlat1} "%s" "${__wrtcmp_stdlat1__}"
  fi

  if [ ! -z "${outvarname_wrtcmp_stdlat2}" ]; then
    printf -v ${outvarname_wrtcmp_stdlat2} "%s" "${__wrtcmp_stdlat2__}"
  fi

  if [ ! -z "${outvarname_wrtcmp_nx}" ]; then
    printf -v ${outvarname_wrtcmp_nx} "%s" "${__wrtcmp_nx__}"
  fi

  if [ ! -z "${outvarname_wrtcmp_ny}" ]; then
    printf -v ${outvarname_wrtcmp_ny} "%s" "${__wrtcmp_ny__}"
  fi

  if [ ! -z "${outvarname_wrtcmp_lon_lwr_left}" ]; then
    printf -v ${outvarname_wrtcmp_lon_lwr_left} "%s" "${__wrtcmp_lon_lwr_left__}"
  fi

  if [ ! -z "${outvarname_wrtcmp_lat_lwr_left}" ]; then
    printf -v ${outvarname_wrtcmp_lat_lwr_left} "%s" "${__wrtcmp_lat_lwr_left__}"
  fi

  if [ ! -z "${outvarname_wrtcmp_lon_upr_rght}" ]; then
    printf -v ${outvarname_wrtcmp_lon_upr_rght} "%s" "${__wrtcmp_lon_upr_rght__}"
  fi

  if [ ! -z "${outvarname_wrtcmp_lat_upr_rght}" ]; then
    printf -v ${outvarname_wrtcmp_lat_upr_rght} "%s" "${__wrtcmp_lat_upr_rght__}"
  fi

  if [ ! -z "${outvarname_wrtcmp_dx}" ]; then
    printf -v ${outvarname_wrtcmp_dx} "%s" "${__wrtcmp_dx__}"
  fi

  if [ ! -z "${outvarname_wrtcmp_dy}" ]; then
    printf -v ${outvarname_wrtcmp_dy} "%s" "${__wrtcmp_dy__}"
  fi

  if [ ! -z "${outvarname_wrtcmp_dlon}" ]; then
    printf -v ${outvarname_wrtcmp_dlon} "%s" "${__wrtcmp_dlon__}"
  fi

  if [ ! -z "${outvarname_wrtcmp_dlat}" ]; then
    printf -v ${outvarname_wrtcmp_dlat} "%s" "${__wrtcmp_dlat__}"
  fi
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
