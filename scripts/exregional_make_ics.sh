#!/bin/bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. ${GLOBAL_VAR_DEFNS_FP}
. $USHDIR/source_util_funcs.sh
#
#-----------------------------------------------------------------------
#
# Save current shell options (in a global array).  Then set new options
# for this script/function.
#
#-----------------------------------------------------------------------
#
{ save_shell_opts; set -u +x; } > /dev/null 2>&1
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

This is the ex-script for the task that generates initial condition
(IC), surface, and zeroth hour lateral boundary condition (LBC0) files
(in NetCDF format) for the FV3-LAM.
========================================================================"
#
#-----------------------------------------------------------------------
#
# Specify the set of valid argument names for this script/function.  Then
# process the arguments provided to this script/function (which should
# consist of a set of name-value pairs of the form arg1="value1", etc).
#
#-----------------------------------------------------------------------
#
valid_args=( \
"ics_dir" \
)
process_args valid_args "$@"
#
#-----------------------------------------------------------------------
#
# For debugging purposes, print out values of arguments passed to this
# script.  Note that these will be printed out only if VERBOSE is set to
# TRUE.
#
#-----------------------------------------------------------------------
#
print_input_args valid_args
#
#-----------------------------------------------------------------------
#
# Set OpenMP variables.
#
#-----------------------------------------------------------------------
#
export KMP_AFFINITY=${KMP_AFFINITY_MAKE_ICS}
export OMP_NUM_THREADS=${OMP_NUM_THREADS_MAKE_ICS}
export OMP_STACKSIZE=${OMP_STACKSIZE_MAKE_ICS}
#
#-----------------------------------------------------------------------
#
# Set machine-dependent parameters.
#
#-----------------------------------------------------------------------
#
source $USHDIR/source_machine_file.sh
eval ${PRE_TASK_CMDS}

nprocs=$(( NNODES_MAKE_ICS*PPN_MAKE_ICS ))

if [ -z "${RUN_CMD_UTILS:-}" ] ; then
  print_err_msg_exit "\
  Run command was not set in machine file. \
  Please set RUN_CMD_UTILS for your platform"
else
  RUN_CMD_UTILS=$(eval echo ${RUN_CMD_UTILS})
  print_info_msg "$VERBOSE" "
  All executables will be submitted with command \'${RUN_CMD_UTILS}\'."
fi


#
#-----------------------------------------------------------------------
#
# Source the file containing definitions of variables associated with the
# external model for ICs.
#
#-----------------------------------------------------------------------
#
extrn_mdl_staging_dir="${CYCLE_DIR}/${EXTRN_MDL_NAME_ICS}/for_ICS"
extrn_mdl_var_defns_fp="${extrn_mdl_staging_dir}/${EXTRN_MDL_ICS_VAR_DEFNS_FN}"
. ${extrn_mdl_var_defns_fp}
#
#-----------------------------------------------------------------------
#
#
#
#-----------------------------------------------------------------------
#
workdir="${ics_dir}/tmp_ICS"
mkdir_vrfy -p "$workdir"
cd_vrfy $workdir
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
  "FV3_RRFS_v1alpha" | \
  "FV3_RRFS_v1beta" | \
  "FV3_GFS_v15_thompson_mynn_lam3km" | \
  "FV3_HRRR" )
    if [ "${EXTRN_MDL_NAME_ICS}" = "RAP" ] || \
       [ "${EXTRN_MDL_NAME_ICS}" = "HRRR" ]; then
      varmap_file="GSDphys_var_map.txt"
    elif [ "${EXTRN_MDL_NAME_ICS}" = "NAM" ] || \
         [ "${EXTRN_MDL_NAME_ICS}" = "FV3GFS" ] || \
         [ "${EXTRN_MDL_NAME_ICS}" = "GSMGFS" ]; then
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
# needed to generate the ICs.
#
# fn_atm:
# Name (not including path) of the nemsio or netcdf file generated by the 
# external model that contains the atmospheric fields.  Currently used for
# GSMGFS and FV3GFS external model data.
#
# fn_sfc:
# Name (not including path) of the nemsio or netcdf file generated by the
# external model that contains the surface fields.  Currently used for
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
# nsoill_out:
# The number of soil layers to include in the output NetCDF file.
#
# FIELD_from_climo, where FIELD = "vgtyp", "sotyp", "vgfrc", "lai", or
# "minmax_vgfrc":
# Logical variable indicating whether or not to obtain the field in
# question from climatology instead of the external model.  The field in
# question is one of vegetation type (FIELD="vgtyp"), soil type (FIELD=
# "sotyp"), vegetation fraction (FIELD="vgfrc"), leaf area index
# (FIELD="lai"), or min/max areal fractional coverage of annual green
# vegetation (FIELD="minmax_vfrr").  If FIELD_from_climo is set to
# ".true.", then the field is obtained from climatology (regardless of
# whether or not it exists in an external model file).  If it is set
# to ".false.", then the field is obtained from the external  model.
# If "false" is chosen and the external model file does not provide
# this field, then chgres_cube prints out an error message and stops.
#
# tg3_from_soil:
# Logical variable indicating whether or not to set the tg3 soil tempe-  # Needs to be verified.
# rature field to the temperature of the deepest soil layer.
#
#-----------------------------------------------------------------------
#

