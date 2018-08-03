#!/bin/bash

############################################
# Staging script to set up FV3 run directory
############################################

#Source variables from user-defined file
. ./setup_grid_orog_ICs_BCs.sh

#Define template namelist/configure file location
templates="${BASEDIR}/fv3gfs/ush/templates"

#Define fixed file location
fix_files=${FIXgsm}

#Define run directory
RUNDIR="${BASEDIR}/run_dirs/${subdir_name}"

#Make run directory if it doesn't already exist
if [ ! -d $RUNDIR ]; then
   echo "Making $RUNDIR..."
   mkdir $RUNDIR
else
   echo "Removing pre-existing $RUNDIR and creating $RUNDIR"
   rm -rf $RUNDIR
   mkdir $RUNDIR
fi

#Copy all namelist and configure file templates to the run directory
echo "Copying necessary namelist and configure file templates to the run directory..."
cp ${templates}/input.nml ${RUNDIR}
cp ${templates}/model_configure ${RUNDIR}
cp ${templates}/diag_table ${RUNDIR}
cp ${templates}/field_table ${RUNDIR}
cp ${templates}/nems.configure ${RUNDIR}
cp ${templates}/run.regional ${RUNDIR}/run.${CRES}.regional

#Place all fixed files into run directory
echo "Copying necessary fixed files into the run directory..."
cp ${fix_files}/CFSR.SEAICE.1982.2012.monthly.clim.grb ${RUNDIR}
cp ${fix_files}/RTGSST.1982.2012.monthly.clim.grb ${RUNDIR}
cp ${fix_files}/seaice_newland.grb ${RUNDIR}
cp ${fix_files}/global_climaeropac_global.txt ${RUNDIR}/aerosol.dat
cp ${fix_files}/global_albedo4.1x1.grb ${RUNDIR}
cp ${fix_files}/global_glacier.2x2.grb ${RUNDIR}
cp ${fix_files}/global_h2o_pltc.f77 ${RUNDIR}/global_h2oprdlos.f77
cp ${fix_files}/global_maxice.2x2.grb ${RUNDIR}
cp ${fix_files}/global_mxsnoalb.uariz.t126.384.190.rg.grb ${RUNDIR}
cp ${fix_files}/global_o3prdlos.f77 ${RUNDIR}
cp ${fix_files}/global_shdmax.0.144x0.144.grb ${RUNDIR}
cp ${fix_files}/global_shdmin.0.144x0.144.grb ${RUNDIR}
cp ${fix_files}/global_slope.1x1.grb ${RUNDIR}
cp ${fix_files}/global_snoclim.1.875.grb ${RUNDIR}
cp ${fix_files}/global_snowfree_albedo.bosu.t126.384.190.rg.grb ${RUNDIR}
cp ${fix_files}/global_soilmgldas.t126.384.190.grb ${RUNDIR}
cp ${fix_files}/global_soiltype.statsgo.t126.384.190.rg.grb ${RUNDIR}
cp ${fix_files}/global_tg3clim.2.6x1.5.grb ${RUNDIR}
cp ${fix_files}/global_vegfrac.0.144.decpercent.grb ${RUNDIR}
cp ${fix_files}/global_vegtype.igbp.t126.384.190.rg.grb ${RUNDIR}
cp ${fix_files}/global_zorclim.1x1.grb ${RUNDIR}
cp ${fix_files}/global_sfc_emissivity_idx.txt ${RUNDIR}/sfc_emissivity_idx.txt
cp ${fix_files}/global_solarconstant_noaa_an.txt ${RUNDIR}/solarconstant_noaa_an.txt
cp ${fix_files}/fix_co2_proj/global_co2historicaldata_2010.txt ${RUNDIR}/co2historicaldata_2010.txt
cp ${fix_files}/fix_co2_proj/global_co2historicaldata_2011.txt ${RUNDIR}/co2historicaldata_2011.txt
cp ${fix_files}/fix_co2_proj/global_co2historicaldata_2012.txt ${RUNDIR}/co2historicaldata_2012.txt
cp ${fix_files}/fix_co2_proj/global_co2historicaldata_2013.txt ${RUNDIR}/co2historicaldata_2013.txt
cp ${fix_files}/fix_co2_proj/global_co2historicaldata_2014.txt ${RUNDIR}/co2historicaldata_2014.txt
cp ${fix_files}/fix_co2_proj/global_co2historicaldata_2015.txt ${RUNDIR}/co2historicaldata_2015.txt
cp ${fix_files}/fix_co2_proj/global_co2historicaldata_2016.txt ${RUNDIR}/co2historicaldata_2016.txt
cp ${fix_files}/fix_co2_proj/global_co2historicaldata_2017.txt ${RUNDIR}/co2historicaldata_2017.txt
cp ${fix_files}/fix_co2_proj/global_co2historicaldata_2018.txt ${RUNDIR}/co2historicaldata_2018.txt
cp ${fix_files}/global_co2historicaldata_glob.txt ${RUNDIR}/co2historicaldata_glob.txt
cp ${fix_files}/co2monthlycyc.txt ${RUNDIR}

