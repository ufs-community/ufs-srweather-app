help([[

This module loads libraries for building the UFS SRW App in a container]])

whatis([===[Loads libraries needed for building the UFS SRW App in a container ]===])

prepend_path("MODULEPATH", "/opt/modulefiles")
prepend_path("MODULEPATH", "/opt/spack-stack/spack-stack-1.9.2/envs/ufs-wm-env/install/modulefiles/Core")
stack_gcc_ver=os.getenv("stack_gcc_ver") or "13.3.1"
stack_openmpi_ver=os.getenv("stack_openmpi_ver") or "4.1.6"

load(pathJoin("stack-gcc", stack_gcc_ver))
load(pathJoin("stack-openmpi", stack_openmpi_ver))
cmake_ver=os.getenv("cmake_ver") or "3.27.9"

load(pathJoin("cmake", cmake_ver))

load("srw_common")

setenv("CC", "mpicc")
setenv("CXX", "mpic++")
setenv("FC", "mpif90")

setenv("CMAKE_C_COMPILER","mpicc")
setenv("CMAKE_CXX_COMPILER","mpic++")
setenv("CMAKE_Fortran_COMPILER","mpif90")
setenv("CMAKE_Platform","singularity.gnu")

