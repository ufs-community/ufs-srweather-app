#
# TEST PURPOSE/DESCRIPTION:
# ------------------------
#
# This test is to ensure that the workflow running in nco mode completes 
# successfully on the RRFS_CONUS_25km grid using the HRRR physics suite 
# with ICs derived from the HRRR and LBCs derived from the RAP.
#

RUN_ENVIR="nco"
PREEXISTING_DIR_METHOD="rename"

PREDEF_GRID_NAME="RRFS_CONUS_25km"
CCPP_PHYS_SUITE="FV3_HRRR"

EXTRN_MDL_NAME_ICS="HRRR"
EXTRN_MDL_NAME_LBCS="RAP"
USE_USER_STAGED_EXTRN_FILES="TRUE"

DATE_FIRST_CYCL="20200208"
DATE_LAST_CYCL="20200208"
CYCL_HRS=( "00" )

FCST_LEN_HRS="6"
LBC_SPEC_INTVL_HRS="3"
