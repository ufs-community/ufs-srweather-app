#
# TEST PURPOSE/DESCRIPTION:
# ------------------------
#
# This test is to ensure that the workflow running in community mode 
# completes successfully on the RRFS_AK_13km grid using the GSD_SAR
# physics suite with ICs and LBCs derived from the RAP. 
#

RUN_ENVIR="community"
PREEXISTING_DIR_METHOD="rename"

PREDEF_GRID_NAME="RRFS_AK_13km"
CCPP_PHYS_SUITE="FV3_GSD_SAR"

EXTRN_MDL_NAME_ICS="RAP"
EXTRN_MDL_NAME_LBCS="RAP"
USE_USER_STAGED_EXTRN_FILES="TRUE"

DATE_FIRST_CYCL="20200801"
DATE_LAST_CYCL="20200801"
CYCL_HRS=( "00" )

FCST_LEN_HRS="6"
LBC_SPEC_INTVL_HRS="6"
