#!/bin/bash
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
# Change shell behavior with "set" with these flags:
#
# -a 
# This will cause the script to automatically export all variables and 
# functions which are modified or created to the environments of subse-
# quent commands.
#
# -e 
# This will cause the script to exit as soon as any line in the script 
# fails (with some exceptions; see manual).  Apparently, it is a bad 
# idea to use "set -e".  See here:
#   http://mywiki.wooledge.org/BashFAQ/105
#
# -u 
# This will cause the script to exit if an undefined variable is encoun-
# tered.
#
# -x
# This will cause all executed commands in the script to be printed to 
# the terminal (used for debugging).
#
#-----------------------------------------------------------------------
#
#set -aux
#set -eux
set -ux
#
#-----------------------------------------------------------------------
#
# Source the script that defines the necessary shell environment varia-
# bles.
#
#-----------------------------------------------------------------------
#
. $SCRIPT_VAR_DEFNS_FP
#
#-----------------------------------------------------------------------
#
# Source the shell script containing the function that replaces variable
# values (or value placeholders) in several types of files (e.g. Fortran
# namelist files) with actual values.
#
#-----------------------------------------------------------------------
#
. $USHDIR/set_file_param.sh
#
#-----------------------------------------------------------------------
#
# Copy templates of various input files to the run directory.
#
#-----------------------------------------------------------------------
#
if [ $VERBOSE ]; then
  echo
  echo "Copying templates of various input files to the run directory..."
fi

cp $TEMPLATE_DIR/$FV3_NAMELIST_FN $RUNDIR
cp $TEMPLATE_DIR/$MODEL_CONFIG_FN $RUNDIR
cp $TEMPLATE_DIR/$DIAG_TABLE_FN $RUNDIR
cp $TEMPLATE_DIR/$FIELD_TABLE_FN $RUNDIR
cp $TEMPLATE_DIR/$DATA_TABLE_FN $RUNDIR
cp $TEMPLATE_DIR/$NEMS_CONFIG_FN $RUNDIR
#
#-----------------------------------------------------------------------
#
# Set parameters in the FV3SAR namelist file.
#
#-----------------------------------------------------------------------
#
FV3_NAMELIST_FP="$RUNDIR/$FV3_NAMELIST_FN"
if [ $VERBOSE ]; then
  echo
  echo "Setting parameters in file:"
  echo "  FV3_NAMELIST_FP = $FV3_NAMELIST_FP"
fi
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
set_file_param $FV3_NAMELIST_FP "layout" "$layout_x,$layout_y" $VERBOSE
set_file_param $FV3_NAMELIST_FP "npx" $npx_T7 $VERBOSE
set_file_param $FV3_NAMELIST_FP "npy" $npy_T7 $VERBOSE
set_file_param $FV3_NAMELIST_FP "target_lon" $lon_ctr_T6 $VERBOSE
set_file_param $FV3_NAMELIST_FP "target_lat" $lat_ctr_T6 $VERBOSE
set_file_param $FV3_NAMELIST_FP "stretch_fac" $stretch_fac $VERBOSE
set_file_param $FV3_NAMELIST_FP "bc_update_interval" $BC_update_intvl_hrs $VERBOSE
#
#-----------------------------------------------------------------------
#
# Set parameters in the model configuration file.
#
#-----------------------------------------------------------------------
#
MODEL_CONFIG_FP="$RUNDIR/$MODEL_CONFIG_FN"
if [ $VERBOSE ]; then
  echo
  echo "Setting parameters in file:"
  echo "  MODEL_CONFIG_FP = $MODEL_CONFIG_FP"
fi
#
#-----------------------------------------------------------------------
#
# If the write component is to be used, then a set of parameters that 
# define the write-component's output grid need to be specified in the
# MODEL_CONFIG file.  Templates for these are already available for the
# predefined RAP and HRRR domains and can simply be appended to the 
# file.  For other grids, they need to be manually specified in the mo-
# del configuration file.
#
#-----------------------------------------------------------------------
#
if [[ $quilting = ".true." ]]; then
#
  case $predef_domain in
#
  "RAP")
    cat $TEMPLATE_DIR/wrtcomp_RAP >> $MODEL_CONFIG_FP
    ;;
#
  "HRRR")
    cat $TEMPLATE_DIR/wrtcomp_HRRR >> $MODEL_CONFIG_FP
    ;;
#
  "")
    echo
    echo "In order to use the write component with a non-predefined \
FV3SAR native grid, the output grid must be specified in the file \
specified in the variable MODEL_CONFIG_FN:"
    echo "  MODEL_CONFIG_FN = $MODEL_CONFIG_FN"
    echo "This must be done manually."
    echo "Exiting script."
    exit 1
    ;;
#
  esac
#
fi

