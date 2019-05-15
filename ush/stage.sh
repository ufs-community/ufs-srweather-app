#!/bin/sh -l

#
#----THEIA JOBCARD
#
# Note that the following PBS directives do not have any effect if this
# script is called via an interactive TORQUE/PBS job (i.e. using the -I
# flag to qsub along with the -x flag to specify this script).  The fol-
# lowing directives are placed here in case this script is called as a
# batch (i.e. non-interactive) job.
#
#PBS -N stage
#PBS -A gsd-fv3
#PBS -o out.$PBS_JOBNAME.$PBS_JOBID
#PBS -e err.$PBS_JOBNAME.$PBS_JOBID
#PBS -l nodes=1:ppn=1
#PBS -q batch
#PBS -l walltime=0:30:00
#PBS -W umask=022


#
#-----------------------------------------------------------------------
#
# This script copies files from various directories into the experiment
# directory, creates links to some of them, and modifies others (e.g. 
# templates) to customize them for the current experiment setup.
#
#-----------------------------------------------------------------------
#

#
#-----------------------------------------------------------------------
#
# Source the variable definitions script.                                                                                                         
#
#-----------------------------------------------------------------------
#
. $SCRIPT_VAR_DEFNS_FP
#
#-----------------------------------------------------------------------
#
# Source function definition files.
#
#-----------------------------------------------------------------------
#
. $USHDIR/source_funcs.sh
#
#-----------------------------------------------------------------------
#
# Save current shell options (in a global array).  Then set new options
# for this script/function.
#
#-----------------------------------------------------------------------
#
{ save_shell_opts; set -u -x; } > /dev/null 2>&1
#
#-----------------------------------------------------------------------
#
# Set and create the run directory for the current cycle.  Then create
# the INPUT and RESTART subdirectories under it.
#
#-----------------------------------------------------------------------
#
RUNDIR="$EXPTDIR/$CDATE"
check_for_preexist_dir $RUNDIR $preexisting_dir_method
mkdir_vrfy $RUNDIR

mkdir_vrfy $RUNDIR/INPUT
mkdir_vrfy $RUNDIR/RESTART



#
#-----------------------------------------------------------------------
#
# Change location to the input subdirectory of the run directory for the
# current cycle.
#
#-----------------------------------------------------------------------
#
cd_vrfy $RUNDIR/INPUT



print_info_msg_verbose "\
Creating links in the INPUT subdirectory of the run directory to grid 
and orography files ..."

filename="${CRES}_mosaic.nc"
ln_vrfy -sf -t $RUNDIR/INPUT ../../INPUT/$filename
ln_vrfy -sf $filename grid_spec.nc

filename="${CRES}_grid.tile7.halo${nh3_T7}.nc"
ln_vrfy -sf -t $RUNDIR/INPUT ../../INPUT/$filename
ln_vrfy -sf $filename ${CRES}_grid.tile7.nc

filename="${CRES}_grid.tile7.halo${nh4_T7}.nc"
ln_vrfy -sf -t $RUNDIR/INPUT ../../INPUT/$filename
ln_vrfy -sf $filename grid.tile7.halo${nh4_T7}.nc

filename="${CRES}_oro_data.tile7.halo${nh4_T7}.nc"
ln_vrfy -sf -t $RUNDIR/INPUT ../../INPUT/$filename
ln_vrfy -sf $filename oro_data.tile7.halo${nh4_T7}.nc

filename="${CRES}_oro_data.tile7.halo${nh0_T7}.nc"
ln_vrfy -sf -t $RUNDIR/INPUT ../../INPUT/$filename
ln_vrfy -sf $filename oro_data.nc
#
#-----------------------------------------------------------------------
#
# Copy files from various work directories into the experiment directory
# and create necesary links.
#
#-----------------------------------------------------------------------
#
print_info_msg_verbose "\
Copying files from work directories into run directory and creating links..."

