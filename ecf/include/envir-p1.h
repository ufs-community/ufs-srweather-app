# envir-p1.h
export job=${job:-$PBS_JOBNAME}
export jobid=${jobid:-$job.$PBS_JOBID}
export RUN_ENVIR=nco
export RUN=%RUN%
export NET=%NET%
export envir=%ENVIR%

if [ -n "%SENDCANNEDDBN:%" ]; then export SENDCANNEDDBN=${SENDCANNEDDBN:-%SENDCANNEDDBN:%}; fi
export SENDCANNEDDBN=${SENDCANNEDDBN:-"NO"}

if [[ "$envir" == prod && "$SENDDBN" == YES ]]; then
    export eval=%EVAL:NO%
    if [ $eval == YES ]; then export SIPHONROOT=${UTILROOT}/para_dbn
    else export SIPHONROOT=/lfs/h1/ops/prod/dbnet_siphon
    fi
    if [ "$PARATEST" == YES ]; then export SIPHONROOT=${UTILROOT}/fakedbn; export NODBNFCHK=YES; fi
else
    export SIPHONROOT=${UTILROOT}/fakedbn
fi
export SIPHONROOT=${UTILROOT}/fakedbn
export DBNROOT=$SIPHONROOT

if [[ ! " prod para test " =~ " ${envir} " && " ops.prod ops.para " =~ " $(whoami) " ]]; then err_exit "ENVIR must be prod, para, or test [envir-p1.h]"; fi

if [ -n "%PDY:%" ]; then
  export PDY=${PDY:-%PDY:%}
  export CDATE=${PDY}%CYC:%
fi

