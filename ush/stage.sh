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
# This script copies files from various directories into the run direc-
# tory, creates links to some of them, and modifies others (e.g. temp-
# lates) to customize them for the current run.
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
# Copy templates of various input files to the run directory.
#
#-----------------------------------------------------------------------
#
print_info_msg_verbose "\
Copying templates of various input files to the run directory..."

if [ "$CCPP" = "true" ]; then

  print_info_msg_verbose "\
Copying the script that initializes the Lmod (Lua-based module) system/
software for handling modules... 

This script:
1) Detects the shell in which it is being invoked (i.e. the shell of the
   \"parent\" script in which it is being sourced).
2) Detects the machine it is running on and and calls the appropriate 
   (shell- and machine-dependent) initalization script to initialize 
   Lmod.
3) Purges all modules.
4) Uses the \"module use ...\" command to prepend or append paths to 
   Lmod's search path (MODULEPATH).
"
# The following might have to be made shell-dependent, e.g. if using csh 
# or tcsh, copy over the file module-setup.csh.inc??.
#
# It may be convenient to also copy over this script when running the 
# non-CCPP version of the FV3SAR and try to simplify the run script 
# (run_FV3SAR.sh) so that it doesn't depend on whether CCPP is set to
# "true" or "false".  We can do that, but currently 
  cp_vrfy $NEMSfv3gfs_DIR/NEMS/src/conf/module-setup.sh.inc $RUNDIR/module-setup.sh
#
# Append the command that adds the path to the CCPP libraries (via the
# shell variable LD_LIBRARY_PATH) to the Lmod initialization script in 
# the run directory.  This is needed if running the dynamic build of the
# CCPP-enabled version of the FV3SAR.
#
  { cat << EOM >> $RUNDIR/module-setup.sh
#
# Add path to libccpp.so and libccpphys.so to LD_LIBRARY_PATH"
#
export LD_LIBRARY_PATH="${NEMSfv3gfs_DIR}/ccpp/lib\${LD_LIBRARY_PATH:+:\$LD_LIBRARY_PATH}"
EOM
} || print_err_msg_exit "\
Heredoc (cat) command to append command to add path to CCPP libraries to
the Lmod initialization script in the run directory returned with a non-
zero status."

  if [ "$CCPP_phys_suite" = "GFS" ]; then

    cp_vrfy $TEMPLATE_DIR/$FV3_NML_CCPP_GFS_FN $RUNDIR/$FV3_NML_FN
    cp_vrfy $TEMPLATE_DIR/$DIAG_TABLE_FN $RUNDIR
    cp_vrfy $TEMPLATE_DIR/$FIELD_TABLE_FN $RUNDIR

  elif [ "$CCPP_phys_suite" = "GSD" ]; then

    cp_vrfy $TEMPLATE_DIR/$FV3_NML_CCPP_GSD_FN $RUNDIR/$FV3_NML_FN
    cp_vrfy $TEMPLATE_DIR/$DIAG_TABLE_CCPP_GSD_FN $RUNDIR/$DIAG_TABLE_FN
    cp_vrfy $TEMPLATE_DIR/$FIELD_TABLE_CCPP_GSD_FN $RUNDIR/$FIELD_TABLE_FN

  fi

elif [ "$CCPP" = "false" ]; then

  cp_vrfy $TEMPLATE_DIR/$FV3_NML_FN $RUNDIR
  cp_vrfy $TEMPLATE_DIR/$DIAG_TABLE_FN $RUNDIR
  cp_vrfy $TEMPLATE_DIR/$FIELD_TABLE_FN $RUNDIR

fi

cp_vrfy $TEMPLATE_DIR/$MODEL_CONFIG_FN $RUNDIR
cp_vrfy $TEMPLATE_DIR/$DATA_TABLE_FN $RUNDIR
cp_vrfy $TEMPLATE_DIR/$NEMS_CONFIG_FN $RUNDIR
#
#-----------------------------------------------------------------------
#
# Set the full path to the FV3SAR namelist file.  Then set parameters in
# that file.
#
#-----------------------------------------------------------------------
#
FV3_NML_FP="$RUNDIR/$FV3_NML_FN"

print_info_msg_verbose "\
Setting parameters in file:
  FV3_NML_FP = \"$FV3_NML_FP\""
