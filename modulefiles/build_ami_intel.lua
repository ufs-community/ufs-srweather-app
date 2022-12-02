help([[
This load("s libraries for building the UFS SRW App on
the NOAA cloud using Intel-oneapi
]])

whatis([===[Loads libraries needed for building the UFS SRW App on NOAA cloud ]===])

prepend_path("MODULEPATH", "/data/spack-stack/spack/share/spack/modules/linux-ubuntu20.04-skylake_avx512")
prepend_path("MODULEPATH", "/data/spack-stack/envs/release/public-v2.1.0/install/modulefiles/Core")
load("intel-oneapi-compilers")
load("intel-oneapi-mpi")
load("stack-intel")
load("stack-intel-oneapi-mpi")
load("cmake/3.22.1") 
load("libjpeg/2.1.0") 

load("srw_common_spack")
