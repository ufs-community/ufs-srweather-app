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

############################################
# Staging script to set up FV3 run directory
############################################

set -ux

# Source the script that defines the necessary shell environment varia-
# bles.
. $RUNDIR/var_defns.sh

#Copy all namelist and configure file templates to the run directory
echo "Copying necessary namelist and configure file templates to the run directory..."
cp $TEMPLATE_DIR/input.nml $RUNDIR
cp $TEMPLATE_DIR/diag_table $RUNDIR
cp $TEMPLATE_DIR/field_table $RUNDIR
cp $TEMPLATE_DIR/nems.configure $RUNDIR
cp $TEMPLATE_DIR/run.regional $RUNDIR/run.regional
cp $TEMPLATE_DIR/data_table $RUNDIR
cp $TEMPLATE_DIR/model_configure $RUNDIR/model_configure

#Append model_configure file depending on quilting and preset domain

if [[ $quilting = ".true." ]]; then

  if [[ $predef_rgnl_domain = "HRRR" ]]; then

    cat $TEMPLATE_DIR/wrtcomp_HRRR >> $RUNDIR/model_configure   

  elif [[ $predef_rgnl_domain = "RAP" ]]; then

    cat $TEMPLATE_DIR/wrtcomp_RAP >> $RUNDIR/model_configure

  else

    echo "Please define model output projection and grid manually in model_configure file."
    exit 1

  fi

fi

#Place all fixed files in run directory
echo "Copying necessary fixed files to the run directory..."
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

#Check to make sure FV3 executable exists and copy to run directory
if [ ! -f $BASEDIR/NEMSfv3gfs/tests/fv3_32bit.exe ]; then
   echo "FV3 executable does not exist, please compile first.  Exiting..."
   exit 1
else
   echo "Copying FV3 executable to run directory..."
   cp $BASEDIR/NEMSfv3gfs/tests/fv3_32bit.exe $RUNDIR/fv3_gfs.x
#   cp /scratch3/BMC/det/beck/FV3-CAM/NEMSfv3gfs/tests/fv3_32bit.exe $RUNDIR/fv3_gfs.x
fi


#Make RESTART directory within the run directory if it doesn't already exist
if [ ! -d $RUNDIR/RESTART ]; then
   echo "Making $RUNDIR/RESTART..."
   mkdir $RUNDIR/RESTART
else
   echo "Removing and recreating pre-existing RESTART directory"
   rm -rf $RUNDIR/RESTART
   mkdir $RUNDIR/RESTART
fi


#Copy, rename, and link pre-processing NetCDF files to $RUNDIR/INPUT

#
# Copy the grid mosaic file (which describes the connectivity of the va-
# rious tiles) to the INPUT subdirectory of the run directory.  In the 
# regional case, this file doesn't have much information because the 
# regional grid is not connected to any other tiles.  However, a mosaic
# file (with a different name; see below) must still be read in by the
# FV3 code.
#
# Note that the FV3 code (specifically the FMS code) looks for a file 
# named "grid_spec.nc" in the INPUT subdirectory of the run directory
# as the grid mosaic file.  Assuming it finds this file, it then reads 
# in the variable "gridfiles" in this file that contains the names of 
# the grid files for each of the tiles of the grid.  In the regional
# case, "gridfiles" will contain only one file name, that of the file
# describing the grid on tile 7. 
#
cp $WORKDIR_GRID/$CRES_mosaic.nc $RUNDIR/INPUT
ln -sf $RUNDIR/INPUT/$CRES_mosaic.nc $RUNDIR/INPUT/grid_spec.nc
#
# The variable "gridfiles" in grid_spec.nc will contain a file name of
# $CRES_grid.tile7.nc, and the FV3 code will try to read this file.  
# This file should contain the regional grid with a halo of 3 cells.
# Thus, we first copy the grid file with a 3-cell halo to the INPUT 
# subdirectory of the run directory, and we then create a link named
# {CRES}_grid.tile7.nc that points to this file.
#
cp $WORKDIR_SHVE/$CRES_grid.tile7.halo${halo}.nc $RUNDIR/INPUT
ln -sf $RUNDIR/INPUT/$CRES_grid.tile7.halo${halo}.nc \
       $RUNDIR/INPUT/$CRES_grid.tile7.nc
