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
# Set grid and other parameters according to the value of the predefined
# domain (PREDEF_GRID_NAME).  Note that the code will enter this script 
# only if PREDEF_GRID_NAME has a valid (and non-empty) value.
#
# The following needs to be updated:
#
# 1) Reset the experiment title (expt_title).
# 2) Reset the grid parameters.
# 3) If the write component is to be used (i.e. QUILTING is set to
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
case ${PREDEF_GRID_NAME} in
#
#-----------------------------------------------------------------------
#
# Emulation of the HAFS v0.A grid at 3 km.
#
#-----------------------------------------------------------------------
#
"GSD_HAFSV0.A3km")

  if [ "${GRID_GEN_METHOD}" = "GFDLgrid" ]; then

    print_err_msg_exit "\
The parameters for a \"${GRID_GEN_METHOD}\" type grid have not yet been specified for this
predefined domain:
  PREDEF_GRID_NAME = \"${PREDEF_GRID_NAME}\"
  GRID_GEN_METHOD = \"${GRID_GEN_METHOD}\""

  elif [ "${GRID_GEN_METHOD}" = "JPgrid" ]; then

    JPgrid_LON_CTR=-62.0
    JPgrid_LAT_CTR=22.0

    JPgrid_DELX="3000.0"
    JPgrid_DELY="3000.0"

    JPgrid_NX=2880
    JPgrid_NY=1920

    JPgrid_WIDE_HALO_WIDTH=6

    DT_ATMOS="40"

    LAYOUT_X="32"
    LAYOUT_Y="24"
    BLOCKSIZE="32"

    if [ "$QUILTING" = "TRUE" ]; then
      WRTCMP_write_groups="1"
      WRTCMP_write_tasks_per_group="32"
      WRTCMP_output_grid="regional_latlon"
      WRTCMP_cen_lon="${JPgrid_LON_CTR}"
      WRTCMP_cen_lat="25.0"
      WRTCMP_lon_lwr_left="-114.5"
      WRTCMP_lat_lwr_left="-5.0"
      WRTCMP_lon_upr_rght="-9.5"
      WRTCMP_lat_upr_rght="55.0"
      WRTCMP_dlon="0.03"
      WRTCMP_dlat="0.03"
    fi

  fi
  ;;
#
#-----------------------------------------------------------------------
#
# Emulation of the HAFS v0.A grid at 13 km.
#
#-----------------------------------------------------------------------
#
"GSD_HAFSV0.A13km")

  if [ "${GRID_GEN_METHOD}" = "GFDLgrid" ]; then

    print_err_msg_exit "\
The parameters for a \"${GRID_GEN_METHOD}\" type grid have not yet been specified for this
predefined domain:
  PREDEF_GRID_NAME = \"${PREDEF_GRID_NAME}\"
  GRID_GEN_METHOD = \"${GRID_GEN_METHOD}\""

  elif [ "${GRID_GEN_METHOD}" = "JPgrid" ]; then

    JPgrid_LON_CTR=-62.0
    JPgrid_LAT_CTR=22.0

    JPgrid_DELX="13000.0"
    JPgrid_DELY="13000.0"

    JPgrid_NX=665
    JPgrid_NY=444

    JPgrid_WIDE_HALO_WIDTH=6

    DT_ATMOS="180"

    LAYOUT_X="19"
    LAYOUT_Y="12"
    BLOCKSIZE="35"

    if [ "$QUILTING" = "TRUE" ]; then
      WRTCMP_write_groups="1"
      WRTCMP_write_tasks_per_group="32"
      WRTCMP_output_grid="regional_latlon"
      WRTCMP_cen_lon="${JPgrid_LON_CTR}"
      WRTCMP_cen_lat="25.0"
      WRTCMP_lon_lwr_left="-114.5"
      WRTCMP_lat_lwr_left="-5.0"
      WRTCMP_lon_upr_rght="-9.5"
      WRTCMP_lat_upr_rght="55.0"
      WRTCMP_dlon="0.13"
      WRTCMP_dlat="0.13"
    fi

  fi
  ;;
