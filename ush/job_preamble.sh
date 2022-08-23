#!/bin/bash

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
# Set cycle and run setpdy to initialize PDYm and PDYp variables
#
#-----------------------------------------------------------------------
#
export cycle="t${cyc}z"
if [ "${RUN_ENVIR}" = "nco" ]; then
    if [ ! -z $(command -v setpdy.sh) ]; then
        setpdy.sh
        . ./PDY
    fi
fi
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
    export -f PREP_STEP
    export -f POST_STEP
else
    export pgmout=
    export pgmerr=
    export REDIRECT_OUT_ERR=
    export PREP_STEP=
    export POST_STEP=
fi
#
#-----------------------------------------------------------------------
#
# Set COMIN / COMOUT
#
#-----------------------------------------------------------------------
#
if [ "${RUN_ENVIR}" = "nco" ]; then
    export COMIN="${COMIN_BASEDIR}/${RUN}.${PDY}/${cyc}"
    export COMOUT="${COMOUT_BASEDIR}/${RUN}.${PDY}"
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
        [[ $KEEPDATA = "FALSE" ]] && rm -rf $DATA
    fi

    # Print exit message
    print_info_msg "
========================================================================
Exiting script:  \"${scrfunc_fn}\"
In directory:    \"${scrfunc_dir}\"
========================================================================"
}


