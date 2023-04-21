help([[
This load("s libraries for building the UFS SRW App on
the NOAA cloud using Intel-oneapi
]])

whatis([===[Loads libraries needed for building the UFS SRW App on NOAA cloud ]===])

prepend_path("MODULEPATH", "/contrib/EPIC/spack-stack/spack-stack-1.3.0/envs/unified-dev/install/modulefiles/Core")
prepend_path("MODULEPATH", "/contrib/spack-stack/modulefiles/core")

load("stack-intel/2021.3.0")
load("stack-intel-oneapi-mpi/2021.3.0")
load("stack-python/3.9.12")
load("cmake/3.22.1") 

load("srw_common_spack")

load("ufs-pyenv")
