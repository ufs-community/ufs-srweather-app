#!/bin/bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. $USHdir/source_util_funcs.sh
source_config_for_task "task_make_lbcs|task_get_extrn_lbcs" ${GLOBAL_VAR_DEFNS_FP}
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

This is the ex-script for the task that generates lateral boundary con-
dition (LBC) files (in NetCDF format) for all LBC update hours (except
hour zero).
========================================================================"
#
#-----------------------------------------------------------------------
#
# Set OpenMP variables.
#
#-----------------------------------------------------------------------
#
export KMP_AFFINITY=${KMP_AFFINITY_MAKE_LBCS}
export OMP_NUM_THREADS=${OMP_NUM_THREADS_MAKE_LBCS}
export OMP_STACKSIZE=${OMP_STACKSIZE_MAKE_LBCS}
#
#-----------------------------------------------------------------------
#
# Set machine-dependent parameters.
#
#-----------------------------------------------------------------------
#
eval ${PRE_TASK_CMDS}

if [ -z "${RUN_CMD_UTILS:-}" ] ; then
  print_err_msg_exit "\
  Run command was not set in machine file. \
  Please set RUN_CMD_UTILS for your platform"
else
  print_info_msg "$VERBOSE" "
  All executables will be submitted with command \'${RUN_CMD_UTILS}\'."
fi
#
#-----------------------------------------------------------------------
#
# Source the file containing definitions of variables associated with the
# external model for LBCs.
#
#-----------------------------------------------------------------------
#
if [ $RUN_ENVIR = "nco" ]; then
    extrn_mdl_staging_dir="${COMINext}${SLASH_ENSMEM_SUBDIR}"
    extrn_mdl_var_defns_fp="${extrn_mdl_staging_dir}/${NET}.${cycle}.${EXTRN_MDL_NAME_LBCS}.LBCS.${EXTRN_MDL_VAR_DEFNS_FN}.sh"
else
    extrn_mdl_staging_dir="${COMIN}/${EXTRN_MDL_NAME_LBCS}/for_LBCS${SLASH_ENSMEM_SUBDIR}"
    extrn_mdl_var_defns_fp="${extrn_mdl_staging_dir}/${EXTRN_MDL_VAR_DEFNS_FN}.sh"
fi
. ${extrn_mdl_var_defns_fp}
#
#-----------------------------------------------------------------------
#
#
#
#-----------------------------------------------------------------------
#
DATA="${DATA}/tmp_LBCS"
mkdir_vrfy -p "$DATA"
cd_vrfy $DATA

if [ "${FCST_LEN_HRS}" = "-1" ]; then
  CYCLE_IDX=$(( ${cyc} / ${INCR_CYCL_FREQ} ))
  FCST_LEN_HRS=${FCST_LEN_CYCL[$CYCLE_IDX]}
fi
LBC_SPEC_FCST_HRS=()
for i_lbc in $(seq ${LBC_SPEC_INTVL_HRS} ${LBC_SPEC_INTVL_HRS} $(( FCST_LEN_HRS+LBC_SPEC_INTVL_HRS )) ); do
  LBC_SPEC_FCST_HRS+=("$i_lbc")
done
#
#-----------------------------------------------------------------------
#
# Set physics-suite-dependent variable mapping table needed in the FORTRAN
# namelist file that the chgres_cube executable will read in.
#
#-----------------------------------------------------------------------
#
varmap_file=""

case "${CCPP_PHYS_SUITE}" in
#
  "FV3_GFS_2017_gfdlmp" | \
  "FV3_GFS_2017_gfdlmp_regional" | \
  "FV3_GFS_v16" | \
  "FV3_GFS_v15p2" )
    varmap_file="GFSphys_var_map.txt"
    ;;
#
  "FV3_RRFS_v1beta" | \
  "FV3_GFS_v15_thompson_mynn_lam3km" | \
  "FV3_GFS_v17_p8" | \
  "FV3_WoFS_v0" | \
  "FV3_HRRR" )
    if [ "${EXTRN_MDL_NAME_LBCS}" = "RAP" ] || \
       [ "${EXTRN_MDL_NAME_LBCS}" = "HRRR" ]; then
      varmap_file="GSDphys_var_map.txt"
    elif [ "${EXTRN_MDL_NAME_LBCS}" = "NAM" ] || \
         [ "${EXTRN_MDL_NAME_LBCS}" = "FV3GFS" ] || \
         [ "${EXTRN_MDL_NAME_LBCS}" = "GEFS" ] || \
         [ "${EXTRN_MDL_NAME_LBCS}" = "GDAS" ] || \
         [ "${EXTRN_MDL_NAME_LBCS}" = "GSMGFS" ]; then
      varmap_file="GFSphys_var_map.txt"
    fi
    ;;
