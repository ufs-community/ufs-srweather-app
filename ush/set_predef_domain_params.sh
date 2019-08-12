#
#-----------------------------------------------------------------------
#
# Set grid and other parameters according to the value of the predefined
# domain (predef_domain).  Note that the code will enter this script on-
# ly if predef_domain has a valid (and non-empty) value.
#
# The following needs to be updated:
#
# 1) Reset the experiment title (expt_title).
# 2) Reset the grid parameters.
# 3) If the write component is to be used (i.e. quilting is set to
#    ".true.") and the variable WRTCMP_PARAMS_TEMPLATE_FN containing the
#    name of the write-component template file is unset or empty, set
#    that filename variable to the appropriate preexisting template
#    file.
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
case $predef_domain in
#
#-----------------------------------------------------------------------
#
# Emulation of GSD's RAP grid.
#
#-----------------------------------------------------------------------
#
"GSD_RAP13km")

  expt_title="_GSD_RAP13km${expt_title}"

  if [ "$grid_gen_method" = "GFDLgrid" ]; then

    lon_ctr_T6=-106.0
    lat_ctr_T6=54.0
    stretch_fac=0.63
    RES="384"
    refine_ratio=3
  
    num_margin_cells_T6_left=10
    istart_rgnl_T6=$(( $num_margin_cells_T6_left + 1 ))
  
    num_margin_cells_T6_right=10
    iend_rgnl_T6=$(( $RES - $num_margin_cells_T6_right ))
  
    num_margin_cells_T6_bottom=10
    jstart_rgnl_T6=$(( $num_margin_cells_T6_bottom + 1 ))
  
    num_margin_cells_T6_top=10
    jend_rgnl_T6=$(( $RES - $num_margin_cells_T6_top ))

    dt_atmos="90"

    layout_x="14"
    layout_y="14"
    blocksize="26"

    if [ "$quilting" = ".true." ]; then
      WRTCMP_write_groups="1"
      WRTCMP_write_tasks_per_group="14"
      WRTCMP_output_grid="rotated_latlon"
      WRTCMP_cen_lon="${lon_rgnl_ctr}"
      WRTCMP_cen_lat="${lat_rgnl_ctr}"
      WRTCMP_lon_lwr_left="-57.9926"
      WRTCMP_lat_lwr_left="-50.74344"
      WRTCMP_lon_upr_rght="57.99249"
      WRTCMP_lat_upr_rght="50.74344"
      WRTCMP_dlon="0.1218331"
      WRTCMP_dlat="0.121833"
    fi

  elif [ "$grid_gen_method" = "JPgrid" ]; then

    lon_rgnl_ctr=-106.0
    lat_rgnl_ctr=54.0

    delx="13000.0"
    dely="13000.0"

    nx_T7=960
    ny_T7=960

    nhw_T7=6

    dt_atmos="90"

    layout_x="16"
    layout_y="16"
    blocksize="30"

    if [ "$quilting" = ".true." ]; then
      WRTCMP_write_groups="1"
      WRTCMP_write_tasks_per_group="16"
      WRTCMP_output_grid="rotated_latlon"
      WRTCMP_cen_lon="${lon_rgnl_ctr}"
      WRTCMP_cen_lat="${lat_rgnl_ctr}"
      WRTCMP_lon_lwr_left="-57.9926"
      WRTCMP_lat_lwr_left="-50.74344"
      WRTCMP_lon_upr_rght="57.99249"
      WRTCMP_lat_upr_rght="50.74344"
      WRTCMP_dlon="0.1218331"
      WRTCMP_dlat="0.121833"
    fi

  fi
  ;;
#
#-----------------------------------------------------------------------
#
# GSD's CONUS domain with ~150km cells.
#
#-----------------------------------------------------------------------
#
"GSD_HRRR25km")

  expt_title="_GSD_HRRR25km${expt_title}"

  if [ "$grid_gen_method" = "GFDLgrid" ]; then

    print_err_msg_exit "\
The parameters for a \"$grid_gen_method\" type grid have not yet been specified for this
predefined domain:
  predef_domain = \"$predef_domain\"
  grid_gen_method = \"$grid_gen_method\"
