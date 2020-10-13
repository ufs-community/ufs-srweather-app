MACHINE="hera"
ACCOUNT="an_account"
EXPT_SUBDIR="test_nco"

QUEUE_DEFAULT="batch"
QUEUE_HPSS="service"
QUEUE_FCST="batch"

VERBOSE="TRUE"

RUN_ENVIR="nco"
PREEXISTING_DIR_METHOD="rename"

EMC_GRID_NAME="conus_c96"  # For now (20200130), this is maps to PREDEF_GRID_NAME="EMC_CONUS_coarse".
GRID_GEN_METHOD="GFDLgrid"

QUILTING="TRUE"
CCPP_PHYS_SUITE="FV3_GFS_2017_gfdlmp"
FCST_LEN_HRS="06"
LBC_SPEC_INTVL_HRS="6"

DATE_FIRST_CYCL="20190901"
DATE_LAST_CYCL="20190901"
CYCL_HRS=( "18" )

EXTRN_MDL_NAME_ICS="FV3GFS"
EXTRN_MDL_NAME_LBCS="FV3GFS"

#
# In NCO mode, the following don't need to be explicitly set to "FALSE" 
# in this configuration file because the experiment generation script
# will do this (along with printing out an informational message).
#
#RUN_TASK_MAKE_GRID="FALSE"
#RUN_TASK_MAKE_OROG="FALSE"
#RUN_TASK_MAKE_SFC_CLIMO="FALSE"

RUN="an_experiment"
COMINgfs="/scratch1/NCEPDEV/hwrf/noscrub/hafs-input/COMGFS"     # Path to directory containing files from the external model (FV3GFS).
STMP="/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/NCO_dirs/stmp"  # Path to directory STMP that mostly contains input files.
PTMP="/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/NCO_dirs/ptmp"  # Path to directory PTMP in which the experiment's output files will be placed.

#
# In NCO mode, the user must manually (e.g. after doing the build step)
# create the symlink "${FIXrrfs}/fix_sar" that points to EMC's FIXLAM
# directory on the machine.  For example, on hera, the symlink's target
# needs to be
#
#   /scratch2/NCEPDEV/fv3-cam/emc.campara/fix_fv3cam/fix_sar
#
# The experiment generation script will then set FIXLAM to 
#
#   FIXLAM="${FIXrrfs}/fix_lam/${EMC_GRID_NAME}"
#
# where EMC_GRID_NAME has the value set above.
#

