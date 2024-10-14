#!/usr/bin/env bash

#
#-----------------------------------------------------------------------
#
# The ex-scrtipt that sets up and runs chgres_cube for preparing lateral
# boundary conditions for the FV3 forecast
#
#-----------------------------------------------------------------------
#
set -xue
#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. ${PARMsrw}/source_util_funcs.sh
task_global_vars=( "CCPP_PHYS_SUITE" "CPL_AQM" "CRES" "DO_SMOKE_DUST" \
  "EXTRN_MDL_LBCS_OFFSET_HRS" "EXTRN_MDL_NAME_LBCS" \
  "EXTRN_MDL_VAR_DEFNS_FN" "FIXlam" "FV3GFS_FILE_FMT_LBCS" "HALO_BLEND" \
  "OMP_NUM_THREADS_MAKE_LBCS" "PRE_TASK_CMDS" "RUN_CMD_UTILS" \
  "SDF_USES_THOMPSON_MP" "THOMPSON_MP_CLIMO_FP" "VCOORD_FILE" )
for var in ${task_global_vars[@]}; do
  source_config_for_task ${var} ${GLOBAL_VAR_DEFNS_FP}
done
#
#-----------------------------------------------------------------------
#
# Save current shell options (in a global array).  Then set new options
# for this script/function.
#
#-----------------------------------------------------------------------
#
#{ save_shell_opts; set -xue; } > /dev/null 2>&1
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
export KMP_AFFINITY="scatter"
export OMP_NUM_THREADS=${OMP_NUM_THREADS_MAKE_LBCS}
export OMP_STACKSIZE="1024m"
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
  print_info_msg "All executables will be submitted with \'${RUN_CMD_UTILS}\'."
fi
#
#-----------------------------------------------------------------------
#
# Source the file containing definitions of variables associated with the
# external model for LBCs.
#
#-----------------------------------------------------------------------
#
extrn_mdl_staging_dir="${DATA_SHARE}/LBCS"
extrn_mdl_var_defns_fp="${extrn_mdl_staging_dir}/${EXTRN_MDL_VAR_DEFNS_FN}.sh"
. ${extrn_mdl_var_defns_fp}
#
#-----------------------------------------------------------------------
#
# Set physics-suite-dependent variable mapping table needed in the FORTRAN
# namelist file that the chgres_cube executable will read in.
#
#-----------------------------------------------------------------------
#
varmap_file_fp=""

case "${CCPP_PHYS_SUITE}" in
#
  "FV3_GFS_v16" | \
  "FV3_GFS_v15p2" )
    varmap_file="GFSphys_var_map.txt"
    ;;
#
  "FV3_RRFS_v1beta" | \
  "FV3_GFS_v17_p8" | \
  "FV3_WoFS_v0" | \
  "FV3_HRRR" | \
  "FV3_HRRR_gf" | \
  "FV3_RAP")
    if [ "${EXTRN_MDL_NAME_LBCS}" = "RAP" ] || \
       [ "${EXTRN_MDL_NAME_LBCS}" = "RRFS" ] || \
       [ "${EXTRN_MDL_NAME_LBCS}" = "HRRR" ]; then
      if [ $(boolify "${DO_SMOKE_DUST}") = "TRUE" ]; then
        varmap_file="GSDphys_var_map_smoke.txt"
      else
        varmap_file="GSDphys_var_map.txt"
      fi
    elif [ "${EXTRN_MDL_NAME_LBCS}" = "NAM" ] || \
         [ "${EXTRN_MDL_NAME_LBCS}" = "FV3GFS" ] || \
         [ "${EXTRN_MDL_NAME_LBCS}" = "UFS-CASE-STUDY" ] || \
         [ "${EXTRN_MDL_NAME_LBCS}" = "GEFS" ] || \
         [ "${EXTRN_MDL_NAME_LBCS}" = "GDAS" ] || \
         [ "${EXTRN_MDL_NAME_LBCS}" = "GSMGFS" ]; then
      varmap_file="GFSphys_var_map.txt"
    fi
    ;;