# GSK comments about chgres:
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
fn_sfc=""
fn_grib2=""
input_type=""
tracers_input="\"\""
tracers="\"\""
nsoill_out=""
geogrid_file_input_grid="\"\""
vgtyp_from_climo=""
sotyp_from_climo=""
vgfrc_from_climo=""
minmax_vgfrc_from_climo=""
lai_from_climo=""
tg3_from_soil=""
convert_nst=""
#
#-----------------------------------------------------------------------
#
# If the external model is not one that uses the RUC land surface model
# (LSM) -- which currently includes all valid external models except the
# HRRR and the RAP -- then we set the number of soil levels to include
# in the output NetCDF file that chgres_cube generates (nsoill_out; this
# is a variable in the namelist that chgres_cube reads in) to 4.  This 
# is because FV3 can handle this regardless of the LSM that it is using
# (which is specified in the suite definition file, or SDF), as follows.  
# If the SDF does not use the RUC LSM (i.e. it uses the Noah or Noah MP 
# LSM), then it will expect to see 4 soil layers; and if the SDF uses 
# the RUC LSM, then the RUC LSM itself has the capability to regrid from 
# 4 soil layers to the 9 layers that it uses.
#
# On the other hand, if the external model is one that uses the RUC LSM
# (currently meaning that it is either the HRRR or the RAP), then what
# we set nsoill_out to depends on whether the RUC or the Noah/Noah MP
# LSM is used in the SDF.  If the SDF uses RUC, then both the external
# model and FV3 use RUC (which expects 9 soil levels), so we simply set
# nsoill_out to 9.  In this case, chgres_cube does not need to do any
# regridding of soil levels (because the number of levels in is the same
# as the number out).  If the SDF uses the Noah or Noah MP LSM, then the
# output from chgres_cube must contain 4 soil levels because that is what
# these LSMs expect, and the code in FV3 does not have the capability to
# regrid from the 9 levels in the external model to the 4 levels expected
# by Noah/Noah MP.  In this case, chgres_cube does the regridding from 
# 9 to 4 levels.
#
# In summary, we can set nsoill_out to 4 unless the external model is
# the HRRR or RAP AND the forecast model is using the RUC LSM.
#
#-----------------------------------------------------------------------
#
nsoill_out="4"
if [ "${EXTRN_MDL_NAME_ICS}" = "HRRR" -o \
     "${EXTRN_MDL_NAME_ICS}" = "RAP" ] && \
   [ "${SDF_USES_RUC_LSM}" = "TRUE" ]; then
  nsoill_out="9"
