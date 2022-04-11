#
# TEST PURPOSE/DESCRIPTION:
# ------------------------
#
# This test checks the capability of the workflow to have the user
# specify a new grid (as opposed to one of the predefined ones in the
# workflow) of ESGgrid type.


RUN_ENVIR="community"
PREEXISTING_DIR_METHOD="rename"

CCPP_PHYS_SUITE="FV3_GFS_2017_gfdlmp_regional"

EXTRN_MDL_NAME_ICS="FV3GFS"
EXTRN_MDL_NAME_LBCS="FV3GFS"
USE_USER_STAGED_EXTRN_FILES="TRUE"

DATE_FIRST_CYCL="20190701"
DATE_LAST_CYCL="20190701"
CYCL_HRS=( "00" )

FCST_LEN_HRS="6"
LBC_SPEC_INTVL_HRS="3"
#
# Define custom grid.
#
GRID_GEN_METHOD="ESGgrid"

ESGgrid_LON_CTR="-97.5"
ESGgrid_LAT_CTR="41.25"

ESGgrid_DELX="25000.0"
ESGgrid_DELY="25000.0"

ESGgrid_NX="216"
ESGgrid_NY="156"

ESGgrid_WIDE_HALO_WIDTH="6"

DT_ATMOS="40"

LAYOUT_X="8"
LAYOUT_Y="12"
BLOCKSIZE="13"

QUILTING="TRUE"
if [ "$QUILTING" = "TRUE" ]; then
  WRTCMP_write_groups="1"
  WRTCMP_write_tasks_per_group=$(( 1*LAYOUT_Y ))
  WRTCMP_output_grid="lambert_conformal"
  WRTCMP_cen_lon="${ESGgrid_LON_CTR}"
  WRTCMP_cen_lat="${ESGgrid_LAT_CTR}"
  WRTCMP_stdlat1="${ESGgrid_LAT_CTR}"
  WRTCMP_stdlat2="${ESGgrid_LAT_CTR}"
  WRTCMP_nx="200"
  WRTCMP_ny="150"
  WRTCMP_lon_lwr_left="-122.21414225"
  WRTCMP_lat_lwr_left="22.41403305"
  WRTCMP_dx="${ESGgrid_DELX}"
  WRTCMP_dy="${ESGgrid_DELY}"
fi