WORKDIR_ICSLBCS_CDATE="$WORKDIR_ICSLBCS/$CDATE"
#
#-----------------------------------------------------------------------
#
# The FV3SAR model looks for a file named "gfs_data.nc" from which to
# read in the initial conditions with a 4-cell-wide halo.  This data is
# created by the preprocessing but is placed in a file with a different
# name ("gfs_data.tile7.nc").  Thus, we first copy the file created by
# the preprocessing to the INPUT subdirectory of the run directory and
# then create a symlink named "gfs_data.nc" that points to it.
#
#-----------------------------------------------------------------------
#
cp_vrfy $WORKDIR_ICSLBCS_CDATE/gfs_data.tile7.nc .
ln_vrfy -sf gfs_data.tile7.nc gfs_data.nc
#
#-----------------------------------------------------------------------
#
# The FV3SAR model looks for a file named "gfs_data.nc" from which to
# read in the surface without a halo.  This data is created by the pre-
# processing but is placed in a file with a different name ("sfc_data.-
# tile7.nc").  Thus, we first copy the file created by the preprocessing
# to the INPUT subdirectory of the run directory and then create a sym-
# link named "sfc_data.nc" that points to it.
#
#-----------------------------------------------------------------------
#
cp_vrfy $WORKDIR_ICSLBCS_CDATE/sfc_data.tile7.nc .
ln_vrfy -sf sfc_data.tile7.nc sfc_data.nc
#
#-----------------------------------------------------------------------
#
# Copy the boundary files (one per boundary update time) to the INPUT
# subdirectory of the run directory.
#
#-----------------------------------------------------------------------
#
cp_vrfy $WORKDIR_ICSLBCS_CDATE/gfs_bndy*.nc .
#
#-----------------------------------------------------------------------
#
# Copy the file gfs_ctrl.nc containing information about the vertical
# coordinate and the number of tracers from its temporary location to
# the INPUT subdirectory of the run directory.
#
#-----------------------------------------------------------------------
#
cp_vrfy $WORKDIR_ICSLBCS_CDATE/gfs_ctrl.nc .



#
#-----------------------------------------------------------------------
#
# Create links in run directory to files in the experiment directory.
#
#-----------------------------------------------------------------------
#
print_info_msg_verbose "\
Creating links in run directory to static files in the experiment di-
rectory..."

cd_vrfy $RUNDIR

ln_vrfy -sf -t $RUNDIR ../CFSR.SEAICE.1982.2012.monthly.clim.grb
ln_vrfy -sf -t $RUNDIR ../RTGSST.1982.2012.monthly.clim.grb
ln_vrfy -sf -t $RUNDIR ../seaice_newland.grb
ln_vrfy -sf -t $RUNDIR ../aerosol.dat
ln_vrfy -sf -t $RUNDIR ../global_albedo4.1x1.grb
ln_vrfy -sf -t $RUNDIR ../global_glacier.2x2.grb
ln_vrfy -sf -t $RUNDIR ../global_h2oprdlos.f77
ln_vrfy -sf -t $RUNDIR ../global_maxice.2x2.grb
ln_vrfy -sf -t $RUNDIR ../global_mxsnoalb.uariz.t126.384.190.rg.grb
ln_vrfy -sf -t $RUNDIR ../global_o3prdlos.f77
ln_vrfy -sf -t $RUNDIR ../global_shdmax.0.144x0.144.grb
ln_vrfy -sf -t $RUNDIR ../global_shdmin.0.144x0.144.grb
ln_vrfy -sf -t $RUNDIR ../global_slope.1x1.grb
ln_vrfy -sf -t $RUNDIR ../global_snoclim.1.875.grb
ln_vrfy -sf -t $RUNDIR ../global_snowfree_albedo.bosu.t126.384.190.rg.grb
ln_vrfy -sf -t $RUNDIR ../global_soilmgldas.t126.384.190.grb
ln_vrfy -sf -t $RUNDIR ../global_soiltype.statsgo.t126.384.190.rg.grb
ln_vrfy -sf -t $RUNDIR ../global_tg3clim.2.6x1.5.grb
ln_vrfy -sf -t $RUNDIR ../global_vegfrac.0.144.decpercent.grb
ln_vrfy -sf -t $RUNDIR ../global_vegtype.igbp.t126.384.190.rg.grb
ln_vrfy -sf -t $RUNDIR ../global_zorclim.1x1.grb
ln_vrfy -sf -t $RUNDIR ../sfc_emissivity_idx.txt
ln_vrfy -sf -t $RUNDIR ../solarconstant_noaa_an.txt
ln_vrfy -sf -t $RUNDIR ../co2historicaldata_2010.txt
ln_vrfy -sf -t $RUNDIR ../co2historicaldata_2011.txt
ln_vrfy -sf -t $RUNDIR ../co2historicaldata_2012.txt
ln_vrfy -sf -t $RUNDIR ../co2historicaldata_2013.txt
ln_vrfy -sf -t $RUNDIR ../co2historicaldata_2014.txt
ln_vrfy -sf -t $RUNDIR ../co2historicaldata_2015.txt
ln_vrfy -sf -t $RUNDIR ../co2historicaldata_2016.txt
ln_vrfy -sf -t $RUNDIR ../co2historicaldata_2017.txt
ln_vrfy -sf -t $RUNDIR ../co2historicaldata_2018.txt
ln_vrfy -sf -t $RUNDIR ../co2historicaldata_glob.txt
ln_vrfy -sf -t $RUNDIR ../co2monthlycyc.txt
#
#-----------------------------------------------------------------------
#
# Create links in the run directory to model input files in the experi-
# ment directory that do not depend on the forecast start time.
#
#-----------------------------------------------------------------------
#
#ln_vrfy -sf -t $RUNDIR ../INPUT