#
# Copy the grid file with a halo of 4 cells to the INPUT subdirectory of
# the run directory.  The regional portion of the FV3 code looks for a 
# file named "grid.tile7.halo4.nc" from which to read in the regional 
# grid, but this is not the name of the grid file that the preprocessing
# generates.  Thus, we create a link with this name that points to the 
# grid file.
#
cp $WORKDIR_SHVE/$CRES_grid.tile7.halo${halop1}.nc $RUNDIR/INPUT
ln -sf $RUNDIR/INPUT/$CRES_grid.tile7.halo${halop1}.nc \
       $RUNDIR/INPUT/grid.tile7.halo${halop1}.nc
#
# Copy the filtered orography file with a halo of 4 cells to the INPUT 
# subdirectory of the run directory.  The regional portion of the FV3 
# code looks for a file named "oro_data.tile7.halo4.nc" from which to 
# read in the orogrpahy, but this is not the name of the filtered oro-
# graphy file that the preprocessing generates.  Thus, we create a link
# with this name that points to the orography file.
#
cp $WORKDIR_SHVE/$CRES_oro_data.tile7.halo${halop1}.nc $RUNDIR/INPUT
ln -sf $RUNDIR/INPUT/$CRES_oro_data.tile7.halo${halop1}.nc \
       $RUNDIR/INPUT/oro_data.tile7.halo${halop1}.nc
#
# It turns out that the FV3 model also needs to read in a file named 
# "oro_data.nc" that contains the filtered orography without any halo
# cells.  Copy that file from the shave directory to the INPUT subdi-
# rectory of the run directory and create a link with the aforementioned
# name that points to it.
#
cp $WORKDIR_SHVE/$CRES_oro_data.tile7.halo${halo0}.nc $RUNDIR/INPUT
ln -sf $RUNDIR/INPUT/$CRES_oro_data.tile7.halo${halo0}.nc \
       $RUNDIR/INPUT/oro_data.nc
#
# Copy the ICs file (with a halo of 4 cells since the input grid and 
# orography files to the chgres program that created the ICs file had 4
# 4 cells) to the INPUT subdirectory of the run directory.  The FV3 code
# looks for a file named "gfs_data.nc" from which to read in the ICs, 
# but this is not the name of the ICs file that the preprocessing gene-
# rates.  Thus, we create a link with this name that points to the ICs
# file.
#
cp $WORKDIR_ICBC/gfs_data.tile7.nc $RUNDIR/INPUT
ln -sf $RUNDIR/INPUT/gfs_data.tile7.nc \
       $RUNDIR/INPUT/gfs_data.nc
#
# Copy the surface file (with a halo of 4 cells since the input grid and 
# orography files to the chgres program that created the surface file 
# had 4 halo cells) to the INPUT subdirectory of the run directory.  The
# FV3 code looks for a file named "gfs_data.nc" from which to read in 
# the ICs, but this is not the name of the ICs file that the preprocess-
# ing generates.  Thus, we create a link with this name that points to 
# the ICs file.
#
cp $WORKDIR_ICBC/sfc_data.tile7.nc $RUNDIR/INPUT
ln -sf $RUNDIR/INPUT/sfc_data.tile7.nc \
       $RUNDIR/INPUT/sfc_data.nc
#
# Copy the boundary files (one per boundary update time) to the INPUT 
# subdirectory of the run directory.
#
cp $WORKDIR_ICBC/gfs_bndy*.nc $RUNDIR/INPUT
#
# Copy the file gfs_ctrl.nc containing information about the vertical
# coordinate and the number of tracers from its temporary location to 
# the INPUT subdirectory of the run directory.
#
cp $WORKDIR_ICBC/gfs_ctrl.nc $RUNDIR/INPUT



if [ 0 = 1 ]; then
#
##cp ${out_dir}/$CRES_oro_data.tile7.halo0.nc $RUNDIR/INPUT/$CRES_oro_data.tile7.halo0.nc
##cp ${out_dir}/$CRES_oro_data.tile7.halo4.nc $RUNDIR/INPUT/$CRES_oro_data.tile7.halo4.nc
#
ln -sf $RUNDIR/INPUT/$CRES_oro_data.tile7.halo${halo0}.nc \
       $RUNDIR/INPUT/$CRES_oro_data.tile7.nc

fi

#############################################################################################################3###
# Math required for grid decomposition and sed commands to replace template values in namelists/configure files #
#################################################################################################################

cd $RUNDIR