#
  *)
  print_err_msg_exit "\
The variable \"varmap_file\" has not yet been specified for this physics
suite (CCPP_PHYS_SUITE):
  CCPP_PHYS_SUITE = \"${CCPP_PHYS_SUITE}\""
  ;;
#
esac
#
#-----------------------------------------------------------------------
#
# Set external-model-dependent variables that are needed in the FORTRAN
# namelist file that the chgres_cube executable will read in.  These are de-
# scribed below.  Note that for a given external model, usually only a
# subset of these all variables are set (since some may be irrelevant).
#
# external_model:
# Name of the external model from which we are obtaining the fields
# needed to generate the LBCs.
#
# fn_atm:
# Name (not including path) of the nemsio or netcdf file generated by the 
# external model that contains the atmospheric fields.  Currently used for
# GSMGFS and FV3GFS external model data.
#
# fn_grib2:
# Name (not including path) of the grib2 file generated by the external
# model.  Currently used for NAM, RAP, and HRRR external model data.
#
# input_type:
# The "type" of input being provided to chgres_cube.  This contains a combi-
# nation of information on the external model, external model file for-
# mat, and maybe other parameters.  For clarity, it would be best to
# eliminate this variable in chgres_cube and replace with with 2 or 3 others
# (e.g. extrn_mdl, extrn_mdl_file_format, etc).
#
# tracers_input:
# List of atmospheric tracers to read in from the external model file
# containing these tracers.
#
# tracers:
# Names to use in the output NetCDF file for the atmospheric tracers
# specified in tracers_input.  With the possible exception of GSD phys-
# ics, the elements of this array should have a one-to-one correspond-
# ence with the elements in tracers_input, e.g. if the third element of
# tracers_input is the name of the O3 mixing ratio, then the third ele-
# ment of tracers should be the name to use for the O3 mixing ratio in
# the output file.  For GSD physics, three additional tracers -- ice,
# rain, and water number concentrations -- may be specified at the end
# of tracers, and these will be calculated by chgres_cube.
#
#-----------------------------------------------------------------------
#

# GSK comments about chgres_cube:
#
# The following are the three atmsopheric tracers that are in the atmo-
# spheric analysis (atmanl) nemsio file for CDATE=2017100700:
#
#   "spfh","o3mr","clwmr"
#
# Note also that these are hardcoded in the code (file input_data.F90,
# subroutine read_input_atm_gfs_spectral_file), so that subroutine will
# break if tracers_input(:) is not specified as above.
#
# Note that there are other fields too ["hgt" (surface height (togography?)),
# pres (surface pressure), ugrd, vgrd, and tmp (temperature)] in the atmanl file, but those
# are not considered tracers (they're categorized as dynamics variables,
# I guess).
#
# Another note:  The way things are set up now, tracers_input(:) and
# tracers(:) are assumed to have the same number of elements (just the
# atmospheric tracer names in the input and output files may be differ-
# ent).  There needs to be a check for this in the chgres_cube code!!
# If there was a varmap table that specifies how to handle missing
# fields, that would solve this problem.
#
# Also, it seems like the order of tracers in tracers_input(:) and
# tracers(:) must match, e.g. if ozone mixing ratio is 3rd in
# tracers_input(:), it must also be 3rd in tracers(:).  How can this be checked?
#
# NOTE: Really should use a varmap table for GFS, just like we do for
# RAP/HRRR.
#

# A non-prognostic variable that appears in the field_table for GSD physics
# is cld_amt.  Why is that in the field_table at all (since it is a non-
# prognostic field), and how should we handle it here??

