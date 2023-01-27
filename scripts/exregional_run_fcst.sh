#!/bin/bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. $USHdir/source_util_funcs.sh
source_config_for_task "task_run_fcst|task_run_post|task_get_extrn_lbcs" ${GLOBAL_VAR_DEFNS_FP}
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

This is the ex-script for the task that runs a forecast with FV3 for the
specified cycle.
========================================================================"
#
#-----------------------------------------------------------------------
#
# Set OpenMP variables.
#
#-----------------------------------------------------------------------
#
export KMP_AFFINITY=${KMP_AFFINITY_RUN_FCST}
export OMP_NUM_THREADS=${OMP_NUM_THREADS_RUN_FCST}
export OMP_STACKSIZE=${OMP_STACKSIZE_RUN_FCST}
#
#-----------------------------------------------------------------------
#
# Load modules.
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

gridspec_dir=${NWGES_BASEDIR}/grid_spec
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


cd_vrfy ${DATA}/INPUT

#
# For experiments in which the MAKE_GRID_TN task is run, we make the 
# symlinks to the grid files relative because those files wlll be located 
# within the experiment directory.  This keeps the experiment directory 
# more portable and the symlinks more readable.  However, for experiments 
# in which the MAKE_GRID_TN task is not run, pregenerated grid files will
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
#target="${FIXlam}/${CRES}${DOT_OR_USCORE}mosaic.halo${NH4}.nc"   # Should this point to this halo4 file or a halo3 file???
target="${FIXlam}/${CRES}${DOT_OR_USCORE}mosaic.halo${NH3}.nc"   # Should this point to this halo4 file or a halo3 file???
symlink="grid_spec.nc"
create_symlink_to_file target="$target" symlink="$symlink" \
                       relative="${relative_link_flag}"

## Symlink to halo-3 grid file with "halo3" stripped from name.
#target="${FIXlam}/${CRES}${DOT_OR_USCORE}grid.tile${TILE_RGNL}.halo${NH3}.nc"
#if [ "${RUN_TASK_MAKE_SFC_CLIMO}" = "TRUE" ] && \
#   [ "${GRID_GEN_METHOD}" = "GFDLgrid" ] && \
#   [ "${GFDLgrid_USE_NUM_CELLS_IN_FILENAMES}" = "FALSE" ]; then
#  symlink="C${GFDLgrid_NUM_CELLS}${DOT_OR_USCORE}grid.tile${TILE_RGNL}.nc"
#else
#  symlink="${CRES}${DOT_OR_USCORE}grid.tile${TILE_RGNL}.nc"
#fi

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
#   check netcdf status=           2
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
# the orography files, use relative paths if running the MAKE_OROG_TN
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
if [ "${CCPP_PHYS_SUITE}" = "FV3_HRRR" ] || \
   [ "${CCPP_PHYS_SUITE}" = "FV3_RAP" ]  || \
   [ "${CCPP_PHYS_SUITE}" = "FV3_GFS_v15_thompson_mynn_lam3km" ]; then

  fileids=( "ss" "ls" )
  for fileid in "${fileids[@]}"; do
    target="${FIXlam}/${CRES}${DOT_OR_USCORE}oro_data_${fileid}.tile${TILE_RGNL}.halo${NH0}.nc"
    symlink="oro_data_${fileid}.nc"
    create_symlink_to_file target="$target" symlink="$symlink" \
                           relative="${relative_link_flag}"
  done

fi

#
#-----------------------------------------------------------------------
#
# The FV3 model looks for the following files in the INPUT subdirectory
# of the run directory:
#
#   gfs_data.nc
#   sfc_data.nc
#   gfs_bndy*.nc
#   gfs_ctrl.nc
#
# Some of these files (gfs_ctrl.nc, gfs_bndy*.nc) already exist, but
# others do not.  Thus, create links with these names to the appropriate
# files (in this case the initial condition and surface files only).
#
#-----------------------------------------------------------------------
#
print_info_msg "$VERBOSE" "
Creating links with names that FV3 looks for in the INPUT subdirectory
of the current run directory (DATA), where
  DATA = \"${DATA}\"
