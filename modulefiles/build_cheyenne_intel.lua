help([[
This module loads libraries for building the UFS SRW App on
the CISL machine Cheyenne using Intel-19.1.1.217
]])

whatis([===[Loads libraries needed for building the UFS SRW App on Cheyenne ]===])

unload("ncarenv/1.3")
unload("intel/19.1.1")
unload("ncarcompilers/0.5.0")
unload("mpt/2.25")
unload("netcdf/4.8.1")

prepend_path("MODULEPATH","/glade/work/epicufsrt/contrib/spack-stack/spack-stack-1.3.0/envs/unified-env/install/modulefiles/Core")
prepend_path("MODULEPATH", "/glade/work/jedipara/cheyenne/spack-stack/modulefiles/misc")

load("stack-intel/19.1.1.217")
load("stack-intel-mpi/2019.7.217")
load("stack-python/3.9.12")
load("cmake/3.22.0")

load("srw_common_spack")
load("ufs-pyenv")

setenv("CMAKE_C_COMPILER","mpiicc")
setenv("CMAKE_CXX_COMPILER","mpiicpc")
setenv("CMAKE_Fortran_COMPILER","mpiifort")
setenv("CMAKE_Platform","cheyenne.intel")
