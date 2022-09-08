#!/bin/bash

set -x

function file_location() {

  # Return the default location of external model files on disk

  local external_file_fmt external_model location

  external_model=${1}
  external_file_fmt=${2}

  case ${external_model} in

    "FV3GFS")
      location='/home/username/DATA/UFS/FV3GFS/'
      ;;
    *)
      print_info_msg"\
        External model \'${external_model}\' does not have a default
      location on Linux systems. "
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

 System scripts to source to initialize various commands within workflow
 scripts (e.g. "module").
if [ -z ${ENV_INIT_SCRIPTS_FPS:-""} ]; then
  ENV_INIT_SCRIPTS_FPS=( "/etc/profile" )
fi


# Commands to run at the start of each workflow task.
PRE_TASK_CMDS='{ ulimit -a; }'

# Architecture information
WORKFLOW_MANAGER="none"
NCORES_PER_NODE=${NCORES_PER_NODE:-8}
SCHED=${SCHED:-"none"}

# UFS SRW App specific paths
FIXgsm=${FIXgsm:-"/home/username/DATA/UFS/fix/fix_am"}
FIXaer=${FIXaer:-"/home/username/DATA/UFS/fix/fix_aer"}
FIXlut=${FIXlut:-"/home/username/DATA/UFS/fix/fix_lut"}
TOPO_DIR=${TOPO_DIR:-"/home/username/DATA/UFS/fix/fix_orog"}
SFC_CLIMO_INPUT_DIR=${SFC_CLIMO_INPUT_DIR:-"/home/username/DATA/UFS/fix/fix_sfc_climo"}

# Run commands for executables
RUN_CMD_SERIAL="time"
#Run Commands currently differ for GNU/openmpi
RUN_CMD_UTILS='mpirun -n 4'
RUN_CMD_FCST='mpirun -n ${PE_MEMBER01} '
RUN_CMD_POST='mpirun -n 4 '

# MET Installation Locations

