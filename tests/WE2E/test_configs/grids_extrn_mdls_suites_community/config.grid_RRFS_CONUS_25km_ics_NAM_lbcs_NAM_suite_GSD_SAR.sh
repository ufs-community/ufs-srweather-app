#
# TEST PURPOSE/DESCRIPTION:
# ------------------------
#
# This test is to ensure that the workflow running in community mode 
# completes successfully on the RRFS_CONUS_25km grid using the GSD_SAR
# physics suite with ICs and LBCs derived from the NAM.
#

RUN_ENVIR="community"
PREEXISTING_DIR_METHOD="rename"

PREDEF_GRID_NAME="RRFS_CONUS_25km"
CCPP_PHYS_SUITE="FV3_GSD_SAR"

EXTRN_MDL_NAME_ICS="NAM"
EXTRN_MDL_NAME_LBCS="NAM"
USE_USER_STAGED_EXTRN_FILES="TRUE"

DATE_FIRST_CYCL="20150602"
DATE_LAST_CYCL="20150602"
CYCL_HRS=( "12" )

FCST_LEN_HRS="24"
LBC_SPEC_INTVL_HRS="3"
