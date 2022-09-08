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

  esac
  echo ${location:-}
}
export PROJ_LIB=/contrib/GST/miniconda/envs/regional_workflow/share/proj
export OPT=/contrib/EPIC/hpc-modules
export PATH=${PATH}:/contrib/GST/miniconda/envs/regional_workflow/bin

EXTRN_MDL_SYSBASEDIR_ICS=${EXTRN_MDL_SYSBASEDIR_ICS:-$(file_location \
  ${EXTRN_MDL_NAME_ICS} \
  ${FV3GFS_FILE_FMT_ICS})}
EXTRN_MDL_SYSBASEDIR_LBCS=${EXTRN_MDL_SYSBASEDIR_LBCS:-$(file_location \
  ${EXTRN_MDL_NAME_LBCS} \
  ${FV3GFS_FILE_FMT_ICS})}

EXTRN_MDL_DATA_STORES=${EXTRN_MDL_DATA_STORES:-"aws nomads"}

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
staged_data_dir="/contrib/EPIC/UFS_SRW_App/develop"
FIXgsm=${FIXgsm:-"${staged_data_dir}/fix/fix_am"}
FIXaer=${FIXaer:-"${staged_data_dir}/fix/fix_aer"}
FIXlut=${FIXlut:-"${staged_data_dir}/fix/fix_lut"}
TOPO_DIR=${TOPO_DIR:-"${staged_data_dir}/fix/fix_orog"}
SFC_CLIMO_INPUT_DIR=${SFC_CLIMO_INPUT_DIR:-"${staged_data_dir}/fix/fix_sfc_climo"}
TEST_EXTRN_MDL_SOURCE_BASEDIR="${staged_data_dir}/input_model_data"

RUN_CMD_SERIAL="time"
#Run Commands currently differ for GNU/openmpi
#RUN_CMD_UTILS='mpirun --mca btl tcp,vader,self -np $nprocs'
#RUN_CMD_FCST='mpirun --mca btl tcp,vader,self -np ${PE_MEMBER01}'
#RUN_CMD_POST='mpirun --mca btl tcp,vader,self -np $nprocs'
RUN_CMD_UTILS='mpiexec -np $nprocs'
RUN_CMD_FCST='mpiexec -np ${PE_MEMBER01}'
RUN_CMD_POST='mpiexec -np $nprocs'

export build_mod_fn="wflow_noaacloud"
BUILD_MOD_FN="wflow_noaacloud"

# MET Installation Locations
# MET Plus is not yet supported on noaacloud
. /contrib/EPIC/.bash_conda
