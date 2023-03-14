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

if [ -z "${RUN_CMD_FCST:-}" ] ; then
  print_err_msg_exit "\
  Run command was not set in machine file. \
  Please set RUN_CMD_FCST for your platform"
else
  print_info_msg "$VERBOSE" "
  All executables will be submitted with command \'${RUN_CMD_FCST}\'."
fi

if [ "${FCST_LEN_HRS}" = "-1" ]; then
  CYCLE_IDX=$(( ${cyc} / ${INCR_CYCL_FREQ} ))
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


cd_vrfy ${DATA}/INPUT

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
if [[ -d "${EXPTDIR}/grid" ]]; then
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
# the orography files, use relative paths if running the TN_MAKE_OROG
# task and absolute paths otherwise.
#
if [ -d "${EXPTDIR}/orog" ]; then
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
if [ "${CCPP_PHYS_SUITE}" = "FV3_HRRR" ] || [ "${CCPP_PHYS_SUITE}" = "FV3_GFS_v17_p8" ]; then

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
  target="${INPUT_DATA}/${NET}.${cycle}${dot_ensmem}.PT.nc"
  if [ -f ${target} ]; then
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

create_symlink_to_file target="${FIELD_DICT_FP}" \
                       symlink="${DATA}/${FIELD_DICT_FN}" \
                       relative="${relative_link_flag}"

if [ ${WRITE_DOPOST} = "TRUE" ]; then
  cp_vrfy ${PARMdir}/upp/nam_micro_lookup.dat ./eta_micro_lookup.dat
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
  cp_vrfy ${post_config_fp} ./postxconfig-NT_FH00.txt
  cp_vrfy ${post_config_fp} ./postxconfig-NT.txt
  cp_vrfy ${PARMdir}/upp/params_grib2_tbl_new .
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

if [ "${CPL_AQM}" = "TRUE" ]; then
#
#-----------------------------------------------------------------------
#
# Setup air quality model cold/warm start
#
#-----------------------------------------------------------------------
#
  init_concentrations="false"
  if [ "${COLDSTART}" = "TRUE" ] && [ "${PDY}${cyc}" = "${DATE_FIRST_CYCL:0:10}" ]; then
    init_concentrations="true"
  fi
#
#-----------------------------------------------------------------------
#
# Call the function that creates the aqm.rc file within each
# cycle directory.
#
#-----------------------------------------------------------------------
#
  python3 $USHdir/create_aqm_rc_file.py \
    --path-to-defns ${GLOBAL_VAR_DEFNS_FP} \
    --cdate "$CDATE" \
    --run-dir "${DATA}" \
    --init-concentration "${init_concentrations}" \
    || print_err_msg_exit "\
Call to function to create an aqm.rc file for the current
cycle's (cdate) run directory (DATA) failed:
  cdate = \"${CDATE}\"
  DATA = \"${DATA}\""
fi
#
#-----------------------------------------------------------------------
#

if [ "${DO_ENSEMBLE}" = TRUE ] && ([ "${DO_SPP}" = TRUE ] || [ "${DO_SPPT}" = TRUE ] || [ "${DO_SHUM}" = TRUE ] || \
   [ "${DO_SKEB}" = TRUE ] || [ "${DO_LSM_SPP}" =  TRUE ]); then
  python3 $USHdir/set_FV3nml_ens_stoch_seeds.py \
      --path-to-defns ${GLOBAL_VAR_DEFNS_FP} \
      --cdate "$CDATE" || print_err_msg_exit "\
Call to function to create the ensemble-based namelist for the current
cycle's (cdate) run directory (DATA) failed:
  cdate = \"${CDATE}\"
  DATA = \"${DATA}\""
else
  create_symlink_to_file target="${FV3_NML_FP}" \
                         symlink="${DATA}/${FV3_NML_FN}" \
                         relative="${relative_link_flag}"
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
  --fcst_len_hrs "${FCST_LEN_HRS}" \
  --run-dir "${DATA}" \
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
# Pre-generate symlinks to forecast output in DATA
#
#-----------------------------------------------------------------------
#
if [ "${RUN_ENVIR}" = "nco" ] && [ "${CPL_AQM}" = "TRUE" ]; then
  # create an intermediate symlink to RESTART
  ln_vrfy -sf "${DATA}/RESTART" "${COMIN}/RESTART"
fi
#
#-----------------------------------------------------------------------
#
# Call the function that creates the NEMS configuration file within each
# cycle directory.
#
#-----------------------------------------------------------------------
#
python3 $USHdir/create_nems_configure_file.py \
  --path-to-defns ${GLOBAL_VAR_DEFNS_FP} \
  --run-dir "${DATA}" \
  || print_err_msg_exit "\
Call to function to create a NEMS configuration file for the current
cycle's (cdate) run directory (DATA) failed:
  DATA = \"${DATA}\""
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
# Move RESTART directory to COMIN and create symlink in DATA only for
# NCO mode and when it is not empty.
#
# Move AQM output product file to COMOUT only for NCO mode in Online-CMAQ.
# Move dyn and phy files to COMIN only if run_post and write_dopost are off. 
#
#-----------------------------------------------------------------------
#
if [ "${CPL_AQM}" = "TRUE" ]; then
  if [ "${RUN_ENVIR}" = "nco" ]; then
    rm_vrfy -rf "${COMIN}/RESTART"
    if [ "$(ls -A ${DATA}/RESTART)" ]; then
      mv_vrfy ${DATA}/RESTART ${COMIN}
      ln_vrfy -sf ${COMIN}/RESTART ${DATA}/RESTART
    fi
  fi

  mv_vrfy ${DATA}/${AQM_RC_PRODUCT_FN} ${COMOUT}/${NET}.${cycle}${dot_ensmem}.${AQM_RC_PRODUCT_FN}
 
fi
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

    if [ "${CPL_AQM}" = "TRUE" ]; then
      fids=( "cmaq" )
    else
      fids=( "prslev" "natlev" )
    fi

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
if [ "${CPL_AQM}" = "TRUE" ]; then
  for fhr in $(seq -f "%03g" 0 ${FCST_LEN_HRS}); do
    mv_vrfy ${DATA}/dynf${fhr}.nc ${COMIN}/${NET}.${cycle}${dot_ensmem}.dyn.f${fhr}.nc
    mv_vrfy ${DATA}/phyf${fhr}.nc ${COMIN}/${NET}.${cycle}${dot_ensmem}.phy.f${fhr}.nc
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