# I guess this works for FV3GFS but not for the spectral GFS since these
# variables won't exist in the spectral GFS atmanl files.
#  tracers_input="\"sphum\",\"liq_wat\",\"ice_wat\",\"rainwat\",\"snowwat\",\"graupel\",\"o3mr\""
#
# Not sure if tracers(:) should include "cld_amt" since that is also in
# the field_table for CDATE=2017100700 but is a non-prognostic variable.

external_model=""
fn_atm=""
fn_grib2=""
input_type=""
tracers_input="\"\""
tracers="\"\""
#
#-----------------------------------------------------------------------
#
# If the external model for LBCs is one that does not provide the aerosol
# fields needed by Thompson microphysics (currently only the HRRR and
# RAP provide aerosol data) and if the physics suite uses Thompson
# microphysics, set the variable thomp_mp_climo_file in the chgres_cube
# namelist to the full path of the file containing aerosol climatology
# data.  In this case, this file will be used to generate approximate
# aerosol fields in the LBCs that Thompson MP can use.  Otherwise, set
# thomp_mp_climo_file to a null string.
#
#-----------------------------------------------------------------------
#
thomp_mp_climo_file=""
if [ "${EXTRN_MDL_NAME_LBCS}" != "HRRR" -a \
     "${EXTRN_MDL_NAME_LBCS}" != "RAP" ] && \
   [ "${SDF_USES_THOMPSON_MP}" = "TRUE" ]; then
  thomp_mp_climo_file="${THOMPSON_MP_CLIMO_FP}"
fi
#
#-----------------------------------------------------------------------
#
# Set other chgres_cube namelist variables depending on the external
# model used.
#
#-----------------------------------------------------------------------
#
case "${EXTRN_MDL_NAME_LBCS}" in

"GSMGFS")
  external_model="GSMGFS"
  input_type="gfs_gaussian_nemsio" # For spectral GFS Gaussian grid in nemsio format.
  tracers_input="[\"spfh\",\"clwmr\",\"o3mr\"]"
  tracers="[\"sphum\",\"liq_wat\",\"o3mr\"]"
  ;;

"FV3GFS")
  if [ "${FV3GFS_FILE_FMT_LBCS}" = "nemsio" ]; then
    external_model="FV3GFS"
    input_type="gaussian_nemsio"     # For FV3GFS data on a Gaussian grid in nemsio format.
    tracers_input="[\"spfh\",\"clwmr\",\"o3mr\",\"icmr\",\"rwmr\",\"snmr\",\"grle\"]"
    tracers="[\"sphum\",\"liq_wat\",\"o3mr\",\"ice_wat\",\"rainwat\",\"snowwat\",\"graupel\"]"
  elif [ "${FV3GFS_FILE_FMT_LBCS}" = "grib2" ]; then
    external_model="GFS"
    fn_grib2="${EXTRN_MDL_FNS[0]}"
    input_type="grib2"
  elif [ "${FV3GFS_FILE_FMT_LBCS}" = "netcdf" ]; then
    external_model="FV3GFS"
    input_type="gaussian_netcdf"     # For FV3GFS data on a Gaussian grid in netcdf format.
    tracers_input="[\"spfh\",\"clwmr\",\"o3mr\",\"icmr\",\"rwmr\",\"snmr\",\"grle\"]"
    tracers="[\"sphum\",\"liq_wat\",\"o3mr\",\"ice_wat\",\"rainwat\",\"snowwat\",\"graupel\"]"
  fi
  ;;

"GDAS")
  tracers_input="[\"spfh\",\"clwmr\",\"o3mr\",\"icmr\",\"rwmr\",\"snmr\",\"grle\"]"
  tracers="[\"sphum\",\"liq_wat\",\"o3mr\",\"ice_wat\",\"rainwat\",\"snowwat\",\"graupel\"]"
  external_model="GFS"
  input_type="gaussian_netcdf"
  fn_atm="${EXTRN_MDL_FNS[0]}"
  ;;

"GEFS")
  external_model="GFS"
  fn_grib2="${EXTRN_MDL_FNS[0]}"
  input_type="grib2"
  ;;

"RAP")
  external_model="RAP"
  input_type="grib2"
  ;;

"HRRR")
  external_model="HRRR"
  input_type="grib2"
  ;;

"NAM")
  external_model="NAM"
  input_type="grib2"
  ;;

