MACHINE="hera"
ACCOUNT="an_account"
EXPT_SUBDIR="test_nco"

QUEUE_DEFAULT="batch"
QUEUE_HPSS="service"
QUEUE_FCST="batch"

VERBOSE="TRUE"

RUN_ENVIR="nco"
PREEXISTING_DIR_METHOD="rename"

EMC_GRID_NAME="conus"
GRID_GEN_METHOD="JPgrid"

QUILTING="TRUE"
USE_CCPP="TRUE"
CCPP_PHYS_SUITE="FV3_GFS_2017_gfdlmp"
FCST_LEN_HRS="06"
LBC_UPDATE_INTVL_HRS="6"

DATE_FIRST_CYCL="20190901"
DATE_LAST_CYCL="20190901"
CYCL_HRS=( "18" )

EXTRN_MDL_NAME_ICS="FV3GFS"
EXTRN_MDL_NAME_LBCS="FV3GFS"

RUN_TASK_MAKE_GRID="TRUE"
RUN_TASK_MAKE_OROG="TRUE"
RUN_TASK_MAKE_SFC_CLIMO="TRUE"

RUN="an_experiment"
COMINgfs="/scratch1/NCEPDEV/hwrf/noscrub/hafs-input/COMGFS"  # Path to files from external model (FV3GFS).
STMP="/path/to/temporary/directory/stmp"  # Path to temporary directory STMP.

LAYOUT_X=50
LAYOUT_Y=50
BLOCKSIZE=20

WRTCMP_write_groups="1"
WRTCMP_write_tasks_per_group="${LAYOUT_Y}"

WRTCMP_output_grid="lambert_conformal"
WRTCMP_PARAMS_TMPL_FN=${WRTCMP_PARAMS_TMPL_FN:-"wrtcmp_${WRTCMP_output_grid}"}

WRTCMP_cen_lon="-97.5"
WRTCMP_cen_lat="38.5"
WRTCMP_lon_lwr_left="-122.21414225"
WRTCMP_lat_lwr_left="22.41403305"
#
# The following are used only for the case of WRTCMP_output_grid set to
# "'lambert_conformal'".
#
WRTCMP_stdlat1="${WRTCMP_cen_lat}"
WRTCMP_stdlat2="${WRTCMP_cen_lat}"
WRTCMP_nx="1738"
WRTCMP_ny="974"
WRTCMP_dx="3000.0"
WRTCMP_dy="3000.0"

