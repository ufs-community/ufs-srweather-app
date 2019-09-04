#!/bin/bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions script and the function definitions
# file.
#
#-----------------------------------------------------------------------
#
. $SCRIPT_VAR_DEFNS_FP
. $USHDIR/source_funcs.sh
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
# Set the script name and print out an informational message informing
# the user that we've entered this script.
#
#-----------------------------------------------------------------------
#
script_name=$( basename "$0" )
print_info_msg "\n\
========================================================================
Entering script:  \"${script_name}\"
This is the ex-script for the task that runs a forecast with FV3 for the
specified cycle.
========================================================================"
#
#-----------------------------------------------------------------------
#
# Specify the set of valid argument names for this script/function.  
# Then process the arguments provided to this script/function (which 
# should consist of a set of name-value pairs of the form arg1="value1",
# etc).
#
#-----------------------------------------------------------------------
#
valid_args=( "CYCLE_DIR" )
process_args valid_args "$@"

# If VERBOSE is set to TRUE, print out what each valid argument has been
# set to.
if [ "$VERBOSE" = "TRUE" ]; then
  num_valid_args="${#valid_args[@]}"
  print_info_msg "\n\
The arguments to script/function \"${script_name}\" have been set as 
follows:
"
  for (( i=0; i<$num_valid_args; i++ )); do
    line=$( declare -p "${valid_args[$i]}" )
    printf "  $line\n"
  done
fi
#
#-----------------------------------------------------------------------
#
# Load modules.
#
#-----------------------------------------------------------------------
#
case $MACHINE in
#
"WCOSS_C" | "WCOSS")
#

  if [ "$CCPP" = "true" ]; then
  
# Needed to change to the run directory to correctly load necessary mo-
# dules for CCPP-version of FV3SAR in lines below

    cd_vrfy ${CYCLE_DIR}
  
    set +x
    source ./module-setup.sh
    module use $( pwd -P )
    module load modules.fv3
    module list
    set -x
  
  else
  
    . /apps/lmod/lmod/init/sh
    module purge
    module use /scratch4/NCEPDEV/nems/noscrub/emc.nemspara/soft/modulefiles
    module load intel/16.1.150 impi/5.1.1.109 netcdf/4.3.0 
    module list
  
  fi

  ulimit -s unlimited
  ulimit -a
  APRUN="mpirun -l -np $PE_MEMBER01"
  ;;
#
"THEIA")
#

  if [ "$CCPP" = "true" ]; then
  
# Need to change to the experiment directory to correctly load necessary 
# modules for CCPP-version of FV3SAR in lines below
    cd_vrfy ${EXPTDIR}
  
    set +x
    source ./module-setup.sh
    module use $( pwd -P )
    module load modules.fv3
    module load contrib wrap-mpi
    module list
    set -x
  
  else
  
    . /apps/lmod/lmod/init/sh
    module purge
    module use /scratch4/NCEPDEV/nems/noscrub/emc.nemspara/soft/modulefiles
    module load intel/16.1.150 impi/5.1.1.109 netcdf/4.3.0 
    module load contrib wrap-mpi 
    module list
  
  fi

  ulimit -s unlimited
  ulimit -a
  np=${SLURM_NTASKS}
  APRUN="mpirun -np ${np}"
  ;;

#
"JET")
#
  . /apps/lmod/lmod/init/sh
  module purge
  module load intel/15.0.3.187
  module load impi/5.1.1.109
  module load szip
  module load hdf5
  module load netcdf4/4.2.1.1
  module load contrib wrap-mpi
  module list

#  . $USHDIR/set_stack_limit_jet.sh
  ulimit -s unlimited
  ulimit -a
  np=${SLURM_NTASKS}
  APRUN="mpirun -np ${np}"
  ;;
#
"ODIN")
#
  module list

  ulimit -s unlimited
  ulimit -a
  APRUN="srun -n $PE_MEMBER01"
  ;;