"

  elif [ "$grid_gen_method" = "JPgrid" ]; then

    lon_rgnl_ctr=-97.5
    lat_rgnl_ctr=38.5

    delx="25000.0"
    dely="25000.0"

    nx_T7=200
    ny_T7=110

    nhw_T7=6

    dt_atmos="10"

    layout_x="2"
    layout_y="2"
    blocksize="2"

    if [ "$quilting" = ".true." ]; then
      WRTCMP_write_groups="1"
      WRTCMP_write_tasks_per_group="2"
      WRTCMP_output_grid="lambert_conformal"
      WRTCMP_cen_lon="${lon_rgnl_ctr}"
      WRTCMP_cen_lat="${lat_rgnl_ctr}"
      WRTCMP_stdlat1="${lat_rgnl_ctr}"
      WRTCMP_stdlat2="${lat_rgnl_ctr}"
      WRTCMP_nx="191"
      WRTCMP_ny="97"
      WRTCMP_lon_lwr_left="-120.72962370"
      WRTCMP_lat_lwr_left="25.11648583"
      WRTCMP_dx="$delx"
      WRTCMP_dy="$dely"
    fi

  fi
  ;;
#
#-----------------------------------------------------------------------
#
# GSD's CONUS domain with ~13km cells.
#
#-----------------------------------------------------------------------
#
"GSD_HRRR13km")

  expt_title="_GSD_HRRR13km${expt_title}"

  if [ "$grid_gen_method" = "GFDLgrid" ]; then

    print_err_msg_exit "\
The parameters for a \"$grid_gen_method\" type grid have not yet been specified for this
predefined domain:
  predef_domain = \"$predef_domain\"
  grid_gen_method = \"$grid_gen_method\"
"

  elif [ "$grid_gen_method" = "JPgrid" ]; then

    lon_rgnl_ctr=-97.5
    lat_rgnl_ctr=38.5

    delx="13000.0"
    dely="13000.0"

    nx_T7=390
    ny_T7=210

    nhw_T7=6

    dt_atmos="10"

    layout_x="10"
    layout_y="10"
    blocksize="39"

    if [ "$quilting" = ".true." ]; then
      WRTCMP_write_groups="1"
      WRTCMP_write_tasks_per_group="10"
      WRTCMP_output_grid="lambert_conformal"
      WRTCMP_cen_lon="${lon_rgnl_ctr}"
      WRTCMP_cen_lat="${lat_rgnl_ctr}"
      WRTCMP_stdlat1="${lat_rgnl_ctr}"
      WRTCMP_stdlat2="${lat_rgnl_ctr}"
      WRTCMP_nx="400"
      WRTCMP_ny="224"
      WRTCMP_lon_lwr_left="-122.21414225"
      WRTCMP_lat_lwr_left="22.41403305"
      WRTCMP_dx="$delx"
      WRTCMP_dy="$dely"
    fi

  fi
  ;;
#
#-----------------------------------------------------------------------
#
# GSD's CONUS domain with ~3km cells.
#
#-----------------------------------------------------------------------
#
"GSD_HRRR3km")

  expt_title="_GSD_HRRR3km${expt_title}"

  if [ "$grid_gen_method" = "GFDLgrid" ]; then

    print_err_msg_exit "\
The parameters for a \"$grid_gen_method\" type grid have not yet been specified for this
predefined domain:
  predef_domain = \"$predef_domain\"
  grid_gen_method = \"$grid_gen_method\"
"

  elif [ "$grid_gen_method" = "JPgrid" ]; then

    lon_rgnl_ctr=-97.5
    lat_rgnl_ctr=38.5

    delx="3000.0"
    dely="3000.0"

    nx_T7=1734
    ny_T7=1008

    nhw_T7=6

    dt_atmos="50"

    layout_x="34"
    layout_y="24"
    blocksize="34"

    if [ "$quilting" = ".true." ]; then
      WRTCMP_write_groups="1"
      WRTCMP_write_tasks_per_group="24"
      WRTCMP_output_grid="lambert_conformal"
      WRTCMP_cen_lon="${lon_rgnl_ctr}"
      WRTCMP_cen_lat="${lat_rgnl_ctr}"
      WRTCMP_stdlat1="${lat_rgnl_ctr}"
      WRTCMP_stdlat2="${lat_rgnl_ctr}"
      WRTCMP_nx="1738"
      WRTCMP_ny="974"
      WRTCMP_lon_lwr_left="-122.21414225"
      WRTCMP_lat_lwr_left="22.41403305"
      WRTCMP_dx="$delx"
      WRTCMP_dy="$dely"
    fi

  fi
  ;;
#
#-----------------------------------------------------------------------
#
# EMC's CONUS grid.
#
#-----------------------------------------------------------------------
#
"EMC_CONUS")

  expt_title="_EMC_CONUS${expt_title}"

  if [ "$grid_gen_method" = "GFDLgrid" ]; then
# Values from an EMC script.