*)
  print_err_msg_exit "\
External-model-dependent namelist variables have not yet been specified
for this external LBC model (EXTRN_MDL_NAME_LBCS):
  EXTRN_MDL_NAME_LBCS = \"${EXTRN_MDL_NAME_LBCS}\""
  ;;

esac
#
#-----------------------------------------------------------------------
#
# Check that the executable that generates the LBCs exists.
#
#-----------------------------------------------------------------------
#
exec_fn="chgres_cube"
exec_fp="$EXECdir/${exec_fn}"
if [ ! -f "${exec_fp}" ]; then
  print_err_msg_exit "\
The executable (exec_fp) for generating initial conditions on the FV3-LAM
native grid does not exist:
  exec_fp = \"${exec_fp}\"
Please ensure that you've built this executable."
fi
#
#-----------------------------------------------------------------------
#
# Loop through the LBC update times and run chgres_cube for each such time to
# obtain an LBC file for each that can be used as input to the FV3-LAM.
#
#-----------------------------------------------------------------------
#
num_fhrs="${#EXTRN_MDL_FHRS[@]}"
for (( i=0; i<${num_fhrs}; i++ )); do
#
# Get the forecast hour of the external model.
#
  fhr="${EXTRN_MDL_FHRS[$i]}"
#
# Set external model output file name and file type/format.  Note that
# these are now inputs into chgres_cube.
#
  fn_atm=""
  fn_grib2=""

  case "${EXTRN_MDL_NAME_LBCS}" in
  "GSMGFS")
    fn_atm="${EXTRN_MDL_FNS[$i]}"
    ;;
  "FV3GFS")
    if [ "${FV3GFS_FILE_FMT_LBCS}" = "nemsio" ]; then
      fn_atm="${EXTRN_MDL_FNS[$i]}"
    elif [ "${FV3GFS_FILE_FMT_LBCS}" = "grib2" ]; then
      fn_grib2="${EXTRN_MDL_FNS[$i]}"
    elif [ "${FV3GFS_FILE_FMT_LBCS}" = "netcdf" ]; then
      fn_atm="${EXTRN_MDL_FNS[$i]}"
    fi
    ;;
  "GDAS")
    fn_atm="${EXTRN_MDL_FNS[0][$i]}"
    ;;
  "GEFS")
    fn_grib2="${EXTRN_MDL_FNS[$i]}"
    ;;
  "RAP")
    fn_grib2="${EXTRN_MDL_FNS[$i]}"
    ;;
  "HRRR")
    fn_grib2="${EXTRN_MDL_FNS[$i]}"
    ;;
  "NAM")
    fn_grib2="${EXTRN_MDL_FNS[$i]}"
    ;;
  *)
    print_err_msg_exit "\
The external model output file name to use in the chgres_cube FORTRAN name-
list file has not specified for this external LBC model (EXTRN_MDL_NAME_LBCS):
  EXTRN_MDL_NAME_LBCS = \"${EXTRN_MDL_NAME_LBCS}\""
    ;;
  esac
#
# Get the starting date (year, month, and day together), month, day, and
# hour of the the external model forecast.  Then add the forecast hour
# to it to get a date and time corresponding to the current forecast time.
#
  yyyymmdd="${EXTRN_MDL_CDATE:0:8}"
  mm="${EXTRN_MDL_CDATE:4:2}"
  dd="${EXTRN_MDL_CDATE:6:2}"
  hh="${EXTRN_MDL_CDATE:8:2}"

  cdate_crnt_fhr=$( $DATE_UTIL --utc --date "${yyyymmdd} ${hh} UTC + ${fhr} hours" "+%Y%m%d%H" )
#
# Get the month, day, and hour corresponding to the current forecast time
# of the the external model.
#
  mm="${cdate_crnt_fhr:4:2}"
  dd="${cdate_crnt_fhr:6:2}"
  hh="${cdate_crnt_fhr:8:2}"
#
# Build the FORTRAN namelist file that chgres_cube will read in.
#

