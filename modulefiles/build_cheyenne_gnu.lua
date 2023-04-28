help([[
This module loads libraries for building the UFS SRW App on
the CISL machine Cheyenne using GNU
]])

whatis([===[Loads libraries needed for building the UFS SRW App on Cheyenne ]===])

unload("ncarenv/1.3")
unload("intel/19.1.1")
unload("ncarcompilers/0.5.0")
unload("mpt/2.25")
unload("netcdf/4.8.1")

prepend_path("MODULEPATH", "/glade/work/epicufsrt/contrib/spack-stack/spack-stack-1.3.0/envs/unified-env/install/modulefiles/Core")
prepend_path("MODULEPATH", "/glade/work/jedipara/cheyenne/spack-stack/modulefiles/misc")

load("stack-gcc/10.1.0")
load("stack-openmpi/4.1.1")
load("stack-python/3.9.12")
load("cmake/3.22.0")


load("srw_common_spack")

--load(pathJoin("g2", os.getenv("g2_ver") or "3.4.5"))
--load(pathJoin("esmf", os.getenv("esmf_ver") or "8.3.0b09"))
--load(pathJoin("netcdf", os.getenv("netcdf_ver") or "4.7.4"))
--load(pathJoin("libpng", os.getenv("libpng_ver") or "1.6.37"))
--load(pathJoin("pio", os.getenv("pio_ver") or "2.5.7"))
--load(pathJoin("fms", os.getenv("fms_ver") or "2022.04"))

setenv("CMAKE_C_COMPILER","mpicc")
setenv("CMAKE_CXX_COMPILER","mpic++")
setenv("CMAKE_Fortran_COMPILER","mpif90")
setenv("CMAKE_Platform","cheyenne.gnu")
setenv("CC", "gcc")
setenv("CXX", "g++")
setenv("FC", "gfortran")

