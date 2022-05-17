MACHINE="hera"
ACCOUNT="an_account"
EXPT_SUBDIR="test_nco"

COMPILER="intel"
VERBOSE="TRUE"

RUN_ENVIR="nco"
PREEXISTING_DIR_METHOD="rename"

USE_CRON_TO_RELAUNCH="TRUE"
CRON_RELAUNCH_INTVL_MNTS="3"

PREDEF_GRID_NAME="RRFS_CONUS_25km"
QUILTING="TRUE"

CCPP_PHYS_SUITE="FV3_GFS_v16"

FCST_LEN_HRS="6"
LBC_SPEC_INTVL_HRS="3"

DATE_FIRST_CYCL="20220407"
DATE_LAST_CYCL="20220407"
CYCL_HRS=( "00" )

EXTRN_MDL_NAME_ICS="FV3GFS"
EXTRN_MDL_NAME_LBCS="FV3GFS"

FV3GFS_FILE_FMT_ICS="grib2"
FV3GFS_FILE_FMT_LBCS="grib2"

WTIME_RUN_FCST="01:00:00"

WRITE_DOPOST="TRUE"

#
# Output directory: {NET}/{model_ver}/{RUN}.YYYYMMDD/
# Output file name: {NET}.tHHz.[var_name].f###.{POST_OUTPUT_DOMAIN_NAME}.grib2
#
POST_OUTPUT_DOMAIN_NAME="conus_25km"
NET="rrfs"
model_ver="v1.0"
RUN="rrfs_test"
#
# The following must be modified for different platforms and users.
#
COMIN="/scratch1/NCEPDEV/rstprod/com/gfs/prod"  # Path to directory containing files from the external model.
DOMAIN_PREGEN_BASEDIR="/scratch2/BMC/det/UFS_SRW_App/develop/FV3LAM_pregen"  # Path to directory containing the pregenerated grid, orography, and surface climatology "fixed" files to use for the experiment.
STMP="/path/to/stmp/directory"  # Path to directory STMP that mostly contains input files.
PTMP="/path/to/ptmp/directory"  # Path to directory PTMP in which the experiment's output files will be placed.