ln_vrfy -sf -t $RUNDIR ../${FV3_NML_FN}
ln_vrfy -sf -t $RUNDIR ../${DATA_TABLE_FN}
ln_vrfy -sf -t $RUNDIR ../${FIELD_TABLE_FN}
ln_vrfy -sf -t $RUNDIR ../${NEMS_CONFIG_FN}

if [ "$CCPP" = "true" ]; then
  ln_vrfy -sf -t $RUNDIR ../module-setup.sh
  ln_vrfy -sf -t $RUNDIR ../modules.fv3
  if [ "$CCPP_phys_suite" = "GSD" ]; then
    ln_vrfy -sf -t $RUNDIR ../suite_FV3_GSD.xml
  elif [ "$CCPP_phys_suite" = "GFS" ]; then
    ln_vrfy -sf -t $RUNDIR ../suite_FV3_GFS_2017_gfdlmp.xml
  fi
  if [ "$CCPP_phys_suite" = "GSD" ]; then
    ln_vrfy -sf -t $RUNDIR ../CCN_ACTIVATE.BIN
  fi
fi
#
#-----------------------------------------------------------------------
#
# Copy to the run directory templates of files that need to be modified
# based on the forecast start time.
#
#-----------------------------------------------------------------------
#
cp_vrfy $TEMPLATE_DIR/$MODEL_CONFIG_FN $RUNDIR

if [ "$CCPP" = "true" ]; then
  if [ "$CCPP_phys_suite" = "GFS" ]; then
    cp_vrfy $TEMPLATE_DIR/$DIAG_TABLE_FN $RUNDIR
  elif [ "$CCPP_phys_suite" = "GSD" ]; then
    cp_vrfy $TEMPLATE_DIR/$DIAG_TABLE_CCPP_GSD_FN $RUNDIR/$DIAG_TABLE_FN
  fi
elif [ "$CCPP" = "false" ]; then
  cp_vrfy $TEMPLATE_DIR/$DIAG_TABLE_FN $RUNDIR
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
MODEL_CONFIG_FP="$RUNDIR/$MODEL_CONFIG_FN"

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
  set_file_param "$MODEL_CONFIG_FP" "write_groups" "$write_groups"
  set_file_param "$MODEL_CONFIG_FP" "write_tasks_per_group" "$write_tasks_per_group"
fi
#
#-----------------------------------------------------------------------
#
# Set the full path to the file that specifies the fields to output.
# Then set parameters in that file.
#
#-----------------------------------------------------------------------
#
DIAG_TABLE_FP="$RUNDIR/$DIAG_TABLE_FN"

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
  cp_vrfy $FV3SAR_EXEC $RUNDIR/fv3_gfs.x
else
  print_err_msg_exit "\
The FV3SAR executable specified in FV3SAR_EXEC does not exist:
  FV3SAR_EXEC = \"$FV3SAR_EXEC\"
Build FV3SAR and rerun."
fi
#
#-----------------------------------------------------------------------
#
# Print message indicating successful completion of script.
#
#-----------------------------------------------------------------------
#
print_info_msg "\

========================================================================
All necessary files and links needed to launch a forecast successfully
copied to or created in the run directory!!!
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