set_file_param $MODEL_CONFIG_FP "print_esmf" $print_esmf $VERBOSE
set_file_param $MODEL_CONFIG_FP "quilting" $quilting $VERBOSE
set_file_param $MODEL_CONFIG_FP "write_groups" $write_groups $VERBOSE
set_file_param $MODEL_CONFIG_FP "write_tasks_per_group" $write_tasks_per_group $VERBOSE
set_file_param $MODEL_CONFIG_FP "PE_MEMBER01" $PE_MEMBER01 $VERBOSE
set_file_param $MODEL_CONFIG_FP "start_year" $YYYY $VERBOSE
set_file_param $MODEL_CONFIG_FP "start_month" $MM $VERBOSE
set_file_param $MODEL_CONFIG_FP "start_day" $DD $VERBOSE
set_file_param $MODEL_CONFIG_FP "start_hour" $HH $VERBOSE
set_file_param $MODEL_CONFIG_FP "nhours_fcst" $fcst_len_hrs $VERBOSE
set_file_param $MODEL_CONFIG_FP "ncores_per_node" $ncores_per_node $VERBOSE
#
#-----------------------------------------------------------------------
#
# Set parameters in the file that specifies the fields to output.
#
#-----------------------------------------------------------------------
#
DIAG_TABLE_FP="$RUNDIR/$DIAG_TABLE_FN"
if [ $VERBOSE ]; then
  echo
  echo "Setting parameters in file:"
  echo "  DIAG_TABLE_FP = $DIAG_TABLE_FP"
fi

set_file_param $DIAG_TABLE_FP "CRES" $CRES $VERBOSE
set_file_param $DIAG_TABLE_FP "YYYY" $YYYY $VERBOSE
set_file_param $DIAG_TABLE_FP "MM" $MM $VERBOSE
set_file_param $DIAG_TABLE_FP "DD" $DD $VERBOSE
set_file_param $DIAG_TABLE_FP "HH" $HH $VERBOSE
set_file_param $DIAG_TABLE_FP "YYYYMMDD" $YMD $VERBOSE
#
#-----------------------------------------------------------------------
#
# Copy fixed files from system directory to run directory.  Note that 
# some of these files get renamed.
#
#-----------------------------------------------------------------------
#
if [ "$VERBOSE" = "true" ]; then
  echo
  echo "Copying fixed files from system directory to run directory..."
fi

cp $FIXgsm/CFSR.SEAICE.1982.2012.monthly.clim.grb $RUNDIR
cp $FIXgsm/RTGSST.1982.2012.monthly.clim.grb $RUNDIR
cp $FIXgsm/seaice_newland.grb $RUNDIR
cp $FIXgsm/global_climaeropac_global.txt $RUNDIR/aerosol.dat
cp $FIXgsm/global_albedo4.1x1.grb $RUNDIR
cp $FIXgsm/global_glacier.2x2.grb $RUNDIR
cp $FIXgsm/global_h2o_pltc.f77 $RUNDIR/global_h2oprdlos.f77
cp $FIXgsm/global_maxice.2x2.grb $RUNDIR
cp $FIXgsm/global_mxsnoalb.uariz.t126.384.190.rg.grb $RUNDIR
cp $FIXgsm/global_o3prdlos.f77 $RUNDIR
cp $FIXgsm/global_shdmax.0.144x0.144.grb $RUNDIR
cp $FIXgsm/global_shdmin.0.144x0.144.grb $RUNDIR
cp $FIXgsm/global_slope.1x1.grb $RUNDIR
cp $FIXgsm/global_snoclim.1.875.grb $RUNDIR
cp $FIXgsm/global_snowfree_albedo.bosu.t126.384.190.rg.grb $RUNDIR
cp $FIXgsm/global_soilmgldas.t126.384.190.grb $RUNDIR
cp $FIXgsm/global_soiltype.statsgo.t126.384.190.rg.grb $RUNDIR
cp $FIXgsm/global_tg3clim.2.6x1.5.grb $RUNDIR
cp $FIXgsm/global_vegfrac.0.144.decpercent.grb $RUNDIR
cp $FIXgsm/global_vegtype.igbp.t126.384.190.rg.grb $RUNDIR
cp $FIXgsm/global_zorclim.1x1.grb $RUNDIR
cp $FIXgsm/global_sfc_emissivity_idx.txt $RUNDIR/sfc_emissivity_idx.txt
cp $FIXgsm/global_solarconstant_noaa_an.txt $RUNDIR/solarconstant_noaa_an.txt
cp $FIXgsm/fix_co2_proj/global_co2historicaldata_2010.txt $RUNDIR/co2historicaldata_2010.txt
cp $FIXgsm/fix_co2_proj/global_co2historicaldata_2011.txt $RUNDIR/co2historicaldata_2011.txt
cp $FIXgsm/fix_co2_proj/global_co2historicaldata_2012.txt $RUNDIR/co2historicaldata_2012.txt
cp $FIXgsm/fix_co2_proj/global_co2historicaldata_2013.txt $RUNDIR/co2historicaldata_2013.txt
cp $FIXgsm/fix_co2_proj/global_co2historicaldata_2014.txt $RUNDIR/co2historicaldata_2014.txt
cp $FIXgsm/fix_co2_proj/global_co2historicaldata_2015.txt $RUNDIR/co2historicaldata_2015.txt
cp $FIXgsm/fix_co2_proj/global_co2historicaldata_2016.txt $RUNDIR/co2historicaldata_2016.txt
cp $FIXgsm/fix_co2_proj/global_co2historicaldata_2017.txt $RUNDIR/co2historicaldata_2017.txt
cp $FIXgsm/fix_co2_proj/global_co2historicaldata_2018.txt $RUNDIR/co2historicaldata_2018.txt
cp $FIXgsm/global_co2historicaldata_glob.txt $RUNDIR/co2historicaldata_glob.txt
cp $FIXgsm/co2monthlycyc.txt $RUNDIR
#
#-----------------------------------------------------------------------
#
# Copy the FV3SAR executable to the run directory.
#
#-----------------------------------------------------------------------
#
FV3SAR_EXEC="$BASEDIR/NEMSfv3gfs/tests/fv3_32bit.exe"