#
# Set npx_T7 and npy_T7, which are just nx_T7 plus 1 and ny_T7 plus 1,
# respectively.  These need to be set in the FV3SAR Fortran namelist
# file.  They represent the number of cell vertices in the x and y di-
# rections on the regional grid (tile 7).
#
npx_T7=$(( $nx_T7 + 1 ))
npy_T7=$(( $ny_T7 + 1 ))
#
# Set parameters.
#
set_file_param "$FV3_NML_FP" "blocksize" "$blocksize"
set_file_param "$FV3_NML_FP" "layout" "$layout_x,$layout_y"
set_file_param "$FV3_NML_FP" "npx" "$npx_T7"
set_file_param "$FV3_NML_FP" "npy" "$npy_T7"
if [ "$grid_gen_method" = "GFDLgrid" ]; then
# Question:
# For a regional grid (i.e. one that only has a tile 7) should the co-
# ordinates that target_lon and target_lat get set to be those of the 
# center of tile 6 (of the parent grid) or those of tile 7?  These two
# are not necessarily the same [although assuming there is only one re-
# gional domain within tile 6, i.e. assuming there is no tile 8, 9, etc,
# there is no reason not to center tile 7 with respect to tile 6].
  set_file_param "$FV3_NML_FP" "target_lon" "$lon_ctr_T6"
  set_file_param "$FV3_NML_FP" "target_lat" "$lat_ctr_T6"
elif [ "$grid_gen_method" = "JPgrid" ]; then
  set_file_param "$FV3_NML_FP" "target_lon" "$lon_rgnl_ctr"
  set_file_param "$FV3_NML_FP" "target_lat" "$lat_rgnl_ctr"
fi
set_file_param "$FV3_NML_FP" "stretch_fac" "$stretch_fac"
set_file_param "$FV3_NML_FP" "bc_update_interval" "$BC_update_intvl_hrs"
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
set_file_param "$DIAG_TABLE_FP" "YYYYMMDD" "$YMD"
#
#-----------------------------------------------------------------------
#
# If CCPP is set to "true", copy the appropriate modulefile, the CCPP
# physics suite definition file (an XML file), and possibly other suite-
# dependent files to run directory.
#
#-----------------------------------------------------------------------
#
if [ "$CCPP" = "true" ]; then

  print_info_msg_verbose "\ 
Copying to the run directory the modulefile required for running the 
CCPP-enabled version of the FV3SAR under NEMS...

A modulefile is a file whose first line is the \"magic cookie\" '#%Module'
that is interpreted by the \"module load ...\" command).  It sets envi-
ronment variables (including prepending/appending to paths) and loads 
modules."
#  cp_vrfy $NEMSfv3gfs_DIR/tests/modules.fv3 $RUNDIR/modules.fv3
#
# It seems like the file modules.nems in the directory
#
#   $NEMSfv3gfs_DIR/NEMS/src/conf
#
# is generated during the FV3 build process and this is configured pro-
# perly for the machine, shell environment, etc.  Thus, we can just copy
# it to the run directory without worrying about what machine we're on, 
# but this still needs to be confirmed.
#
# Why don't we do this for the non-CCPP version of FV3??
# Because for that case, we load different versions of intel and impi 
# (compare modules.nems to the modules loaded for CCPP set to "false" in
# run_FV3SAR.sh).  Maybe these can be combined at some point??
#
  cp_vrfy $NEMSfv3gfs_DIR/NEMS/src/conf/modules.nems $RUNDIR/modules.fv3

  if [ "$CCPP_phys_suite" = "GFS" ]; then

    print_info_msg_verbose "\
Copying the GFS physics suite XML file to the run directory..."
    cp_vrfy $NEMSfv3gfs_DIR/ccpp/suites/suite_FV3_GFS_2017_updated_gfdlmp_regional.xml $RUNDIR/ccpp_suite.xml

  elif [ "$CCPP_phys_suite" = "GSD" ]; then

    print_info_msg_verbose "\
Copying the GSD physics suite XML file and the Thompson microphysics CCN 
fixed file to the run directory..."
    cp_vrfy $NEMSfv3gfs_DIR/ccpp/suites/suite_FV3_GSD.xml $RUNDIR/ccpp_suite.xml
    cp_vrfy $GSDFIX/CCN_ACTIVATE.BIN $RUNDIR

  fi

fi
#
#-----------------------------------------------------------------------
#
# Copy fixed files from system directory to run directory.  Note that
# some of these files get renamed.
#
#-----------------------------------------------------------------------
#
print_info_msg_verbose "\
Copying fixed files from system directory to run directory..."

