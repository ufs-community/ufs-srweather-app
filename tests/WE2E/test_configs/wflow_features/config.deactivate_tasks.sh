#
# TEST PURPOSE/DESCRIPTION:
# ------------------------
#
# This test ensures that the various workflow tasks can be deactivated,
# i.e. removed from the Rocoto XML.  Note that we leave the MAKE_GRID_TN, 
# MAKE_OROG_TN, and MAKE_SFC_CLIMO_TN activated because there is a 
# separate test for turning those off.
#

RUN_ENVIR="community"
PREEXISTING_DIR_METHOD="rename"

PREDEF_GRID_NAME="RRFS_CONUS_25km"
CCPP_PHYS_SUITE="FV3_GFS_v15p2"

DATE_FIRST_CYCL="20190615"
DATE_LAST_CYCL="20190615"
CYCL_HRS=( "00" )

RUN_TASK_GET_EXTRN_ICS="FALSE"
RUN_TASK_GET_EXTRN_LBCS="FALSE"
RUN_TASK_MAKE_ICS="FALSE"
RUN_TASK_MAKE_LBCS="FALSE"
RUN_TASK_RUN_FCST="FALSE"
RUN_TASK_RUN_POST="FALSE"
