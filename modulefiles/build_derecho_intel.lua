help([[
This module loads libraries for building the UFS SRW App on
the CISL machine Derecho (Cray) using Intel@2021.10.0
]])

whatis([===[Loads libraries needed for building the UFS SRW App on Derecho ]===])

prepend_path("MODULEPATH","/lustre/desc1/scratch/epicufsrt/contrib/modulefiles_extra")
prepend_path("MODULEPATH", "/glade/work/epicufsrt/contrib/spack-stack/derecho/spack-stack-1.6.0/envs/upp-addon-env/install/modulefiles/Core")

load(pathJoin("stack-intel", os.getenv("stack_intel_ver") or "2021.10.0"))
load(pathJoin("stack-cray-mpich", os.getenv("stack_cray_mpich_ver") or "8.1.25"))
load(pathJoin("cmake", os.getenv("cmake_ver") or "3.23.1"))

load("srw_common")

load(pathJoin("prod_util", os.getenv("prod_util_ver") or "2.1.1"))

setenv("CMAKE_Platform","derecho.intel")

