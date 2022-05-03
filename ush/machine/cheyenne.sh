#!/bin/bash

function file_location() {

  # Return the default location of external model files on disk

  local external_file_fmt external_model location

  external_model=${1}
  external_file_fmt=${2}

  location=""
  case ${external_model} in

    "FV3GFS")
      location='/glade/p/ral/jntp/UFS_CAM/COMGFS/gfs.${yyyymmdd}/${hh}'
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
  ENV_INIT_SCRIPTS_FPS=( "/etc/profile" )
fi

# Commands to run at the start of each workflow task.
PRE_TASK_CMDS='{ ulimit -s unlimited; ulimit -a; }'

# Architecture information
WORKFLOW_MANAGER="rocoto"
NCORES_PER_NODE="${NCORES_PER_NODE:-36}"
SCHED=${SCHED:-"pbspro"}
QUEUE_DEFAULT=${QUEUE_DEFAULT:-"regular"}
QUEUE_HPSS=${QUEUE_HPSS:-"regular"}
QUEUE_FCST=${QUEUE_FCST:-"regular"}

# UFS SRW App specific paths
staged_data_dir="/glade/p/ral/jntp/UFS_SRW_App/develop"
FIXgsm=${FIXgsm:-"${staged_data_dir}/fix/fix_am"}
FIXaer=${FIXaer:-"${staged_data_dir}/fix/fix_aer"}
FIXlut=${FIXlut:-"${staged_data_dir}/fix/fix_lut"}
TOPO_DIR=${TOPO_DIR:-"${staged_data_dir}/fix/fix_orog"}
SFC_CLIMO_INPUT_DIR=${SFC_CLIMO_INPUT_DIR:-"${staged_data_dir}/fix/fix_sfc_climo"}
DOMAIN_PREGEN_BASEDIR=${DOMAIN_PREGEN_BASEDIR:-"${staged_data_dir}/FV3LAM_pregen"}

# Run commands for executables
RUN_CMD_SERIAL="time"
RUN_CMD_UTILS='mpirun -np $nprocs'
RUN_CMD_FCST='mpirun -np ${PE_MEMBER01}'
RUN_CMD_POST='mpirun -np $nprocs'

# MET/METplus-Related Paths
MET_INSTALL_DIR=${MET_INSTALL_DIR:-"/glade/p/ral/jntp/MET/MET_releases/10.0.0"}
METPLUS_PATH=${METPLUS_PATH:-"/glade/p/ral/jntp/MET/METplus/METplus-4.0.0"}
CCPA_OBS_DIR=${CCPA_OBS_DIR:-"${staged_data_dir}/obs_data/ccpa/proc"}
MRMS_OBS_DIR=${MRMS_OBS_DIR:-"${staged_data_dir}/obs_data/mrms/proc"}
NDAS_OBS_DIR=${NDAS_OBS_DIR:-"${staged_data_dir}/obs_data/ndas/proc"}
MET_BIN_EXEC=${MET_BIN_EXEC:-"bin"}

# Test Data Locations
TEST_COMIN="${staged_data_dir}/COMGFS"
TEST_PREGEN_BASEDIR="${staged_data_dir}/FV3LAM_pregen"
TEST_EXTRN_MDL_SOURCE_BASEDIR="${staged_data_dir}/input_model_data"
