# envir-p1.h

export model_ver="v7.0"
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


# Developer configuration
PTMP=/lfs/h2/emc/ptmp
PSLOT=ecflow_aqm

export SENDDBN="NO"
export SENDDBN_NTC="NO"

export OPSROOT="${PTMP}/${USER}/${PSLOT}/para"
export COMROOT="${OPSROOT}/com"
export DATAROOT="${OPSROOT}/tmp"
export DCOMROOT="${OPSROOT}/dcom"

#export DCOMINbio: /lfs/h2/emc/lam/noscrub/RRFS_CMAQ/aqm/bio
#export DCOMINdust: /lfs/h2/emc/lam/noscrub/RRFS_CMAQ/FENGSHA
#export DCOMINfire: /lfs/h2/emc/physics/noscrub/kai.wang/RAVE_fire/RAVE_NA_NRT
#export DCOMINchem_lbcs: /lfs/h2/emc/lam/noscrub/RRFS_CMAQ/LBCS/AQM_NA13km_AM4_v1
#export DCOMINgefs: /lfs/h2/emc/lam/noscrub/RRFS_CMAQ/GEFS_DATA
#export DCOMINpt_src: /lfs/h2/emc/physics/noscrub/Youhua.Tang/nei2016v1-pt/v2023-01-PT
#export DCOMINairnow: /lfs/h1/ops/prod/dcom

if [ -n "%PDY:%" ]; then
  export PDY=${PDY:-%PDY:%}
  export CDATE=${PDY}%CYC:%
fi