#
#-----------------------------------------------------------------------
#
# Emulation of the HAFS v0.A grid at 25 km.
#
#-----------------------------------------------------------------------
#
"GSD_HAFSV0.A25km")

  if [ "${GRID_GEN_METHOD}" = "GFDLgrid" ]; then

    print_err_msg_exit "\
The parameters for a \"${GRID_GEN_METHOD}\" type grid have not yet been specified for this
predefined domain:
  PREDEF_GRID_NAME = \"${PREDEF_GRID_NAME}\"
  GRID_GEN_METHOD = \"${GRID_GEN_METHOD}\""

  elif [ "${GRID_GEN_METHOD}" = "JPgrid" ]; then

    JPgrid_LON_CTR=-62.0
    JPgrid_LAT_CTR=22.0

    JPgrid_DELX="25000.0"
    JPgrid_DELY="25000.0"

    JPgrid_NX=345
    JPgrid_NY=230

    JPgrid_WIDE_HALO_WIDTH=6

    DT_ATMOS="300"

    LAYOUT_X="5"
    LAYOUT_Y="5"
    BLOCKSIZE="6"

    if [ "$QUILTING" = "TRUE" ]; then
      WRTCMP_write_groups="1"
      WRTCMP_write_tasks_per_group="32"
      WRTCMP_output_grid="regional_latlon"
      WRTCMP_cen_lon="${JPgrid_LON_CTR}"
      WRTCMP_cen_lat="25.0"
      WRTCMP_lon_lwr_left="-114.5"
      WRTCMP_lat_lwr_left="-5.0"
      WRTCMP_lon_upr_rght="-9.5"
      WRTCMP_lat_upr_rght="55.0"
      WRTCMP_dlon="0.25"
      WRTCMP_dlat="0.25"
    fi

  fi
  ;;