cp_vrfy $FIXgsm/CFSR.SEAICE.1982.2012.monthly.clim.grb $RUNDIR
cp_vrfy $FIXgsm/RTGSST.1982.2012.monthly.clim.grb $RUNDIR
cp_vrfy $FIXgsm/seaice_newland.grb $RUNDIR
cp_vrfy $FIXgsm/global_climaeropac_global.txt $RUNDIR/aerosol.dat
cp_vrfy $FIXgsm/global_albedo4.1x1.grb $RUNDIR
cp_vrfy $FIXgsm/global_glacier.2x2.grb $RUNDIR
cp_vrfy $FIXgsm/global_h2o_pltc.f77 $RUNDIR/global_h2oprdlos.f77
cp_vrfy $FIXgsm/global_maxice.2x2.grb $RUNDIR
cp_vrfy $FIXgsm/global_mxsnoalb.uariz.t126.384.190.rg.grb $RUNDIR
cp_vrfy $FIXgsm/global_o3prdlos.f77 $RUNDIR
cp_vrfy $FIXgsm/global_shdmax.0.144x0.144.grb $RUNDIR
cp_vrfy $FIXgsm/global_shdmin.0.144x0.144.grb $RUNDIR
cp_vrfy $FIXgsm/global_slope.1x1.grb $RUNDIR
cp_vrfy $FIXgsm/global_snoclim.1.875.grb $RUNDIR
cp_vrfy $FIXgsm/global_snowfree_albedo.bosu.t126.384.190.rg.grb $RUNDIR
cp_vrfy $FIXgsm/global_soilmgldas.t126.384.190.grb $RUNDIR
cp_vrfy $FIXgsm/global_soiltype.statsgo.t126.384.190.rg.grb $RUNDIR
cp_vrfy $FIXgsm/global_tg3clim.2.6x1.5.grb $RUNDIR
cp_vrfy $FIXgsm/global_vegfrac.0.144.decpercent.grb $RUNDIR
cp_vrfy $FIXgsm/global_vegtype.igbp.t126.384.190.rg.grb $RUNDIR
cp_vrfy $FIXgsm/global_zorclim.1x1.grb $RUNDIR
cp_vrfy $FIXgsm/global_sfc_emissivity_idx.txt $RUNDIR/sfc_emissivity_idx.txt
cp_vrfy $FIXgsm/global_solarconstant_noaa_an.txt $RUNDIR/solarconstant_noaa_an.txt
cp_vrfy $FIXgsm/fix_co2_proj/global_co2historicaldata_2010.txt $RUNDIR/co2historicaldata_2010.txt
cp_vrfy $FIXgsm/fix_co2_proj/global_co2historicaldata_2011.txt $RUNDIR/co2historicaldata_2011.txt
cp_vrfy $FIXgsm/fix_co2_proj/global_co2historicaldata_2012.txt $RUNDIR/co2historicaldata_2012.txt
cp_vrfy $FIXgsm/fix_co2_proj/global_co2historicaldata_2013.txt $RUNDIR/co2historicaldata_2013.txt
cp_vrfy $FIXgsm/fix_co2_proj/global_co2historicaldata_2014.txt $RUNDIR/co2historicaldata_2014.txt
cp_vrfy $FIXgsm/fix_co2_proj/global_co2historicaldata_2015.txt $RUNDIR/co2historicaldata_2015.txt
cp_vrfy $FIXgsm/fix_co2_proj/global_co2historicaldata_2016.txt $RUNDIR/co2historicaldata_2016.txt
cp_vrfy $FIXgsm/fix_co2_proj/global_co2historicaldata_2017.txt $RUNDIR/co2historicaldata_2017.txt
cp_vrfy $FIXgsm/fix_co2_proj/global_co2historicaldata_2018.txt $RUNDIR/co2historicaldata_2018.txt
cp_vrfy $FIXgsm/global_co2historicaldata_glob.txt $RUNDIR/co2historicaldata_glob.txt
cp_vrfy $FIXgsm/co2monthlycyc.txt $RUNDIR
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
# Copy files from various work directories into the run directory and
# create necesary links.
#
#-----------------------------------------------------------------------
#
print_info_msg_verbose "\
Copying files from work directories into run directory and creating links..."
#
#-----------------------------------------------------------------------
#
# Change location to the INPUT subdirectory of the run directory.
#
#-----------------------------------------------------------------------
#
cd_vrfy $RUNDIR/INPUT
#
#-----------------------------------------------------------------------
#
# Copy the grid mosaic file (which describes the connectivity of the va-
# rious tiles) to the INPUT subdirectory of the run directory.  In the
# regional case, this file doesn't have much information because the
# regional grid is not connected to any other tiles.  However, a mosaic
# file (with a different name; see below) must still be read in by the
# FV3SAR code.
#
# Note that the FV3 code (specifically the FMS code) looks for a file
# named "grid_spec.nc" in the INPUT subdirectory of the run directory
# as the grid mosaic file.  Assuming it finds this file, it then reads
# in the variable "gridfiles" in this file that contains the names of
# the grid files for each of the tiles of the grid.  In the regional
# case, "gridfiles" will contain only one file name, that of the file
# describing the grid on tile 7.
#
#-----------------------------------------------------------------------
#
cp_vrfy $WORKDIR_GRID/${CRES}_mosaic.nc .
ln_vrfy -sf ${CRES}_mosaic.nc grid_spec.nc
#
#-----------------------------------------------------------------------
#
# The FV3SAR model looks for a file named "${CRES}_grid.tile7.nc" from
# which to read in the grid with a 3-cell-wide halo.  This data is crea-
# ted by the preprocessing but is placed in a file with a different name
# ("${CRES}_grid.tile7.halo3.nc").  Thus, we first copy the file created
# by the preprocessing to the INPUT subdirectory of the run directory
# and then create a symlink named "${CRES}_grid.tile7.nc" that points to
# it.
#
#-----------------------------------------------------------------------
#
cp_vrfy $WORKDIR_SHVE/${CRES}_grid.tile7.halo${nh3_T7}.nc .
ln_vrfy -sf ${CRES}_grid.tile7.halo${nh3_T7}.nc ${CRES}_grid.tile7.nc
#
#-----------------------------------------------------------------------
#
# The FV3SAR model looks for a file named "grid.tile7.halo4.nc" from
# which to read in the grid with a 4-cell-wide halo.  This data is crea-
# ted by the preprocessing but is placed in a file with a different name
# ("${CRES}_grid.tile7.halo4.nc").  Thus, we first copy the file created
# by the preprocessing to the INPUT subdirectory of the run directory
# and then create a symlink named "grid.tile7.halo4.nc" that points to
# it.
#
#-----------------------------------------------------------------------
#
cp_vrfy $WORKDIR_SHVE/${CRES}_grid.tile7.halo${nh4_T7}.nc .
ln_vrfy -sf ${CRES}_grid.tile7.halo${nh4_T7}.nc grid.tile7.halo${nh4_T7}.nc
#
#-----------------------------------------------------------------------
#
# The FV3SAR model looks for a file named "oro_data.tile7.halo4.nc" from
# which to read in the orogrpahy with a 4-cell-wide halo.  This data is
# created by the preprocessing but is placed in a file with a different
# name ("${CRES}_oro_data.tile7.halo4.nc").  Thus, we first copy the
# file created by the preprocessing to the INPUT subdirectory of the run
# directory and then create a symlink named "oro_data.tile7.halo4.nc"
# that points to it.
#
#-----------------------------------------------------------------------
#
cp_vrfy $WORKDIR_SHVE/${CRES}_oro_data.tile7.halo${nh4_T7}.nc .
ln_vrfy -sf ${CRES}_oro_data.tile7.halo${nh4_T7}.nc oro_data.tile7.halo${nh4_T7}.nc
#
#-----------------------------------------------------------------------
#
# The FV3SAR model looks for a file named "oro_data.nc" from which to
# read in the orogrpahy without a halo.  This data is created by the
# preprocessing but is placed in a file with a different name
# ("${CRES}_oro_data.tile7.halo0.nc").  Thus, we first copy the file
# created by the preprocessing to the INPUT subdirectory of the run di-
# rectory and then create a symlink named "oro_data.nc" that points to
# it.
#
#-----------------------------------------------------------------------
#
cp_vrfy $WORKDIR_SHVE/${CRES}_oro_data.tile7.halo${nh0_T7}.nc .
ln_vrfy -sf ${CRES}_oro_data.tile7.halo${nh0_T7}.nc oro_data.nc
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
cp_vrfy $WORKDIR_ICBC/gfs_data.tile7.nc .
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
cp_vrfy $WORKDIR_ICBC/sfc_data.tile7.nc .
ln_vrfy -sf sfc_data.tile7.nc sfc_data.nc
#
#-----------------------------------------------------------------------
#
# Copy the boundary files (one per boundary update time) to the INPUT
# subdirectory of the run directory.
#
#-----------------------------------------------------------------------
#
cp_vrfy $WORKDIR_ICBC/gfs_bndy*.nc .
#
#-----------------------------------------------------------------------
#
# Copy the file gfs_ctrl.nc containing information about the vertical
# coordinate and the number of tracers from its temporary location to
# the INPUT subdirectory of the run directory.
#
#-----------------------------------------------------------------------
#
cp_vrfy $WORKDIR_ICBC/gfs_ctrl.nc .
#
#-----------------------------------------------------------------------
#
# Print message indicating successful completion of script.
#
#-----------------------------------------------------------------------
#
print_info_msg "\

========================================================================
All necessary files and links needed to launch a forecast copied/created
successfully!!!
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
