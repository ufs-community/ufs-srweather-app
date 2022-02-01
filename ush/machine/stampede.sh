#!/bin/bash

set -x

function file_location() {

  # Return the default location of external model files on disk

  local external_file_fmt external_model location

  external_model=${1}
  external_file_fmt=${2}

  case ${external_model} in

    "GSMGFS")
      ;& # Fall through. All files in same place
    "FV3GFS")
      location='/scratch/00315/tg455890/GDAS/20190530/2019053000_mem001'
      ;;
    "*")
      print_err_msg_exit"\
        External model \'${external_model}\' does not have a default
      location on Jet Please set a user-defined file location."
      ;;

  esac
  echo ${location:-}
}


SYSBASEDIR_ICS=${EXTRN_MDL_SYSBASEDIR_ICS:-$(file_location \
  ${EXTRN_MDL_NAME_ICS} \
  ${FV3GFS_FILE_FMT_ICS})}
EXTRN_MDL_SYSBASEDIR_LBCS=${EXTRN_MDL_SYSBASEDIR_LBCS:-$(file_location \
  ${EXTRN_MDL_NAME_LBCS} \
  ${FV3GFS_FILE_FMT_ICS})}

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
FIXgsm=${FIXgsm:-"/work/00315/tg455890/stampede2/regional_fv3/fix_am"}
FIXaer=${FIXaer:-"/work/00315/tg455890/stampede2/regional_fv3/fix_aer"}
FIXlut=${FIXlut:-"/work/00315/tg455890/stampede2/regional_fv3/fix_lut"}
TOPO_DIR=${TOPO_DIR:-"/work/00315/tg455890/stampede2/regional_fv3/fix_orog"}
SFC_CLIMO_INPUT_DIR=${SFC_CLIMO_INPUT_DIR:-"/work/00315/tg455890/stampede2/regional_fv3/climo_fields_netcdf"}
FIXLAM_NCO_BASEDIR=${FIXLAM_NCO_BASEDIR:-"/needs/to/be/specified"}

RUN_CMD_SERIAL="time"
RUN_CMD_UTILS='ibrun -np $nprocs'
RUN_CMD_FCST='ibrun -np $nprocs'
RUN_CMD_POST='ibrun -np $nprocs'

ulimit -s unlimited
ulimit -a
