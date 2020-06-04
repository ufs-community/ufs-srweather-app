#
# MACHINE will be set by the workflow launch script (launch_FV3SAR_-
# wflow.sh) to value passed in as an argument to that script.
#
MACHINE=""
#
# ACCOUNT will be set by the workflow launch script (launch_FV3SAR_-
# wflow.sh) to value passed in as an argument to that script.
#
ACCOUNT=""
#
# EXPT_SUBDIR will be set by the workflow launch script (launch_FV3SAR_-
# wflow.sh) to a value obtained from the name of this file.
#
EXPT_SUBDIR=""
#
# USE_CRON_TO_RELAUNCH may be reset by the workflow launch script
# (launch_FV3SAR_wflow.sh) to value passed in as an argument to that
# script, but in case it is not, we give it a default value here.
#
USE_CRON_TO_RELAUNCH="TRUE"
#
# CRON_RELAUNCH_INTVL_MNTS may be reset by the workflow launch script
# (launch_FV3SAR_wflow.sh) to value passed in as an argument to that
# script, but in case it is not, we give it a default value here.
#
CRON_RELAUNCH_INTVL_MNTS="02"


QUEUE_DEFAULT="batch"
QUEUE_HPSS="service"
QUEUE_FCST="batch"

VERBOSE="TRUE"

RUN_ENVIR="community"
PREEXISTING_DIR_METHOD="rename"

GRID_GEN_METHOD="JPgrid"

JPgrid_LON_CTR=-97.5
JPgrid_LAT_CTR=41.25

JPgrid_DELX="25000.0"
JPgrid_DELY="25000.0"

JPgrid_NX=216
JPgrid_NY=156

JPgrid_WIDE_HALO_WIDTH=6

DT_ATMOS="40"

LAYOUT_X="8"
LAYOUT_Y="6"
BLOCKSIZE="26"

if [ "$QUILTING" = "TRUE" ]; then
  WRTCMP_write_groups="1"
  WRTCMP_write_tasks_per_group=$(( 1*LAYOUT_Y ))                     
  WRTCMP_output_grid="lambert_conformal"
  WRTCMP_cen_lon="${JPgrid_LON_CTR}"
  WRTCMP_cen_lat="${JPgrid_LAT_CTR}"
  WRTCMP_stdlat1="${JPgrid_LAT_CTR}"
  WRTCMP_stdlat2="${JPgrid_LAT_CTR}"
  WRTCMP_nx="200"
  WRTCMP_ny="150"
  WRTCMP_lon_lwr_left="-122.21414225"
  WRTCMP_lat_lwr_left="22.41403305"
  WRTCMP_dx="${JPgrid_DELX}"
  WRTCMP_dy="${JPgrid_DELY}"
fi

USE_CCPP="TRUE"
CCPP_PHYS_SUITE="FV3_GFS_2017_gfdlmp_regional"
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