# Read in the grid dimensions from the NetCDF file containing surface
# fields.
nx=$(ncdump -h $RUNDIR/INPUT/sfc_data.tile7.nc | grep "lon =" | sed -e "s/.*= //;s/ .*//")
ny=$(ncdump -h $RUNDIR/INPUT/sfc_data.tile7.nc | grep "lat =" | sed -e "s/.*= //;s/ .*//")

echo "FV3SAR regional domain dimensions:"
echo "  nx = $nx"
echo "  ny = $ny"
             
# Set npx and npy.
npx=$(( $nx+1 ))
npy=$(( $ny+1))
    
echo ""
echo "For input.nml:"
echo "npx = $npx"
echo "npy = $npy"
echo ""
    
#Modify npx and npy values in input.nml
echo "Modifying npx and npy values in input.nml..."
echo ""
sed -i -r -e "s/^(\s*npx\s*=)(.*)/\1 $npx/" $RUNDIR/input.nml
sed -i -r -e "s/^(\s*npy\s*=)(.*)/\1 $npy/" $RUNDIR/input.nml

#Modify target_lon, target_lat, stretch_fac in input.nml
echo "Modifying target_lat and target_lon in input.nml..."
echo ""
sed -i -r -e "s/^(\s*target_lon\s*=)(.*)/\1 $lon_ctr_T6/" $RUNDIR/input.nml
sed -i -r -e "s/^(\s*target_lat\s*=)(.*)/\1 $lat_ctr_T6/" $RUNDIR/input.nml
sed -i -r -e "s/^(\s*stretch_fac\s*=)(.*)/\1 $stretch_fac/" $RUNDIR/input.nml
sed -i -r -e "s/^(\s*bc_update_interval\s*=)(.*)/\1 $BC_update_intvl_hrs/" $RUNDIR/input.nml

#Test whether dimensions values are evenly divisible by user-chosen layout_x and layout_y.

# Make sure number of cells in y direction is divisible by layout_y.
if [[ $(( $ny%$layout_y )) -eq 0 ]]; then
   echo "Latitude dimension ($ny) is evenly divisible by user-defined layout_y ($layout_y)"
else
   echo "Latitude dimension ($ny) is not evenly divisible by user-defined layout_y ($layout_y), please redefine.  Exiting."
   exit 1
fi

#Make sure longitude dimension is divisible by layout_x.
if [[ $(( $lon%$layout_x )) -eq 0 ]]; then 
   echo "Longitude dimension ($lon) is evenly divisible by user-defined layout_x ($layout_x)"
else  
   echo "Longitude dimension ($lon) is not evenly divisible by user-defined layout_x ($layout_x), please redefine.  Exiting."
   exit 1
fi

#If the write component is turned on, make sure PE_MEMBER01 is divisible by write_tasks_per_group.
if [[ $quilting = ".true." ]]; then
 
 if [[ $(( (($layout_x*$layout_y)+($write_groups*$write_tasks_per_group))%$write_tasks_per_group )) -eq 0 ]]; then
    echo "Value of PE_MEMBER01 ($(( ($layout_x*$layout_y)+($write_groups*$write_tasks_per_group) ))) is evenly divisible by write_tasks_per_group ($write_tasks_per_group)."
 else
    echo "Value of PE_MEMBER01 ($(( ($layout_x*$layout_y)+($write_groups*$write_tasks_per_group) ))) is not evenly divisible by write_tasks_per_group ($write_tasks_per_group), please redefine.  Exiting."
    exit 1
 fi

else
  : #Do nothing
fi
 
echo ""
echo "Value for layout(x): $layout_x"
echo "Value for layout(y): $layout_y"
    
echo ""
echo "Layout for input.nml: $layout_x,$layout_y"
echo ""

#Modify layout_x and layout_y values in input.nml
echo "Modifying layout_x and layout_y values in input.nml..."
sed -i -r -e "s/^(\s*layout\s*=\s*)(.*)/\1$layout_x,$layout_y/" $RUNDIR/input.nml

#Calculate PE_MEMBER01
if [[ $quilting = ".true." ]]; then

#Add write_groups*write_tasks_per_group to the product of layout_x and layout_y for the write component.
  PE_MEMBER01=$(( ($layout_x*$layout_y)+($write_groups*$write_tasks_per_group) ))

else

  PE_MEMBER01=$(( $layout_x*$layout_y ))

