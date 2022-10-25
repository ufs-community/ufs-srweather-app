help([[
This load("s libraries for building the UFS SRW App on
the NOAA cloud using Intel-oneapi
]])

whatis([===[Loads libraries needed for building the UFS SRW App on NOAA cloud ]===])

prepend_path("MODULEPATH", "/contrib/spack-stack/apps/srw-app-test/modulefiles/Core")
load("stack-intel")
load("stack-intel-oneapi-mpi")
load("cmake/3.22.1") 

load("srw_common")
load("esmf/8.2.0")
load("netcdf-c")
load("netcdf-fortran")
load("libpng")
load("jasper")
