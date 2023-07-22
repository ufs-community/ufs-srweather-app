help([[
This module loads libraries for building the UFS SRW App on
the NOAA RDHPC machine Gaea using Intel-2022.0.2
]])

whatis([===[Loads libraries needed for building the UFS SRW App on Gaea ]===])

load(pathJoin("cmake", os.getenv("cmake_ver") or "3.20.1"))

prepend_path("MODULEPATH","/lustre/f2/dev/role.epic/contrib/hpc-stack/intel-classic-2022.0.2/modulefiles/stack")
load(pathJoin("hpc", os.getenv("hpc_ver") or "1.2.0"))
load(pathJoin("hpc-intel-classic", os.getenv("hpc_intel_classic_ver") or "2022.0.2"))
load(pathJoin("hpc-cray-mpich", os.getenv("hpc_cray_mpich_ver") or "7.7.20"))

load("srw_common")
-- Need at runtime
load("alps")

local MKLROOT="/opt/intel/oneapi/mkl/2022.0.2/"
prepend_path("LD_LIBRARY_PATH",pathJoin(MKLROOT,"lib/intel64"))
pushenv("MKLROOT", MKLROOT)

pushenv("GSI_BINARY_SOURCE_DIR", "/lustre/f2/dev/role.epic/contrib/GSI_data/fix/20230601")
pushenv("CRAYPE_LINK_TYPE","dynamic")

setenv("CC","cc")
setenv("FC","ftn")
setenv("CXX","CC")
setenv("CMAKE_C_COMPILER","cc")
setenv("CMAKE_CXX_COMPILER","CC")
setenv("CMAKE_Fortran_COMPILER","ftn")
setenv("CMAKE_Platform","gaea.intel")