#
  *)
  message_txt="The variable \"varmap_file\" has not yet been specified 
for this physics suite (CCPP_PHYS_SUITE):
  CCPP_PHYS_SUITE = \"${CCPP_PHYS_SUITE}\""
  err_exit "${message_txt}"
  print_err_msg_exit "${message_txt}"
  ;;
#
esac

varmap_file_fp="${PARMsrw}/ufs_utils_parm/varmap_tables/${varmap_file}"
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
# model.  Currently used for NAM, RAP, and HRRR/RRFS external model data.
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
# fields needed by Thompson microphysics (currently only the HRRR/RRFS and
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
     "${EXTRN_MDL_NAME_LBCS}" != "RRFS" -a \
     "${EXTRN_MDL_NAME_LBCS}" != "RAP" ] && \
     [ $(boolify "${SDF_USES_THOMPSON_MP}") = "TRUE" ]; then
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

"UFS-CASE-STUDY")
  if [ "${FV3GFS_FILE_FMT_LBCS}" = "nemsio" ]; then
    external_model="UFS-CASE-STUDY"
    input_type="gaussian_nemsio"     # For FV3GFS data on a Gaussian grid in nemsio format.
    tracers_input="[\"spfh\",\"clwmr\",\"o3mr\",\"icmr\",\"rwmr\",\"snmr\",\"grle\"]"
    tracers="[\"sphum\",\"liq_wat\",\"o3mr\",\"ice_wat\",\"rainwat\",\"snowwat\",\"graupel\"]"
  fi
  ;;

"GDAS")
  if [ "${FV3GFS_FILE_FMT_LBCS}" = "nemsio" ]; then
    input_type="gaussian_nemsio"
  elif [ "${FV3GFS_FILE_FMT_LBCS}" = "netcdf" ]; then
    input_type="gaussian_netcdf"
  fi 
  external_model="GFS" 
  tracers_input="[\"spfh\",\"clwmr\",\"o3mr\",\"icmr\",\"rwmr\",\"snmr\",\"grle\"]"
  tracers="[\"sphum\",\"liq_wat\",\"o3mr\",\"ice_wat\",\"rainwat\",\"snowwat\",\"graupel\"]"
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

"HRRR"|"RRFS")
  external_model="HRRR"
  input_type="grib2"
  ;;

"NAM")
  external_model="NAM"
  input_type="grib2"
  ;;

*)
  message_txt="External-model-dependent namelist variables have not yet been 
specified for this external LBC model (EXTRN_MDL_NAME_LBCS):
  EXTRN_MDL_NAME_LBCS = \"${EXTRN_MDL_NAME_LBCS}\""
  err_exit "${message_txt}"
  print_err_msg_exit "${message_txt}"
  ;;

esac
#
#-----------------------------------------------------------------------
#
# Loop through the LBC update times and run chgres_cube for each such time to
# obtain an LBC file for each that can be used as input to the FV3-LAM.
#
#-----------------------------------------------------------------------
#
num_fhrs="${#EXTRN_MDL_FHRS[@]}"
bcgrp10=${bcgrp#0}
bcgrpnum10=${bcgrpnum#0}
for (( ii=0; ii<${num_fhrs}; ii=ii+bcgrpnum10 )); do
  i=$(( ii + bcgrp10 ))
  if [ ${i} -lt ${num_fhrs} ]; then
    echo " group ${bcgrp10} processes member ${i}"
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
    "UFS-CASE-STUDY")
      if [ "${FV3GFS_FILE_FMT_LBCS}" = "nemsio" ]; then
        hh="${EXTRN_MDL_CDATE:8:2}"
        fhr_str=$(printf "%03d" ${fhr})
        fn_atm="gfs.t${hh}z.atmf${fhr_str}.nemsio"
        unset hh fhr_str
      fi
      ;;
    "GDAS")
      fn_atm="${EXTRN_MDL_FNS[$i]}"
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
    "RRFS")
      fn_grib2="${EXTRN_MDL_FNS[$i]}"
      ;;
    "NAM")
      fn_grib2="${EXTRN_MDL_FNS[$i]}"
      ;;
    *)
      message_txt="The external model output file name to use in the chgres_cube 
