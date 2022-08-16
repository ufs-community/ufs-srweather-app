#!/bin/bash

#
#-----------------------------------------------------------------------
#
# Set cycle and run setpdy to initialize PDYm and PDYp variables
#
#-----------------------------------------------------------------------
#
if [ ! -z ${DATAROOT} ]; then
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
