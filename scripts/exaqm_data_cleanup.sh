#! /bin/bash

set -xe
##############################################
# Clean up the DATA directory from previous cycle if found
##############################################
[[ $KEEPDATA = "YES" ]] && exit 0

##############################################
# Set variables used in the script
##############################################
CDATE=${PDY}${cyc}
GDATE=$($NDATE -24 $CDATE)
gPDY=$(echo $GDATE | cut -c1-8)
gcyc=$(echo $GDATE | cut -c9-10)

##############################################
# Looking for the following directory for cleanup
#   aqm_forecast_${gcyc}.${gPDY}${gcyc}
##############################################
target_for_delete=${DATAROOT}/aqm_forecast_${gcyc}.${gPDY}${gcyc}
echo "If DATA exist in ${target_for_delete} will be deleted"
[[ -d $target_for_delete ]] && rm -rf $target_for_delete

#####################################################
exit 0
