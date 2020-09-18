RUN_ENVIR="nco"
PREEXISTING_DIR_METHOD="rename"

EMC_GRID_NAME="GSD_SUBCONUS3km"
GRID_GEN_METHOD="ESGgrid"

QUILTING="TRUE"
USE_CCPP="TRUE"
CCPP_PHYS_SUITE="FV3_GSD_SAR"
FCST_LEN_HRS="06"
LBC_SPEC_INTVL_HRS="3"

DATE_FIRST_CYCL="20200801"
DATE_LAST_CYCL="20200801"
CYCL_HRS=( "00" )

EXTRN_MDL_NAME_ICS="HRRRX"
EXTRN_MDL_NAME_LBCS="RAPX"

#
# In NCO mode, the following don't need to be explicitly set to "FALSE"
# in this configuration file because the experiment generation script
# will do this (along with printing out an informational message).
#
#RUN_TASK_MAKE_GRID="FALSE"
#RUN_TASK_MAKE_OROG="FALSE"
#RUN_TASK_MAKE_SFC_CLIMO="FALSE"

#
# In order to prevent simultaneous WE2E (Workflow End-to-End) tests that
# are running in NCO mode and which run the same cycles from interfering
# with each other, for each cycle, each such test must have a distinct
# path to the following two directories:
#
# 1) The directory in which the cycle-dependent model input files, symlinks
#    to cycle-independent input files, and raw (i.e. before post-processing)
#    forecast output files for a given cycle are stored.  The path to this
#    directory is
#
#      $STMP/tmpnwprd/$RUN/$cdate
#
#    where cdate is the starting year (yyyy), month (mm), day (dd) and
#    hour of the cycle in the form yyyymmddhh.
#
# 2) The directory in which the output files from the post-processor (UPP)
#    for a given cycle are stored.  The path to this directory is
#
#      $PTMP/com/$NET/$envir/$RUN.$yyyymmdd/$hh
#
# Here, we make the first directory listed above unique to a WE2E test
# by setting RUN to the name of the current test.  This will also make
# the second directory unique because it also conains the variable RUN
# in its full path, but if this directory -- or set of directories since
# it involves a set of cycles and forecast hours -- already exists from
# a previous run of the same test, then it is much less confusing to the
# user to first move or delete this set of directories during the workflow
# generation step and then start the experiment (whether we move or delete
# depends on the setting of PREEXISTING_DIR_METHOD).  For this purpose,
# it is most convenient to put this set of directories under an umbrella
# directory that has the same name as the experiment.  This can be done
# by setting the variable envir to the name of the current test.  Since
# as mentiond above we will store this name in RUN, below we simply set
# envir to RUN.  Then, for this test, the UPP output will be located in
# the directory
#
#   $PTMP/com/$NET/$RUN/$RUN.$yyyymmdd/$hh
#
# Note that by the time this file is sourced by the experiment generation
# script, the script that launces the WE2E test experiments will have 
# filled in the value of the variable EXPT_SUBDIR above (which contains 
# the name of the experiment).  Thus, below, we can assume that EXPT_SUBDIR
# has a valid value and use it to set RUN and envir.
#
RUN="${EXPT_SUBDIR}"
envir="${EXPT_SUBDIR}"

#
# In NCO mode, the user must manually (e.g. after doing the build step)
# create the symlink "${FIXrrfs}/fix_sar" that points to EMC's FIXsar
# directory on the machine.  For example, on hera, the symlink's target
# needs to be
#
#   /scratch2/NCEPDEV/fv3-cam/emc.campara/fix_fv3cam/fix_sar
#
# The experiment generation script will then set FIXsar to
#
#   FIXsar="${FIXrrfs}/fix_sar/${EMC_GRID_NAME}"
#
# where EMC_GRID_NAME has the value set above.
#

