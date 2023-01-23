#!/bin/bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. $USHdir/source_util_funcs.sh
source_config_for_task "task_run_archive" ${GLOBAL_VAR_DEFNS_FP}
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

This is the ex-script for the task that runs the post-processor (UPP) on
the output files corresponding to a specified forecast hour.
========================================================================"
#
#-----------------------------------------------------------------------
#
# Get date and archive forecast results to specified directory.
#
#-----------------------------------------------------------------------
#
currentime=$(echo "${CDATE}" | sed 's/\([[:digit:]]\{2\}\)$/ \1/')
day=$(date +%d -d "${currentime} 24 hours ago")
month=$(date +%m -d "${currentime} 24 hours ago")
year=$(date +%Y -d "${currentime} 24 hours ago")


cd ${COMOUT_BASEDIR}
declare -a XX=$(ls -d ${RUN}.$year$month$day/* | sort -r)
runcount=${#XX[*]}
if [[ $runcount -gt 0 ]];then

  hsi mkdir -p $ARCHIVEDIR/$year/$month/$day

  for onerun in ${XX[*]}; do

    echo "Archive files from ${onerun}"
    hour=${onerun##*/}

    if [[ -e ${COMOUT_BASEDIR}/${onerun}/nclprd/full/files.zip ]];then
      echo "Graphics..."
      mkdir -p $COMOUT_BASEDIR/stage/$year$month$day$hour/nclprd
      cp -rsv ${COMOUT_BASEDIR}/${onerun}/nclprd/* $COMOUT_BASEDIR/stage/$year$month$day$hour/nclprd
    fi

    YY=$(ls -d ${COMOUT_BASEDIR}/${onerun}/*bg*tm*)
    postcount=${#YY[*]}
    echo $postcount
    if [[ $postcount -gt 0 ]];then
      echo "GRIB-2..."
      mkdir -p $COMOUT_BASEDIR/stage/$year$month$day$hour/postprd
      cp -rsv ${COMOUT_BASEDIR}/${onerun}/*bg*tm* $COMOUT_BASEDIR/stage/$year$month$day$hour/postprd 
    fi

    if [[ -e ${COMOUT_BASEDIR}/stage/$year$month$day$hour ]];then
      cd ${COMOUT_BASEDIR}/stage
      htar -chvf $ARCHIVEDIR/$year/$month/$day/post_$year$month$day$hour.tar $year$month$day$hour
      rm -rf $year$month$day$hour
    fi

  done
fi

rmdir $COMOUT_BASEDIR/stage

cd ${NWGES_BASEDIR}
declare -a YY=$(ls -d ${year}${month}${day}?? | sort -r)
runcount=${#YY[*]}
if [[ $runcount -gt 0 ]];then

  hsi mkdir -p $ARCHIVEDIR/$year/$month/$day

  for onerun in ${YY[*]};do
     hour=$(echo $onerun | cut -c9-10 )
     htar -chvf $ARCHIVEDIR/$year/$month/$day/nwges_${onerun} ${onerun}
  done

fi


#
#-----------------------------------------------------------------------
#
# Print message indicating successful completion of script.
#
#-----------------------------------------------------------------------
#
dateval=`date`
print_info_msg "
========================================================================
Completed archive at \"${dateval}\" successfully.

Exiting script:  \"${scrfunc_fn}\"
In directory:    \"${scrfunc_dir}\"
========================================================================"
#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script/func-
# tion.
#
#-----------------------------------------------------------------------
#
{ restore_shell_opts; } > /dev/null 2>&1
