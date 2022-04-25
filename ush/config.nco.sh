MACHINE="hera"
ACCOUNT="an_account"
EXPT_SUBDIR="test_nco"

COMPILER="intel"
VERBOSE="TRUE"

RUN_ENVIR="nco"
PREEXISTING_DIR_METHOD="rename"

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

WRITE_DOPOST="TRUE"

#
# The following must be modified for different platforms and users.
#
NET="rrfs"
model_ver="v1.0"
RUN="rrfs_test"
COMIN="/scratch1/NCEPDEV/rstprod/com/gfs/prod"     # Path to directory containing files from the external model.
FIXLAM_NCO_BASEDIR="/scratch2/BMC/det/FV3LAM_pregen"            # Path to directory containing the pregenerated grid, orography, and surface climatology "fixed" files to use for the experiment.
STMP="/scratch2/NCEPDEV/fv3-cam/Chan-hoo.Jeon/01_OUT_DATA/stmp"  # Path to directory STMP that mostly contains input files.
PTMP="/scratch2/NCEPDEV/fv3-cam/Chan-hoo.Jeon/01_OUT_DATA/ptmp"  # Path to directory PTMP in which the experiment's output files will be placed.

