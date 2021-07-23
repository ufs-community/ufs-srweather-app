# 
# TEST PURPOSE/DESCRIPTION:
# ------------------------
#
# This test checks the capability of the workflow to have the base 
# directories on the system disk in which the external model files are 
# located be set to user-specified values.
#

RUN_ENVIR="community"
PREEXISTING_DIR_METHOD="rename"

PREDEF_GRID_NAME="RRFS_CONUS_25km"
CCPP_PHYS_SUITE="FV3_GFS_v15p2"

EXTRN_MDL_NAME_ICS="FV3GFS"
FV3GFS_FILE_FMT_ICS="grib2"
EXTRN_MDL_NAME_LBCS="FV3GFS"
FV3GFS_FILE_FMT_LBCS="grib2"

DATE_FIRST_CYCL="20210603"
DATE_LAST_CYCL="20210603"
CYCL_HRS=( "06" )

FCST_LEN_HRS="6"
LBC_SPEC_INTVL_HRS="3"

EXTRN_MDL_SYSBASEDIR_ICS="set_to_non_default_location_in_testing_script"
EXTRN_MDL_SYSBASEDIR_LBCS="set_to_non_default_location_in_testing_script"