#
# Create a multiline variable that consists of a yaml-compliant string
# specifying the values that the namelist variables need to be set to
# (one namelist variable per line, plus a header and footer).  Below,
# this variable will be passed to a python script that will create the
# namelist file.
#
# IMPORTANT:
# If we want a namelist variable to be removed from the namelist file,
# in the "settings" variable below, we need to set its value to the
# string "null".  This is equivalent to setting its value to
#    !!python/none
# in the base namelist file specified by FV3_NML_BASE_SUITE_FP or the
# suite-specific yaml settings file specified by FV3_NML_YAML_CONFIG_FP.
#
# It turns out that setting the variable to an empty string also works
# to remove it from the namelist!  Which is better to use??
#
settings="
'config': {
 'fix_dir_target_grid': ${FIXlam},
 'mosaic_file_target_grid': ${FIXlam}/${CRES}${DOT_OR_USCORE}mosaic.halo$((10#${NH4})).nc,
 'orog_dir_target_grid': ${FIXlam},
 'orog_files_target_grid': ${CRES}${DOT_OR_USCORE}oro_data.tile${TILE_RGNL}.halo$((10#${NH4})).nc,
 'vcoord_file_target_grid': ${FIXam}/global_hyblev.l65.txt,
 'varmap_file': ${PARMdir}/ufs_utils/varmap_tables/${varmap_file},
 'data_dir_input_grid': ${extrn_mdl_staging_dir},
 'atm_files_input_grid': ${fn_atm},
 'grib2_file_input_grid': \"${fn_grib2}\",
 'cycle_mon': $((10#${mm})),
 'cycle_day': $((10#${dd})),
 'cycle_hour': $((10#${hh})),
 'convert_atm': True,
 'regional': 2,
 'halo_bndy': $((10#${NH4})),
 'halo_blend': $((10#${HALO_BLEND})),
 'input_type': ${input_type},
 'external_model': ${external_model},
 'tracers_input': ${tracers_input},
 'tracers': ${tracers},
 'thomp_mp_climo_file': ${thomp_mp_climo_file},
}
"
#
# Call the python script to create the namelist file.
#
  nml_fn="fort.41"
  ${USHdir}/set_namelist.py -q -u "$settings" -o ${nml_fn} || \
    print_err_msg_exit "\
Call to python script set_namelist.py to set the variables in the namelist
file read in by the ${exec_fn} executable failed.  Parameters passed to
this script are:
  Name of output namelist file:
    nml_fn = \"${nml_fn}\"
  Namelist settings specified on command line (these have highest precedence):
    settings =
$settings"
#
#-----------------------------------------------------------------------
#
# Run chgres_cube.
#
#-----------------------------------------------------------------------
#
# NOTE:
# Often when the chgres_cube.exe run fails, it still returns a zero
# return code, so the failure isn't picked up the the logical OR (||)
# below.  That should be fixed.  This might be due to the RUN_CMD_UTILS
# command - maybe that is returning a zero exit code even though the
# exit code of chgres_cube is nonzero.  A similar thing happens in the
# forecast task.
#
  PREP_STEP
  eval ${RUN_CMD_UTILS} ${exec_fp} ${REDIRECT_OUT_ERR} || \
    print_err_msg_exit "\
Call to executable (exec_fp) to generate lateral boundary conditions (LBCs)
file for the FV3-LAM for forecast hour fhr failed:
  exec_fp = \"${exec_fp}\"
  fhr = \"$fhr\"
The external model from which the LBCs files are to be generated is:
  EXTRN_MDL_NAME_LBCS = \"${EXTRN_MDL_NAME_LBCS}\"
The external model files that are inputs to the executable (exec_fp) are
located in the following directory:
  extrn_mdl_staging_dir = \"${extrn_mdl_staging_dir}\""
  POST_STEP
#
# Move LBCs file for the current lateral boundary update time to the LBCs
# work directory.  Note that we rename the file by including in its name
# the forecast hour of the FV3-LAM (which is not necessarily the same as
# that of the external model since their start times may be offset).
#
  fcst_hhh_FV3LAM=$( printf "%03d" "${LBC_SPEC_FCST_HRS[$i]}" )
  mv_vrfy gfs.bndy.nc ${INPUT_DATA}/${NET}.${cycle}${dot_ensmem}.gfs_bndy.tile7.f${fcst_hhh_FV3LAM}.nc

done
#
#-----------------------------------------------------------------------
#
# Print message indicating successful completion of script.
#
#-----------------------------------------------------------------------
#
print_info_msg "
========================================================================
Lateral boundary condition (LBC) files (in NetCDF format) generated suc-
cessfully for all LBC update hours (except hour zero)!!!

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