..."

cd_vrfy ${DATA}/INPUT

#
# Forecast background
#
BKTYPE=1    # cold start using INPUT
if [ -r ${DATA}/INPUT/coupler.res ] ; then
  BKTYPE=0  # cycling using RESTART
fi
print_info_msg "$VERBOSE" "
The forecast has BKTYPE $BKTYPE (1:cold start ; 0 cycling)"

n_iolayouty=$(($IO_LAYOUT_Y-1))
list_iolayout=$(seq 0 $n_iolayouty)

if [ $DO_RRFS_DEV = "FALSE" ]; then
   PREFIX="${NET}.${cycle}${dot_ensmem}."
else
   PREFIX=""
fi
#
# The symlinks to be created point to files in the same directory (INPUT),
# so it's most straightforward to use relative paths.
#
relative_link_flag="FALSE"

if [ ${BKTYPE} -eq 1 ]; then
    target="${INPUT_DATA}/${PREFIX}gfs_data.tile${TILE_RGNL}.halo${NH0}.nc"
else
    target="fv_core.res.tile1.nc"
fi
symlink="gfs_data.nc"
if [ -f "${target}.0000" ]; then
  for ii in ${list_iolayout}
  do
    iii=$(printf %4.4i $ii)
    create_symlink_to_file target="$target.${iii}" symlink="$symlink.${iii}" \
                       relative="${relative_link_flag}"
  done
else
    create_symlink_to_file target="$target" symlink="$symlink" \
                       relative="${relative_link_flag}"
fi

#
# Symlink sfc data
#
if [ ${BKTYPE} -eq 1 ]; then
  target="${INPUT_DATA}/${PREFIX}sfc_data.tile${TILE_RGNL}.halo${NH0}.nc"
  symlink="sfc_data.nc"
  create_symlink_to_file target="$target" symlink="$symlink" \
                         relative="${relative_link_flag}"
else
  if [ -f "sfc_data.nc.0000" ] || [ -f "sfc_data.nc" ]; then
    print_info_msg "$VERBOSE" "
    sfc_data.nc is available at INPUT directory"
  else
    print_err_msg_exit "\
    sfc_data.nc is not available for cycling"
  fi
fi

#
# Symlink gfs_ctrl and bndy data
#
if [ $DO_RRFS_DEV = "FALSE" ]; then
  target="${INPUT_DATA}/${PREFIX}gfs_ctrl.nc"
  symlink="gfs_ctrl.nc"
  create_symlink_to_file target="$target" symlink="$symlink" \
                         relative="${relative_link_flag}"
  
  
  for fhr in $(seq -f "%03g" 0 ${LBC_SPEC_INTVL_HRS} ${FCST_LEN_HRS}); do
    target="${INPUT_DATA}/${PREFIX}gfs_bndy.tile${TILE_RGNL}.f${fhr}.nc"
    symlink="gfs_bndy.tile${TILE_RGNL}.${fhr}.nc"
    create_symlink_to_file target="$target" symlink="$symlink" \
                           relative="${relative_link_flag}"
  done
fi