#
#-----------------------------------------------------------------------
#
# Emulation of GSD's RAP grid.
#
#-----------------------------------------------------------------------
#
"GSD_RAP13km")

  if [ "${GRID_GEN_METHOD}" = "GFDLgrid" ]; then

    GFDLgrid_LON_T6_CTR=-106.0
    GFDLgrid_LAT_T6_CTR=54.0
    GFDLgrid_STRETCH_FAC=0.63
    GFDLgrid_RES="384"
    GFDLgrid_REFINE_RATIO=3
  
    num_margin_cells_T6_left=10
    GFDLgrid_ISTART_OF_RGNL_DOM_ON_T6G=$(( num_margin_cells_T6_left + 1 ))
  
    num_margin_cells_T6_right=10
    GFDLgrid_IEND_OF_RGNL_DOM_ON_T6G=$(( GFDLgrid_RES - num_margin_cells_T6_right ))
  
    num_margin_cells_T6_bottom=10
    GFDLgrid_JSTART_OF_RGNL_DOM_ON_T6G=$(( num_margin_cells_T6_bottom + 1 ))
  
    num_margin_cells_T6_top=10
    GFDLgrid_JEND_OF_RGNL_DOM_ON_T6G=$(( GFDLgrid_RES - num_margin_cells_T6_top ))

    GFDLgrid_USE_GFDLgrid_RES_IN_FILENAMES="FALSE"

    DT_ATMOS="90"

    LAYOUT_X="14"
    LAYOUT_Y="14"
    BLOCKSIZE="26"

    if [ "$QUILTING" = "TRUE" ]; then
      WRTCMP_write_groups="1"
      WRTCMP_write_tasks_per_group="14"
      WRTCMP_output_grid="rotated_latlon"
      WRTCMP_cen_lon="${GFDLgrid_LON_T6_CTR}"
      WRTCMP_cen_lat="${GFDLgrid_LAT_T6_CTR}"
      WRTCMP_lon_lwr_left="-57.9926"
      WRTCMP_lat_lwr_left="-50.74344"
      WRTCMP_lon_upr_rght="57.99249"
      WRTCMP_lat_upr_rght="50.74344"
      WRTCMP_dlon="0.1218331"
      WRTCMP_dlat="0.121833"
    fi

  elif [ "${GRID_GEN_METHOD}" = "JPgrid" ]; then

    JPgrid_LON_CTR=-106.0
    JPgrid_LAT_CTR=54.0

    JPgrid_DELX="13000.0"
    JPgrid_DELY="13000.0"

    JPgrid_NX=960
    JPgrid_NY=960

    JPgrid_WIDE_HALO_WIDTH=6

    DT_ATMOS="90"

    LAYOUT_X="16"
    LAYOUT_Y="16"
    BLOCKSIZE="30"

    if [ "$QUILTING" = "TRUE" ]; then
      WRTCMP_write_groups="1"
      WRTCMP_write_tasks_per_group="16"
      WRTCMP_output_grid="rotated_latlon"
      WRTCMP_cen_lon="${JPgrid_LON_CTR}"
      WRTCMP_cen_lat="${JPgrid_LAT_CTR}"
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

  if [ "${GRID_GEN_METHOD}" = "GFDLgrid" ]; then

    print_err_msg_exit "\
The parameters for a \"${GRID_GEN_METHOD}\" type grid have not yet been specified for this
predefined domain:
  PREDEF_GRID_NAME = \"${PREDEF_GRID_NAME}\"
  GRID_GEN_METHOD = \"${GRID_GEN_METHOD}\""

  elif [ "${GRID_GEN_METHOD}" = "JPgrid" ]; then

    JPgrid_LON_CTR=-97.5
    JPgrid_LAT_CTR=38.5

    JPgrid_DELX="25000.0"
    JPgrid_DELY="25000.0"

    JPgrid_NX=200
    JPgrid_NY=110

    JPgrid_WIDE_HALO_WIDTH=6

    DT_ATMOS="300"

    LAYOUT_X="2"
    LAYOUT_Y="2"
    BLOCKSIZE="2"

    if [ "$QUILTING" = "TRUE" ]; then
      WRTCMP_write_groups="1"
      WRTCMP_write_tasks_per_group="2"
      WRTCMP_output_grid="lambert_conformal"
      WRTCMP_cen_lon="${JPgrid_LON_CTR}"
      WRTCMP_cen_lat="${JPgrid_LAT_CTR}"
      WRTCMP_stdlat1="${JPgrid_LAT_CTR}"
      WRTCMP_stdlat2="${JPgrid_LAT_CTR}"
      WRTCMP_nx="191"
      WRTCMP_ny="97"
      WRTCMP_lon_lwr_left="-120.72962370"
      WRTCMP_lat_lwr_left="25.11648583"
      WRTCMP_dx="${JPgrid_DELX}"
      WRTCMP_dy="${JPgrid_DELY}"
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

  if [ "${GRID_GEN_METHOD}" = "GFDLgrid" ]; then

    print_err_msg_exit "\
The parameters for a \"${GRID_GEN_METHOD}\" type grid have not yet been specified for this
predefined domain:
  PREDEF_GRID_NAME = \"${PREDEF_GRID_NAME}\"
  GRID_GEN_METHOD = \"${GRID_GEN_METHOD}\""

  elif [ "${GRID_GEN_METHOD}" = "JPgrid" ]; then

    JPgrid_LON_CTR=-97.5
    JPgrid_LAT_CTR=38.5

    JPgrid_DELX="13000.0"
    JPgrid_DELY="13000.0"

    JPgrid_NX=390
    JPgrid_NY=210

    JPgrid_WIDE_HALO_WIDTH=6

    DT_ATMOS="180"

    LAYOUT_X="10"
    LAYOUT_Y="10"
    BLOCKSIZE="39"

    if [ "$QUILTING" = "TRUE" ]; then
      WRTCMP_write_groups="1"
      WRTCMP_write_tasks_per_group="10"
      WRTCMP_output_grid="lambert_conformal"
      WRTCMP_cen_lon="${JPgrid_LON_CTR}"
      WRTCMP_cen_lat="${JPgrid_LAT_CTR}"
      WRTCMP_stdlat1="${JPgrid_LAT_CTR}"
      WRTCMP_stdlat2="${JPgrid_LAT_CTR}"
      WRTCMP_nx="383"
      WRTCMP_ny="195"
      WRTCMP_lon_lwr_left="-121.58647982"
      WRTCMP_lat_lwr_left="24.36006861"
      WRTCMP_dx="${JPgrid_DELX}"
      WRTCMP_dy="${JPgrid_DELY}"
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

  if [ "${GRID_GEN_METHOD}" = "GFDLgrid" ]; then

    print_err_msg_exit "\
The parameters for a \"${GRID_GEN_METHOD}\" type grid have not yet been specified for this
predefined domain:
  PREDEF_GRID_NAME = \"${PREDEF_GRID_NAME}\"
  GRID_GEN_METHOD = \"${GRID_GEN_METHOD}\""

  elif [ "${GRID_GEN_METHOD}" = "JPgrid" ]; then

    JPgrid_LON_CTR=-97.5
    JPgrid_LAT_CTR=38.5

    JPgrid_DELX="3000.0"
    JPgrid_DELY="3000.0"

    JPgrid_NX=1734
    JPgrid_NY=1008

    JPgrid_WIDE_HALO_WIDTH=6

    DT_ATMOS="40"

    LAYOUT_X="34"
    LAYOUT_Y="24"
    BLOCKSIZE="34"

    if [ "$QUILTING" = "TRUE" ]; then
      WRTCMP_write_groups="1"
      WRTCMP_write_tasks_per_group="24"
      WRTCMP_output_grid="lambert_conformal"
      WRTCMP_cen_lon="${JPgrid_LON_CTR}"
      WRTCMP_cen_lat="${JPgrid_LAT_CTR}"
      WRTCMP_stdlat1="${JPgrid_LAT_CTR}"
      WRTCMP_stdlat2="${JPgrid_LAT_CTR}"
      WRTCMP_nx="1738"
      WRTCMP_ny="974"
      WRTCMP_lon_lwr_left="-122.21414225"
      WRTCMP_lat_lwr_left="22.41403305"
      WRTCMP_dx="${JPgrid_DELX}"
      WRTCMP_dy="${JPgrid_DELY}"
    fi

  fi
  ;;
