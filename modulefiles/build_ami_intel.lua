help([[
This load("s libraries for building the UFS SRW App on
the NOAA cloud using Intel-oneapi
]])

whatis([===[Loads libraries needed for building the UFS SRW App on NOAA cloud ]===])

prepend_path("MODULEPATH", "/opt/spack-stack/envs/release/public-v2.1.0/install/modulefiles/Core")
prepend_path("MODULEPATH", "/opt/spack-stack/spack/share/spack/modules/linux-ubuntu20.04-skylake_avx512")
load("intel-oneapi-compilers")
load("intel-oneapi-mpi")
load("stack-intel")
load("stack-intel-oneapi-mpi")
load("cmake/3.22.1") 

load("srw_common_spack")