FORTRAN namelist file has not specified for this external LBC model (EXTRN_MDL_NAME_LBCS):
  EXTRN_MDL_NAME_LBCS = \"${EXTRN_MDL_NAME_LBCS}\""
      err_exit "${message_txt}"
      print_err_msg_exit "${message_txt}"
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
    # Create a multiline variable that consists of a yaml-compliant string
    # specifying the values that the namelist variables need to be set to
    # (one namelist variable per line, plus a header and footer).  Below,
    # this variable will be passed to a python script that will create the
    # namelist file.
    #
    # IMPORTANT:
    # If we want a namelist variable to be removed from the namelist file,
    # in the "settings" variable below, we need to set its value to the
    # string "null".
    #
    settings="
'config':
 'convert_atm': True
 'cycle_mon': $((10#${mm}))
 'cycle_day': $((10#${dd}))
 'cycle_hour': $((10#${hh}))
 'data_dir_input_grid': ${extrn_mdl_staging_dir}
 'external_model': ${external_model}
 'fix_dir_target_grid': ${FIXlam}
 'grib2_file_input_grid': \"${fn_grib2}\"
 'halo_bndy': 4
 'halo_blend': $((10#${HALO_BLEND}))
 'input_type': ${input_type}
 'mosaic_file_target_grid': ${FIXlam}/${CRES}_mosaic.halo4.nc
 'orog_dir_target_grid': ${FIXlam}
 'orog_files_target_grid': ${CRES}_oro_data.tile7.halo4.nc
 'regional': 2
 'atm_files_input_grid': ${fn_atm}
 'thomp_mp_climo_file': ${thomp_mp_climo_file}
 'tracers_input': ${tracers_input}
 'tracers': ${tracers}
 'varmap_file': ${varmap_file_fp}
 'vcoord_file_target_grid': ${VCOORD_FILE}
"

    nml_fn="fort.41"
    ${USHsrw}/set_namelist.py -u "$settings" -o ${nml_fn}
    export err=$?
    if [ $err -ne 0 ]; then
      message_txt="Error creating namelist read by ${exec_fn} failed.
       Settings for input are:
$settings"
      err_exit "${message_txt}"
      print_err_msg_exit "${message_txt}"
    fi
    #
    #-----------------------------------------------------------------------
    #
    # Run chgres_cube.
    #
    #-----------------------------------------------------------------------
    #
    export pgm="chgres_cube"

    . prep_step
    eval ${RUN_CMD_UTILS} ${EXECsrw}/$pgm >>$pgmout 2>errfile
    export err=$?; err_chk
    #
    # Move LBCs file for the current lateral boundary update time to the LBCs
    # work directory.  Note that we rename the file by including in its name
    # the forecast hour of the FV3-LAM (which is not necessarily the same as
    # that of the external model since their start times may be offset).
    #
    lbc_spec_fhrs=( "${EXTRN_MDL_FHRS[$i]}" )
    fcst_hhh=$(( ${lbc_spec_fhrs} - ${EXTRN_MDL_LBCS_OFFSET_HRS} ))
    fcst_hhh_FV3LAM=$( printf "%03d" "$fcst_hhh" )
    if [ $(boolify "${CPL_AQM}") = "TRUE" ]; then
      cp -p gfs.bndy.nc ${DATA_SHARE}/${NET}.${cycle}${dot_ensmem}.gfs_bndy.tile7.f${fcst_hhh_FV3LAM}.nc
    else
      cp -p gfs.bndy.nc ${COMOUT}/${NET}.${cycle}${dot_ensmem}.gfs_bndy.tile7.f${fcst_hhh_FV3LAM}.nc
    fi
  fi
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
#{ restore_shell_opts; } > /dev/null 2>&1
