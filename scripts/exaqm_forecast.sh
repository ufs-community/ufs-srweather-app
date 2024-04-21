#!/bin/bash

set -x

msg="JOB $job HAS BEGUN"
postmsg "$msg"
   
export pgm=aqm_fcst

#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. $USHaqm/source_util_funcs.sh
source_config_for_task "task_run_fcst|task_run_post|task_get_extrn_ics|task_get_extrn_lbcs" ${GLOBAL_VAR_DEFNS_FP}
#
#-----------------------------------------------------------------------
#
# Save current shell options (in a global array).  Then set new options
# for this script/function.
#
#-----------------------------------------------------------------------
#
{ save_shell_opts; . $USHaqm/preamble.sh; } > /dev/null 2>&1
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

This is the ex-script for the task that runs a forecast with FV3 for the
specified cycle.
========================================================================"
#
#-----------------------------------------------------------------------
#
# Set environment variables.
#
#-----------------------------------------------------------------------
#
export KMP_AFFINITY=${KMP_AFFINITY_RUN_FCST}
export OMP_NUM_THREADS=${OMP_NUM_THREADS_RUN_FCST}
export OMP_STACKSIZE=${OMP_STACKSIZE_RUN_FCST}
export MPI_TYPE_DEPTH=20
export ESMF_RUNTIME_COMPLIANCECHECK=OFF:depth=4
if [ "${PRINT_ESMF}" = "TRUE" ]; then
  export ESMF_RUNTIME_PROFILE=ON
  export ESMF_RUNTIME_PROFILE_OUTPUT="SUMMARY"
fi
#
#-----------------------------------------------------------------------
#
# Checking fcst CMD.
#
#-----------------------------------------------------------------------
#
eval ${PRE_TASK_CMDS}

nprocs=$(( NNODES_RUN_FCST*PPN_RUN_FCST ))

if [ -z "${RUN_CMD_FCST:-}" ] ; then
  print_err_msg_exit "\
  Run command was not set in machine file. \
  Please set RUN_CMD_FCST for your platform"
else
  print_info_msg "$VERBOSE" "
  All executables will be submitted with command \'${RUN_CMD_FCST}\'."
fi

