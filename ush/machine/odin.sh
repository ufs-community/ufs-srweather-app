#!/bin/bash

function file_location() {

  # Return the default location of external model files on disk

  local external_file_fmt external_model location

  external_model=${1}
  external_file_fmt=${2}

  case ${external_model} in

    "GSMGFS")
      location='/scratch/ywang/EPIC/GDAS/2019053000_mem001'
      ;;
    "FV3GFS")
      location='/scratch/ywang/test_runs/FV3_regional/gfs/${yyyymmdd}'
      ;;
    "*")
      print_info_msg"\
        External model \'${external_model}\' does not have a default
      location on Odin Please set a user-defined file location."
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
  ENV_INIT_SCRIPTS_FPS=()
fi

# Commands to run at the start of each workflow task.
PRE_TASK_CMDS='{ ulimit -s unlimited; ulimit -a; }'

# Architecture information
WORKFLOW_MANAGER="rocoto"
NCORES_PER_NODE=${NCORES_PER_NODE:-24}
SCHED=${SCHED:-"slurm"}
PARTITION_DEFAULT=${PARTITION_DEFAULT:-"workq"}
QUEUE_DEFAULT=${QUEUE_DEFAULT:-"workq"}
PARTITION_HPSS=${PARTITION_HPSS:-"workq"}
QUEUE_HPSS=${QUEUE_HPSS:-"workq"}
PARTITION_FCST=${PARTITION_FCST:-"workq"}
QUEUE_FCST=${QUEUE_FCST:-"workq"}

# UFS SRW App specific paths
FIXgsm=${FIXgsm:-"/scratch/ywang/fix/theia_fix/fix_am"}
FIXaer=${FIXaer:-"/scratch/ywang/fix/theia_fix/fix_aer"}
FIXlut=${FIXlut:-"/scratch/ywang/fix/theia_fix/fix_lut"}
TOPO_DIR=${TOPO_DIR:-"/scratch/ywang/fix/theia_fix/fix_orog"}
SFC_CLIMO_INPUT_DIR=${SFC_CLIMO_INPUT_DIR:-"/scratch/ywang/fix/climo_fields_netcdf"}
FIXLAM_NCO_BASEDIR=${FIXLAM_NCO_BASEDIR:-"/needs/to/be/specified"}

RUN_CMD_SERIAL="srun -n 1"
RUN_CMD_UTILS='srun -n $nprocs'
RUN_CMD_FCST='srun -n ${PE_MEMBER01}'
RUN_CMD_POST="srun -n 1"