fi

echo ""
echo "PE_MEMBER01 for model_configure: ${PE_MEMBER01}"
echo ""

#Modify values in model_configure
echo "Modifying print_esmf flag in model_configure... "
echo ""
sed -i -r -e "s/^(\s*print_esmf:\s*)(.*)/\1$print_esmf/" $RUNDIR/model_configure

echo "Modifying quilting flag in model_configure... "
echo ""
sed -i -r -e "s/^(\s*quilting:\s*)(.*)/\1$quilting/" $RUNDIR/model_configure

echo "Modifying write_groups in model_configure... "
echo ""
sed -i -r -e "s/^(\s*write_groups:\s*)(.*)/\1$write_groups/" $RUNDIR/model_configure

echo "Modifying write_tasks_per_group in model_configure... "
echo ""
sed -i -r -e "s/^(\s*write_tasks_per_group:\s*)(.*)/\1$write_tasks_per_group/" $RUNDIR/model_configure

echo "Modifying PE_MEMBER01 in model_configure... "
echo ""
sed -i -r -e "s/^(\s*PE_MEMBER01:\s*)(.*)/\1$PE_MEMBER01/" $RUNDIR/model_configure

echo "Modifying simulation date and time in model_configure... "
echo ""
sed -i -r -e "s/^(\s*start_year:\s*)(<start_year>)(.*)/\1${YYYY}\3/" $RUNDIR/model_configure
sed -i -r -e "s/^(\s*start_month:\s*)(<start_month>)(.*)/\1${MM}\3/" $RUNDIR/model_configure
sed -i -r -e "s/^(\s*start_day:\s*)(<start_day>)(.*)/\1${DD}\3/" $RUNDIR/model_configure
sed -i -r -e "s/^(\s*start_hour:\s*)(<start_hour>)(.*)/\1${HH}\3/" $RUNDIR/model_configure

echo "Modifying forecast length in model_configure... "
echo ""
sed -i -r -e "s/^(\s*nhours_fcst:\s*)(.*)/\1$fcst_len_hrs/" $RUNDIR/model_configure

#Modify simulation date, time, and resolution in diag_table
echo "Modifying simulation date and time in diag_table... "
echo ""
sed -i -r -e "s/^<YYYYMMDD>\.<HH>Z\.<CRES>/${YMD}\.${HH}Z\.$CRES/" $RUNDIR/diag_table
sed -i -r -e "s/^<YYYY>\s+<MM>\s+<DD>\s+<HH>\s+/${YYYY} ${MM} ${DD} ${HH} /" $RUNDIR/diag_table

#Modify cores per node
echo "Modifying number of cores per node in model_configure... "
echo ""
sed -i -r -e "s/^(\s*ncores_per_node:\s*)(.*)/\1$ncores_per_node/" $RUNDIR/model_configure

#Calculate values for nodes and ppn for job scheduler
PPN=$ncores_per_node 
      
Nodes=$(( ($PE_MEMBER01+$ncores_per_node-1)/$ncores_per_node ))

echo "Nodes: $Nodes"
echo "PPN: $PPN"
echo "" 
    
#Modify nodes and PPN in the run script
echo "Modifying nodes and PPN in run.regional..."
echo ""
sed -i -r -e "s/^(#PBS.*nodes=)([^:]*)(:.*)/\1$Nodes\3/" $RUNDIR/run.regional
sed -i -r -e "s/(ppn=)(.*)/\1$PPN/" $RUNDIR/run.regional

#Modify $RUNDIR in run.regional
echo "Modifying run directory in run.$CRES.regional..."
sed -i -r -e 's+\$\{RUNDIR\}+'"$RUNDIR"'+' $RUNDIR/run.regional

#Modify $PBS_NP in run.regional
echo "Modifying \$PBS_NP directory in run.$CRES.regional..."
sed -i -r -e 's+\$PBS_NP+'"${PE_MEMBER01}"'+' $RUNDIR/run.regional

#Modify FV3 run proc in FV3_Theia.xml
echo "Modifying FV3 run proc in FV3_Theia.xml..."
REGEXP="(^\s*<!ENTITY\s*FV3_PROC\s*\")(.*)(\">.*)"
sed -i -r -e "s/$REGEXP/\1${Nodes}:ppn=${PPN}\3/g" ${BASEDIR}/fv3gfs/regional/FV3_Theia.xml
