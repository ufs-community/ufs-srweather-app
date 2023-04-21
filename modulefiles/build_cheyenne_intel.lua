help([[
This module loads libraries for building the UFS SRW App on
the CISL machine Cheyenne using Intel-19.1.1.217
]])

whatis([===[Loads libraries needed for building the UFS SRW App on Cheyenne ]===])


prepend_path("MODULEPATH","/glade/work/epicufsrt/contrib/spack-stack/spack-stack-1.3.0/envs/unified-env/install/modulefiles/Core")
prepend_path("MODULEPATH", "/glade/work/jedipara/cheyenne/spack-stack/modulefiles/misc")

load("stack-intel/19.1.1.217")
load("stack-intel-mpi/2019.7.217")
load("stack-python/3.9.12")
load("cmake/3.22.0")

load("srw_common_spack")

load("g2/3.4.5")
load("esmf/8.3.0b09")
load("netcdf-c/4.9.2")
load("netcdf-fortran/4.6.0")
load("libpng/1.6.37")
load("parallelio/2.5.9")
load("fms/2022.04")
load("ufs-pyenv")

setenv("CMAKE_C_COMPILER","mpicc")
setenv("CMAKE_CXX_COMPILER","mpicpc")
setenv("CMAKE_Fortran_COMPILER","mpif90")
setenv("CMAKE_Platform","cheyenne.intel")
