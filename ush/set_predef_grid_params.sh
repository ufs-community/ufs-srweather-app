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

    LON_RGNL_CTR=-62.0
    LAT_RGNL_CTR=22.0

    DELX="3000.0"
    DELY="3000.0"

    NX_T7=2880
    NY_T7=1920

    NHW_T7=6

    DT_ATMOS="100"

    LAYOUT_X="32"
    LAYOUT_Y="24"
    BLOCKSIZE="32"

    if [ "$QUILTING" = "TRUE" ]; then
      WRTCMP_write_groups="1"
      WRTCMP_write_tasks_per_group="32"
      WRTCMP_output_grid="regional_latlon"
      WRTCMP_cen_lon="${LON_RGNL_CTR}"
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

    LON_RGNL_CTR=-62.0
    LAT_RGNL_CTR=22.0

    DELX="13000.0"
    DELY="13000.0"

    NX_T7=665
    NY_T7=444

    NHW_T7=6

    DT_ATMOS="180"

    LAYOUT_X="19"
    LAYOUT_Y="12"
    BLOCKSIZE="35"

    if [ "$QUILTING" = "TRUE" ]; then
      WRTCMP_write_groups="1"
      WRTCMP_write_tasks_per_group="32"
      WRTCMP_output_grid="regional_latlon"
      WRTCMP_cen_lon="${LON_RGNL_CTR}"
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

    LON_RGNL_CTR=-62.0
    LAT_RGNL_CTR=22.0

    DELX="25000.0"
    DELY="25000.0"

    NX_T7=345
    NY_T7=230

    NHW_T7=6

    DT_ATMOS="300"

    LAYOUT_X="5"
    LAYOUT_Y="5"
    BLOCKSIZE="6"

    if [ "$QUILTING" = "TRUE" ]; then
      WRTCMP_write_groups="1"
      WRTCMP_write_tasks_per_group="32"
      WRTCMP_output_grid="regional_latlon"
      WRTCMP_cen_lon="${LON_RGNL_CTR}"
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

    LON_CTR_T6=-106.0
    LAT_CTR_T6=54.0
    STRETCH_FAC=0.63
    RES="384"
    REFINE_RATIO=3
  
    num_margin_cells_T6_left=10
    ISTART_RGNL_T6=$(( num_margin_cells_T6_left + 1 ))
  
    num_margin_cells_T6_right=10
    IEND_RGNL_T6=$(( RES - num_margin_cells_T6_right ))
  
    num_margin_cells_T6_bottom=10
    JSTART_RGNL_T6=$(( num_margin_cells_T6_bottom + 1 ))
  
    num_margin_cells_T6_top=10
    JEND_RGNL_T6=$(( RES - num_margin_cells_T6_top ))

    DT_ATMOS="90"

    LAYOUT_X="14"
    LAYOUT_Y="14"
    BLOCKSIZE="26"

    if [ "$QUILTING" = "TRUE" ]; then
      WRTCMP_write_groups="1"
      WRTCMP_write_tasks_per_group="14"
      WRTCMP_output_grid="rotated_latlon"
      WRTCMP_cen_lon="${LON_RGNL_CTR}"
      WRTCMP_cen_lat="${LAT_RGNL_CTR}"
      WRTCMP_lon_lwr_left="-57.9926"
      WRTCMP_lat_lwr_left="-50.74344"
      WRTCMP_lon_upr_rght="57.99249"
      WRTCMP_lat_upr_rght="50.74344"
      WRTCMP_dlon="0.1218331"
      WRTCMP_dlat="0.121833"
    fi

  elif [ "${GRID_GEN_METHOD}" = "JPgrid" ]; then

    LON_RGNL_CTR=-106.0
    LAT_RGNL_CTR=54.0

    DELX="13000.0"
    DELY="13000.0"

    NX_T7=960
    NY_T7=960

    NHW_T7=6

    DT_ATMOS="90"

    LAYOUT_X="16"
    LAYOUT_Y="16"
    BLOCKSIZE="30"

    if [ "$QUILTING" = "TRUE" ]; then
      WRTCMP_write_groups="1"
      WRTCMP_write_tasks_per_group="16"
      WRTCMP_output_grid="rotated_latlon"
      WRTCMP_cen_lon="${LON_RGNL_CTR}"
      WRTCMP_cen_lat="${LAT_RGNL_CTR}"
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

    LON_RGNL_CTR=-97.5
    LAT_RGNL_CTR=38.5

    DELX="25000.0"
    DELY="25000.0"

    NX_T7=200
    NY_T7=110

    NHW_T7=6

    DT_ATMOS="300"

    LAYOUT_X="2"
    LAYOUT_Y="2"
    BLOCKSIZE="2"

    if [ "$QUILTING" = "TRUE" ]; then
      WRTCMP_write_groups="1"
      WRTCMP_write_tasks_per_group="2"
      WRTCMP_output_grid="lambert_conformal"
      WRTCMP_cen_lon="${LON_RGNL_CTR}"
      WRTCMP_cen_lat="${LAT_RGNL_CTR}"
      WRTCMP_stdlat1="${LAT_RGNL_CTR}"
      WRTCMP_stdlat2="${LAT_RGNL_CTR}"
      WRTCMP_nx="191"
      WRTCMP_ny="97"
      WRTCMP_lon_lwr_left="-120.72962370"
      WRTCMP_lat_lwr_left="25.11648583"
      WRTCMP_dx="$DELX"
      WRTCMP_dy="$DELY"
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

    LON_RGNL_CTR=-97.5
    LAT_RGNL_CTR=38.5

    DELX="13000.0"
    DELY="13000.0"

    NX_T7=390
    NY_T7=210

    NHW_T7=6

    DT_ATMOS="180"

    LAYOUT_X="10"
    LAYOUT_Y="10"
    BLOCKSIZE="39"

    if [ "$QUILTING" = "TRUE" ]; then
      WRTCMP_write_groups="1"
      WRTCMP_write_tasks_per_group="10"
      WRTCMP_output_grid="lambert_conformal"
      WRTCMP_cen_lon="${LON_RGNL_CTR}"
      WRTCMP_cen_lat="${LAT_RGNL_CTR}"
      WRTCMP_stdlat1="${LAT_RGNL_CTR}"
      WRTCMP_stdlat2="${LAT_RGNL_CTR}"
      WRTCMP_nx="383"
      WRTCMP_ny="195"
      WRTCMP_lon_lwr_left="-121.58647982"
      WRTCMP_lat_lwr_left="24.36006861"
      WRTCMP_dx="$DELX"
      WRTCMP_dy="$DELY"
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

    LON_RGNL_CTR=-97.5
    LAT_RGNL_CTR=38.5

    DELX="3000.0"
    DELY="3000.0"

    NX_T7=1734
    NY_T7=1008

    NHW_T7=6

    DT_ATMOS="40"

    LAYOUT_X="34"
    LAYOUT_Y="24"
    BLOCKSIZE="34"

    if [ "$QUILTING" = "TRUE" ]; then
      WRTCMP_write_groups="1"
      WRTCMP_write_tasks_per_group="24"
      WRTCMP_output_grid="lambert_conformal"
      WRTCMP_cen_lon="${LON_RGNL_CTR}"
      WRTCMP_cen_lat="${LAT_RGNL_CTR}"
      WRTCMP_stdlat1="${LAT_RGNL_CTR}"
      WRTCMP_stdlat2="${LAT_RGNL_CTR}"
      WRTCMP_nx="1738"
      WRTCMP_ny="974"
      WRTCMP_lon_lwr_left="-122.21414225"
      WRTCMP_lat_lwr_left="22.41403305"
      WRTCMP_dx="$DELX"
      WRTCMP_dy="$DELY"
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


    LON_CTR_T6=-97.5
    LAT_CTR_T6=38.5
    STRETCH_FAC=1.5
    RES="768"
    REFINE_RATIO=3
  
    num_margin_cells_T6_left=61
    ISTART_RGNL_T6=$(( num_margin_cells_T6_left + 1 ))
  
    num_margin_cells_T6_right=67
    IEND_RGNL_T6=$(( RES - num_margin_cells_T6_right ))
  
    num_margin_cells_T6_bottom=165
    JSTART_RGNL_T6=$(( num_margin_cells_T6_bottom + 1 ))
  
    num_margin_cells_T6_top=171
    JEND_RGNL_T6=$(( RES - num_margin_cells_T6_top ))

    DT_ATMOS="18"

    LAYOUT_X="16"
    LAYOUT_Y="72"
    write_tasks_per_group="72"
    BLOCKSIZE=32


  elif [ "${GRID_GEN_METHOD}" = "JPgrid" ]; then

    LON_RGNL_CTR=-97.5
    LAT_RGNL_CTR=38.5

    DELX="3000.0"
    DELY="3000.0"

    NX_T7=960
    NY_T7=960

    NHW_T7=6

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

    LON_CTR_T6=-153.0
    LAT_CTR_T6=61.0
    STRETCH_FAC=1.0  # ???
    RES="768"
    REFINE_RATIO=3   # ???
  
    num_margin_cells_T6_left=61
    ISTART_RGNL_T6=$(( num_margin_cells_T6_left + 1 ))
  
    num_margin_cells_T6_right=67
    IEND_RGNL_T6=$(( RES - num_margin_cells_T6_right ))
  
    num_margin_cells_T6_bottom=165
    JSTART_RGNL_T6=$(( num_margin_cells_T6_bottom + 1 ))
  
    num_margin_cells_T6_top=171
    JEND_RGNL_T6=$(( RES - num_margin_cells_T6_top ))

    DT_ATMOS="18"

    LAYOUT_X="16"
    LAYOUT_Y="48"
    write_groups="2"
    write_tasks_per_group="24"
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

    LON_RGNL_CTR=-163.5 #HRRR-AK is -163.5 
    LAT_RGNL_CTR=62.8 #HRRR-AK is 60.8

    DELX="3000.0"
    DELY="3000.0"

    NX_T7=1230 #HRRR-AK is 1300
    NY_T7=850 #HRRR-AK is 920

    NHW_T7=6

    DT_ATMOS="50"

    LAYOUT_X="30"
    LAYOUT_Y="17"
    BLOCKSIZE="25"

    if [ "$QUILTING" = "TRUE" ]; then
      WRTCMP_write_groups="1"
      WRTCMP_write_tasks_per_group="2"
      WRTCMP_output_grid="lambert_conformal"
      WRTCMP_cen_lon="${LON_RGNL_CTR}"
      WRTCMP_cen_lat="${LAT_RGNL_CTR}"
      WRTCMP_stdlat1="${LAT_RGNL_CTR}"
      WRTCMP_stdlat2="${LAT_RGNL_CTR}"
      WRTCMP_nx="1169"
      WRTCMP_ny="762"
      WRTCMP_lon_lwr_left="172.0"
      WRTCMP_lat_lwr_left="49.0"
      WRTCMP_dx="$DELX"
      WRTCMP_dy="$DELY"
    fi

  fi
  ;;
