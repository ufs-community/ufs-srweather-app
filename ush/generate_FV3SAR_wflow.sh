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
# ration file/script (config.sh) in the current directory.  It also cre-
# ates the run and work directories, the INPUT and RESTART subdirecto-
# ries under the run directory, and a variable definitions file/script
# in the run directory.  The latter gets sources by each of the scripts
# that run the various workflow tasks.
#
#-----------------------------------------------------------------------
#
. ./setup.sh
#
#-----------------------------------------------------------------------
#
# Set the names of the template and actual rocoto xml files and their 
# full paths.
#
#-----------------------------------------------------------------------
#
XML_TEMPLATE_FN="FV3SAR_wflow.xml"
XML_TEMPLATE_FP="$TEMPLATE_DIR/$XML_TEMPLATE_FN"
XML_FN="FV3SAR_wflow.xml"
XML_FP="$RUNDIR/$XML_FN"
#
#-----------------------------------------------------------------------
#
# Copy the xml template file to the run directory.
#
#-----------------------------------------------------------------------
#
cp $XML_TEMPLATE_FP $XML_FP
#
#-----------------------------------------------------------------------
#
# Fill in the xml file with parameter values that are either specified
# in the configuration file/script (config.sh) or set in the setup 
# script sourced above.
#
#-----------------------------------------------------------------------
#
REGEXP="(^\s*<!ENTITY\s+SCRIPT_VAR_DEFNS_FP\s*\")(.*)(\">.*)"
sed -i -r -e "s|$REGEXP|\1${SCRIPT_VAR_DEFNS_FP}\3|g" $XML_FP

REGEXP="(^\s*<!ENTITY\s+ACCOUNT\s*\")(.*)(\">.*)"
sed -i -r -e "s|$REGEXP|\1${ACCOUNT}\3|g" $XML_FP

REGEXP="(^\s*<!ENTITY\s+USHDIR\s*\")(.*)(\">.*)"
sed -i -r -e "s|$REGEXP|\1${USHDIR}\3|g" $XML_FP

REGEXP="(^\s*<!ENTITY\s+RUNDIR\s*\")(.*)(\">.*)"
sed -i -r -e "s|$REGEXP|\1${RUNDIR}\3|g" $XML_FP

REGEXP="(^\s*<!ENTITY\s*PROC_RUN_FV3SAR\s*\")(.*)(\">.*)"
sed -i -r -e "s/$REGEXP/\1${NUM_NODES}:ppn=${ncores_per_node}\3/g" $XML_FP
#
#-----------------------------------------------------------------------
#
# Get the full path to the various rocoto commands.
#
#-----------------------------------------------------------------------
#
set +x
module load rocoto
set -x
ROCOTO_EXEC_FP=$( which rocotorun )
ROCOTO_EXEC_DIR=${ROCOTO_EXEC_FP%/rocotorun}
#
#-----------------------------------------------------------------------
#
# For convenience, print out the shell command that needs to be issued
# in order to launch the workflow.  This should be placed in the user's
# crontab so that the workflow is continually resubmitted.
#
#-----------------------------------------------------------------------
#
DB_FN="${XML_FN%.xml}.db"

cmd="cd $RUNDIR && ${ROCOTO_EXEC_DIR}/rocotorun -d ${DB_FN} -w ${XML_FN} -v 10"
echo
echo "To run the workflow, use the following command:"
echo
echo "$cmd"
echo
echo "This command can be added in the user's crontab for automatic \
resubmission of the workflow."

cmd="cd $RUNDIR && ${ROCOTO_EXEC_DIR}/rocotostat -d ${DB_FN} -w ${XML_FN} -v 10"
echo
echo "To check on the status of the workflow, use the following command:"
echo
echo "$cmd"



