#
# TEST PURPOSE/DESCRIPTION:
# ------------------------
#
# This test is to ensure that the workflow running in community mode 
# completes successfully on the RRFS_CONUS_25km grid using the HRRR
# physics suite with ICs derived from the FV3GFS and LBCs derived from 
# the RAP.
#
# Note that this test specifies the file format of the FV3GFS external
# model data (from which to generate ICs) to be "grib2" as opposed to 
# the default value of "nemsio".
#

RUN_ENVIR="community"
PREEXISTING_DIR_METHOD="rename"

PREDEF_GRID_NAME="RRFS_CONUS_25km"
CCPP_PHYS_SUITE="FV3_HRRR"

EXTRN_MDL_NAME_ICS="FV3GFS"
FV3GFS_FILE_FMT_ICS="grib2"
EXTRN_MDL_NAME_LBCS="RAP"
USE_USER_STAGED_EXTRN_FILES="TRUE"
EXTRN_MDL_FILES_LBCS=( '{yy}{jjj}{hh}00{fcst_hr:02d}00' )

DATE_FIRST_CYCL="20200810"
DATE_LAST_CYCL="20200810"
CYCL_HRS=( "00" )

FCST_LEN_HRS="6"
LBC_SPEC_INTVL_HRS="1"
