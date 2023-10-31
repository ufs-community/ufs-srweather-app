#!/bin/bash 
#
export dev_fix=/lfs/h2/emc/physics/noscrub/UFS_SRW_App/aqm.v7/fix
cd ../

export HOMEaqm=$(pwd)

mkdir -p $HOMEaqm/fix
cd $HOMEaqm/fix
for var in aqm bio canopy chem_lbcs FENGSHA fire fix_aer fix_am fix_lut fix_orog fix_sfc_climo nexus restart 
 do 
 cp -rp ${dev_fix}/$var .
done

mkdir -p $HOMEaqm/fix/fix_lam
cd ${HOMEaqm}/fix/fix_lam
ln -s $HOMEaqm/fix/aqm/DOMAIN_DATA/AQM_NA_13km/C793_mosaic.halo6.nc C793_mosaic.halo6.nc
ln -s $HOMEaqm/fix/aqm/DOMAIN_DATA/AQM_NA_13km/C793_mosaic.halo4.nc C793_mosaic.halo4.nc
ln -s $HOMEaqm/fix/aqm/DOMAIN_DATA/AQM_NA_13km/C793_mosaic.halo3.nc C793_mosaic.halo3.nc 
ln -s  C793_grid.tile7.halo4.nc C793_grid.tile7.nc
ln -s ${HOMEaqm}/fix/aqm/DOMAIN_DATA/AQM_NA_13km/C793_grid.tile7.halo6.nc C793_grid.tile7.halo6.nc
ln -s ${HOMEaqm}/fix/aqm/DOMAIN_DATA/AQM_NA_13km/C793_grid.tile7.halo4.nc C793_grid.tile7.halo4.nc 
ln -s ${HOMEaqm}/fix/aqm/DOMAIN_DATA/AQM_NA_13km/C793_grid.tile7.halo3.nc C793_grid.tile7.halo3.nc 
ln -s C793.vegetation_type.tile7.halo4.nc C793.vegetation_type.tile7.nc
ln -s ${HOMEaqm}/fix/aqm/DOMAIN_DATA/AQM_NA_13km/C793.vegetation_type.tile7.halo4.nc C793.vegetation_type.tile7.halo4.nc 
ln -s ${HOMEaqm}/fix/aqm/DOMAIN_DATA/AQM_NA_13km/C793.vegetation_type.tile7.halo0.nc C793.vegetation_type.tile7.halo0.nc 
ln -s C793.vegetation_type.tile7.halo0.nc  C793.vegetation_type.tile1.nc
ln -s C793.vegetation_greenness.tile7.halo4.nc C793.vegetation_greenness.tile7.nc
ln -s $HOMEaqm/fix/aqm/DOMAIN_DATA/AQM_NA_13km/C793.vegetation_greenness.tile7.halo4.nc C793.vegetation_greenness.tile7.halo4.nc
ln -s $HOMEaqm/fix/aqm/DOMAIN_DATA/AQM_NA_13km/C793.vegetation_greenness.tile7.halo0.nc C793.vegetation_greenness.tile7.halo0.nc
ln -s  C793.vegetation_greenness.tile7.halo0.nc  C793.vegetation_greenness.tile1.nc
ln -s  C793.substrate_temperature.tile7.halo4.nc C793.substrate_temperature.tile7.nc 
ln -s $HOMEaqm/fix/aqm/DOMAIN_DATA/AQM_NA_13km/C793.substrate_temperature.tile7.halo4.nc C793.substrate_temperature.tile7.halo4.nc
ln -s $HOMEaqm/fix/aqm/DOMAIN_DATA/AQM_NA_13km/C793.substrate_temperature.tile7.halo0.nc C793.substrate_temperature.tile7.halo0.nc 
ln -s C793.substrate_temperature.tile7.halo0.nc C793.substrate_temperature.tile1.nc
ln -s C793.soil_type.tile7.halo4.nc C793.soil_type.tile7.nc
ln -s $HOMEaqm/fix/aqm/DOMAIN_DATA/AQM_NA_13km/C793.soil_type.tile7.halo4.nc C793.soil_type.tile7.halo4.nc
ln -s $HOMEaqm/fix/aqm/DOMAIN_DATA/AQM_NA_13km/C793.soil_type.tile7.halo0.nc C793.soil_type.tile7.halo0.nc
ln -s C793.soil_type.tile7.halo0.nc C793.soil_type.tile1.nc
ln -s C793.snowfree_albedo.tile7.halo4.nc C793.snowfree_albedo.tile7.nc
ln -s $HOMEaqm/fix/aqm/DOMAIN_DATA/AQM_NA_13km/C793.snowfree_albedo.tile7.halo4.nc C793.snowfree_albedo.tile7.halo4.nc 
ln -s $HOMEaqm/fix/aqm/DOMAIN_DATA/AQM_NA_13km/C793.snowfree_albedo.tile7.halo0.nc C793.snowfree_albedo.tile7.halo0.nc
ln -s C793.snowfree_albedo.tile7.halo0.nc C793.snowfree_albedo.tile1.nc
ln -s C793.slope_type.tile7.halo4.nc C793.slope_type.tile7.nc
ln -s $HOMEaqm/fix/aqm/DOMAIN_DATA/AQM_NA_13km/C793.slope_type.tile7.halo4.nc C793.slope_type.tile7.halo4.nc
ln -s $HOMEaqm/fix/aqm/DOMAIN_DATA/AQM_NA_13km/C793.slope_type.tile7.halo0.nc C793.slope_type.tile7.halo0.nc 
ln -s C793.slope_type.tile7.halo0.nc C793.slope_type.tile1.nc
ln -s $HOMEaqm/fix/aqm/DOMAIN_DATA/AQM_NA_13km/C793_oro_data.tile7.halo4.nc C793_oro_data.tile7.halo4.nc 
ln -s $HOMEaqm/fix/aqm/DOMAIN_DATA/AQM_NA_13km/C793_oro_data.tile7.halo0.nc C793_oro_data.tile7.halo0.nc 
ln -s C793.maximum_snow_albedo.tile7.halo4.nc C793.maximum_snow_albedo.tile7.nc
ln -s $HOMEaqm/fix/aqm/DOMAIN_DATA/AQM_NA_13km/C793.maximum_snow_albedo.tile7.halo4.nc C793.maximum_snow_albedo.tile7.halo4.nc
ln -s $HOMEaqm/fix/aqm/DOMAIN_DATA/AQM_NA_13km/C793.maximum_snow_albedo.tile7.halo0.nc C793.maximum_snow_albedo.tile7.halo0.nc
ln -s C793.maximum_snow_albedo.tile7.halo0.nc C793.maximum_snow_albedo.tile1.nc
ln -s C793.facsf.tile7.halo4.nc C793.facsf.tile7.nc
ln -s $HOMEaqm/fix/aqm/DOMAIN_DATA/AQM_NA_13km/C793.facsf.tile7.halo4.nc C793.facsf.tile7.halo4.nc
ln -s $HOMEaqm/fix/aqm/DOMAIN_DATA/AQM_NA_13km/C793.facsf.tile7.halo0.nc C793.facsf.tile7.halo0.nc
ln -s C793.facsf.tile7.halo0.nc C793.facsf.tile1.nc
