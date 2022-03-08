#!/bin/bash

set -x

function file_location() {

  # Return the default location of external model files on disk

  local external_file_fmt external_model location

  external_model=${1}
  external_file_fmt=${2}

  case ${external_model} in

    "FV3GFS")
      location='/contrib/GST/model_data/FV3GFS/${yyyymmdd}${hh}'
      ;;
    *)
      print_info_msg"\
        External model \'${external_model}\' does not have a default
      location on Hera. Will try to pull from HPSS"
      ;;

  esac
  echo ${location:-}
}


EXTRN_MDL_SYSBASEDIR_ICS=${EXTRN_MDL_SYSBASEDIR_ICS:-$(file_location \
  ${EXTRN_MDL_NAME_ICS} \
  ${FV3GFS_FILE_FMT_ICS})}
EXTRN_MDL_SYSBASEDIR_LBCS=${EXTRN_MDL_SYSBASEDIR_LBCS:-$(file_location \
  ${EXTRN_MDL_NAME_LBCS} \
  ${FV3GFS_FILE_FMT_ICS})}

# System scripts to source to initialize various commands within workflow
# scripts (e.g. "module").
if [ -z ${ENV_INIT_SCRIPTS_FPS:-""} ]; then
  ENV_INIT_SCRIPTS_FPS=( "/etc/profile" )
fi


# Commands to run at the start of each workflow task.
PRE_TASK_CMDS='{ ulimit -s unlimited; ulimit -a; }'

# Architecture information
WORKFLOW_MANAGER="rocoto"
NCORES_PER_NODE=${NCORES_PER_NODE:-36}
SCHED=${SCHED:-"slurm"}

# UFS SRW App specific paths
FIXgsm=${FIXgsm:-"/contrib/EPIC/fix/fix_am"}
FIXaer=${FIXaer:-"/contrib/EPIC/fix/fix_aer"}
FIXlut=${FIXlut:-"/contrib/EPIC/fix/fix_lut"}
TOPO_DIR=${TOPO_DIR:-"/contrib/EPIC/fix/fix_orog"}
SFC_CLIMO_INPUT_DIR=${SFC_CLIMO_INPUT_DIR:-"/contrib/EPIC/fix/fix_sfc_climo"}
FIXLAM_NCO_BASEDIR=${FIXLAM_NCO_BASEDIR:-"/scratch2/BMC/det/FV3LAM_pregen"}

RUN_CMD_SERIAL="time"
#Run Commands currently differ for GNU/openmpi
#RUN_CMD_UTILS='mpirun --mca btl tcp,vader,self -np $nprocs'
#RUN_CMD_FCST='mpirun --mca btl tcp,vader,self -np ${PE_MEMBER01}'
#RUN_CMD_POST='mpirun --mca btl tcp,vader,self -np $nprocs'
RUN_CMD_UTILS='srun --mpi=pmi2 -n $nprocs'
RUN_CMD_FCST='srun --mpi=pmi2 -n ${PE_MEMBER01}'
RUN_CMD_POST='srun --mpi=pmi2 -n $nprocs'

# MET Installation Locations
# MET Plus is not yet supported on noaacloud