#
#-----------------------------------------------------------------------
#
# EMC's 3km CONUS grid.
#
#-----------------------------------------------------------------------
#
"EMC_CONUS_3km")

  if [ "${GRID_GEN_METHOD}" = "GFDLgrid" ]; then
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


    GFDLgrid_LON_T6_CTR=-97.5
    GFDLgrid_LAT_T6_CTR=38.5
    GFDLgrid_STRETCH_FAC=1.5
    GFDLgrid_RES="768"
    GFDLgrid_REFINE_RATIO=3
  
    num_margin_cells_T6_left=61
    GFDLgrid_ISTART_OF_RGNL_DOM_ON_T6G=$(( num_margin_cells_T6_left + 1 ))
  
    num_margin_cells_T6_right=67
    GFDLgrid_IEND_OF_RGNL_DOM_ON_T6G=$(( GFDLgrid_RES - num_margin_cells_T6_right ))
  
    num_margin_cells_T6_bottom=165
    GFDLgrid_JSTART_OF_RGNL_DOM_ON_T6G=$(( num_margin_cells_T6_bottom + 1 ))
  
    num_margin_cells_T6_top=171
    GFDLgrid_JEND_OF_RGNL_DOM_ON_T6G=$(( GFDLgrid_RES - num_margin_cells_T6_top ))

    GFDLgrid_USE_GFDLgrid_RES_IN_FILENAMES="TRUE"

    DT_ATMOS="18"

    LAYOUT_X="16"
    LAYOUT_Y="72"
    BLOCKSIZE=32

    if [ "$QUILTING" = "TRUE" ]; then
      WRTCMP_write_groups="1"
      WRTCMP_write_tasks_per_group=$(( 1*LAYOUT_Y ))
      WRTCMP_output_grid="rotated_latlon"
      WRTCMP_cen_lon="${GFDLgrid_LON_T6_CTR}"
      WRTCMP_cen_lat="${GFDLgrid_LAT_T6_CTR}"
# GSK - The following have not been tested...
      WRTCMP_lon_lwr_left="-25.0"
      WRTCMP_lat_lwr_left="-15.0"
      WRTCMP_lon_upr_rght="25.0"
      WRTCMP_lat_upr_rght="15.0"
      WRTCMP_dlon="0.02"
      WRTCMP_dlat="0.02"
    fi

  elif [ "${GRID_GEN_METHOD}" = "JPgrid" ]; then

    JPgrid_LON_CTR=-97.5
    JPgrid_LAT_CTR=38.5

    JPgrid_DELX="3000.0"
    JPgrid_DELY="3000.0"

    JPgrid_NX=960
    JPgrid_NY=960

    JPgrid_WIDE_HALO_WIDTH=6

  fi
  ;;