#
esac
#
#-----------------------------------------------------------------------
#
# Change location to the INPUT subdirectory of the current cycle's run 
# directory.
#
#-----------------------------------------------------------------------
#
cd_vrfy ${CYCLE_DIR}/INPUT
#
#-----------------------------------------------------------------------
#
# Create links in the INPUT subdirectory of the current cycle's run di-
# rectory to the grid and (filtered) orography files.
#
#-----------------------------------------------------------------------
#
print_info_msg_verbose "\
Creating links in the INPUT subdirectory of the current cycle's run di-
rectory to the grid and (filtered) orography files ..."

filename="${CRES}_mosaic.nc"
ln_vrfy -sf -t ${CYCLE_DIR}/INPUT ../../INPUT/$filename
ln_vrfy -sf $filename grid_spec.nc

filename="${CRES}_grid.tile7.halo${nh3_T7}.nc"
ln_vrfy -sf -t ${CYCLE_DIR}/INPUT ../../INPUT/$filename
ln_vrfy -sf $filename ${CRES}_grid.tile7.nc

filename="${CRES}_grid.tile7.halo${nh4_T7}.nc"
ln_vrfy -sf -t ${CYCLE_DIR}/INPUT ../../INPUT/$filename
ln_vrfy -sf $filename grid.tile7.halo${nh4_T7}.nc

filename="${CRES}_oro_data.tile7.halo${nh4_T7}.nc"
ln_vrfy -sf -t ${CYCLE_DIR}/INPUT ../../INPUT/$filename
ln_vrfy -sf $filename oro_data.tile7.halo${nh4_T7}.nc

filename="${CRES}_oro_data.tile7.halo${nh0_T7}.nc"
ln_vrfy -sf -t ${CYCLE_DIR}/INPUT ../../INPUT/$filename
ln_vrfy -sf $filename oro_data.nc
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
print_info_msg_verbose "\
Creating links with names that FV3 looks for in the INPUT subdirectory
of the current cycle's run directory (CYCLE_DIR)..."

ln_vrfy -sf gfs_data.tile7.nc gfs_data.nc
ln_vrfy -sf sfc_data.tile7.nc sfc_data.nc
#
#-----------------------------------------------------------------------
#
# Create links in the current cycle's run directory to "fix" files in 
# the main experiment directory.
#
#-----------------------------------------------------------------------
#
cd_vrfy ${CYCLE_DIR}

print_info_msg_verbose "\
Creating links in the current cycle's run directory to static (fix) 
files in the main experiment directory..."

