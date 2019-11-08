#
#-----------------------------------------------------------------------
#
# This is the local (i.e. user-specific) experiment/workflow configura-
# tion file.  It is not tracked by the git repository.
#
#-----------------------------------------------------------------------
#
RUN_ENVIR="nco"
RUN_ENVIR="community"

MACHINE="HERA"
ACCOUNT="gsd-fv3"
QUEUE_DEFAULT="batch"
QUEUE_HPSS="service"
QUEUE_FCST="batch"

USE_CRON_TO_RELAUNCH="TRUE"
CRON_RELAUNCH_INTVL_MNTS="03"

VERBOSE="TRUE"

# Can specify EXPT_BASEDIR if you want.  If not specified, will default
# to "$HOMErrfs/../expt_dirs".
#EXPT_BASEDIR="/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/test_latest_20190927/expt_dirs"

PREDEF_GRID_NAME="GSD_HRRR25km"
#PREDEF_GRID_NAME="GSD_HRRR13km"
#PREDEF_GRID_NAME="GSD_HRRR3km"
#PREDEF_GRID_NAME="GSD_HAFSV0.A"
#PREDEF_GRID_NAME="EMC_HI3km"
#
GRID_GEN_METHOD="JPgrid"
#
PREEXISTING_DIR_METHOD="delete"
QUILTING="TRUE"
#
USE_CCPP="TRUE"
CCPP_PHYS_SUITE="GFS"
CCPP_PHYS_SUITE="GSD"

FCST_LEN_HRS="06"
LBC_UPDATE_INTVL_HRS="6"
#LBC_UPDATE_INTVL_HRS="12"
#LBC_UPDATE_INTVL_HRS="1"


if [ "${RUN_ENVIR}" = "nco" ]; then

  EXPT_SUBDIR="test_NCO"

  RUN="an_experiment"
  COMINgfs="/scratch1/NCEPDEV/hwrf/noscrub/hafs-input/COMGFS"

#  STMP="/scratch2/NCEPDEV/stmp3/${USER}"
#  PTMP="/scratch2/NCEPDEV/stmp3/${USER}"
  
  DATE_FIRST_CYCL="20190422"
  DATE_LAST_CYCL="20190422"
#  DATE_FIRST_CYCL="20181216"
#  DATE_LAST_CYCL="20181216"
  CYCL_HRS=( "00" )

  EXTRN_MDL_NAME_ICS="FV3GFS"
  EXTRN_MDL_NAME_LBCS="FV3GFS"

else

  EXPT_SUBDIR="test_community"
  EXPT_SUBDIR="yunheng_GSMGFS_20190520_GSDphys"

#  DATE_FIRST_CYCL="20190701"
#  DATE_LAST_CYCL="20190701"
  DATE_FIRST_CYCL="20190520"
  DATE_LAST_CYCL="20190520"
#  CYCL_HRS=( "00" "12" )
  CYCL_HRS=( "00" )
  
  EXTRN_MDL_NAME_ICS="GSMGFS"
#  EXTRN_MDL_NAME_ICS="FV3GFS"
#  EXTRN_MDL_NAME_ICS="HRRRX"

  EXTRN_MDL_NAME_LBCS="GSMGFS"
#  EXTRN_MDL_NAME_LBCS="FV3GFS"
#  EXTRN_MDL_NAME_LBCS="RAPX"

  RUN_TASK_MAKE_GRID="TRUE"
#  RUN_TASK_MAKE_GRID="FALSE"
  GRID_DIR="/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/pregen_grid/GSD_HRRR25km"

  RUN_TASK_MAKE_OROG="TRUE"
#  RUN_TASK_MAKE_OROG="FALSE"
  OROG_DIR="/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/pregen_orog/GSD_HRRR25km"

  RUN_TASK_MAKE_SFC_CLIMO="TRUE"
#  RUN_TASK_MAKE_SFC_CLIMO="FALSE"
  SFC_CLIMO_DIR="/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/pregen_sfc_climo/GSD_HRRR25km"

fi

