#! /bin/bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. $USHdir/source_util_funcs.sh
. ${GLOBAL_VAR_DEFNS_FP}
#
#-----------------------------------------------------------------------
#
# Save current shell options (in a global array).  Then set new options
# for this script/function.
#
#-----------------------------------------------------------------------
#
{ save_shell_opts; . $USHdir/preamble.sh; } > /dev/null 2>&1
#
#-----------------------------------------------------------------------
#
# Get the full path to the file in which this script/function is located
# (scrfunc_fp), the name of that file (scrfunc_fn), and the directory in
# which the file is located (scrfunc_dir).
#
#-----------------------------------------------------------------------
#
scrfunc_fp=$( $READLINK -f "${BASH_SOURCE[0]}" )
scrfunc_fn=$( basename "${scrfunc_fp}" )
scrfunc_dir=$( dirname "${scrfunc_fp}" )
#
#-----------------------------------------------------------------------
#
# Print message indicating entry into script.
#
#-----------------------------------------------------------------------
#
print_info_msg "
========================================================================
Entering script:  \"${scrfunc_fn}\"
In directory:     \"${scrfunc_dir}\"

This is the ex-script for DATA-CLEANUP.
========================================================================"

# Clean up the DATA directory from previous cycle if found
[[ $KEEPDATA = "TRUE" ]] && exit 0

# Set variables used in the script
CDATE=${PDY}${cyc}
GDATE=$($NDATE -24 $CDATE)
gPDY=$(echo $GDATE | cut -c1-8)
gcyc=$(echo $GDATE | cut -c9-10)

##############################################
# Looking for the following directory for cleanup
#   forecast.${gPDY}${gcyc}
#   get_extrn_ics.${gPDY}${gcyc}
#   get_extrn_lbcs.${gPDY}${gcyc}
#   nexus_gfs_sfc.${gPDY}${gcyc}
##############################################
target_for_delete=${DATAROOT}/forecast.${gPDY}${gcyc}
echo "Remove DATA from ${target_for_delete}"
[[ -d $target_for_delete ]] && rm -rf $target_for_delete

target_for_delete=${DATAROOT}/get_extrn_ics.${gPDY}${gcyc}
echo "Remove DATA from ${target_for_delete}"
[[ -d $target_for_delete ]] && rm -rf $target_for_delete

target_for_delete=${DATAROOT}/get_extrn_lbcs.${gPDY}${gcyc}
echo "Remove DATA from ${target_for_delete}"
[[ -d $target_for_delete ]] && rm -rf $target_for_delete

target_for_delete=${DATAROOT}/nexus_gfs_sfc.${gPDY}${gcyc}
echo "Remove DATA from ${target_for_delete}"
[[ -d $target_for_delete ]] && rm -rf $target_for_delete

exit 0
#####################################################

