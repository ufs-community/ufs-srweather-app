help([[
This load("s libraries for building the UFS SRW App on
the NOAA cloud using Intel-oneapi
]])

whatis([===[Loads libraries needed for building the UFS SRW App on NOAA cloud ]===])

prepend_path("MODULEPATH", "/opt/spack-stack/envs/release/public-v2.1.0/install/modulefiles/Core")
prepend_path("PATH", "/opt/ufs-srweather-app//container-bin")
--load("intel/2022.1.0")
--load("impi/2021.6.0")
load("stack-intel")
load("stack-intel-oneapi-mpi")
--load("cmake/3.22.1") 

load("srw_common_singularity")