#
#-----------------------------------------------------------------------
#
# EMC's coarse (?? km) CONUS grid.
#
#-----------------------------------------------------------------------
#
"EMC_CONUS_coarse")

  if [ "${GRID_GEN_METHOD}" = "GFDLgrid" ]; then

    GFDLgrid_LON_T6_CTR=-97.5
    GFDLgrid_LAT_T6_CTR=38.5
    GFDLgrid_STRETCH_FAC=1.5
    GFDLgrid_RES="96"
    GFDLgrid_REFINE_RATIO=2
  
    num_margin_cells_T6_left=9
    GFDLgrid_ISTART_OF_RGNL_DOM_ON_T6G=$(( num_margin_cells_T6_left + 1 ))
  
    num_margin_cells_T6_right=9
    GFDLgrid_IEND_OF_RGNL_DOM_ON_T6G=$(( GFDLgrid_RES - num_margin_cells_T6_right ))
  
    num_margin_cells_T6_bottom=9
    GFDLgrid_JSTART_OF_RGNL_DOM_ON_T6G=$(( num_margin_cells_T6_bottom + 1 ))
  
    num_margin_cells_T6_top=9
    GFDLgrid_JEND_OF_RGNL_DOM_ON_T6G=$(( GFDLgrid_RES - num_margin_cells_T6_top ))

    GFDLgrid_USE_GFDLgrid_RES_IN_FILENAMES="TRUE"

    DT_ATMOS="100"

    LAYOUT_X="6"
    LAYOUT_Y="6"
    BLOCKSIZE="26"

    if [ "$QUILTING" = "TRUE" ]; then
      WRTCMP_write_groups="1"
      WRTCMP_write_tasks_per_group=$(( 1*LAYOUT_Y ))
      WRTCMP_output_grid="rotated_latlon"
      WRTCMP_cen_lon="${GFDLgrid_LON_T6_CTR}"
      WRTCMP_cen_lat="${GFDLgrid_LAT_T6_CTR}"
# GSK - The following have not been tested...
      WRTCMP_lon_lwr_left="-25.0"
      WRTCMP_lat_lwr_left="-15.0"
      WRTCMP_lon_upr_rght="25.0"
      WRTCMP_lat_upr_rght="15.0"
      WRTCMP_dlon="0.24"
      WRTCMP_dlat="0.24"
    fi

  elif [ "${GRID_GEN_METHOD}" = "JPgrid" ]; then

    print_err_msg_exit "\
The parameters for a \"${GRID_GEN_METHOD}\" type grid have not yet been specified for this
predefined domain:
  PREDEF_GRID_NAME = \"${PREDEF_GRID_NAME}\"
  GRID_GEN_METHOD = \"${GRID_GEN_METHOD}\""

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

  if [ "${GRID_GEN_METHOD}" = "GFDLgrid" ]; then

    print_err_msg_exit "\
The parameters for a \"${GRID_GEN_METHOD}\" type grid have not yet been specified for this
predefined domain:
  PREDEF_GRID_NAME = \"${PREDEF_GRID_NAME}\"
  GRID_GEN_METHOD = \"${GRID_GEN_METHOD}\""

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

    GFDLgrid_LON_T6_CTR=-153.0
    GFDLgrid_LAT_T6_CTR=61.0
    GFDLgrid_STRETCH_FAC=1.0  # ???
    GFDLgrid_RES="768"
    GFDLgrid_REFINE_RATIO=3   # ???
  
    num_margin_cells_T6_left=61
    GFDLgrid_ISTART_OF_RGNL_DOM_ON_T6G=$(( num_margin_cells_T6_left + 1 ))
  
    num_margin_cells_T6_right=67
    GFDLgrid_IEND_OF_RGNL_DOM_ON_T6G=$(( GFDLgrid_RES - num_margin_cells_T6_right ))
  
    num_margin_cells_T6_bottom=165
    GFDLgrid_JSTART_OF_RGNL_DOM_ON_T6G=$(( num_margin_cells_T6_bottom + 1 ))
  
    num_margin_cells_T6_top=171
    GFDLgrid_JEND_OF_RGNL_DOM_ON_T6G=$(( GFDLgrid_RES - num_margin_cells_T6_top ))

    GFDLgrid_USE_GFDLgrid_RES_IN_FILENAMES="TRUE"

    DT_ATMOS="18"

    LAYOUT_X="16"
    LAYOUT_Y="48"
    WRTCMP_write_groups="2"
    WRTCMP_write_tasks_per_group="24"
    BLOCKSIZE=32

  elif [ "${GRID_GEN_METHOD}" = "JPgrid" ]; then

    print_err_msg_exit "\
The parameters for a \"${GRID_GEN_METHOD}\" type grid have not yet been specified for this
predefined domain:
  PREDEF_GRID_NAME = \"${PREDEF_GRID_NAME}\"
  GRID_GEN_METHOD = \"${GRID_GEN_METHOD}\""

  fi
  ;;