fi
#
#-----------------------------------------------------------------------
#
# If the external model for ICs is one that does not provide the aerosol
# fields needed by Thompson microphysics (currently only the HRRR and 
# RAP provide aerosol data) and if the physics suite uses Thompson 
# microphysics, set the variable thomp_mp_climo_file in the chgres_cube 
# namelist to the full path of the file containing aerosol climatology 
# data.  In this case, this file will be used to generate approximate 
# aerosol fields in the ICs that Thompson MP can use.  Otherwise, set
# thomp_mp_climo_file to a null string.
#
#-----------------------------------------------------------------------
#
thomp_mp_climo_file=""
if [ "${EXTRN_MDL_NAME_ICS}" != "HRRR" -a \
     "${EXTRN_MDL_NAME_ICS}" != "RAP" ] && \
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
case "${EXTRN_MDL_NAME_ICS}" in

"GSMGFS")
  external_model="GSMGFS"
  fn_atm="${EXTRN_MDL_FNS[0]}"
  fn_sfc="${EXTRN_MDL_FNS[1]}"
  input_type="gfs_gaussian_nemsio" # For spectral GFS Gaussian grid in nemsio format.
  convert_nst=False
  tracers_input="[\"spfh\",\"clwmr\",\"o3mr\"]"
  tracers="[\"sphum\",\"liq_wat\",\"o3mr\"]"
  vgtyp_from_climo=True
  sotyp_from_climo=True
  vgfrc_from_climo=True
  minmax_vgfrc_from_climo=True
  lai_from_climo=True
  tg3_from_soil=False
  ;;

"FV3GFS")
  if [ "${FV3GFS_FILE_FMT_ICS}" = "nemsio" ]; then
    external_model="FV3GFS"
    input_type="gaussian_nemsio"     # For FV3GFS data on a Gaussian grid in nemsio format.
    tracers_input="[\"spfh\",\"clwmr\",\"o3mr\",\"icmr\",\"rwmr\",\"snmr\",\"grle\"]"
    tracers="[\"sphum\",\"liq_wat\",\"o3mr\",\"ice_wat\",\"rainwat\",\"snowwat\",\"graupel\"]"
    fn_atm="${EXTRN_MDL_FNS[0]}"
    fn_sfc="${EXTRN_MDL_FNS[1]}"
    convert_nst=True
  elif [ "${FV3GFS_FILE_FMT_ICS}" = "grib2" ]; then
    external_model="GFS"
    fn_grib2="${EXTRN_MDL_FNS[0]}"
    input_type="grib2"
    convert_nst=False
  elif [ "${FV3GFS_FILE_FMT_ICS}" = "netcdf" ]; then
    external_model="FV3GFS"
    input_type="gaussian_netcdf"     # For FV3GFS data on a Gaussian grid in netcdf format.
    tracers_input="[\"spfh\",\"clwmr\",\"o3mr\",\"icmr\",\"rwmr\",\"snmr\",\"grle\"]"
    tracers="[\"sphum\",\"liq_wat\",\"o3mr\",\"ice_wat\",\"rainwat\",\"snowwat\",\"graupel\"]"
    fn_atm="${EXTRN_MDL_FNS[0]}"
    fn_sfc="${EXTRN_MDL_FNS[1]}"
    convert_nst=True
  fi
  vgtyp_from_climo=True
  sotyp_from_climo=True
  vgfrc_from_climo=True
  minmax_vgfrc_from_climo=True
  lai_from_climo=True
  tg3_from_soil=False
  ;;

"HRRR")
  external_model="HRRR"
  fn_grib2="${EXTRN_MDL_FNS[0]}"
  input_type="grib2"
#
# Path to the HRRRX geogrid file.
#
  geogrid_file_input_grid="${FIXgsm}/geo_em.d01.nc_HRRRX"
# Note that vgfrc, shdmin/shdmax (minmax_vgfrc), and lai fields are only available in HRRRX
# files after mid-July 2019, and only so long as the record order didn't change afterward
  vgtyp_from_climo=True
  sotyp_from_climo=True
  vgfrc_from_climo=True
  minmax_vgfrc_from_climo=True
  lai_from_climo=True
  tg3_from_soil=True
  convert_nst=False
  ;;

