#
# TEST PURPOSE/DESCRIPTION:
# ------------------------
#
# This test is to ensure that the workflow running in nco mode completes 
# successfully on the RRFS_CONUS_3km grid using the GFS_2017_gfdlmp_regional 
# physics suite with ICs and LBCs derived from the FV3GFS.
#

RUN_ENVIR="nco"
PREEXISTING_DIR_METHOD="rename"

PREDEF_GRID_NAME="RRFS_CONUS_3km"
CCPP_PHYS_SUITE="FV3_GFS_2017_gfdlmp_regional"

EXTRN_MDL_NAME_ICS="FV3GFS"
EXTRN_MDL_NAME_LBCS="FV3GFS"
USE_USER_STAGED_EXTRN_FILES="TRUE"

DATE_FIRST_CYCL="20190901"
DATE_LAST_CYCL="20190901"
CYCL_HRS=( "18" )

FCST_LEN_HRS="6"
LBC_SPEC_INTVL_HRS="3"