if [ -f $FV3SAR_EXEC ]; then
  
  if [ "$VERBOSE" = "true" ]; then
    echo
    echo "Copying FV3SAR executable to the run directory..."
  fi
  cp $BASEDIR/NEMSfv3gfs/tests/fv3_32bit.exe $RUNDIR/fv3_gfs.x
#  cp /scratch3/BMC/det/beck/FV3-CAM/NEMSfv3gfs/tests/fv3_32bit.exe $RUNDIR/fv3_gfs.x

else

  echo
  echo "The FV3SAR executable specified in FV3SAR_EXEC does not exist:"
  echo "  FV3SAR_EXEC = $FV3SAR_EXEC"
  echo "Build FV3SAR and rerun."
  echo "Exiting script."
  exit 1

fi
#
#-----------------------------------------------------------------------
#
# Copy files from various work directories into the run directory and 
# create necesary links.
#
#-----------------------------------------------------------------------
#
if [ "$VERBOSE" = "true" ]; then
  echo
  echo "Copying files from work directories into run directory and \
creating links..."
fi
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
cp $WORKDIR_GRID/${CRES}_mosaic.nc $RUNDIR/INPUT
ln -sf $RUNDIR/INPUT/${CRES}_mosaic.nc $RUNDIR/INPUT/grid_spec.nc
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
cp $WORKDIR_SHVE/${CRES}_grid.tile7.halo${nh3_T7}.nc $RUNDIR/INPUT
ln -sf $RUNDIR/INPUT/${CRES}_grid.tile7.halo${nh3_T7}.nc \
       $RUNDIR/INPUT/${CRES}_grid.tile7.nc
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
cp $WORKDIR_SHVE/${CRES}_grid.tile7.halo${nh4_T7}.nc $RUNDIR/INPUT
ln -sf $RUNDIR/INPUT/${CRES}_grid.tile7.halo${nh4_T7}.nc \
       $RUNDIR/INPUT/grid.tile7.halo${nh4_T7}.nc
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
cp $WORKDIR_SHVE/${CRES}_oro_data.tile7.halo${nh4_T7}.nc $RUNDIR/INPUT
ln -sf $RUNDIR/INPUT/${CRES}_oro_data.tile7.halo${nh4_T7}.nc \
       $RUNDIR/INPUT/oro_data.tile7.halo${nh4_T7}.nc
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
cp $WORKDIR_SHVE/${CRES}_oro_data.tile7.halo${nh0_T7}.nc $RUNDIR/INPUT
ln -sf $RUNDIR/INPUT/${CRES}_oro_data.tile7.halo${nh0_T7}.nc \
       $RUNDIR/INPUT/oro_data.nc
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
cp $WORKDIR_ICBC/gfs_data.tile7.nc $RUNDIR/INPUT
ln -sf $RUNDIR/INPUT/gfs_data.tile7.nc \
       $RUNDIR/INPUT/gfs_data.nc
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
cp $WORKDIR_ICBC/sfc_data.tile7.nc $RUNDIR/INPUT
ln -sf $RUNDIR/INPUT/sfc_data.tile7.nc \
       $RUNDIR/INPUT/sfc_data.nc
#
#-----------------------------------------------------------------------
#
# Copy the boundary files (one per boundary update time) to the INPUT 
# subdirectory of the run directory.
#
#-----------------------------------------------------------------------
#
cp $WORKDIR_ICBC/gfs_bndy*.nc $RUNDIR/INPUT
#
#-----------------------------------------------------------------------
#
# Copy the file gfs_ctrl.nc containing information about the vertical
# coordinate and the number of tracers from its temporary location to 
# the INPUT subdirectory of the run directory.
#
#-----------------------------------------------------------------------
#
cp $WORKDIR_ICBC/gfs_ctrl.nc $RUNDIR/INPUT


