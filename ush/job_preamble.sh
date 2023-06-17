#!/bin/bash

#
#-----------------------------------------------------------------------
#
# If requested to share data with next task, override jobid
# When an argument exists with this script, a shared job id will be created.
#
#-----------------------------------------------------------------------
#
export share_pid=${WORKFLOW_ID}_${PDY}${cyc}
if [ $# -ne 0 ]; then
    export pid=$share_pid
    export jobid=${job}.${pid}
fi

#
#-----------------------------------------------------------------------
#
# Set NCO standard environment variables
#
#-----------------------------------------------------------------------
#
export envir="${envir:-${envir_default}}"
export NET="${NET:-${NET_default}}"
export RUN="${RUN:-${RUN_default}}"
export model_ver="${model_ver:-${model_ver_default}}"
export COMROOT="${COMROOT:-${COMROOT_default}}"
export DATAROOT="${DATAROOT:-${DATAROOT_default}}"
export DCOMROOT="${DCOMROOT:-${DCOMROOT_default}}"
export LOGBASEDIR="${LOGBASEDIR:-${LOGBASEDIR_default}}"

export DBNROOT="${DBNROOT:-${DBNROOT_default}}"
export SENDECF="${SENDECF:-${SENDECF_default}}"
export SENDDBN="${SENDDBN:-${SENDDBN_default}}"
export SENDDBN_NTC="${SENDDBN_NTC:-${SENDDBN_NTC_default}}"
export SENDCOM="${SENDCOM:-${SENDCOM_default}}"
export SENDWEB="${SENDWEB:-${SENDWEB_default}}"
export KEEPDATA="${KEEPDATA:-${KEEPDATA_default}}"
export MAILTO="${MAILTO:-${MAILTO_default}}"
export MAILCC="${MAILCC:-${MAILCC_default}}"

if [ "${RUN_ENVIR}" = "nco" ]; then
  if [ "${MACHINE}" = "WCOSS2" ]; then
    [[ "$WORKFLOW_MANAGER" = "rocoto" ]] && export COMROOT=$COMROOT
    export COMIN="${COMIN:-$(compath.py -o ${NET}/${model_ver}/${RUN}.${PDY}/${cyc})}"
    export COMOUT="${COMOUT:-$(compath.py -o ${NET}/${model_ver}/${RUN}.${PDY}/${cyc})}"
    export COMINm1="${COMINm1:-$(compath.py -o ${NET}/${model_ver}/${RUN}.${PDYm1})}"
    export COMINgfs="${COMINgfs:-$(compath.py ${envir}/gfs/${gfs_ver})}"
    export COMINgefs="${COMINgefs:-$(compath.py ${envir}/gefs/${gefs_ver})}"
  else
    export COMIN="${COMIN_BASEDIR}/${RUN}.${PDY}/${cyc}"
    export COMOUT="${COMOUT_BASEDIR}/${RUN}.${PDY}/${cyc}"
    export COMINm1="${COMIN_BASEDIR}/${RUN}.${PDYm1}"
  fi
else
  export COMIN="${COMIN_BASEDIR}/${PDY}${cyc}"
  export COMOUT="${COMOUT_BASEDIR}/${PDY}${cyc}"
  export COMINm1="${COMIN_BASEDIR}/${RUN}.${PDYm1}"
fi
export COMOUTwmo="${COMOUTwmo:-${COMOUT}/wmo}"

export DCOMINbio="${DCOMINbio:-${DCOMINbio_default}}"
export DCOMINdust="${DCOMINdust:-${DCOMINdust_default}}"
export DCOMINcanopy="${DCOMINcanopy:-${DCOMINcanopy_default}}"
export DCOMINfire="${DCOMINfire:-${DCOMINfire_default}}"
export DCOMINchem_lbcs="${DCOMINchem_lbcs:-${DCOMINchem_lbcs_default}}"
export DCOMINgefs="${DCOMINgefs:-${DCOMINgefs_default}}"
export DCOMINpt_src="${DCOMINpt_src:-${DCOMINpt_src_default}}"
export DCOMINairnow="${DCOMINairnow:-${DCOMINairnow_default}}"

#
#-----------------------------------------------------------------------
#
# Change YES/NO (NCO standards; job card) to TRUE/FALSE (workflow standards)
# for NCO environment variables
#
#-----------------------------------------------------------------------
#
export KEEPDATA=$(boolify "${KEEPDATA}")
export SENDCOM=$(boolify "${SENDCOM}")
export SENDDBN=$(boolify "${SENDDBN}")
export SENDDBN_NTC=$(boolify "${SENDDBN_NTC}")
export SENDECF=$(boolify "${SENDECF}")
export SENDWEB=$(boolify "${SENDWEB}")

#
#-----------------------------------------------------------------------
#
# Set cycle and ensemble member names in file/diectory names
#
#-----------------------------------------------------------------------
#
if [ $subcyc -eq 0 ]; then
    export cycle="t${cyc}z"
else
    export cycle="t${cyc}${subcyc}z"
fi
if [ "${RUN_ENVIR}" = "nco" ] && [ "${DO_ENSEMBLE}" = "TRUE" ] && [ ! -z $ENSMEM_INDX ]; then
    export dot_ensmem=".mem${ENSMEM_INDX}"
else
    export dot_ensmem=
fi
#
#-----------------------------------------------------------------------
#
# Create a temp working directory (DATA) and cd into it.
#
#-----------------------------------------------------------------------
#
export DATA=
if [ "${RUN_ENVIR}" = "nco" ]; then
    export DATA=${DATAROOT}/${jobid}
    mkdir_vrfy -p $DATA
    cd $DATA
fi
#
#-----------------------------------------------------------------------
#
# Run setpdy to initialize PDYm and PDYp variables
#
#-----------------------------------------------------------------------
#
if [ "${RUN_ENVIR}" = "nco" ]; then
    if [ ! -z $(command -v setpdy.sh) ]; then
        COMROOT=$COMROOT setpdy.sh
        . ./PDY
    fi
else
    export PDYm1=$( $DATE_UTIL --date "${PDY} -1 day" "+%Y%m%d" )
    export PDYm2=$( $DATE_UTIL --date "${PDY} -2 day" "+%Y%m%d" )
    export PDYm3=$( $DATE_UTIL --date "${PDY} -3 day" "+%Y%m%d" )
fi
export CDATE=${PDY}${cyc}
#
#-----------------------------------------------------------------------
#
# Set pgmout and pgmerr files
#
#-----------------------------------------------------------------------
#
if [ "${RUN_ENVIR}" = "nco" ]; then
    export pgmout="${DATA}/OUTPUT.$$"
    export pgmerr="${DATA}/errfile"
    export REDIRECT_OUT_ERR=">>${pgmout} 2>${pgmerr}"
    export pgmout_lines=1
    export pgmerr_lines=1

    function PREP_STEP() {
        export pgm="$(basename ${0})"
        if [ ! -z $(command -v prep_step) ]; then
            . prep_step
        else
            # Append header
            if [ -n "$pgm" ] && [ -n "$pgmout" ]; then
              echo "$pgm" >> $pgmout
            fi
            # Remove error file
            if [ -f $pgmerr ]; then
              rm $pgmerr
            fi
        fi
    }
    function POST_STEP() {
        if [ -f $pgmout ]; then
            tail -n +${pgmout_lines} $pgmout
            pgmout_line=$( wc -l $pgmout )
            pgmout_lines=$((pgmout_lines + 1))
        fi
        if [ -f $pgmerr ]; then
            tail -n +${pgmerr_lines} $pgmerr
            pgmerr_line=$( wc -l $pgmerr )
            pgmerr_lines=$((pgmerr_lines + 1))
        fi
    }
else
    export pgmout=
    export pgmerr=
    export REDIRECT_OUT_ERR=
    function PREP_STEP() {
        :
    }
    function POST_STEP() {
        :
    }
fi
export -f PREP_STEP
export -f POST_STEP

#
#-----------------------------------------------------------------------
#
# Create symlinks to log files in the experiment directory. Makes viewing
# log files easier in NCO mode, as well as make CIs work
#
#-----------------------------------------------------------------------
#
if [ "${RUN_ENVIR}" = "nco" ] && [ "${WORKFLOW_MANAGER}" != "ecflow" ]; then
    __EXPTLOG=${EXPTDIR}/log
    mkdir_vrfy -p ${__EXPTLOG}
    for i in ${LOGDIR}/*.${WORKFLOW_ID}.log; do
        __LOGB=$(basename $i .${WORKFLOW_ID}.log)
        ln_vrfy -sf $i ${__EXPTLOG}/${__LOGB}.log
    done
fi
#
#-----------------------------------------------------------------------
#
# Add a postamble function
# When an argument exists, the working directory will not be removed
# even with KEEPDATA: false.
# Only when an argument is TRUE, the existing working directories in 
# the tmp directory will be removed.
#
#-----------------------------------------------------------------------
#
function job_postamble() {

    # Remove temp directory
    if [ "${RUN_ENVIR}" = "nco" ] && [ "${KEEPDATA}" = "FALSE" ]; then
	cd ${DATAROOT}
	# Remove current data directory
	if [ $# -eq 0 ]; then
	    rm -rf $DATA
	# Remove all current and shared data directories
	elif [ "$1" = "TRUE" ]; then
            rm -rf $DATA
	    share_pid="${WORKFLOW_ID}_${PDY}${cyc}"
            rm -rf *${share_pid}
	fi
    fi

    # Print exit message
    print_info_msg "
========================================================================
Exiting script:  \"${scrfunc_fn}\"
In directory:    \"${scrfunc_dir}\"
========================================================================"
}