#Copy FV3 executable to run directory
#echo "Copying FV3 executable to run directory..."
#cp $BASEDIR/NEMSfv3gfs/tests/fv3_32bit.exe $RUNDIR/fv3_gfs.x

#Make INPUT directory within the run directory if it doesn't already exist
if [ ! -d $RUNDIR/INPUT ]; then
   echo "Making $RUNDIR/INPUT..."
   mkdir $RUNDIR/INPUT
else
   echo "Removing and recreating pre-existing INPUT directory"
   rm -rf $RUNDIR/INPUT
   mkdir $RUNDIR/INPUT
fi

#Copy, rename, and link pre-processing NetCDF files to ${RUNDIR}/INPUT
cp ${out_dir}/${CRES}_grid.tile7.halo3.nc ${RUNDIR}/INPUT
ln -s ${RUNDIR}/INPUT/${CRES}_grid.tile7.halo3.nc ${RUNDIR}/INPUT/${CRES}_grid.tile7.nc
cp ${out_dir}/${CRES}_grid.tile7.halo4.nc ${RUNDIR}/INPUT
ln -s ${RUNDIR}/INPUT/${CRES}_grid.tile7.halo4.nc ${RUNDIR}/INPUT/grid.tile7.halo4.nc
cp ${out_dir}/${CRES}_mosaic.nc ${RUNDIR}/INPUT
ln -s ${RUNDIR}/INPUT/${CRES}_mosaic.nc ${RUNDIR}/INPUT/grid_spec.nc
cp ${out_dir}/${CRES}_oro_data.tile7.halo0.nc ${RUNDIR}/INPUT/${CRES}_oro_data.tile7.halo0.nc
cp ${out_dir}/${CRES}_oro_data.tile7.halo4.nc ${RUNDIR}/INPUT/${CRES}_oro_data.tile7.halo4.nc
ln -s ${RUNDIR}/INPUT/${CRES}_oro_data.tile7.halo0.nc ${RUNDIR}/INPUT/${CRES}_oro_data.tile7.nc
ln -s ${RUNDIR}/INPUT/${CRES}_oro_data.tile7.halo0.nc ${RUNDIR}/INPUT/oro_data.nc
ln -s ${RUNDIR}/INPUT/${CRES}_oro_data.tile7.halo4.nc ${RUNDIR}/INPUT/oro_data.tile7.halo4.nc
cp ${out_dir}/gfs* ${RUNDIR}/INPUT
ln -s ${RUNDIR}/INPUT/gfs_data.tile7.nc ${RUNDIR}/INPUT/gfs_data.nc
cp ${out_dir}/sfc_data.tile7.nc ${RUNDIR}/INPUT
ln -s ${RUNDIR}/INPUT/sfc_data.tile7.nc ${RUNDIR}/INPUT/sfc_data.nc

##############################################
# Compute math required for grid decomposition
##############################################

#Define cores per node for current system
cores_per_node=24 #Theia
#cores_per_node=?? #Jet
#cores_per_node=?? #Cheyenne

#Define layout_x and layout_y
layout_x=15  #19 - for HRRR
layout_y=15  #25 - for HRRR

#Define run directory
RUNDIR="${BASEDIR}/run_dirs/${subdir_name}"

####################################

#Verify that directories/files exist

#Check to make sure the run directory exists
if [ ! -d $RUNDIR ]; then
   echo "$RUNDIR does not exist.  Please create it first.  Exiting..."
   exit 1
fi  
    
#Verify that input.nml exists

if [ ! -f $RUNDIR/input.nml ]; then
   echo "input.xml does not exist.  Check your run directory.  Exiting..."
   exit 1
fi

#Verify that model_configure exists

if [ ! -f $RUNDIR/model_configure ]; then
   echo "model_configure does not exist.  Check your run directory.  Exiting..."
   exit 1
fi

#Verify that run script exists

if [ ! -f $RUNDIR/run.${CRES}.regional ]; then
   echo "Run script, run.${CRES}.regional, does not exist.  Check your run directory.  Exiting..."
   exit 1
fi

cd $RUNDIR

#Read lat and lon dimensions from NetCDF file
lat=$(ncdump -h ${RUNDIR}/INPUT/sfc_data.tile7.nc | grep "lat =" | sed -e "s/.*= //;s/ .*//")
lon=$(ncdump -h ${RUNDIR}/INPUT/sfc_data.tile7.nc | grep "lon =" | sed -e "s/.*= //;s/ .*//")

echo "FV3 domain dimensions for selected case:"
echo "Latitude = $lat"
echo "Longitude = $lon"
             
#Define npx and npy
npx=$(($lon+1))
npy=$(($lat+1))
    