ln_vrfy -sf -t ${CYCLE_DIR} ../CFSR.SEAICE.1982.2012.monthly.clim.grb
ln_vrfy -sf -t ${CYCLE_DIR} ../RTGSST.1982.2012.monthly.clim.grb
ln_vrfy -sf -t ${CYCLE_DIR} ../seaice_newland.grb
ln_vrfy -sf -t ${CYCLE_DIR} ../aerosol.dat
ln_vrfy -sf -t ${CYCLE_DIR} ../global_albedo4.1x1.grb
ln_vrfy -sf -t ${CYCLE_DIR} ../global_glacier.2x2.grb
ln_vrfy -sf -t ${CYCLE_DIR} ../global_h2oprdlos.f77
ln_vrfy -sf -t ${CYCLE_DIR} ../global_maxice.2x2.grb
ln_vrfy -sf -t ${CYCLE_DIR} ../global_mxsnoalb.uariz.t126.384.190.rg.grb
ln_vrfy -sf -t ${CYCLE_DIR} ../global_o3prdlos.f77
ln_vrfy -sf -t ${CYCLE_DIR} ../global_shdmax.0.144x0.144.grb
ln_vrfy -sf -t ${CYCLE_DIR} ../global_shdmin.0.144x0.144.grb
ln_vrfy -sf -t ${CYCLE_DIR} ../global_slope.1x1.grb
ln_vrfy -sf -t ${CYCLE_DIR} ../global_snoclim.1.875.grb
ln_vrfy -sf -t ${CYCLE_DIR} ../global_snowfree_albedo.bosu.t126.384.190.rg.grb
ln_vrfy -sf -t ${CYCLE_DIR} ../global_soilmgldas.t126.384.190.grb
ln_vrfy -sf -t ${CYCLE_DIR} ../global_soiltype.statsgo.t126.384.190.rg.grb
ln_vrfy -sf -t ${CYCLE_DIR} ../global_tg3clim.2.6x1.5.grb
ln_vrfy -sf -t ${CYCLE_DIR} ../global_vegfrac.0.144.decpercent.grb
ln_vrfy -sf -t ${CYCLE_DIR} ../global_vegtype.igbp.t126.384.190.rg.grb
ln_vrfy -sf -t ${CYCLE_DIR} ../global_zorclim.1x1.grb
ln_vrfy -sf -t ${CYCLE_DIR} ../sfc_emissivity_idx.txt
ln_vrfy -sf -t ${CYCLE_DIR} ../solarconstant_noaa_an.txt
ln_vrfy -sf -t ${CYCLE_DIR} ../co2historicaldata_2010.txt
ln_vrfy -sf -t ${CYCLE_DIR} ../co2historicaldata_2011.txt
ln_vrfy -sf -t ${CYCLE_DIR} ../co2historicaldata_2012.txt
ln_vrfy -sf -t ${CYCLE_DIR} ../co2historicaldata_2013.txt
ln_vrfy -sf -t ${CYCLE_DIR} ../co2historicaldata_2014.txt
ln_vrfy -sf -t ${CYCLE_DIR} ../co2historicaldata_2015.txt
ln_vrfy -sf -t ${CYCLE_DIR} ../co2historicaldata_2016.txt
ln_vrfy -sf -t ${CYCLE_DIR} ../co2historicaldata_2017.txt
ln_vrfy -sf -t ${CYCLE_DIR} ../co2historicaldata_2018.txt
ln_vrfy -sf -t ${CYCLE_DIR} ../co2historicaldata_glob.txt
ln_vrfy -sf -t ${CYCLE_DIR} ../co2monthlycyc.txt
#
#-----------------------------------------------------------------------
#
# Create links in the current cycle's run directory to cycle-independent
# model input files in the main experiment directory.
#
#-----------------------------------------------------------------------
#
print_info_msg_verbose "\
Creating links in the current cycle's run directory to cycle-independent
model input files in the main experiment directory..."

ln_vrfy -sf -t ${CYCLE_DIR} ../${FV3_NML_FN}
ln_vrfy -sf -t ${CYCLE_DIR} ../${DATA_TABLE_FN}
ln_vrfy -sf -t ${CYCLE_DIR} ../${FIELD_TABLE_FN}
ln_vrfy -sf -t ${CYCLE_DIR} ../${NEMS_CONFIG_FN}

if [ "$CCPP" = "true" ]; then
  ln_vrfy -sf -t ${CYCLE_DIR} ../module-setup.sh
  ln_vrfy -sf -t ${CYCLE_DIR} ../modules.fv3
  if [ "$CCPP_phys_suite" = "GSD" ]; then
    ln_vrfy -sf -t ${CYCLE_DIR} ../suite_FV3_GSD_v0.xml
  elif [ "$CCPP_phys_suite" = "GFS" ]; then
    ln_vrfy -sf -t ${CYCLE_DIR} ../suite_FV3_GFS_2017_gfdlmp.xml
  fi
  if [ "$CCPP_phys_suite" = "GSD" ]; then
    ln_vrfy -sf -t ${CYCLE_DIR} ../CCN_ACTIVATE.BIN
  fi
fi
#
#-----------------------------------------------------------------------
#
# Copy templates of cycle-dependent model input files from the templates
# directory to the current cycle's run directory.
#
#-----------------------------------------------------------------------
#
print_info_msg_verbose "\
Copying cycle-independent model input files from the templates directory 
to the current cycle's run directory..." 

cp_vrfy ${TEMPLATE_DIR}/${MODEL_CONFIG_FN} ${CYCLE_DIR}

