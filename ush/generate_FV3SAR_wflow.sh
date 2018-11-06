#!/bin/bash
#
#-----------------------------------------------------------------------
#
# Change shell behavior with "set" with these flags:
#
# -a 
# This will cause the script to automatically export all variables and 
# functions which are modified or created to the environments of subse-
# quent commands.
#
# -e 
# This will cause the script to exit as soon as any line in the script 
# fails (with some exceptions; see manual).  Apparently, it is a bad 
# idea to use "set -e".  See here:
#   http://mywiki.wooledge.org/BashFAQ/105
#
# -u 
# This will cause the script to exit if an undefined variable is encoun-
# tered.
#
# -x
# This will cause all executed commands in the script to be printed to 
# the terminal (used for debugging).
#
#-----------------------------------------------------------------------
#
#set -eux
set -ux
#
#-----------------------------------------------------------------------
#
# Source the setup script.  Note that this in turn sources the configu-
# ration script config.sh file in the current directory.
#
#-----------------------------------------------------------------------
#
. ./setup.sh
#
#-----------------------------------------------------------------------
#
# Set the names of the template and actual rocoto xml files.
#
#-----------------------------------------------------------------------
#
XML_TEMPLATE="$TEMPLATE_DIR/FV3SAR_wflow.xml"
XML_FILENAME="$RUNDIR/FV3SAR_wflow.xml"
#
#-----------------------------------------------------------------------
#
# Copy the xml template file to the run directory.
#
#-----------------------------------------------------------------------
#
cp $XML_TEMPLATE $XML_FILENAME
#
#-----------------------------------------------------------------------
#
# Fill in the xml file with parameter values specified in the config.sh
# file and those calculated by the setup script sourced above.
#
# First, fill in values of those parameters needed only by the workflow.
#
#-----------------------------------------------------------------------
#
REGEXP="(^\s*<!ENTITY\s+SCRIPT_VAR_DEFNS_FP\s*\")(.*)(\">.*)"
sed -i -r -e "s|$REGEXP|\1${SCRIPT_VAR_DEFNS_FP}\3|g" $XML_FILENAME

REGEXP="(^\s*<!ENTITY\s+ACCOUNT\s*\")(.*)(\">.*)"
sed -i -r -e "s|$REGEXP|\1${ACCOUNT}\3|g" $XML_FILENAME

REGEXP="(^\s*<!ENTITY\s+USHDIR\s*\")(.*)(\">.*)"
sed -i -r -e "s|$REGEXP|\1${USHDIR}\3|g" $XML_FILENAME

REGEXP="(^\s*<!ENTITY\s+RUNDIR\s*\")(.*)(\">.*)"
sed -i -r -e "s|$REGEXP|\1${RUNDIR}\3|g" $XML_FILENAME

REGEXP="(^\s*<!ENTITY\s*PROC_RUN_FV3SAR\s*\")(.*)(\">.*)"
sed -i -r -e "s/$REGEXP/\1${NUM_NODES}:ppn=${ncores_per_node}\3/g" $XML_FILENAME
#
#-----------------------------------------------------------------------
#
# Next, fill in values of those parameters needed only by the scripts 
# for the various tasks.
#
#-----------------------------------------------------------------------
#
if [ 0 = 1 ]; then

REGEXP="(^\s*<!ENTITY\s+MACHINE\s*\")(.*)(\">.*)"
sed -i -r -e "s|$REGEXP|\1${machine}\3|g" $XML_FILENAME

REGEXP="(^\s*<!ENTITY\s+USER\s*\")(.*)(\">.*)"
sed -i -r -e "s|$REGEXP|\1${USER}\3|g" $XML_FILENAME

REGEXP="(^\s*<!ENTITY\s+BASEDIR\s*\")(.*)(\">.*)"
sed -i -r -e "s|$REGEXP|\1${BASEDIR}\3|g" $XML_FILENAME

REGEXP="(^\s*<!ENTITY\s+FV3SAR_DIR\s*\")(.*)(\">.*)"
sed -i -r -e "s|$REGEXP|\1${FV3SAR_DIR}\3|g" $XML_FILENAME

REGEXP="(^\s*<!ENTITY\s+TEMPLATE_DIR\s*\")(.*)(\">.*)"
sed -i -r -e "s|$REGEXP|\1${TEMPLATE_DIR}\3|g" $XML_FILENAME

REGEXP="(^\s*<!ENTITY\s+TMPDIR\s*\")(.*)(\">.*)"
sed -i -r -e "s|$REGEXP|\1${TMPDIR}\3|g" $XML_FILENAME

REGEXP="(^\s*<!ENTITY\s+GTYPE\s*\")(.*)(\">.*)"
sed -i -r -e "s|$REGEXP|\1${gtype}\3|g" $XML_FILENAME

REGEXP="(^\s*<!ENTITY\s+RES\s*\")(.*)(\">.*)"
sed -i -r -e "s|$REGEXP|\1${RES}\3|g" $XML_FILENAME

REGEXP="(^\s*<!ENTITY\s+FCST_LEN_HRS\s*\")(.*)(\">.*)"
sed -i -r -e "s|$REGEXP|\1${fcst_len_hrs}\3|g" $XML_FILENAME

REGEXP="(^\s*<!ENTITY\s+BC_UPDATE_INTVL_HRS\s*\")(.*)(\">.*)"
sed -i -r -e "s|$REGEXP|\1${BC_update_intvl_hrs}\3|g" $XML_FILENAME

