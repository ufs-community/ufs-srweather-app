#!/bin/bash

function file_location() {

  # Return the default location of external model files on disk

  local external_file_fmt external_model location

  external_model=${1}
  external_file_fmt=${2}

  staged_data_dir="/work2/00315/tg455890/stampede2/UFS_SRW_App/develop"

  location=""
  case ${external_model} in

    "GSMGFS")
      location="${staged_data_dir}/input_model_data/GFS"
      ;;
    "FV3GFS")
      location="${staged_data_dir}/input_model_data/FV3GFS"
      ;;
    "HRRR")
      location="${staged_data_dir}/input_model_data/HRRR"
      ;;
    "RAP")
      location="${staged_data_dir}/input_model_data/RAP"
      ;;
    "NAM")
      location="${staged_data_dir}/input_model_data/NAM"
      ;;
  esac
  echo ${location:-}

}

EXTRN_MDL_SYSBASEDIR_ICS=${EXTRN_MDL_SYSBASEDIR_ICS:-$(file_location \
  ${EXTRN_MDL_NAME_ICS} \
  ${FV3GFS_FILE_FMT_ICS})}
EXTRN_MDL_SYSBASEDIR_LBCS=${EXTRN_MDL_SYSBASEDIR_LBCS:-$(file_location \
  ${EXTRN_MDL_NAME_LBCS} \
  ${FV3GFS_FILE_FMT_LBCS})}

# System scripts to source to initialize various commands within workflow
# scripts (e.g. "module").
if [ -z ${ENV_INIT_SCRIPTS_FPS:-""} ]; then
  ENV_INIT_SCRIPTS_FPS=()
fi

# Commands to run at the start of each workflow task.
PRE_TASK_CMDS='{ ulimit -s unlimited; ulimit -a; }'

# Architecture information
WORKFLOW_MANAGER="rocoto"
NCORES_PER_NODE="${NCORES_PER_NODE:-68}"
SCHED=${SCHED:-"slurm"}
PARTITION_DEFAULT=${PARTITION_DEFAULT:-"normal"}
QUEUE_DEFAULT=${QUEUE_DEFAULT:-"normal"}
PARTITION_HPSS=${PARTITION_HPSS:-"normal"}
QUEUE_HPSS=${QUEUE_HPSS:-"normal"}
PARTITION_FCST=${PARTITION_FCST:-"normal"}
QUEUE_FCST=${QUEUE_FCST:-"normal"}

# UFS SRW App specific paths
staged_data_dir="/work2/00315/tg455890/stampede2/UFS_SRW_App/develop"
FIXgsm=${FIXgsm:-"${staged_data_dir}/fix/fix_am"}
FIXaer=${FIXaer:-"${staged_data_dir}/fix/fix_aer"}
FIXlut=${FIXlut:-"${staged_data_dir}/fix/fix_lut"}
TOPO_DIR=${TOPO_DIR:-"${staged_data_dir}/fix/fix_orog"}
SFC_CLIMO_INPUT_DIR=${SFC_CLIMO_INPUT_DIR:-"${staged_data_dir}/fix/fix_sfc_climo"}
DOMAIN_PREGEN_BASEDIR=${DOMAIN_PREGEN_BASEDIR:-"${staged_data_dir}/FV3LAM_pregen"}

# Run commands for executables
RUN_CMD_SERIAL="time"
RUN_CMD_UTILS='ibrun -np $nprocs'
RUN_CMD_FCST='ibrun -np $nprocs'
RUN_CMD_POST='ibrun -np $nprocs'

# Test Data Locations
TEST_PREGEN_BASEDIR="${staged_data_dir}/FV3LAM_pregen"
TEST_EXTRN_MDL_SOURCE_BASEDIR="${staged_data_dir}/input_model_data"