#
# Smoke and dust
#
if [ "${DO_SMOKE_DUST}" = "TRUE" ]; then
  ln_vrfy -snf  ${FIXsmoke}/${PREDEF_GRID_NAME}/dust12m_data.nc  ${DATA}/INPUT/dust12m_data.nc
  ln_vrfy -snf  ${FIXsmoke}/${PREDEF_GRID_NAME}/emi_data.nc      ${DATA}/INPUT/emi_data.nc
  yyyymmddhh=${cdate:0:10}
  echo ${yyyymmddhh}
  if [ ${CYCLE_TYPE} == "spinup" ]; then
    smokefile=${NWGES_BASEDIR}/RAVE_INTP/SMOKE_RRFS_data_${yyyymmddhh}00_spinup.nc
  else
    smokefile=${NWGES_BASEDIR}/RAVE_INTP/SMOKE_RRFS_data_${yyyymmddhh}00.nc
  fi
  echo "try to use smoke file=",${smokefile}
  if [ -f ${smokefile} ]; then
    ln_vrfy -snf ${smokefile} ${DATA}/INPUT/SMOKE_RRFS_data.nc
  else
    ln_vrfy -snf ${FIXsmoke}/${PREDEF_GRID_NAME}/dummy_24hr_smoke.nc ${DATA}/INPUT/SMOKE_RRFS_data.nc
    echo "smoke file is not available, use dummy_24hr_smoke.nc instead"
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
cd_vrfy ${DATA}

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
# If running this cycle/ensemble member combination more than once (e.g.
# using rocotoboot), remove any time stamp file that may exist from the
# previous attempt.
#
#-----------------------------------------------------------------------
#
cd_vrfy ${DATA}
rm_vrfy -f time_stamp.out
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
if [ "${RUN_ENVIR}" != "nco" ]; then
  relative_link_flag="TRUE"
else
  relative_link_flag="FALSE"
fi

create_symlink_to_file target="${DATA_TABLE_FP}" \
                       symlink="${DATA}/${DATA_TABLE_FN}" \
                       relative="${relative_link_flag}"

create_symlink_to_file target="${FIELD_TABLE_FP}" \
                       symlink="${DATA}/${FIELD_TABLE_FN}" \
                       relative="${relative_link_flag}"

create_symlink_to_file target="${NEMS_CONFIG_FP}" \
                       symlink="${DATA}/${NEMS_CONFIG_FN}" \
                       relative="${relative_link_flag}"

create_symlink_to_file target="${FIELD_DICT_FP}" \
                       symlink="${DATA}/${FIELD_DICT_FN}" \
                       relative="${relative_link_flag}"

if [ ${WRITE_DOPOST} = "TRUE" ]; then
  cp_vrfy ${PARMdir}/upp/nam_micro_lookup.dat ./eta_micro_lookup.dat
  if [ ${USE_CUSTOM_POST_CONFIG_FILE} = "TRUE" ]; then
    post_config_fp="${CUSTOM_POST_CONFIG_FP}"
    post_params_fp="${CUSTOM_POST_PARAMS_FP}"
    print_info_msg "
====================================================================
  CUSTOM_POST_CONFIG_FP = \"${CUSTOM_POST_CONFIG_FP}\"
  CUSTOM_POST_PARAMS_FP = \"${CUSTOM_POST_PARAMS_FP}\"
===================================================================="
  else
    if [ ${FCST_MODEL} = "fv3gfs_aqm" ]; then
      post_config_fp="${PARMdir}/upp/postxconfig-NT-fv3lam_cmaq.txt"
      post_params_fp="${PARMdir}/upp/params_grib2_tbl_new_cmaq"
    else
      post_config_fp="${PARMdir}/upp/postxconfig-NT-fv3lam.txt"
      post_params_fp="${PARMdir}/upp/params_grib2_tbl_new"
    fi
    print_info_msg "
====================================================================
  post_config_fp = \"${post_config_fp}\"
  post_params_fp = \"${post_params_fp}\"
===================================================================="
  fi
  cp_vrfy ${post_config_fp} ./postxconfig-NT_FH00.txt
  cp_vrfy ${post_config_fp} ./postxconfig-NT.txt
  cp_vrfy ${post_params_fp} ./params_grib2_tbl_new
  # Set itag for inline-post:
cat > itag <<EOF
&MODEL_INPUTS
 MODELNAME='FV3R'
/
&NAMPGB
 KPO=47,PO=1000.,975.,950.,925.,900.,875.,850.,825.,800.,775.,750.,725.,700.,675.,650.,625.,600.,575.,550.,525.,500.,475.,450.,425.,400.,375.,350.,325.,300.,275.,250.,225.,200.,175.,150.,125.,100.,70.,50.,30.,20.,10.,7.,5.,3.,2.,1.,
/
EOF
fi

