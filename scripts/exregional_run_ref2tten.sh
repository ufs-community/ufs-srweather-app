#!/bin/bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. $USHdir/source_util_funcs.sh
source_config_for_task "task_run_ref2tten|task_run_fcst" ${GLOBAL_VAR_DEFNS_FP}
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
scrfunc_fp=$( readlink -f "${BASH_SOURCE[0]}" )
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
This is the ex-script for the task that runs a analysis with FV3 for the
specified cycle.
========================================================================"
#
#-----------------------------------------------------------------------
#
# Load modules.
#
#-----------------------------------------------------------------------
#
eval ${PRE_TASK_CMDS}

nprocs=$((NNODES_RUN_REF2TTEN*PPN_RUN_REF2TTEN))

gridspec_dir=${NWGES_BASEDIR}/grid_spec
#
#-----------------------------------------------------------------------
#
# Extract from CDATE the starting year, month, day, and hour of the
# forecast.  These are needed below for various operations.
#
#-----------------------------------------------------------------------
#
START_DATE=$(echo "${CDATE}" | sed 's/\([[:digit:]]\{2\}\)$/ \1/')
YYYYMMDDHH=$(date +%Y%m%d%H -d "${START_DATE}")
JJJ=$(date +%j -d "${START_DATE}")

YYYY=${YYYYMMDDHH:0:4}
MM=${YYYYMMDDHH:4:2}
DD=${YYYYMMDDHH:6:2}
HH=${YYYYMMDDHH:8:2}
YYYYMMDD=${YYYYMMDDHH:0:8}
YYYYJJJHH=${YYYY}${JJJ}${HH}
#
#-----------------------------------------------------------------------
#
# Get into working directory and define fix directory
#
#-----------------------------------------------------------------------
#
print_info_msg "$VERBOSE" "
Getting into working directory for radar tten process ..."

cd_vrfy ${DATA}

fixdir=$FIXgsi
fixgriddir=$FIXgsi/${PREDEF_GRID_NAME}

print_info_msg "$VERBOSE" "fixdir is $fixdir"
print_info_msg "$VERBOSE" "fixgriddir is $fixgriddir"
pwd

#
#-----------------------------------------------------------------------
#
# link or copy background and grid configuration files
#
#-----------------------------------------------------------------------

if [ ${CYCLE_TYPE} == "spinup" ]; then
  cycle_tag="_spinup"
else
  cycle_tag=""
fi
if [ ${MEM_TYPE} == "MEAN" ]; then
    bkpath=${COMIN}/ensmean/fcst_fv3lam${cycle_tag}/INPUT
