#!/bin/bash

#
#-----------------------------------------------------------------------
#
# If requested to share data with next task, override jobid
#
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
#
# Set NCO standard environment variables
#
#-----------------------------------------------------------------------
#
export envir="${envir:-${envir_dfv}}"
export NET="${NET:-${NET_dfv}}"
export RUN="${RUN:-${RUN_dfv}}"
export model_ver="${model_ver:-${model_ver_dfv}}"
export COMROOT="${COMROOT:-${COMROOT_dfv}}"
export DATAROOT="${DATAROOT:-${DATAROOT_dfv}}"
export DCOMROOT="${DCOMROOT:-${DCOMROOT_dfv}}"
export LOGBASEDIR="${LOGBASEDIR:-${LOGBASEDIR_dfv}}"

export DBNROOT="${DBNROOT:-${DBNROOT_dfv}}"
export SENDECF="${SENDECF:-${SENDECF_dfv}}"
export SENDDBN="${SENDDBN:-${SENDDBN_dfv}}"
export SENDDBN_NTC="${SENDDBN_NTC:-${SENDDBN_NTC_dfv}}"
export SENDCOM="${SENDCOM:-${SENDCOM_dfv}}"
export SENDWEB="${SENDWEB:-${SENDWEB_dfv}}"
export KEEPDATA="${KEEPDATA:-${KEEPDATA_dfv}}"
export MAILTO="${MAILTO:-${MAILTO_dfv}}"
export MAILCC="${MAILCC:-${MAILCC_dfv}}"

[[ "$WORKFLOW_MANAGER" = "rocoto" ]] && export COMROOT=$COMROOT
if [ "${MACHINE}" = "WCOSS2" ]; then
  export COMIN="${COMIN:-$(compath.py -o ${NET}/${model_ver}/${RUN}.${PDY})}"
  export COMOUT="${COMOUT:-$(compath.py -o ${NET}/${model_ver}/${RUN}.${PDY}/${cyc})}"
  export COMINgfs="${COMINgfs:-$(compath.py ${envir}/gfs/${gfs_ver})}"
  export COMINgefs="${COMINgefs:-$(compath.py ${envir}/gefs/${gefs_ver})}"
  export COMOUTwmo="${COMOUTwmo:-${COMOUT}/wmo}"
else
  export COMIN="${COMIN:-${COMROOT}/${NET}/${model_ver}/${RUN}.${PDY}}"
  export COMOUT="${COMOUT:-${COMROOT}/${NET}/${model_ver}/${RUN}.${PDY}/${cyc}}"
  export COMOUTwmo="${COMOUTwmo:-${COMOUT}/wmo}"
  mkdir -p ${COMIN}
  mkdir -p ${COMOUT}
fi

export FIXaqmconfig="${FIXaqmbio:-${HOMEaqm}/fix/aqm/epa/data}"
export FIXaqmbio="${FIXaqmbio:-${HOMEaqm}/fix/bio}"
export FIXaqmdust="${FIXaqmdust:-${HOMEaqm}/fix/dust}"
export FIXaqmcanopy="${FIXaqmcanopy:-${HOMEaqm}/fix/canopy}"
export FIXaqmchem_lbcs="${FIXaqmchem_lbcs:-${HOMEaqm}/fix/chem_lbcs}"
export FIXaqmnexus="${FIXaqmnexus:-${HOMEaqm}/fix/nexus}"
export FIXaqmnexus_gfs_sfc="${FIXaqmnexus:-${HOMEaqm}/fix/gfs}"
export FIXaqmfire="${FIXaqmfire:-${HOMEaqm}/fix/fire}"
export COMINemispt="${COMINemispt:-${COMIN}/emission/pt}"
export COMINemis="${COMINemis:-${COMIN}/emission}"
export DCOMINfire="${DCOMINfire:-${DCOMROOT}/${PDY}/rave}"
export DCOMINairnow="${DCOMINairnow:-${DCOMROOT}}"

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
if [ "${DO_ENSEMBLE}" = "TRUE" ] && [ ! -z $ENSMEM_INDX ]; then
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
export DATA=${DATAROOT}/${jobid}
mkdir -p $DATA
cd $DATA
#
#-----------------------------------------------------------------------
#
# Run setpdy to initialize PDYm and PDYp variables
#
#-----------------------------------------------------------------------
#
if [ ! -z $(command -v setpdy.sh) ]; then
    COMROOT=$COMROOT setpdy.sh
    . ./PDY
fi
if [ "${MACHINE}" = "WCOSS2" ]; then
  export COMINm1="${COMINm1:-$(compath.py -o ${NET}/${model_ver}/${RUN}.${PDYm1})}"
  export COMINm2="${COMINm1:-$(compath.py -o ${NET}/${model_ver}/${RUN}.${PDYm2})}"
else
  export COMINm1="${COMINm1:-${COMROOT}/${NET}/${model_ver}/${RUN}.${PDYm1}}"
  export COMINm2="${COMINm1:-${COMROOT}/${NET}/${model_ver}/${RUN}.${PDYm2}}"
fi
export CDATE=${PDY}${cyc}
#
#-----------------------------------------------------------------------
#
# Set pgmout and pgmerr files
#
#-----------------------------------------------------------------------
#
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
#
# Add a postamble function
#
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