"RAP")
  external_model="RAP"
  fn_grib2="${EXTRN_MDL_FNS[0]}"
  input_type="grib2"
#
# Path to the RAPX geogrid file.
#
  geogrid_file_input_grid="${FIXgsm}/geo_em.d01.nc_RAPX"
  vgtyp_from_climo=True
  sotyp_from_climo=False
  vgfrc_from_climo=True
  minmax_vgfrc_from_climo=True
  lai_from_climo=True
  tg3_from_soil=True
  convert_nst=False
  ;;

"NAM")
  external_model="NAM"
  fn_grib2="${EXTRN_MDL_FNS[0]}"
  input_type="grib2"
  vgtyp_from_climo=True
  sotyp_from_climo=True
  vgfrc_from_climo=True
  minmax_vgfrc_from_climo=True
  lai_from_climo=True
  tg3_from_soil=False
  convert_nst=False
  ;;

*)
  print_err_msg_exit "\
External-model-dependent namelist variables have not yet been specified
for this external IC model (EXTRN_MDL_NAME_ICS):
  EXTRN_MDL_NAME_ICS = \"${EXTRN_MDL_NAME_ICS}\""
  ;;

esac
#
#-----------------------------------------------------------------------
#
# Get the starting month, day, and hour of the the external model forecast.
#
#-----------------------------------------------------------------------
#
mm="${EXTRN_MDL_CDATE:4:2}"
dd="${EXTRN_MDL_CDATE:6:2}"
hh="${EXTRN_MDL_CDATE:8:2}"
#
#-----------------------------------------------------------------------
#
# Check that the executable that generates the ICs exists.
#
#-----------------------------------------------------------------------
#
exec_fn="chgres_cube"
exec_fp="$EXECDIR/${exec_fn}"
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
# Build the FORTRAN namelist file that chgres_cube will read in.
#
#-----------------------------------------------------------------------
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
 'fix_dir_input_grid': ${FIXgsm},
 'fix_dir_target_grid': ${FIXLAM},
 'mosaic_file_target_grid': ${FIXLAM}/${CRES}${DOT_OR_USCORE}mosaic.halo$((10#${NH4})).nc,
 'orog_dir_target_grid': ${FIXLAM},
 'orog_files_target_grid': ${CRES}${DOT_OR_USCORE}oro_data.tile${TILE_RGNL}.halo$((10#${NH4})).nc,
 'vcoord_file_target_grid': ${FIXam}/global_hyblev.l65.txt,
 'varmap_file': ${UFS_UTILS_DIR}/parm/varmap_tables/${varmap_file},
 'data_dir_input_grid': ${extrn_mdl_staging_dir},
 'atm_files_input_grid': ${fn_atm},
 'sfc_files_input_grid': ${fn_sfc},
 'grib2_file_input_grid': \"${fn_grib2}\",
 'cycle_mon': $((10#${mm})),
 'cycle_day': $((10#${dd})),
 'cycle_hour': $((10#${hh})),
 'convert_atm': True,
 'convert_sfc': True,
 'convert_nst': ${convert_nst},
 'regional': 1,
 'halo_bndy': $((10#${NH4})),
 'halo_blend': $((10#${HALO_BLEND})),
 'input_type': ${input_type},
 'external_model': ${external_model},
 'tracers_input': ${tracers_input},
 'tracers': ${tracers},
 'nsoill_out': $((10#${nsoill_out})),
 'geogrid_file_input_grid': ${geogrid_file_input_grid},
 'vgtyp_from_climo': ${vgtyp_from_climo},
 'sotyp_from_climo': ${sotyp_from_climo},
 'vgfrc_from_climo': ${vgfrc_from_climo},
 'minmax_vgfrc_from_climo': ${minmax_vgfrc_from_climo},
 'lai_from_climo': ${lai_from_climo},
 'tg3_from_soil': ${tg3_from_soil},
 'thomp_mp_climo_file': ${thomp_mp_climo_file},
}
"
#
# Call the python script to create the namelist file.
#
nml_fn="fort.41"
${USHDIR}/set_namelist.py -q -u "$settings" -o ${nml_fn} || \
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
${RUN_CMD_UTILS} ${exec_fp} || \
  print_err_msg_exit "\
Call to executable (exec_fp) to generate surface and initial conditions
(ICs) files for the FV3-LAM failed:
  exec_fp = \"${exec_fp}\"
The external model from which the ICs files are to be generated is:
  EXTRN_MDL_NAME_ICS = \"${EXTRN_MDL_NAME_ICS}\"
The external model files that are inputs to the executable (exec_fp) are
located in the following directory:
  extrn_mdl_staging_dir = \"${extrn_mdl_staging_dir}\""
#
#-----------------------------------------------------------------------
#
# Move initial condition, surface, control, and 0-th hour lateral bound-
# ary files to ICs_BCs directory.
#
#-----------------------------------------------------------------------
#
mv_vrfy out.atm.tile${TILE_RGNL}.nc \
        ${ics_dir}/gfs_data.tile${TILE_RGNL}.halo${NH0}.nc

mv_vrfy out.sfc.tile${TILE_RGNL}.nc \
        ${ics_dir}/sfc_data.tile${TILE_RGNL}.halo${NH0}.nc

mv_vrfy gfs_ctrl.nc ${ics_dir}

mv_vrfy gfs.bndy.nc ${ics_dir}/gfs_bndy.tile${TILE_RGNL}.000.nc
#
#-----------------------------------------------------------------------
#
# Process FVCOM Data
#
#-----------------------------------------------------------------------
#
if [ "${USE_FVCOM}" = "TRUE" ]; then

#Format for fvcom_time: YYYY-MM-DDTHH:00:00.000000
  fvcom_exec_fn="fvcom_to_FV3"
  fvcom_exec_fp="$EXECDIR/${fvcom_exec_fn}"
  fvcom_time="${DATE_FIRST_CYCL:0:4}-${DATE_FIRST_CYCL:4:2}-${DATE_FIRST_CYCL:6:2}T${CYCL_HRS[0]}:00:00.000000"
  if [ ! -f "${fvcom_exec_fp}" ]; then
    print_err_msg_exit "\
The executable (fvcom_exec_fp) for processing FVCOM data onto FV3-LAM
native grid does not exist:
  fvcom_exec_fp = \"${fvcom_exec_fp}\"
Please ensure that you've built this executable."
  fi
  cp_vrfy ${fvcom_exec_fp} ${ics_dir}/.
  fvcom_data_fp="${FVCOM_DIR}/${FVCOM_FILE}"
  if [ ! -f "${fvcom_data_fp}" ]; then
    print_err_msg_exit "\
The file or path (fvcom_data_fp) does not exist:
  fvcom_data_fp = \"${fvcom_data_fp}\"
Please check the following user defined variables:
  FVCOM_DIR = \"${FVCOM_DIR}\"
  FVCOM_FILE= \"${FVCOM_FILE}\" "
  fi

  cp_vrfy ${fvcom_data_fp} ${ics_dir}/fvcom.nc
  cd_vrfy ${ics_dir}
  ${RUN_CMD_UTILS} ${fvcom_exec_fn} sfc_data.tile${TILE_RGNL}.halo${NH0}.nc fvcom.nc ${FVCOM_WCSTART} ${fvcom_time}|| \
  print_err_msg_exit "\
Call to executable (fvcom_exe) to modify sfc fields for FV3-LAM failed:
  fvcom_exe = \"${fvcom_exe}\"
The following variables were being used:
  FVCOM_DIR = \"${FVCOM_DIR}\"
  FVCOM_FILE = \"${FVCOM_FILE}\"
  fvcom_time = \"${fvcom_time}\"
  FVCOM_WCSTART = \"${FVCOM_WCSTART}\"
  ics_dir = \"${ics_dir}\"
  fvcom_exe_dir = \"${fvcom_exe_dir}\"
  fvcom_exe = \"${fvcom_exe}\""
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
Initial condition, surface, and zeroth hour lateral boundary condition
files (in NetCDF format) for FV3 generated successfully!!!

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