else
    if [ "${RUN_ENVIR}" = "nco" ]; then
        bkpath=$DATAROOT/${TAG}run_fcst_${CYCLE_TYPE}${SLASH_ENSMEM_SUBDIR/\//_}.${share_pid}
    else
        bkpath=${COMIN}${SLASH_ENSMEM_SUBDIR}
    fi
    bkpath=${bkpath}/fcst_fv3lam${cycle_tag}/INPUT
fi

n_iolayouty=$(($IO_LAYOUT_Y-1))
list_iolayout=$(seq 0 $n_iolayouty)

cp_vrfy ${fixgriddir}/fv3_akbk                               fv3_akbk
cp_vrfy ${fixgriddir}/fv3_grid_spec                          fv3_grid_spec

if [ -r "${bkpath}/coupler.res" ]; then # Use background from warm restart
  if [ "${IO_LAYOUT_Y}" == "1" ]; then
    ln_vrfy -s ${bkpath}/fv_core.res.tile1.nc         fv3_dynvars
    ln_vrfy -s ${bkpath}/fv_tracer.res.tile1.nc       fv3_tracer
    ln_vrfy -s ${bkpath}/sfc_data.nc                  fv3_sfcdata
    ln_vrfy -s ${bkpath}/phy_data.nc                  fv3_phydata
  else
    for ii in ${list_iolayout}
    do
      iii=$(printf %4.4i $ii)
      ln_vrfy -s ${bkpath}/fv_core.res.tile1.nc.${iii}         fv3_dynvars.${iii}
      ln_vrfy -s ${bkpath}/fv_tracer.res.tile1.nc.${iii}       fv3_tracer.${iii}
      ln_vrfy -s ${bkpath}/sfc_data.nc.${iii}                  fv3_sfcdata.${iii}
      ln_vrfy -s ${bkpath}/phy_data.nc.${iii}                  fv3_phydata.${iii}
      ln_vrfy -s ${gridspec_dir}/fv3_grid_spec.${iii}          fv3_grid_spec.${iii}
    done
  fi
  BKTYPE=0
else                                   # Use background from cold start
  ln_vrfy -s ${bkpath}/sfc_data.tile7.halo0.nc      fv3_sfcdata
  ln_vrfy -s ${bkpath}/gfs_data.tile7.halo0.nc      fv3_dynvars
  ln_vrfy -s ${bkpath}/gfs_data.tile7.halo0.nc      fv3_tracer
  print_info_msg "$VERBOSE" "radar2tten is not ready for cold start"
  BKTYPE=1
  exit 0
fi

#
#-----------------------------------------------------------------------
#
# link/copy observation files to working directory
#
#-----------------------------------------------------------------------
if [ "${RUN_ENVIR}" = "nco" ]; then
    process_radarref_path=${DATAROOT}/${TAG}process_radarref${cycle_tag}.${share_pid}
    process_lightning_path=${DATAROOT}/${TAG}process_lightning${cycle_tag}.${share_pid}
else
    process_radarref_path=${COMIN}/process_radarref${cycle_tag}
    process_lightning_path=${COMIN}/process_lightning${cycle_tag}
fi

ss=0
for bigmin in ${RADARREFL_TIMELEVEL[@]}; do
  bigmin=$( printf %2.2i $bigmin )
  obs_file=${process_radarref_path}/${bigmin}/RefInGSI3D.dat
  if [ "${IO_LAYOUT_Y}" == "1" ]; then
    obs_file_check=${obs_file}
  else
    obs_file_check=${obs_file}.0000
  fi
  ((ss+=1))
  num=$( printf %2.2i ${ss} )
  if [ -r "${obs_file_check}" ]; then
     if [ "${IO_LAYOUT_Y}" == "1" ]; then
       cp_vrfy "${obs_file}" "RefInGSI3D.dat_${num}"
     else
       for ii in ${list_iolayout}
       do
         iii=$(printf %4.4i $ii)
         cp_vrfy "${obs_file}.${iii}" "RefInGSI3D.dat.${iii}_${num}"
       done
     fi
  else
     print_info_msg "$VERBOSE" "Warning: ${obs_file} does not exist!"
  fi
done

obs_file=${process_lightning_path}/LightningInFV3LAM.dat
if [ -r "${obs_file}" ]; then
   cp_vrfy "${obs_file}" "LightningInGSI.dat_01"
else
   print_info_msg "$VERBOSE" "Warning: ${obs_file} does not exist!"
fi


#-----------------------------------------------------------------------
#
# Create links to BUFR table, which needed for generate the BUFR file
#
#-----------------------------------------------------------------------
bufr_table=${fixdir}/prepobs_prep_RAP.bufrtable

# Fixed fields
cp_vrfy $bufr_table prepobs_prep.bufrtable


#-----------------------------------------------------------------------
#
# Build namelist and run executable 
#
#   fv3_io_layout_y : subdomain of restart files
#
#-----------------------------------------------------------------------

if [ ${BKTYPE} -eq 1 ]; then
  n_iolayouty=1
else
  n_iolayouty=$(($IO_LAYOUT_Y))
fi

cat << EOF > namelist.ref2tten
   &setup
    dfi_radar_latent_heat_time_period=15.0,
    convection_refl_threshold=28.0,
    l_tten_for_convection_only=.true.,
    l_convection_suppress=.false.,
    fv3_io_layout_y=${n_iolayouty},
    timelevel=${ss},
   /
EOF

#
#-----------------------------------------------------------------------
#
# Copy the executable to the run directory.
#
#-----------------------------------------------------------------------
#

exec_fn="ref2tten.exe"
exec_fp="${EXECdir}/${exec_fn}"

if [ ! -f "${exec_fp}" ]; then
  print_err_msg_exit "\
The executable specified in exec_fp does not exist:
  exec_fp = \"${exec_fp}\"
Build lightning process and rerun."
fi
#
#
#-----------------------------------------------------------------------
#
# Run the radar to tten application.  
#
#-----------------------------------------------------------------------
#
PREP_STEP
eval $RUN_CMD_UTILS ${exec_fp} ${REDIRECT_OUT_ERR} print_err_msg_exit "\
Call to executable to run radar refl tten returned with nonzero exit code."
POST_STEP
#
#-----------------------------------------------------------------------
#
# Print message indicating successful completion of script.
#
#-----------------------------------------------------------------------
#
print_info_msg "
========================================================================
RADAR REFL TTEN PROCESS completed successfully!!!

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
