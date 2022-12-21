#!/bin/bash

#
#-----------------------------------------------------------------------
#
# If requested to share data with next task, override jobid
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
# Set COMIN / COMOUT
#
#-----------------------------------------------------------------------
#
if [ "${RUN_ENVIR}" = "nco" ]; then
    export COMIN="${COMIN_BASEDIR}/${RUN}.${PDY}/${cyc}"
    export COMOUT="${COMOUT_BASEDIR}/${RUN}.${PDY}/${cyc}"
    export COMINext="${EXTROOT}/${RUN}.${PDY}/${cyc}"
else
    export COMIN="${COMIN_BASEDIR}/${PDY}${cyc}"
    export COMOUT="${COMOUT_BASEDIR}/${PDY}${cyc}"
    export COMINext="${EXTROOT}/${PDY}${cyc}"
fi

#
#-----------------------------------------------------------------------
#
# Create symlinks to log files in the experiment directory. Makes viewing
# log files easier in NCO mode, as well as make CIs work
#
#-----------------------------------------------------------------------
#
if [ "${RUN_ENVIR}" = "nco" ]; then
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
#
#-----------------------------------------------------------------------
#
function job_postamble() {

    # Remove temp directory
    if [ "${RUN_ENVIR}" = "nco" ] && [ $# -eq 0 ]; then
        cd ${DATAROOT}
        [[ $KEEPDATA = "FALSE" ]] && rm -rf $DATA
    fi

    # Print exit message
    print_info_msg "
========================================================================
Exiting script:  \"${scrfunc_fn}\"
In directory:    \"${scrfunc_dir}\"
========================================================================"
}


