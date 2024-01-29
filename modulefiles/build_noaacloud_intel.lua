help([[
This load("s libraries for building the UFS SRW App on
the NOAA cloud using Intel-oneapi
]])

whatis([===[Loads libraries needed for building the UFS SRW App on NOAA cloud ]===])

prepend_path("MODULEPATH", "/contrib/EPIC/spack-stack/spack-stack-1.4.1/envs/unified-dev/install/modulefiles/Core")
prepend_path("MODULEPATH", "/apps/modules/modulefiles")
prepend_path("PATH", "/contrib/EPIC/bin")
load("stack-intel")
load("stack-intel-oneapi-mpi")
load("cmake/3.23.1") 

load("srw_common")
