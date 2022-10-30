#!/bin/bash

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
export DATA_SHARED=
if [ "${RUN_ENVIR}" = "nco" ]; then
    export DATA=${DATAROOT}/${jobid}
    export DATA_SHARED=${DATAROOT}/${RUN}.${PDY}.${WORKFLOW_ID}
    mkdir_vrfy -p $DATA $DATA_SHARED
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
        setpdy.sh
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
else
    export COMIN="${COMIN_BASEDIR}/${PDY}${cyc}"
    export COMOUT="${COMOUT_BASEDIR}/${PDY}${cyc}"
fi
#
#-----------------------------------------------------------------------
#
# Add a postamble function
#
#-----------------------------------------------------------------------
#
function job_postamble() {

    if [ "${RUN_ENVIR}" = "nco" ]; then

        # Remove temp directory
        cd ${DATAROOT}
        [[ $KEEPDATA = "FALSE" ]] && rm -rf $DATA $DATA_SHARED

        # Create symlinks to log files
        local EXPTLOG=${EXPTDIR}/log
        mkdir_vrfy -p ${EXPTLOG}
        for i in ${LOGDIR}/*.${WORKFLOW_ID}.log; do
            local LOGB=$(basename $i .${WORKFLOW_ID}.log)
            ln_vrfy -sf $i ${EXPTLOG}/${LOGB}.log
        done
    fi

    # Print exit message
    print_info_msg "
========================================================================
Exiting script:  \"${scrfunc_fn}\"
In directory:    \"${scrfunc_dir}\"
========================================================================"
}