### rocoto items
#
#fcstnodes=76
#bcnodes=11
#postnodes=2
#goespostnodes=15
#goespostthrottle=3
#sh=00
#eh=12
#
### namelist items
#
#task_layout_x=16
#task_layout_y=48
#npx=1921
#npy=1297
#target_lat=38.5
#target_lon=-97.5
#
### model config items
#
##write_groups=3            # Already defined in community workflow.
##write_tasks_per_group=48  # Already defined in community workflow.
#cen_lon=$target_lon
#cen_lat=$target_lat
#lon1=-25.0
#lat1=-15.0
#lon2=25.0
#lat2=15.0
#dlon=0.02
#dlat=0.02


    lon_ctr_T6=-97.5
    lat_ctr_T6=38.5
    stretch_fac=1.5
    RES="768"
    refine_ratio=3
  
    num_margin_cells_T6_left=61
    istart_rgnl_T6=$(( $num_margin_cells_T6_left + 1 ))
  
    num_margin_cells_T6_right=67
    iend_rgnl_T6=$(( $RES - $num_margin_cells_T6_right ))
  
    num_margin_cells_T6_bottom=165
    jstart_rgnl_T6=$(( $num_margin_cells_T6_bottom + 1 ))
  
    num_margin_cells_T6_top=171
    jend_rgnl_T6=$(( $RES - $num_margin_cells_T6_top ))

    dt_atmos="18"

    layout_x="16"
    layout_y="72"
    write_tasks_per_group="72"
    blocksize=32


  elif [ "$grid_gen_method" = "JPgrid" ]; then

    lon_rgnl_ctr=-97.5
    lat_rgnl_ctr=38.5

    delx="3000.0"
    dely="3000.0"

    nx_T7=960
    ny_T7=960

    nhw_T7=6

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

  expt_title="_EMC_AK${expt_title}"

  if [ "$grid_gen_method" = "GFDLgrid" ]; then

    print_err_msg_exit "\
The parameters for a \"$grid_gen_method\" type grid have not yet been specified for this
predefined domain:
  predef_domain = \"$predef_domain\"
  grid_gen_method = \"$grid_gen_method\"
"

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

    lon_ctr_T6=-153.0
    lat_ctr_T6=61.0
    stretch_fac=1.0  # ???
    RES="768"
    refine_ratio=3   # ???
  
    num_margin_cells_T6_left=61
    istart_rgnl_T6=$(( $num_margin_cells_T6_left + 1 ))
  
    num_margin_cells_T6_right=67
    iend_rgnl_T6=$(( $RES - $num_margin_cells_T6_right ))
  
    num_margin_cells_T6_bottom=165
    jstart_rgnl_T6=$(( $num_margin_cells_T6_bottom + 1 ))
  
    num_margin_cells_T6_top=171
    jend_rgnl_T6=$(( $RES - $num_margin_cells_T6_top ))

    dt_atmos="18"

    layout_x="16"
    layout_y="48"
    write_groups="2"
    write_tasks_per_group="24"
    blocksize=32

  elif [ "$grid_gen_method" = "JPgrid" ]; then

    print_err_msg_exit "\
The parameters for a \"$grid_gen_method\" type grid have not yet been specified for this
predefined domain:
  predef_domain = \"$predef_domain\"
  grid_gen_method = \"$grid_gen_method\"
"

  fi
  ;;
#
esac
#
#-----------------------------------------------------------------------
#
# Set the name of the template file containing placeholder values for
# write-component parameters (if this file name is not already set).  
# This file will be appended to the model_configure file, and place-
# holder values will be replaced with actual ones.
#
#-----------------------------------------------------------------------
#
if [ "$quilting" = ".true." ]; then
#
# First, make sure that WRTCMP_output_grid is set to a valid value.
#
  iselementof "$WRTCMP_output_grid" valid_vals_WRTCMP_output_grid || { \
  valid_vals_WRTCMP_output_grid_str=$(printf "\"%s\" " "${valid_vals_WRTCMP_output_grid[@]}");
  print_err_msg_exit "\
The write-component coordinate system specified in WRTCMP_output_grid is 
not supported:
  WRTCMP_output_grid = \"$WRTCMP_output_grid\"
WRTCMP_output_grid must be set to one of the following:
  $valid_vals_WRTCMP_output_grid_str
"; }
#
# Now set the name of the write-component template file.
#
  WRTCMP_PARAMS_TEMPLATE_FN=${WRTCMP_PARAMS_TEMPLATE_FN:-"wrtcmp_${WRTCMP_output_grid}"}

fi