if [ "$CCPP" = "true" ]; then
  if [ "${CCPP_phys_suite}" = "GFS" ]; then
    cp_vrfy ${TEMPLATE_DIR}/${DIAG_TABLE_FN} ${CYCLE_DIR}
  elif [ "$CCPP_phys_suite" = "GSD" ]; then
    cp_vrfy ${TEMPLATE_DIR}/${DIAG_TABLE_CCPP_GSD_FN} ${CYCLE_DIR}/${DIAG_TABLE_FN}
  fi
elif [ "$CCPP" = "false" ]; then
  cp_vrfy ${TEMPLATE_DIR}/${DIAG_TABLE_FN} ${CYCLE_DIR}
fi
#
#-----------------------------------------------------------------------
#
# Extract from CDATE the starting year, month, day, and hour of the
# forecast.  These are needed below for various operations.
#
#-----------------------------------------------------------------------
#
YYYY=${CDATE:0:4}
MM=${CDATE:4:2}
DD=${CDATE:6:2}
HH=${CDATE:8:2}
YYYYMMDD=${CDATE:0:8}
#
#-----------------------------------------------------------------------
#
# Set the full path to the model configuration file.  Then set parame-
# ters in that file.
#
#-----------------------------------------------------------------------
#
MODEL_CONFIG_FP="${CYCLE_DIR}/${MODEL_CONFIG_FN}"

print_info_msg_verbose "\
Setting parameters in file:
  MODEL_CONFIG_FP = \"$MODEL_CONFIG_FP\""

set_file_param "$MODEL_CONFIG_FP" "PE_MEMBER01" "$PE_MEMBER01"
set_file_param "$MODEL_CONFIG_FP" "dt_atmos" "$dt_atmos"
set_file_param "$MODEL_CONFIG_FP" "start_year" "$YYYY"
set_file_param "$MODEL_CONFIG_FP" "start_month" "$MM"
set_file_param "$MODEL_CONFIG_FP" "start_day" "$DD"
set_file_param "$MODEL_CONFIG_FP" "start_hour" "$HH"
set_file_param "$MODEL_CONFIG_FP" "nhours_fcst" "$fcst_len_hrs"
set_file_param "$MODEL_CONFIG_FP" "ncores_per_node" "$ncores_per_node"
set_file_param "$MODEL_CONFIG_FP" "quilting" "$quilting"
set_file_param "$MODEL_CONFIG_FP" "print_esmf" "$print_esmf"
#
#-----------------------------------------------------------------------
#
# If the write component is to be used, then a set of parameters, in-
# cluding those that define the write component's output grid, need to
# be specified in the model configuration file (MODEL_CONFIG_FP).  This
# is done by appending a template file (in which some write-component
# parameters are set to actual values while others are set to placehol-
# ders) to MODEL_CONFIG_FP and then replacing the placeholder values in
# the (new) MODEL_CONFIG_FP file with actual values.  The full path of
# this template file is specified in the variable WRTCMP_PA RAMS_TEMP-
# LATE_FP.
#
#-----------------------------------------------------------------------
#
if [ "$quilting" = ".true." ]; then

  cat $WRTCMP_PARAMS_TEMPLATE_FP >> $MODEL_CONFIG_FP

  set_file_param "$MODEL_CONFIG_FP" "write_groups" "$WRTCMP_write_groups"
  set_file_param "$MODEL_CONFIG_FP" "write_tasks_per_group" "$WRTCMP_write_tasks_per_group"

  set_file_param "$MODEL_CONFIG_FP" "output_grid" "\'$WRTCMP_output_grid\'"
  set_file_param "$MODEL_CONFIG_FP" "cen_lon" "$WRTCMP_cen_lon"
  set_file_param "$MODEL_CONFIG_FP" "cen_lat" "$WRTCMP_cen_lat"
  set_file_param "$MODEL_CONFIG_FP" "lon1" "$WRTCMP_lon_lwr_left"
  set_file_param "$MODEL_CONFIG_FP" "lat1" "$WRTCMP_lat_lwr_left"

  if [ "${WRTCMP_output_grid}" = "rotated_latlon" ]; then
    set_file_param "$MODEL_CONFIG_FP" "lon2" "$WRTCMP_lon_upr_rght"
    set_file_param "$MODEL_CONFIG_FP" "lat2" "$WRTCMP_lat_upr_rght"
    set_file_param "$MODEL_CONFIG_FP" "dlon" "$WRTCMP_dlon"
    set_file_param "$MODEL_CONFIG_FP" "dlat" "$WRTCMP_dlat"
  elif [ "${WRTCMP_output_grid}" = "lambert_conformal" ]; then
    set_file_param "$MODEL_CONFIG_FP" "stdlat1" "$WRTCMP_stdlat1"
    set_file_param "$MODEL_CONFIG_FP" "stdlat2" "$WRTCMP_stdlat2"
    set_file_param "$MODEL_CONFIG_FP" "nx" "$WRTCMP_nx"
    set_file_param "$MODEL_CONFIG_FP" "ny" "$WRTCMP_ny"
    set_file_param "$MODEL_CONFIG_FP" "dx" "$WRTCMP_dx"
    set_file_param "$MODEL_CONFIG_FP" "dy" "$WRTCMP_dy"
  fi

