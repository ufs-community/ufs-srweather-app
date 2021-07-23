#
# TEST PURPOSE/DESCRIPTION:
# ------------------------
#
# This test is to ensure that the workflow running in community mode 
# completes successfully on the RRFS_CONUS_25km grid using the GFS_v16
# physics suite with ICs and LBCs derived from the GSMGFS.
#

RUN_ENVIR="community"
PREEXISTING_DIR_METHOD="rename"

PREDEF_GRID_NAME="RRFS_CONUS_25km"
CCPP_PHYS_SUITE="FV3_GFS_v16"

EXTRN_MDL_NAME_ICS="GSMGFS"
EXTRN_MDL_NAME_LBCS="GSMGFS"
USE_USER_STAGED_EXTRN_FILES="TRUE"

DATE_FIRST_CYCL="20190520"
DATE_LAST_CYCL="20190520"
CYCL_HRS=( "00" )

FCST_LEN_HRS="6"
LBC_SPEC_INTVL_HRS="6"
