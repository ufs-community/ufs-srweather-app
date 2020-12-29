MACHINE="hera"
ACCOUNT="an_account"
EXPT_SUBDIR="test_nco"

VERBOSE="TRUE"

RUN_ENVIR="nco"
PREEXISTING_DIR_METHOD="rename"

PREDEF_GRID_NAME="CONUS_25km_GFDLgrid"
QUILTING="TRUE"

CCPP_PHYS_SUITE="FV3_GFS_v15p2"

FCST_LEN_HRS="06"
LBC_SPEC_INTVL_HRS="6"

DATE_FIRST_CYCL="20190901"
DATE_LAST_CYCL="20190901"
CYCL_HRS=( "18" )

EXTRN_MDL_NAME_ICS="FV3GFS"
EXTRN_MDL_NAME_LBCS="FV3GFS"

#
# The following must be modified for different platforms and users.
#
RUN="an_experiment"
COMINgfs="/scratch1/NCEPDEV/hwrf/noscrub/hafs-input/COMGFS"     # Path to directory containing files from the external model (FV3GFS).
FIXLAM_NCO_BASEDIR="/scratch2/BMC/det/FV3LAM_pregen"            # Path to directory containing the pregenerated grid, orography, and surface climatology "fixed" files to use for the experiment.
STMP="/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/NCO_dirs/stmp"  # Path to directory STMP that mostly contains input files.
PTMP="/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/NCO_dirs/ptmp"  # Path to directory PTMP in which the experiment's output files will be placed.