fi
#
#-----------------------------------------------------------------------
#
# Set the full path to the file that specifies the fields to output.
# Then set parameters in that file.
#
#-----------------------------------------------------------------------
#
DIAG_TABLE_FP="${CYCLE_DIR}/${DIAG_TABLE_FN}"

print_info_msg_verbose "\
Setting parameters in file:
  DIAG_TABLE_FP = \"$DIAG_TABLE_FP\""

set_file_param "$DIAG_TABLE_FP" "CRES" "$CRES"
set_file_param "$DIAG_TABLE_FP" "YYYY" "$YYYY"
set_file_param "$DIAG_TABLE_FP" "MM" "$MM"
set_file_param "$DIAG_TABLE_FP" "DD" "$DD"
set_file_param "$DIAG_TABLE_FP" "HH" "$HH"
set_file_param "$DIAG_TABLE_FP" "YYYYMMDD" "$YYYYMMDD"
#
#-----------------------------------------------------------------------
#
# Copy the FV3SAR executable to the run directory.
#
#-----------------------------------------------------------------------
#
if [ "$CCPP" = "true" ]; then
  FV3SAR_EXEC="$NEMSfv3gfs_DIR/tests/fv3.exe"
else
  FV3SAR_EXEC="$NEMSfv3gfs_DIR/tests/fv3_32bit.exe"
fi

if [ -f $FV3SAR_EXEC ]; then
  print_info_msg_verbose "\
Copying the FV3SAR executable to the run directory..."
  cp_vrfy ${FV3SAR_EXEC} ${CYCLE_DIR}/fv3_gfs.x
else
  print_err_msg_exit "\
The FV3SAR executable specified in FV3SAR_EXEC does not exist:
  FV3SAR_EXEC = \"$FV3SAR_EXEC\"
Build FV3SAR and rerun."
fi
#
#-----------------------------------------------------------------------
#
# Set and export variables.
#
#-----------------------------------------------------------------------
#
export KMP_AFFINITY=scatter
export OMP_NUM_THREADS=1 #Needs to be 1 for dynamic build of CCPP with GFDL fast physics, was 2 before.
export OMP_STACKSIZE=1024m
#
#-----------------------------------------------------------------------
#
# Run the FV3SAR model.  Note that we have to launch the forecast from
# the current cycle's run directory because the FV3 executable will look
# for input files in the current directory.  Since those files have been 
# staged in the run directory, the current directory must be the run di-
# rectory (which it already is).
#
#-----------------------------------------------------------------------
#
$APRUN ./fv3_gfs.x || print_err_msg_exit "\
Call to executable to run FV3SAR forecast returned with nonzero exit code."
#
#-----------------------------------------------------------------------
#
# Print message indicating successful completion of script.
#
#-----------------------------------------------------------------------
#
print_info_msg "\
========================================================================
FV3 forecast completed successfully!!!
Exiting script:  \"${script_name}\"
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