echo ""
echo "For input.nml:"
echo "npx = $npx"
echo "npy = $npy"
echo ""
    
#Modify npx and npy values in input.nml
echo "Modifying npx and npy values in input.nml..."
echo ""
sed -i -r -e "s/^(\s*npx\s*=)(.*)/\1 $npx/" ${RUNDIR}/input.nml
sed -i -r -e "s/^(\s*npy\s*=)(.*)/\1 $npy/" ${RUNDIR}/input.nml

#Modify target_lat, target_lon, stretch_fac in input.nml
echo "Modifying target_lat and target_lon in input.nml..."
echo ""
sed -i -r -e "s/^(\s*target_lat\s*=)(.*)/\1 $target_lat/" ${RUNDIR}/input.nml
sed -i -r -e "s/^(\s*target_lon\s*=)(.*)/\1 $target_lon/" ${RUNDIR}/input.nml
sed -i -r -e "s/^(\s*stretch_fac\s*=)(.*)/\1 $stretch_fac/" ${RUNDIR}/input.nml

#Test whether dimensions values are evenly divisible by user-chosen layout_x and layout_y

if [[ $(( $lat%$layout_y )) -eq 0 ]]; then
   echo "Latitude dimension is evenly divisible by user-defined layout_y"
else
   echo "Latitude dimension is not evenly divisible by user-defined layout_y, please redefine.  Exiting."
   exit 1
fi

if [[ $(( $lon%$layout_x )) -eq 0 ]]; then 
   echo "Longitude dimension is evenly divisible by user-defined layout_x"
else  
   echo "Longitude dimension is not evenly divisible by user-defined layout_x, please redefine.  Exiting."
   exit 1
fi
 
echo ""
echo "Value for layout(x): $layout_x"
echo "Value for layout(y): $layout_y"
    
echo ""
echo "Layout for input.nml: $layout_x,$layout_y"
echo ""

#Modify layout_x and layout_y values in input.nml
echo "Modifying layout_x and layout_y values in input.nml..."
sed -i -r -e "s/^(\s*layout\s*=\s*)(.*)/\1$layout_x,$layout_y/" ${RUNDIR}/input.nml

#Calculate PE_MEMBER01
PE_MEMBER01=$(($layout_x*$layout_y))

echo ""
echo "PE_MEMBER01 for model_configure: $PE_MEMBER01"
echo ""

#Modify values in model_configure
echo "Modifying PE_MEMBER01 in model_configure... "
echo ""
sed -i -r -e "s/^(\s*PE_MEMBER01:\s*)(.*)/\1$PE_MEMBER01/" ${RUNDIR}/model_configure

echo "Modifying simulation date and time in model_configure... "
echo ""
sed -i -r -e "s/^(\s*start_year:\s*)(.*)/\1$start_year/" ${RUNDIR}/model_configure
sed -i -r -e "s/^(\s*start_month:\s*)(.*)/\1$start_month/" ${RUNDIR}/model_configure
sed -i -r -e "s/^(\s*start_day:\s*)(.*)/\1$start_day/" ${RUNDIR}/model_configure
sed -i -r -e "s/^(\s*start_hour:\s*)(.*)/\1$start_hour/" ${RUNDIR}/model_configure

echo "Modifying forecast length in model_configure... "
echo ""
sed -i -r -e "s/^(\s*nhours_fcst:\s*)(.*)/\1$fcst_len_hrs/" ${RUNDIR}/model_configure

#Modify simulation date, time, and resolution in diag_table
echo "Modifying simulation date and time in diag_table... "
echo ""
sed -i -r -e "s/YYYYMMDD.HHZ.CRES/${start_year}${start_month}${start_day}.${start_hour}Z.${CRES}/" ${RUNDIR}/diag_table
sed -i -r -e "s/YYYY MM DD HH/${start_year} ${start_month} ${start_day} ${start_hour}/" ${RUNDIR}/diag_table

#Calculate values for nodes and ppn for job scheduler
PPN=$cores_per_node 
      
Nodes=$(( ($PE_MEMBER01+$cores_per_node-1)/$cores_per_node ))

echo "Nodes: $Nodes"
echo "PPN: $PPN"
echo"" 
    
#Modify nodes and PPN in the run script
echo "Modifying nodes and PPN in run.${CRES}.regional..."
echo ""
sed -i -r -e "s/^(#PBS.*nodes=)([^:]*)(:.*)/\1$Nodes\3/" ${RUNDIR}/run.${CRES}.regional
sed -i -r -e "s/(ppn=)(.*)/\1$PPN/" ${RUNDIR}/run.${CRES}.regional

#Modify $RUNDIR in run.${CRES}.regionl
echo "Modifying run directory in run.${CRES}.regional..."
sed -i -r -e "s/\$\{RUNDIR\}/${RUNDIR}" ${RUNDIR}/run.${CRES}.regional
