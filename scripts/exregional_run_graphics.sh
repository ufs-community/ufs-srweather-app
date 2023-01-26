#!/bin/bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. $USHdir/source_util_funcs.sh
source_config_for_task "task_run_graphics|task_run_fcst|task_run_post" ${GLOBAL_VAR_DEFNS_FP}
#
#-----------------------------------------------------------------------
#
# Save current shell options (in a global array).  Then set new options
# for this script/function.
#
#-----------------------------------------------------------------------
#
{ save_shell_opts; . $USHdir/preamble.sh; } > /dev/null 2>&1
#
#-----------------------------------------------------------------------
#
# Get the full path to the file in which this script/function is located 
# (scrfunc_fp), the name of that file (scrfunc_fn), and the directory in
# which the file is located (scrfunc_dir).
#
#-----------------------------------------------------------------------
#
scrfunc_fp=$( $READLINK -f "${BASH_SOURCE[0]}" )
scrfunc_fn=$( basename "${scrfunc_fp}" )
scrfunc_dir=$( dirname "${scrfunc_fp}" )
#
#-----------------------------------------------------------------------
#
# Print message indicating entry into script.
#
#-----------------------------------------------------------------------
#
print_info_msg "
========================================================================
Entering script:  \"${scrfunc_fn}\"
In directory:     \"${scrfunc_dir}\"

