help([[
This module loads libraries for building the UFS SRW App on
the CISL machine Derecho (Cray) using Intel@2021.10.0
]])

whatis([===[Loads libraries needed for building the UFS SRW App on Derecho ]===])

prepend_path("MODULEPATH","/lustre/desc1/scratch/epicufsrt/contrib/modulefiles_extra")
prepend_path("MODULEPATH", "/glade/work/epicufsrt/contrib/spack-stack/derecho/spack-stack-1.9.2/envs/ue-oneapi-2024.2.1/install/modulefiles/Core")
prepend_path("MODULEPATH", "/glade/work/epicufsrt/contrib/spack-stack/derecho/spack-stack-1.9.2/envs/ue-oneapi-2024.2.1/install/modulefiles/cray-mpich/8.1.29-3sepg3g/gcc/12.4.0")

load(pathJoin("stack-oneapi", os.getenv("stack_intel_ver") or "2024.2.1"))
load(pathJoin("stack-cray-mpich", os.getenv("stack_cray_mpich_ver") or "8.1.29"))
load(pathJoin("cmake", os.getenv("cmake_ver") or "3.27.9"))

load("srw_common")

load(pathJoin("nco", os.getenv("nco_ver") or "5.2.4"))
load(pathJoin("prod_util", os.getenv("prod_util_ver") or "2.1.1"))

setenv("CC", "mpicc")
setenv("CXX", "mpicxx")
setenv("FC", "mpif90")
setenv("I_MPI_CC", "icx")
setenv("I_MPI_CXX", "icpx")
setenv("I_MPI_F90", "ifort")

setenv("CMAKE_Platform","derecho.intel")