#
#-----------------------------------------------------------------------
#
# Choose namelist file to use
#
#-----------------------------------------------------------------------
#
STOCH="FALSE"
if [ "${DO_ENSEMBLE}" = "TRUE" ] && ([ "${DO_SPP}" = "TRUE" ] || [ "${DO_SPPT}" = "TRUE" ] || [ "${DO_SHUM}" = "TRUE" ] || \
   [ "${DO_SKEB}" = "TRUE" ] || [ "${DO_LSM_SPP}" =  "TRUE" ]); then

   if [ "${DO_RRFS_DEV}" = "TRUE" ]; then
     for cyc_start in "${CYCL_HRS_STOCH[@]}"; do
       if [ ${HH} -eq ${cyc_start} ]; then 
         STOCH="TRUE"
       fi
     done
   else
     STOCH="TRUE"
   fi

fi

if [ ${BKTYPE} -eq 0 ]; then
  # cycling, using namelist for cycling forecast
  if [ "${STOCH}" == "TRUE" ]; then
    ln_vrfy -sf ${FV3_NML_RESTART_STOCH_FP} ${DATA}/${FV3_NML_FN}
   else
    ln_vrfy -sf ${FV3_NML_RESTART_FP} ${DATA}/${FV3_NML_FN}
  fi
else
  if [ -f "INPUT/cycle_surface.done" ]; then
    # namelist for cold start with surface cycle
    ln_vrfy -sf ${FV3_NML_CYCSFC_FP} ${DATA}/${FV3_NML_FN}
  else
    # cold start, using namelist for cold start
    if [ "${STOCH}" == "TRUE" ]; then
      ln_vrfy -sf ${FV3_NML_STOCH_FP} ${DATA}/${FV3_NML_FN}
     else
      ln_vrfy -sf ${FV3_NML_FP} ${DATA}/${FV3_NML_FN}
    fi
  fi
fi

if [ "$STOCH" == "TRUE" ]; then
  cp_vrfy ${DATA}/${FV3_NML_FN} ${DATA}/${FV3_NML_FN}_base
  python3 $USHdir/set_FV3nml_ens_stoch_seeds.py \
      --path-to-defns ${GLOBAL_VAR_DEFNS_FP} \
      --cdate "$CDATE" || print_err_msg_exit "\
Call to function to create the ensemble-based namelist for the current
cycle's (cdate) run directory (DATA) failed:
  cdate = \"${CDATE}\"
  DATA = \"${DATA}\""
fi

#
#-----------------------------------------------------------------------
#
# Call the function that creates the model configuration file within each
# cycle directory.
#
#-----------------------------------------------------------------------
#
python3 $USHdir/create_model_configure_file.py \
  --path-to-defns ${GLOBAL_VAR_DEFNS_FP} \
  --cdate "$CDATE" \
  --run-dir "${DATA}" \
  --cyc "$cyc" \
  --cycle-type "${CYCLE_TYPE:-prod}" \
  --cycle-subtype "${CYCLE_SUBTYPE:-empty}" \
  --sub-hourly-post "${SUB_HOURLY_POST}" \
  --dt-subhourly-post-mnts "${DT_SUBHOURLY_POST_MNTS}" \
  --dt-atmos "${DT_ATMOS}" || print_err_msg_exit "\
Call to function to create a model configuration file for the current
cycle's (cdate) run directory (DATA) failed:
  cdate = \"${CDATE}\"
  DATA = \"${DATA}\""
#
#-----------------------------------------------------------------------
#
# Call the function that creates the diag_table file within each cycle 
# directory.
#
#-----------------------------------------------------------------------
#
python3 $USHdir/create_diag_table_file.py \
  --path-to-defns ${GLOBAL_VAR_DEFNS_FP} \
  --run-dir "${DATA}" || print_err_msg_exit "\
Call to function to create a diag table file for the current cycle's 
(cdate) run directory (DATA) failed:
  DATA = \"${DATA}\""