This is the ex-script for the task that plots graphics using pygraf.
========================================================================"
#
#-----------------------------------------------------------------------
#
# Setup variables needed for plotting
#
#-----------------------------------------------------------------------
#
if [ "${IS_RTMA}" = "TRUE" ]; then
  fcst_length=${FCST_LEN_HRS_CYCLES[$((10#$cyc))]/%.*/}
else
  fcst_length=${FCST_LEN_HRS_CYCLES[$((10#$cyc))]}
fi

IMAGES_FN=${IMAGES_FN:-$PYTHON_GRAPHICS_YML_FN}
# Choose an appropriate sites file for the grid
sites_file=conus_raobs.txt
tiles=${TILES:-full}

if [[ "${PREDEF_GRID_NAME}" =~ "AK" || \
      "${TILELABEL:-}" == "242" || \
      "${TILELABEL:-}" == "hrrrak" ]] ; then
  sites_file=alaska_raobs.txt
  tiles=${TILES:-hrrrak}

elif [[ "${PREDEF_GRID_NAME}" =~ "RAP" || \
        "${PREDEF_GRID_NAME}" =~ "NA" || \
        "${TILELABEL:-}" = "221" ]] ; then
  age=5
  wait_time=15
  sites_file=na_raobs.txt
  tiles=${TILES:-full}

elif [[ "${TILELABEL:-}" = hrrr ]] ; then

  # This domain comes from a NA domain, so wait longer.
  age=5
  wait_time=15
  tiles=${TILES:-hrrr}

fi

# Use a subdirectory for input from alternative wgrib2-produced grids.
wgrib2_grids=( hrrr hrrrak full )
first_grid=${tiles%%,*} # First in a comma separated list
first_grid=${first_grid%%_*} # First part of an underscore separated string (requirement set by Rocoto)

sub_conus_grids=( SE SC SW NE NC NW \
  ATL CA-NV CentralCA CHI-DET DCArea EastCO GreatLakes NYC-BOS SEA-POR SouthCA SouthFL VortexSE )

sub_ak_grids=( AKRange Anchorage Juneau )

if [[ "${sub_conus_grids[*]}" =~ $first_grid ]] ; then
  subdir=hrrr_grid
elif [[ "${sub_ak_grids[*]}" =~ $first_grid ]] ; then
  subdir=hrrrak_grid
elif [[ "${wgrib2_grids[*]}" =~ $first_grid ]] ; then
  subdir=${first_grid:-}_grid
fi

if [ -d ${POSTPRD_DIR}/${subdir} ] ; then
  POSTPRD_DIR=${POSTPRD_DIR}/${subdir}
  DATA=${DATA}/${subdir:-}
  ZIP_DIR=${ZIP_DIR}/${subdir:-}
fi

if [ "${ENSPROD:-}" = 'ensprod' ] ; then
  file_id="ens"
  start_hour=1
fi

# Choose the appropriate file template for graphics type
case ${GRAPHICS_TYPE} in

  "maps")

    file_tmpl="${NET}.t${CDATE:8:2}z.bg${file_id:-dawp}.f{FCST_TIME:03d}.${POST_OUTPUT_DOMAIN_NAME}.grib2"
    file_type=prs
    extra_args="\
      --tiles $tiles \
      --images ${GRAPHICSdir}/image_lists/${IMAGES_FN} hourly"
    if [ ${ALL_LEADS:-true} = "true" ] ; then
        extra_args="\
          ${extra_args} \
          --all_leads"
    fi
    ;;

  "skewts")

    file_tmpl="${NET}.t${CDATE:8:2}z.bgrd3d.f{FCST_TIME:03d}.${POST_OUTPUT_DOMAIN_NAME}.grib2"
    file_type=nat
    extra_args="\
      --sites ${GRAPHICSdir}/static/${sites_file} \
      --max_plev 100"
    ;;

  "enspanel")

    file_tmpl="${NET}.t${CDATE:8:2}z.bgdawp.f{FCST_TIME:03d}.${POST_OUTPUT_DOMAIN_NAME}.grib2"
    file_type=prs
    extra_args="\
      --tiles $tiles \
      --images ${GRAPHICSdir}/image_lists/rrfs_ens.yml hourly"

    # Link in control member to the location it should be
    ens_mem0=${POSTPRD_DIR/'#mem#'/'0000'/}
    mem0_fp=${COMOUT_mem0}
    mem0_fn=${file_tmpl/'{FCST_TIME:03d}'/'*'}

    mkdir_vrfy -p ${ens_mem0}
    pushd ${ens_mem0}

    rm *.grib2

    for mem0_file in $( find ${mem0_fp} -name ${mem0_fn} ) ; do
      cp_vrfy ${mem0_file} .
    done
    popd

    # Create a python template for POSTPRD_DIR
    POSTPRD_DIR=${POSTPRD_DIR/'#mem#'/'{mem:04d}'/}

    # Remove ensemble reference from output locations
    DATA=${DATA/'/mem#mem#/'//}
    ZIP_DIR=${ZIP_DIR/'/mem#mem#/'//}

    ;;

  *)
    print_err_msg_exit "\
      GRAPHICS_TYPE \"${GRAPHICS_TYPE}\" is not recognized."
    ;;
esac
mkdir_vrfy -p "${DATA}"
#
#-----------------------------------------------------------------------
#
# Call the graphics driver script.
#
#-----------------------------------------------------------------------
#
cd_vrfy ${GRAPHICSdir}
python -u ${GRAPHICSdir}/create_graphics.py \
  ${GRAPHICS_TYPE} \
  -a ${age:-3} \
  -d ${POSTPRD_DIR} \
  -f ${start_hour:-0} ${fcst_length} \
  --file_tmpl ${file_tmpl} \
  --file_type ${file_type} \
  -m "${MODEL}" \
  -n ${SLURM_CPUS_ON_NODE:-12} \
  -o ${DATA} \
  -s ${CDATE} \
  -w ${wait_time:-10} \
  -z ${ZIP_DIR} \
  ${extra_args} ||
print_err_msg_exit "\
Call to pyscript \"${scrfunc_fn}\" failed."

#
#-----------------------------------------------------------------------
#
# Print message indicating successful completion of script.
#
#-----------------------------------------------------------------------
#
print_info_msg "
========================================================================
Completed graphics successfully.

Exiting script:  \"${scrfunc_fn}\"
In directory:    \"${scrfunc_dir}\"
========================================================================"
#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script/func-
# tion.
#
#-----------------------------------------------------------------------
#
{ restore_shell_opts; } > /dev/null 2>&1