#
#-----------------------------------------------------------------------
#
# 3-km HRRR Alaska grid.
#
#-----------------------------------------------------------------------
#
"GSD_HRRR_AK_3km")

  if [ "${GRID_GEN_METHOD}" = "GFDLgrid" ]; then

    print_err_msg_exit "\
The parameters for a \"${GRID_GEN_METHOD}\" type grid have not yet been specified for this
predefined domain:
  PREDEF_GRID_NAME = \"${PREDEF_GRID_NAME}\"
  GRID_GEN_METHOD = \"${GRID_GEN_METHOD}\"
"
  elif [ "${GRID_GEN_METHOD}" = "JPgrid" ]; then

    JPgrid_LON_CTR=-163.5 #HRRR-AK is -163.5 
    JPgrid_LAT_CTR=62.8 #HRRR-AK is 60.8

    JPgrid_DELX="3000.0"
    JPgrid_DELY="3000.0"

    JPgrid_NX=1230 #HRRR-AK is 1300
    JPgrid_NY=850 #HRRR-AK is 920

    JPgrid_WIDE_HALO_WIDTH=6

    DT_ATMOS="50"

    LAYOUT_X="30"
    LAYOUT_Y="17"
    BLOCKSIZE="25"

    if [ "$QUILTING" = "TRUE" ]; then
      WRTCMP_write_groups="1"
      WRTCMP_write_tasks_per_group="2"
      WRTCMP_output_grid="lambert_conformal"
      WRTCMP_cen_lon="${JPgrid_LON_CTR}"
      WRTCMP_cen_lat="${JPgrid_LAT_CTR}"
      WRTCMP_stdlat1="${JPgrid_LAT_CTR}"
      WRTCMP_stdlat2="${JPgrid_LAT_CTR}"
      WRTCMP_nx="1169"
      WRTCMP_ny="762"
      WRTCMP_lon_lwr_left="172.0"
      WRTCMP_lat_lwr_left="49.0"
      WRTCMP_dx="${JPgrid_DELX}"
      WRTCMP_dy="${JPgrid_DELY}"
    fi

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

  if [ "${GRID_GEN_METHOD}" = "GFDLgrid" ]; then

    print_err_msg_exit "\
The parameters for a \"${GRID_GEN_METHOD}\" type grid have not yet been specified for this
predefined domain:
  PREDEF_GRID_NAME = \"${PREDEF_GRID_NAME}\"
  GRID_GEN_METHOD = \"${GRID_GEN_METHOD}\"
"
  elif [ "${GRID_GEN_METHOD}" = "JPgrid" ]; then

    JPgrid_LON_CTR=-163.5
    JPgrid_LAT_CTR=62.8

    JPgrid_DELX="50000.0"
    JPgrid_DELY="50000.0"

    JPgrid_NX=74
    JPgrid_NY=51

    JPgrid_WIDE_HALO_WIDTH=6

    DT_ATMOS="600"

    LAYOUT_X="2"
    LAYOUT_Y="3"
    BLOCKSIZE="37"

    if [ "$QUILTING" = "TRUE" ]; then
      WRTCMP_write_groups="1"
      WRTCMP_write_tasks_per_group="1"
      WRTCMP_output_grid="lambert_conformal"
      WRTCMP_cen_lon="${JPgrid_LON_CTR}"
      WRTCMP_cen_lat="${JPgrid_LAT_CTR}"
      WRTCMP_stdlat1="${JPgrid_LAT_CTR}"
      WRTCMP_stdlat2="${JPgrid_LAT_CTR}"
      WRTCMP_nx="70"
      WRTCMP_ny="45"
      WRTCMP_lon_lwr_left="172.0"
      WRTCMP_lat_lwr_left="49.0"
      WRTCMP_dx="${JPgrid_DELX}"
      WRTCMP_dy="${JPgrid_DELY}"
    fi

  fi
  ;;
#
esac

}
#
#-----------------------------------------------------------------------
#
# Call the function defined above.
#
#-----------------------------------------------------------------------
#
set_predef_grid_params