#
#-----------------------------------------------------------------------
#
# If INPUT/phy_data.nc exists, convert it from NetCDF4 to NetCDF3
# (happens for cycled runs, not cold-started)
#
#-----------------------------------------------------------------------
#
if [[ -f phy_data.nc ]] ; then
  echo "convert phy_data.nc from NetCDF4 to NetCDF3"
  cd INPUT
  rm -f phy_data.nc3 phy_data.nc4
  cp -fp phy_data.nc phy_data.nc4
  if ( ! time ( module purge ; module load intel szip hdf5 netcdf nco ; module list ; set -x ; ncks -3 --64 phy_data.nc4 phy_data.nc3) ) ; then
    mv -f phy_data.nc4 phy_data.nc
    rm -f phy_data.nc3
    echo "NetCDF 4=>3 conversion failed. :-( Continuing with NetCDF 4 data."
  else
    mv -f phy_data.nc3 phy_data.nc
  fi
  cd ..
fi
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
PREP_STEP
eval ${RUN_CMD_FCST} ${FV3_EXEC_FP} ${REDIRECT_OUT_ERR} || print_err_msg_exit "\
Call to executable to run FV3-LAM forecast returned with nonzero exit
code."
POST_STEP
#
#-----------------------------------------------------------------------
#
# If doing inline post, create the directory in which the post-processing 
# output will be stored (postprd_dir).
#
#-----------------------------------------------------------------------
#
if [ ${WRITE_DOPOST} = "TRUE" ]; then
	
  yyyymmdd=${PDY}
  hh=${cyc}
  fmn="00"

  if [ "${RUN_ENVIR}" != "nco" ]; then
    export COMOUT="${DATA}/postprd"
  fi
  mkdir_vrfy -p "${COMOUT}"

  cd_vrfy ${COMOUT}

  for fhr in $(seq -f "%03g" 0 ${FCST_LEN_HRS}); do

    if [ ${fhr:0:1} = "0" ]; then
      fhr_d=${fhr:1:2}
    else
      fhr_d=${fhr}
    fi

    post_time=$( $DATE_UTIL --utc --date "${yyyymmdd} ${hh} UTC + ${fhr_d} hours + ${fmn} minutes" "+%Y%m%d%H%M" )
    post_mn=${post_time:10:2}
    post_mn_or_null=""
    post_fn_suffix="GrbF${fhr_d}"
    post_renamed_fn_suffix="f${fhr}${post_mn_or_null}.${POST_OUTPUT_DOMAIN_NAME}.grib2"

    fids=( "prslev" "natlev" )
    for fid in "${fids[@]}"; do
      FID=$(echo_uppercase $fid)
      post_orig_fn="${FID}.${post_fn_suffix}"
      post_renamed_fn="${NET}.${cycle}${dot_ensmem}.${fid}.${post_renamed_fn_suffix}"
 
      mv_vrfy ${DATA}/${post_orig_fn} ${post_renamed_fn}
      if [ $RUN_ENVIR != "nco" ]; then
        basetime=$( $DATE_UTIL --date "$yyyymmdd $hh" +%y%j%H%M )
        symlink_suffix="_${basetime}f${fhr}${post_mn}"
        create_symlink_to_file target="${post_renamed_fn}" \
                         symlink="${FID}${symlink_suffix}" \
	                 relative="TRUE"
      fi
      # DBN alert
      if [ $SENDDBN = "TRUE" ]; then
        $DBNROOT/bin/dbn_alert MODEL rrfs_post ${job} ${COMOUT}/${post_renamed_fn}
      fi
    done
  done

fi
#
#-----------------------------------------------------------------------
#
# Save grid_spec files for restart subdomain.
#
#-----------------------------------------------------------------------
#
if [ ${BKTYPE} -eq 1 ] && [ ${n_iolayouty} -ge 1 ]; then
  for ii in ${list_iolayout}
  do
    iii=$(printf %4.4i $ii)
    if [ -f "grid_spec.nc.${iii}" ]; then
      cp_vrfy grid_spec.nc.${iii} ${gridspec_dir}/fv3_grid_spec.${iii}
    else
      print_err_msg_exit "\
      Cannot create symlink because target does not exist:
      target = \"grid_spec.nc.$iii\""
    fi
  done
fi
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