#
#-----------------------------------------------------------------------
#
# 3-km HRRR Alaska grid.
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

    LON_RGNL_CTR=-163.5 #HRRR-AK is -163.5 
    LAT_RGNL_CTR=62.8 #HRRR-AK is 60.8

    DELX="50000.0"
    DELY="50000.0"

    NX_T7=74 #HRRR-AK is 1300
    NY_T7=51 #HRRR-AK is 920

    NHW_T7=6

    DT_ATMOS="600"

    LAYOUT_X="2"
    LAYOUT_Y="3"
    BLOCKSIZE="37"

    if [ "$QUILTING" = "TRUE" ]; then
      WRTCMP_write_groups="1"
      WRTCMP_write_tasks_per_group="1"
      WRTCMP_output_grid="lambert_conformal"
      WRTCMP_cen_lon="${LON_RGNL_CTR}"
      WRTCMP_cen_lat="${LAT_RGNL_CTR}"
      WRTCMP_stdlat1="${LAT_RGNL_CTR}"
      WRTCMP_stdlat2="${LAT_RGNL_CTR}"
      WRTCMP_nx="70"
      WRTCMP_ny="45"
      WRTCMP_lon_lwr_left="172.0"
      WRTCMP_lat_lwr_left="49.0"
      WRTCMP_dx="$DELX"
      WRTCMP_dy="$DELY"
    fi

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
if [ "$QUILTING" = "TRUE" ]; then
#
# First, make sure that WRTCMP_output_grid is set to a valid value.
#
  err_msg="\
The coordinate system used by the write-component output grid specified
in WRTCMP_output_grid is not supported:
  WRTCMP_output_grid = \"${WRTCMP_output_grid}\""
  check_var_valid_value \
    "WRTCMP_output_grid" "valid_vals_WRTCMP_output_grid" "${err_msg}"
#
# Now set the name of the write-component template file.
#
  WRTCMP_PARAMS_TMPL_FN=${WRTCMP_PARAMS_TMPL_FN:-"wrtcmp_${WRTCMP_output_grid}"}

fi

}
#
#-----------------------------------------------------------------------
#
# Call the function defined above.
#
#-----------------------------------------------------------------------
#
set_predef_grid_params

