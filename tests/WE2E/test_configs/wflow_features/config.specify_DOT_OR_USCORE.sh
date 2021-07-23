# 
# TEST PURPOSE/DESCRIPTION:
# ------------------------
#
# This test checks the capability of the workflow to have the character 
# (DOT_OR_USCORE) in the names of the input grid and orography files 
# that comes after the C-resolution be set to a user-specified value.  
# For example, a grid file may be named
#
#   C403${DOT_OR_USCORE}grid.tile7.halo4.nc
#
# where "C403" is the C-resolution for this specific grid and 
# ${DOT_OR_USCORE} represents the contents of the workflow variable
# DOT_OR_USCORE (bash syntax).  DOT_OR_USCORE is by default set to an 
# underscore, but for consistency with the rest of the separators in the 
# file name (as well as with the character after the C-resolution in the 
# names of the surface climatology files), it should be a "." (a dot).  
# The MAKE_GRID_TN and MAKE_OROG_TN tasks will name the grid and orography 
# files that they create using this character.
#

RUN_ENVIR="community"
PREEXISTING_DIR_METHOD="rename"

PREDEF_GRID_NAME="RRFS_CONUS_25km"
CCPP_PHYS_SUITE="FV3_GFS_2017_gfdlmp"

EXTRN_MDL_NAME_ICS="GSMGFS"
EXTRN_MDL_NAME_LBCS="GSMGFS"
USE_USER_STAGED_EXTRN_FILES="TRUE"

DATE_FIRST_CYCL="20190520"
DATE_LAST_CYCL="20190520"
CYCL_HRS=( "00" )

FCST_LEN_HRS="6"
LBC_SPEC_INTVL_HRS="6"

DOT_OR_USCORE="."