if [ ${#FCST_LEN_CYCL[@]} -gt 1 ]; then
  cyc_mod=$(( ${cyc} - ${DATE_FIRST_CYCL:8:2} ))
  CYCLE_IDX=$(( ${cyc_mod} / ${INCR_CYCL_FREQ} ))
  FCST_LEN_HRS=${FCST_LEN_CYCL[$CYCLE_IDX]}
fi
#
#-----------------------------------------------------------------------
#
# Create links in the INPUT subdirectory of the current run directory to
# the grid and (filtered) orography files.
#
#-----------------------------------------------------------------------
#
print_info_msg "$VERBOSE" "
Creating links in the INPUT subdirectory of the current run directory to
the grid and (filtered) orography files ..."

# Create links to fix files in the FIXlam directory.
cd $DATA
ln -s $FIXaqm  .

cd ${DATA}/INPUT

#
# For experiments in which the TN_MAKE_GRID task is run, we make the 
# symlinks to the grid files relative because those files wlll be located 
# within the experiment directory.  This keeps the experiment directory 
# more portable and the symlinks more readable.  However, for experiments 
# in which the TN_MAKE_GRID task is not run, pregenerated grid files will
# be used, and those will be located in an arbitrary directory (specified 
# by the user) that is somwehere outside the experiment directory.  Thus, 
# in this case, there isn't really an advantage to using relative symlinks, 
# so we use symlinks with absolute paths.
#
if [ "${RUN_TASK_MAKE_GRID}" = "TRUE" ]; then
  relative_link_flag="TRUE"
else
  relative_link_flag="FALSE"
fi

# Symlink to mosaic file with a completely different name.
target="${FIXlam}/${CRES}${DOT_OR_USCORE}mosaic.halo${NH3}.nc"   # Should this point to this halo4 file or a halo3 file???
symlink="grid_spec.nc"
create_symlink_to_file target="$target" symlink="$symlink" \
                       relative="${relative_link_flag}"

# Symlink to halo-3 grid file with "halo3" stripped from name.
mosaic_fn="grid_spec.nc"
grid_fn=$( get_charvar_from_netcdf "${mosaic_fn}" "gridfiles" )

target="${FIXlam}/${grid_fn}"
symlink="${grid_fn}"
create_symlink_to_file target="$target" symlink="$symlink" \
                       relative="${relative_link_flag}"

# Symlink to halo-4 grid file with "${CRES}_" stripped from name.
#
# If this link is not created, then the code hangs with an error message
# like this:
#
#  check netcdf status=           2
#  NetCDF error No such file or directory
# Stopped
#
# Note that even though the message says "Stopped", the task still con-
# sumes core-hours.
#
target="${FIXlam}/${CRES}${DOT_OR_USCORE}grid.tile${TILE_RGNL}.halo${NH4}.nc"
symlink="grid.tile${TILE_RGNL}.halo${NH4}.nc"
create_symlink_to_file target="$target" symlink="$symlink" \
                       relative="${relative_link_flag}"


#
# As with the symlinks grid files above, when creating the symlinks to
# the orography files, use relative paths if running the TN_MAKE_OROG
# task and absolute paths otherwise.
#
if [ "${RUN_TASK_MAKE_OROG}" = "TRUE" ]; then
  relative_link_flag="TRUE"
else
  relative_link_flag="FALSE"
fi

# Symlink to halo-0 orography file with "${CRES}_" and "halo0" stripped from name.
target="${FIXlam}/${CRES}${DOT_OR_USCORE}oro_data.tile${TILE_RGNL}.halo${NH0}.nc"
symlink="oro_data.nc"
create_symlink_to_file target="$target" symlink="$symlink" \
                       relative="${relative_link_flag}"
#
# Symlink to halo-4 orography file with "${CRES}_" stripped from name.
#
# If this link is not created, then the code hangs with an error message
# like this:
#
#   check netcdf status=           2
#  NetCDF error No such file or directory
# Stopped
#
# Note that even though the message says "Stopped", the task still con-
# sumes core-hours.
#
target="${FIXlam}/${CRES}${DOT_OR_USCORE}oro_data.tile${TILE_RGNL}.halo${NH4}.nc"
symlink="oro_data.tile${TILE_RGNL}.halo${NH4}.nc"
create_symlink_to_file target="$target" symlink="$symlink" \
                       relative="${relative_link_flag}"
#
# If using the FV3_HRRR physics suite, there are two files (that contain 
# statistics of the orography) that are needed by the gravity wave drag 
# parameterization in that suite.  Below, create symlinks to these files
# in the run directory.  Note that the symlinks must have specific names 
# that the FV3 model is hardcoded to recognize, and those are the names 
# we use below.
#
suites=( "FV3_HRRR" "FV3_GFS_v15_thompson_mynn_lam3km" "FV3_GFS_v17_p8" )
if [[ ${suites[@]} =~ "${CCPP_PHYS_SUITE}" ]] ; then
  file_ids=( "ss" "ls" )
  for file_id in "${file_ids[@]}"; do
    target="${FIXlam}/${CRES}${DOT_OR_USCORE}oro_data_${file_id}.tile${TILE_RGNL}.halo${NH0}.nc"
    symlink="oro_data_${file_id}.nc"
    create_symlink_to_file target="$target" symlink="$symlink" \
                           relative="${relative_link_flag}"
  done
fi
#
#-----------------------------------------------------------------------
#
print_info_msg "$VERBOSE" "
Creating links with names that FV3 looks for in the INPUT subdirectory
of the current run directory (DATA), where
  DATA = \"${DATA}\"
..."

cd ${DATA}/INPUT

#
# The symlinks to be created point to files in the same directory (INPUT),
# so it's most straightforward to use relative paths.
#
relative_link_flag="FALSE"

target="${INPUT_DATA}/${NET}.${cycle}${dot_ensmem}.gfs_data.tile${TILE_RGNL}.halo${NH0}.nc"
symlink="gfs_data.nc"
create_symlink_to_file target="$target" symlink="$symlink" \
                       relative="${relative_link_flag}"

target="${INPUT_DATA}/${NET}.${cycle}${dot_ensmem}.sfc_data.tile${TILE_RGNL}.halo${NH0}.nc"
symlink="sfc_data.nc"
create_symlink_to_file target="$target" symlink="$symlink" \
                       relative="${relative_link_flag}"

target="${INPUT_DATA}/${NET}.${cycle}${dot_ensmem}.gfs_ctrl.nc"
symlink="gfs_ctrl.nc"
create_symlink_to_file target="$target" symlink="$symlink" \
                       relative="${relative_link_flag}"


for fhr in $(seq -f "%03g" 0 ${LBC_SPEC_INTVL_HRS} ${FCST_LEN_HRS}); do
  target="${INPUT_DATA}/${NET}.${cycle}${dot_ensmem}.gfs_bndy.tile${TILE_RGNL}.f${fhr}.nc"
  symlink="gfs_bndy.tile${TILE_RGNL}.${fhr}.nc"
  create_symlink_to_file target="$target" symlink="$symlink" \
                         relative="${relative_link_flag}"
done

if [ "${CPL_AQM}" = "TRUE" ]; then
  target="${INPUT_DATA}/${NET}.${cycle}${dot_ensmem}.NEXUS_Expt.nc"
  symlink="NEXUS_Expt.nc"
  create_symlink_to_file target="$target" symlink="$symlink" \
                       relative="${relative_link_flag}"

  # create symlink to PT for point source in Online-CMAQ
  if [ "${RUN_TASK_POINT_SOURCE}" = "TRUE" ]; then
    target="${INPUT_DATA}/${NET}.${cycle}${dot_ensmem}.PT.nc"
    symlink="PT.nc"
    create_symlink_to_file target="$target" symlink="$symlink" \
	                       relative="${relative_link_flag}"
  fi
fi
#
#-----------------------------------------------------------------------
#
# Create links in the current run directory to fixed (i.e. static) files
# in the FIXam directory.  These links have names that are set to the
# names of files that the forecast model expects to exist in the current
# working directory when the forecast model executable is called (and
# that is just the run directory).
#
#-----------------------------------------------------------------------
#
cd ${DATA}

print_info_msg "$VERBOSE" "
Creating links in the current run directory (DATA) to fixed (i.e.
static) files in the FIXam directory:
  FIXam = \"${FIXam}\"
  DATA = \"${DATA}\""
#
# For experiments that are run in "community" mode, the FIXam directory
# is an actual directory (i.e. not a symlink) located under the experiment 
# directory containing actual files (i.e. not symlinks).  In this case,
# we use relative paths for the symlinks in order to keep the experiment
# directory more portable and the symlinks more readable.  However, for
# experiments that are run in "nco" mode, the FIXam directory is a symlink
# under the experiment directory that points to an arbitrary (user specified)
# location outside the experiment directory.  Thus, in this case, there 
# isn't really an advantage to using relative symlinks, so we use symlinks 
# with absolute paths.
#
if [ "${SYMLINK_FIX_FILES}" == "FALSE" ]; then
  relative_link_flag="TRUE"
else
  relative_link_flag="FALSE"
fi

regex_search="^[ ]*([^| ]+)[ ]*[|][ ]*([^| ]+)[ ]*$"
num_symlinks=${#CYCLEDIR_LINKS_TO_FIXam_FILES_MAPPING[@]}
for (( i=0; i<${num_symlinks}; i++ )); do

  mapping="${CYCLEDIR_LINKS_TO_FIXam_FILES_MAPPING[$i]}"
  symlink=$( printf "%s\n" "$mapping" | \
             $SED -n -r -e "s/${regex_search}/\1/p" )
  target=$( printf "%s\n" "$mapping" | \
            $SED -n -r -e "s/${regex_search}/\2/p" )

  symlink="${DATA}/$symlink"
  target="$FIXam/$target"
  create_symlink_to_file target="$target" symlink="$symlink" \
                         relative="${relative_link_flag}"

done
#
#-----------------------------------------------------------------------
#
# Create links in the current run directory to the MERRA2 aerosol 
# climatology data files and lookup table for optics properties.
#
#-----------------------------------------------------------------------
#
if [ "${USE_MERRA_CLIMO}" = "TRUE" ]; then
  for f_nm_path in ${FIXclim}/*; do
    f_nm=$( basename "${f_nm_path}" )
    pre_f="${f_nm%%.*}"

    if [ "${pre_f}" = "merra2" ]; then
      mnth=$( printf "%s\n" "${f_nm}" | grep -o -P '(?<=2014.m).*(?=.nc)' )
      symlink="${DATA}/aeroclim.m${mnth}.nc"
    else
      symlink="${DATA}/${pre_f}.dat"
    fi
    target="${f_nm_path}"
    create_symlink_to_file target="$target" symlink="$symlink" \
                         relative="${relative_link_flag}"
  done
fi
#
#-----------------------------------------------------------------------
#
cd ${DATA}
rm -f time_stamp.out
#
#-----------------------------------------------------------------------
#
# Create links in the current run directory to cycle-independent (and
# ensemble-member-independent) model input files in the main experiment
# directory.
#
#-----------------------------------------------------------------------
#
print_info_msg "$VERBOSE" "
Creating links in the current run directory to cycle-independent model
input files in the main experiment directory..."
#
# For experiments that are run in "community" mode, the model input files
# to which the symlinks will point are under the experiment directory.
# Thus, in this case, we use relative paths for the symlinks in order to 
# keep the experiment directory more portable and the symlinks more readable.  
# However, for experiments that are run in "nco" mode, the experiment
# directory in which the model input files are located is in general 
# completely different than the run directory in which the symlinks will
# be created.  Thus, in this case, there isn't really an advantage to 
# using relative symlinks, so we use symlinks with absolute paths.
#
relative_link_flag="FALSE"

#create_symlink_to_file target="${DATA_TABLE_FP}" \
#                       symlink="${DATA}/${DATA_TABLE_FN}" \
#                       relative="${relative_link_flag}"
if [[ ! -s ${DATA}/${DATA_TABLE_FN} ]]; then
  cat > ${DATA}/${DATA_TABLE_FN} << EOF
EOF
fi

create_symlink_to_file target="${FIELD_TABLE_FP}" \
                       symlink="${DATA}/${FIELD_TABLE_FN}" \
                       relative="${relative_link_flag}"

create_symlink_to_file target="${FIELD_DICT_FP}" \
                       symlink="${DATA}/${FIELD_DICT_FN}" \
                       relative="${relative_link_flag}"

if [ ${WRITE_DOPOST} = "TRUE" ]; then
  cpreq ${PARMdir}/upp/nam_micro_lookup.dat ./eta_micro_lookup.dat
  if [ ${USE_CUSTOM_POST_CONFIG_FILE} = "TRUE" ]; then
    post_config_fp="${CUSTOM_POST_CONFIG_FP}"
    print_info_msg "
====================================================================
  CUSTOM_POST_CONFIG_FP = \"${CUSTOM_POST_CONFIG_FP}\"
===================================================================="
  else
    if [ "${CPL_AQM}" = "TRUE" ]; then
      post_config_fp="${PARMdir}/upp/postxconfig-NT-AQM.txt"
    else
      post_config_fp="${PARMdir}/upp/postxconfig-NT-fv3lam.txt"
    fi
    print_info_msg "
====================================================================
  post_config_fp = \"${post_config_fp}\"
===================================================================="
  fi
  cpreq ${post_config_fp} ./postxconfig-NT_FH00.txt
  cpreq ${post_config_fp} ./postxconfig-NT.txt
  cpreq ${PARMdir}/upp/params_grib2_tbl_new .
  # Set itag for inline-post:
  if [ "${CPL_AQM}" = "TRUE" ]; then
    post_itag_add="aqf_on=.true.,"
  else
    post_itag_add=""
  fi
cat > itag <<EOF
&MODEL_INPUTS
 MODELNAME='FV3R'
/
&NAMPGB
 KPO=47,PO=1000.,975.,950.,925.,900.,875.,850.,825.,800.,775.,750.,725.,700.,675.,650.,625.,600.,575.,550.,525.,500.,475.,450.,425.,400.,375.,350.,325.,300.,275.,250.,225.,200.,175.,150.,125.,100.,70.,50.,30.,20.,10.,7.,5.,3.,2.,1.,${post_itag_add}
/
EOF
fi
#
#-----------------------------------------------------------------------
#
# Update or copy the FV3 input.nml file
#
#-----------------------------------------------------------------------
#
if [ "${DO_ENSEMBLE}" = TRUE ] && ([ "${DO_SPP}" = TRUE ] || [ "${DO_SPPT}" = TRUE ] || [ "${DO_SHUM}" = TRUE ] || \
   [ "${DO_SKEB}" = TRUE ] || [ "${DO_LSM_SPP}" =  TRUE ]); then
   $USHaqm/set_FV3nml_ens_stoch_seeds.py \
      --path-to-defns ${GLOBAL_VAR_DEFNS_FP} \
      --cdate "$CDATE"
  export err=$?
  if [ $err -ne 0 ]; then
    message_txt="FATAL ERROR Call to function to create the ensemble-based namelist
for the current cycle's (cdate) run directory (DATA) failed:
  cdate = \"${CDATE}\"
  DATA = \"${DATA}\""
      err_exit "${message_txt}"
  fi
else
  cpreq "${FV3_NML_FP}" "${DATA}/${FV3_NML_FN}"
fi
#
#-----------------------------------------------------------------------
#
# Replace parameter values for restart in FV3 input.nml and model_configure.
# Add restart files to INPUT directory.
#
#-----------------------------------------------------------------------
#
flag_fcst_restart="FALSE"
coupler_res_ct=0
if [ -d ${umbrella_forecast_data}/RESTART ]; then
  set +eu
  coupler_res_ct=$(eval ls -A ${umbrella_forecast_data}/RESTART/*.coupler.res|wc -l)
fi

if [ "${DO_FCST_RESTART}" = "TRUE" ] && [ $coupler_res_ct -gt 0 ] && [ $FCST_LEN_HRS -gt 6 ]; then
  relative_link_flag="FALSE"
  flag_fcst_restart="TRUE"

  # Update FV3 input.nml for restart
   $USHaqm/update_input_nml.py \
    --path-to-defns ${GLOBAL_VAR_DEFNS_FP} \
    --run_dir "${DATA}" \
    --restart
  export err=$?
  if [ $err -ne 0 ]; then
    message_txt="FATAL ERROR Call to function to update the FV3 input.nml file for restart 
for the current cycle's (cdate) run directory (DATA) failed:
  cdate = \"${CDATE}\"
  DATA = \"${DATA}\""
      err_exit "${message_txt}"
  fi

  # Check that restart files exist at restart_interval
  file_ids=( "coupler.res" "fv_core.res.nc" "fv_core.res.tile1.nc" "fv_srf_wnd.res.tile1.nc" "fv_tracer.res.tile1.nc" "phy_data.nc" "sfc_data.nc" )
  num_file_ids=${#file_ids[*]}
  IFS=' '
  read -a restart_hrs <<< "${RESTART_INTERVAL}"
  num_restart_hrs=${#restart_hrs[*]}
  
  for (( ih_rst=${num_restart_hrs}-1; ih_rst>=0; ih_rst-- )); do
    cdate_restart_hr=`$NDATE +${restart_hrs[ih_rst]} ${PDY}${cyc}` 
    rst_yyyymmdd="${cdate_restart_hr:0:8}"
    rst_hh="${cdate_restart_hr:8:2}"

    num_rst_files=0
    for file_id in "${file_ids[@]}"; do
      if [ -e "${umbrella_forecast_data}/RESTART/${rst_yyyymmdd}.${rst_hh}0000.${file_id}" ]; then
        (( num_rst_files=num_rst_files+1 ))
      fi
    done
    if [ "${num_rst_files}" = "${num_file_ids}" ]; then
      FHROT="${restart_hrs[ih_rst]}"
      break
    fi
  done

  # Create soft-link of restart files in INPUT directory
  cd ${DATA}/INPUT
  for file_id in "${file_ids[@]}"; do
    if [ -e "${file_id}" ]; then
      rm -f "${file_id}"
    fi
    target="${umbrella_forecast_data}/RESTART/${rst_yyyymmdd}.${rst_hh}0000.${file_id}"
    symlink="${file_id}"
    create_symlink_to_file target="$target" symlink="$symlink" relative="${relative_link_flag}"
  done
  cd ${DATA}   
fi

#
#-----------------------------------------------------------------------
#
# Setup air quality model cold/warm start
#
#-----------------------------------------------------------------------
#
if [ "${CPL_AQM}" = "TRUE" ]; then
  if [ "${COLDSTART}" = "TRUE" ] && [ "${PDY}${cyc}" = "${DATE_FIRST_CYCL:0:10}" ] && [ "${flag_fcst_restart}" = "FALSE" ]; then
    init_concentrations="false"
  else
    init_concentrations="false"
  fi
#
#-----------------------------------------------------------------------
#
# Call the function that creates the aqm.rc file within each
# cycle directory.
#
#-----------------------------------------------------------------------
#
  $USHaqm/create_aqm_rc_file.py \
    --path-to-defns ${GLOBAL_VAR_DEFNS_FP} \
    --cdate "$CDATE" \
    --run-dir "${DATA}" \
    --init_concentrations "${init_concentrations}"
  export err=$?
  if [ $err -ne 0 ]; then
    message_txt="FATAL ERROR Call to function to create an aqm.rc file for the current
cycle's (cdate) run directory (DATA) failed:
  cdate = \"${CDATE}\"
  DATA = \"${DATA}\""
      err_exit "${message_txt}"
  fi
fi
#
#-----------------------------------------------------------------------
#
# Call the function that creates the model configuration file within each
# cycle directory.
#
#-----------------------------------------------------------------------
#
 $USHaqm/create_model_configure_file.py \
  --path-to-defns ${GLOBAL_VAR_DEFNS_FP} \
  --cdate "$CDATE" \
  --fcst_len_hrs "${FCST_LEN_HRS}" \
  --fhrot "${FHROT}" \
  --run-dir "${DATA}" \
  --sub-hourly-post "${SUB_HOURLY_POST}" \
  --dt-subhourly-post-mnts "${DT_SUBHOURLY_POST_MNTS}" \
  --dt-atmos "${DT_ATMOS}"
export err=$?
if [ $err -ne 0 ]; then
  message_txt="FATAL ERROR Call to function to create a model configuration file 
for the current cycle's (cdate) run directory (DATA) failed:
  cdate = \"${CDATE}\"
  DATA = \"${DATA}\""
    err_exit "${message_txt}"
fi
#
#-----------------------------------------------------------------------
#
# Call the function that creates the diag_table file within each cycle 
# directory.
#
#-----------------------------------------------------------------------
#
 $USHaqm/create_diag_table_file.py \
  --path-to-defns ${GLOBAL_VAR_DEFNS_FP} \
  --run-dir "${DATA}"
export err=$?
if [ $err -ne 0 ]; then
  message_txt="FATAL ERROR Call to function to create a diag table file for the current 
cycle's (cdate) run directory (DATA) failed:
  DATA = \"${DATA}\""
    err_exit "${message_txt}"
fi
#
#-----------------------------------------------------------------------
#
# Call the function that creates the NEMS configuration file within each
# cycle directory.
#
#-----------------------------------------------------------------------
#
 $USHaqm/create_nems_configure_file.py \
  --path-to-defns ${GLOBAL_VAR_DEFNS_FP} \
  --run-dir "${DATA}"
export err=$?
if [ $err -ne 0 ]; then
  message_txt="FATAL ERROR Call to function to create a NEMS configuration file for 
the current cycle's (cdate) run directory (DATA) failed:
  DATA = \"${DATA}\""
  err_exit "${message_txt}"
fi
#
#-----------------------------------------------------------------------
#
# make symbolic links to write forecast files directly in shared forecast output location
#   $DATAROOT/$RUN_forecast_$PDY_$cyc_$aqm_ver/output
#-----------------------------------------------------------------------
#
shared_output_data=${umbrella_forecast_data}/output
mkdir -p ${shared_output_data}
fhr_ct=0
fhr=0
NLN=${NLN:-"/bin/ln -sf"}
while [ $fhr -le ${FCST_LEN_HRS} ]; do
  fhr_ct=$(printf "%03d" $fhr)
  source_dyn="dynf${fhr_ct}.nc"
  source_phy="phyf${fhr_ct}.nc"
  source_log="logf${fhr_ct}"
  target_dyn="${shared_output_data}/${NET}.${cycle}${dot_ensmem}.dyn.f${fhr_ct}.nc"
  target_phy="${shared_output_data}/${NET}.${cycle}${dot_ensmem}.phy.f${fhr_ct}.nc"
  target_log="${shared_output_data}/${NET}.${cycle}${dot_ensmem}.logf${fhr_ct}"
  eval $NLN ${target_dyn} ${source_dyn}
  eval $NLN ${target_phy} ${source_phy}
  eval $NLN ${target_log} ${source_log}
  (( fhr=fhr+1 ))
done
#
#-----------------------------------------------------------------------
# make symbolic links to write forecast RESTART files directly to shared forecast RESTART location
#   $DATAROOT/$RUN_forecast_$PDY_$cyc_$aqm_ver/RESTART
#-----------------------------------------------------------------------
#
shared_restart_data=${umbrella_forecast_data}/RESTART
mkdir -p ${shared_restart_data}
cd ${DATA}/RESTART
[[ -e ${umbrella_forecast_data}/clean.flag ]] && rm -f ${umbrella_forecast_data}/clean.flag
file_ids=( "coupler.res" "fv_core.res.nc" "fv_core.res.tile1.nc" "fv_srf_wnd.res.tile1.nc" "fv_tracer.res.tile1.nc" "phy_data.nc" "sfc_data.nc" )
num_file_ids=${#file_ids[*]}
read -a restart_hrs <<< "${RESTART_INTERVAL}"
num_restart_hrs=${#restart_hrs[*]}
# 06Z and 12Z
if [ $cyc = 06 -o $cyc = 12 ]; then
  # 06Z and 12Z
  for (( ih_rst=${num_restart_hrs}-1; ih_rst>=0; ih_rst-- )); do
    cdate_restart_hr=`$NDATE +${restart_hrs[ih_rst]} ${PDY}${cyc}`
    rst_yyyymmdd="${cdate_restart_hr:0:8}"
    rst_hh="${cdate_restart_hr:8:2}"
    for file_id in "${file_ids[@]}"; do
      eval $NLN ${shared_restart_data}/${rst_yyyymmdd}.${rst_hh}0000.${file_id} ${rst_yyyymmdd}.${rst_hh}0000.${file_id}
    done
  done
else
  # 00Z and 18Z
  cdate_restart_hr=`$NDATE +6 ${PDY}${cyc}`
  rst_yyyymmdd="${cdate_restart_hr:0:8}"
  rst_hh="${cdate_restart_hr:8:2}"
  for file_id in "${file_ids[@]}"; do
    eval $NLN ${shared_restart_data}/${rst_yyyymmdd}.${rst_hh}0000.${file_id} ${file_id}
  done
fi

ecflow_client --event release_manager
cd ${DATA}
#
#-----------------------------------------------------------------------
#
# Run the FV3-LAM model.  Note that we have to launch the forecast from
# the current cycle's directory because the FV3 executable will look for
# input files in the current directory.  Since those files have been
# staged in the cycle directory, the current directory must be the cycle
# directory (which it already is).
#
#-----------------------------------------------------------------------
#
startmsg
eval ${RUN_CMD_FCST} ${FV3_EXEC_FP} ${REDIRECT_OUT_ERR} >> $pgmout 2>errfile
export err=$?; err_chk
if [ -e "$pgmout" ]; then
   cat $pgmout
fi


eval cpreq ${AQM_RC_PRODUCT_FN} ${COMOUT}/${NET}.${cycle}${dot_ensmem}.${AQM_RC_PRODUCT_FN}
echo "Forecast job is completed" &> ${umbrella_forecast_data}/clean.flag
#
#-----------------------------------------------------------------------
#
# Print message indicating successful completion of script.
#
#-----------------------------------------------------------------------
#
print_info_msg "
========================================================================
FV3 forecast completed successfully!!!

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

