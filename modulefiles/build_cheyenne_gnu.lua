help([[
This module loads libraries for building the UFS SRW App on
the CISL machine Cheyenne using GNU
]])

whatis([===[Loads libraries needed for building the UFS SRW App on Cheyenne ]===])

load(pathJoin("cmake", os.getenv("cmake_ver") or "3.22.0"))
load(pathJoin("ncarenv", os.getenv("ncarenv_ver") or "1.3"))
load(pathJoin("gnu", os.getenv("gnu_ver") or "11.2.0"))
load(pathJoin("mpt", os.getenv("mpt_ver") or "2.25"))
load(pathJoin("python", os.getenv("python_ver") or "3.7.9"))
setenv("MKLROOT", "/glade/u/apps/opt/intel/2022.1/mkl/latest")
load(pathJoin("ncarcompilers", os.getenv("ncarcompilers_ver") or "0.5.0"))
unload("netcdf")

prepend_path("MODULEPATH","/glade/work/epicufsrt/contrib/hpc-stack/gnu11.2.0/modulefiles/stack")
load(pathJoin("hpc", os.getenv("hpc_ver") or "1.2.0"))
load(pathJoin("hpc-gnu", os.getenv("hpc_gnu_ver") or "11.2.0"))
load(pathJoin("hpc-mpt", os.getenv("hpc_mpt_ver") or "2.25"))

load("srw_common")

load(pathJoin("g2", os.getenv("g2_ver") or "3.4.5"))
load(pathJoin("esmf", os.getenv("esmf_ver") or "8.3.0b09"))
load(pathJoin("netcdf", os.getenv("netcdf_ver") or "4.7.4"))
load(pathJoin("libpng", os.getenv("libpng_ver") or "1.6.37"))
load(pathJoin("pio", os.getenv("pio_ver") or "2.5.7"))
load(pathJoin("fms", os.getenv("fms_ver") or "2022.04"))
load(pathJoin("openblas", os.getenv("openblas_ver") or "0.3.23"))

unsetenv("MKLROOT")
setenv("CMAKE_C_COMPILER","mpicc")
setenv("CMAKE_CXX_COMPILER","mpicxx")
setenv("CMAKE_Fortran_COMPILER","mpif90")
setenv("CMAKE_Platform","cheyenne.gnu")
setenv("CC", "mpicc")
setenv("CXX", "mpicxx")
setenv("FC", "mpif90")

