#!/bin/bash

#
#-----------------------------------------------------------------------
#
# Set cycle and run setpdy to initialize PDYm and PDYp variables
#
#-----------------------------------------------------------------------
#
if [ -e ${DATAROOT} ]; then
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
export cycle="t${cyc}${subcyc}z"
if [ command -v setpdy.sh ]; then
    setpdy.sh
    . ./PDY
fi
#
#-----------------------------------------------------------------------
#
# Set pgmout and pgmerr files
#
#-----------------------------------------------------------------------
#
export pgmout="OUTPUT.$$"
export pgmerr="errfile"
#
#-----------------------------------------------------------------------
#
# Set COMIN / COMOUT
#
#-----------------------------------------------------------------------
#
export COMIN="${CYCLE_BASEDIR}/${RUN}.${PDY}"
export COMOUT="${COMOUT_BASEDIR}/${RUN}.${PDY}"
#
#-----------------------------------------------------------------------
#
# Add a postamble function
#
#-----------------------------------------------------------------------
#
function job_postamble() {

    # Print output file to stdout
    if [ -e "$pgmout" ]; then
        cat $pgmout
    fi

    # Remove temp directory
    if [ -e ${DATAROOT} ]; then
        cd $DATAROOT
        [[ $KEEPDATA = "FALSE" ]] && rm -rf $DATA
    fi

    # Print exit message
    print_info_msg "
========================================================================
Exiting script:  \"${scrfunc_fn}\"
In directory:    \"${scrfunc_dir}\"
========================================================================"
}


