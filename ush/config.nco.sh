MACHINE="hera"
ACCOUNT="an_account"
EXPT_SUBDIR="test_nco"

QUEUE_DEFAULT="batch"
QUEUE_HPSS="service"
QUEUE_FCST="batch"

VERBOSE="TRUE"

RUN_ENVIR="nco"
PREEXISTING_DIR_METHOD="rename"

EMC_GRID_NAME="conus"  # For now, this is maps to PREDEF_GRID_NAME="EMC_CONUS_coarse".
GRID_GEN_METHOD="GFDLgrid"
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

#RUN_TASK_MAKE_GRID="FALSE"
#RUN_TASK_MAKE_OROG="FALSE"
#RUN_TASK_MAKE_SFC_CLIMO="FALSE"

RUN="an_experiment"
COMINgfs="/scratch1/NCEPDEV/hwrf/noscrub/hafs-input/COMGFS"  # Path to files from external model (FV3GFS).
#STMP="/path/to/temporary/directory/stmp"  # Path to temporary directory STMP.
STMP="/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/stmp"  # Path to temporary directory STMP.

