#!/bin/bash

#
#-----------------------------------------------------------------------
# If requested to share data with next task, override jobid
#-----------------------------------------------------------------------
#
if [ "${WORKFLOW_MANAGER}" = "ecflow" ]; then
    export share_pid=${share_pid:-${PDY}${cyc}}
else
    export share_pid=${share_pid:-${WORKFLOW_ID}_${PDY}${cyc}}
fi

if [ $# -ne 0 ]; then
    export pid=$share_pid
    export jobid=${job}.${pid}
fi
#
#-----------------------------------------------------------------------
# Set NCO standard environment variables
#-----------------------------------------------------------------------
#
export envir="${envir:-${envir_dfv}}"
export NET="${NET:-${NET_dfv}}"
export RUN="${RUN:-${RUN_dfv}}"
export model_ver="${model_ver:-${model_ver_dfv}}"
export COMROOT="${COMROOT:-${COMROOT_dfv}}"
export DATAROOT="${DATAROOT:-${DATAROOT_dfv}}"
export LOGBASEDIR="${LOGBASEDIR:-${LOGBASEDIR_dfv}}"

export KEEPDATA="${KEEPDATA:-${KEEPDATA_dfv}}"
export MAILTO="${MAILTO:-${MAILTO_dfv}}"
export MAILCC="${MAILCC:-${MAILCC_dfv}}"

#-----------------------------------------------------------------------
# Set cycle and ensemble member names in file/diectory names
#-----------------------------------------------------------------------
if [ $subcyc -eq 0 ]; then
    export cycle="t${cyc}z"
else
    export cycle="t${cyc}${subcyc}z"
fi

export dot_ensmem=

export CDATE=${PDY}${cyc}
#
#-----------------------------------------------------------------------
# Set pgmout and pgmerr files
#-----------------------------------------------------------------------
export pgmout="${DATA}/OUTPUT.$$"
export pgmerr="${DATA}/errfile"
export REDIRECT_OUT_ERR=">>${pgmout} 2>${pgmerr}"
export pgmout_lines=1
export pgmerr_lines=1

#
#-----------------------------------------------------------------------
# Create symlinks to log files in the experiment directory. Makes viewing
# log files easier in NCO mode, as well as make CIs work
#-----------------------------------------------------------------------
#
if [ "${WORKFLOW_MANAGER}" != "ecflow" ]; then
    __EXPTLOG=${EXPTDIR}/log
    mkdir -p ${__EXPTLOG}
    for i in ${LOGDIR}/*.${WORKFLOW_ID}.log; do
        __LOGB=$(basename $i .${WORKFLOW_ID}.log)
        ln -sf $i ${__EXPTLOG}/${__LOGB}.log
    done
fi
#
#-----------------------------------------------------------------------
# Add a postamble function
#-----------------------------------------------------------------------
#
function job_postamble() {

    # Remove temp directory
    if [ "${KEEPDATA}" = "FALSE" ]; then
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