REGEXP="(^\s*<!ENTITY\s+STRETCH_FAC\s*\")(.*)(\">.*)"
sed -i -r -e "s|$REGEXP|\1${stretch_fac}\3|g" $XML_FILENAME

REGEXP="(^\s*<!ENTITY\s+LON_CTR_T6\s*\")(.*)(\">.*)"
sed -i -r -e "s|$REGEXP|\1${lon_ctr_T6}\3|g" $XML_FILENAME

REGEXP="(^\s*<!ENTITY\s+LAT_CTR_T6\s*\")(.*)(\">.*)"
sed -i -r -e "s|$REGEXP|\1${lat_ctr_T6}\3|g" $XML_FILENAME

REGEXP="(^\s*<!ENTITY\s+REFINE_RATIO\s*\")(.*)(\">.*)"
sed -i -r -e "s|$REGEXP|\1${refine_ratio}\3|g" $XML_FILENAME

REGEXP="(^\s*<!ENTITY\s+ISTART_RGNL_T6\s*\")(.*)(\">.*)"
sed -i -r -e "s|$REGEXP|\1${istart_rgnl_T6}\3|g" $XML_FILENAME

REGEXP="(^\s*<!ENTITY\s+IEND_RGNL_T6\s*\")(.*)(\">.*)"
sed -i -r -e "s|$REGEXP|\1${iend_rgnl_T6}\3|g" $XML_FILENAME

REGEXP="(^\s*<!ENTITY\s+JSTART_RGNL_T6\s*\")(.*)(\">.*)"
sed -i -r -e "s|$REGEXP|\1${jstart_rgnl_T6}\3|g" $XML_FILENAME

REGEXP="(^\s*<!ENTITY\s+JEND_RGNL_T6\s*\")(.*)(\">.*)"
sed -i -r -e "s|$REGEXP|\1${jend_rgnl_T6}\3|g" $XML_FILENAME

REGEXP="(^\s*<!ENTITY\s+RUN_TITLE\s*\")(.*)(\">.*)"
sed -i -r -e "s|$REGEXP|\1${run_title}\3|g" $XML_FILENAME

REGEXP="(^\s*<!ENTITY\s+QUILTING\s*\")(.*)(\">.*)"
sed -i -r -e "s|$REGEXP|\1${quilting}\3|g" $XML_FILENAME

REGEXP="(^\s*<!ENTITY\s+PRINT_ESMF\s*\")(.*)(\">.*)"
sed -i -r -e "s|$REGEXP|\1${print_esmf}\3|g" $XML_FILENAME

REGEXP="(^\s*<!ENTITY\s+PREDEF_RGNL_DOMAIN\s*\")(.*)(\">.*)"
sed -i -r -e "s|$REGEXP|\1${predef_rgnl_domain}\3|g" $XML_FILENAME

REGEXP="(^\s*<!ENTITY\s+LAYOUT_X\s*\")(.*)(\">.*)"
sed -i -r -e "s|$REGEXP|\1${layout_x}\3|g" $XML_FILENAME

REGEXP="(^\s*<!ENTITY\s+LAYOUT_Y\s*\")(.*)(\">.*)"
sed -i -r -e "s|$REGEXP|\1${layout_y}\3|g" $XML_FILENAME

REGEXP="(^\s*<!ENTITY\s+NCORES_PER_NODE\s*\")(.*)(\">.*)"
sed -i -r -e "s|$REGEXP|\1${ncores_per_node}\3|g" $XML_FILENAME

REGEXP="(^\s*<!ENTITY\s+WRITE_GROUPS\s*\")(.*)(\">.*)"
sed -i -r -e "s|$REGEXP|\1${write_groups}\3|g" $XML_FILENAME

REGEXP="(^\s*<!ENTITY\s+WRITE_TASKS_PER_GROUP\s*\")(.*)(\">.*)"
sed -i -r -e "s|$REGEXP|\1${write_tasks_per_group}\3|g" $XML_FILENAME

fi
#
#-----------------------------------------------------------------------
#
# Set the location of the rocoto executable.
#
#-----------------------------------------------------------------------
#
set +x
module load rocoto
set -x
ROCOTO_EXEC_DIR=$( which rocotorun )
#
#-----------------------------------------------------------------------
#
# For convenience, print out the shell command that needs to be issued
# in order to launch the workflow.  This should be placed in the user's
# crontab so that the workflow is continually resubmitted.
#
#-----------------------------------------------------------------------
#
DB_FILENAME="${XML_FILENAME%.xml}.db"

if [ -f "$XML_FILENAME" ]; then

  cmd="${ROCOTO_EXEC_DIR}/rocotorun -d ${DB_FILENAME} -w ${XML_FILENAME} -v 10"
  echo
  echo "To run the workflow, use the following command:"
  echo
  echo "$cmd"
  echo
  echo "This can also be placed in a crontab for automatic resubmission of the workflow."

  cmd="${ROCOTO_EXEC_DIR}/rocotostat -d ${DB_FILENAME} -w ${XML_FILENAME} -v 10"
  echo
  echo "To check on the status of the workflow, use the following command:"
  echo
  echo "$cmd"

else

  echo
  echo "Rocoto XML file was not created.  It should be at:"
  echo
  echo "  $XML_FILENAME"
  echo
  echo "Exiting script."
  exit 1

fi



