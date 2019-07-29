#
#-----------------------------------------------------------------------
#
# Check if predef_domain is set to a valid (non-empty) value.  If so:
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
"GSD_RAP")

  expt_title="_GSD_RAP${expt_title}"

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
    write_tasks_per_group="14"
    blocksize="26"

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
    write_tasks_per_group="16"
    blocksize="30"

  fi

  if [ "$quilting" = ".true." ]; then
    WRTCMP_PARAMS_TEMPLATE_FN=${WRTCMP_PARAMS_TEMPLATE_FN:-"wrtcmp_GSD_RAP"}
  fi
  ;;
#
#-----------------------------------------------------------------------
#
# Emulation of GSD's HRRR grid.
#
#-----------------------------------------------------------------------
#
"GSD_HRRR")

  expt_title="_GSD_HRRR${expt_title}"

  if [ "$grid_gen_method" = "GFDLgrid" ]; then

    lon_ctr_T6=-97.5
    lat_ctr_T6=38.5
    stretch_fac=1.65
    RES="384"
    refine_ratio=5

    num_margin_cells_T6_left=12
    istart_rgnl_T6=$(( $num_margin_cells_T6_left + 1 ))
  
    num_margin_cells_T6_right=12
    iend_rgnl_T6=$(( $RES - $num_margin_cells_T6_right ))
  
    num_margin_cells_T6_bottom=80
    jstart_rgnl_T6=$(( $num_margin_cells_T6_bottom + 1 ))
  
    num_margin_cells_T6_top=80
    jend_rgnl_T6=$(( $RES - $num_margin_cells_T6_top ))

    dt_atmos="50"

    layout_x="20"
    layout_y="20"
    write_tasks_per_group="20"
    blocksize="36"

  elif [ "$grid_gen_method" = "JPgrid" ]; then

    lon_rgnl_ctr=-97.5
    lat_rgnl_ctr=38.5

    delx="3000.0"
    dely="3000.0"

#
# This is the old HRRR-like grid that is slightly larger than the WRF-
# ARW HRRR grid.
#
if [ 0 = 1 ]; then

    nx_T7=1800
    ny_T7=1120

    nhw_T7=6

    dt_atmos="50"

    layout_x="20"
    layout_y="20"
    write_tasks_per_group="20"
    blocksize="36"
#
# This is the new HRRR-like grid that is slightly smaller than the WRF-
# ARW HRRR grid (so that it can be initialized off the latter).
#
else

    nx_T7=1734
    ny_T7=1008

    nhw_T7=6

    dt_atmos="50"

    layout_x="34"
    layout_y="24"
    write_tasks_per_group="24"
    blocksize="34"

fi


  fi

  if [ "$quilting" = ".true." ]; then
    WRTCMP_PARAMS_TEMPLATE_FN=${WRTCMP_PARAMS_TEMPLATE_FN:-"wrtcmp_HRRR"}
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

  if [ "$quilting" = ".true." ]; then
    WRTCMP_PARAMS_TEMPLATE_FN=${WRTCMP_PARAMS_TEMPLATE_FN:-"wrtcmp_EMC_CONUS"}
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

  if [ "$quilting" = ".true." ]; then
    WRTCMP_PARAMS_TEMPLATE_FN=${WRTCMP_PARAMS_TEMPLATE_FN:-"wrtcmp_EMC_AK"}
  fi
  ;;
#
esac
