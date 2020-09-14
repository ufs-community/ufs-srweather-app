#
# The values of the variables MACHINE, ACCOUNT, and EXPT_SUBDIR are required
# inputs to the script that launces the WE2E test experiments.  That script 
# will use those inputs to fill in the values of these variables below.
#
MACHINE=""
ACCOUNT=""
EXPT_SUBDIR=""
#
# The values of the variables USE_CRON_TO_RELAUNCH and CRON_RELAUNCH_INTVL_MNTS
# are optional inputs to the script that launces the WE2E test experiments.  
# If one or both of these values are specified, then that script will 
# replace the default values of these variables below with those values.
# Otherwise, it will keep the default values.
#
USE_CRON_TO_RELAUNCH="TRUE"
CRON_RELAUNCH_INTVL_MNTS="02"

VERBOSE="TRUE"

RUN_ENVIR="community"
PREEXISTING_DIR_METHOD="rename"

GRID_GEN_METHOD="GFDLgrid"

GFDLgrid_LON_T6_CTR=-97.5
GFDLgrid_LAT_T6_CTR=38.5
GFDLgrid_STRETCH_FAC=1.5
GFDLgrid_RES="96"
GFDLgrid_REFINE_RATIO=2
  
#num_margin_cells_T6_left=9
#GFDLgrid_ISTART_OF_RGNL_DOM_ON_T6G=$(( num_margin_cells_T6_left + 1 ))
GFDLgrid_ISTART_OF_RGNL_DOM_ON_T6G="10"

#num_margin_cells_T6_right=9
#GFDLgrid_IEND_OF_RGNL_DOM_ON_T6G=$(( GFDLgrid_RES - num_margin_cells_T6_right ))
GFDLgrid_IEND_OF_RGNL_DOM_ON_T6G="87"

#num_margin_cells_T6_bottom=9
#GFDLgrid_JSTART_OF_RGNL_DOM_ON_T6G=$(( num_margin_cells_T6_bottom + 1 ))
GFDLgrid_JSTART_OF_RGNL_DOM_ON_T6G="10"

#num_margin_cells_T6_top=9
#GFDLgrid_JEND_OF_RGNL_DOM_ON_T6G=$(( GFDLgrid_RES - num_margin_cells_T6_top ))
GFDLgrid_JEND_OF_RGNL_DOM_ON_T6G="87"

GFDLgrid_USE_GFDLgrid_RES_IN_FILENAMES="FALSE"

DT_ATMOS="100"

LAYOUT_X="6"
LAYOUT_Y="6"
BLOCKSIZE="26"

QUILTING="TRUE"

if [ "$QUILTING" = "TRUE" ]; then
  WRTCMP_write_groups="1"
  WRTCMP_write_tasks_per_group=$(( 1*LAYOUT_Y ))
  WRTCMP_output_grid="rotated_latlon"
  WRTCMP_cen_lon="${GFDLgrid_LON_T6_CTR}"
  WRTCMP_cen_lat="${GFDLgrid_LAT_T6_CTR}"
# The following have not been tested...
  WRTCMP_lon_lwr_left="-25.0"
  WRTCMP_lat_lwr_left="-15.0"
  WRTCMP_lon_upr_rght="25.0"
  WRTCMP_lat_upr_rght="15.0"
  WRTCMP_dlon="0.24"
  WRTCMP_dlat="0.24"
fi

USE_CCPP="TRUE"
CCPP_PHYS_SUITE="FV3_GFS_2017_gfdlmp"
FCST_LEN_HRS="06"
LBC_SPEC_INTVL_HRS="3"

DATE_FIRST_CYCL="20190701"
DATE_LAST_CYCL="20190701"
CYCL_HRS=( "00" )

EXTRN_MDL_NAME_ICS="FV3GFS"
EXTRN_MDL_NAME_LBCS="FV3GFS"

RUN_TASK_MAKE_GRID="TRUE"
RUN_TASK_MAKE_OROG="TRUE"
RUN_TASK_MAKE_SFC_CLIMO="TRUE"

