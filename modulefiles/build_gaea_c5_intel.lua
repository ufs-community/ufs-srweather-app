help([[
This module loads libraries for building the UFS SRW App on
the NOAA RDHPC machine Gaea C5 using Intel-2022.2.1
]])

whatis([===[Loads libraries needed for building the UFS SRW App on Gaea ]===])

load(pathJoin("cmake", os.getenv("cmake_ver") or "3.23.1"))
load("craype-x86-rome")
load("craype/2.7.20")
load("cray-libsci/23.02.1.1")
load("PrgEnv-intel/8.3.3")
load("cray-pmi/6.1.10")

prepend_path("MODULEPATH","/lustre/f2/dev/role.epic/contrib/C5/hpc-stack/intel-classic-2023.1.0/modulefiles/stack")
load(pathJoin("hpc", os.getenv("hpc_ver") or "1.2.0"))
load(pathJoin("hpc-intel-classic", os.getenv("hpc_intel_classic_ver") or "2023.1.0"))
load(pathJoin("hpc-cray-mpich", os.getenv("hpc_cray_mpich_ver") or "8.1.25"))

load("srw_common")

--unload("darshan-runtime/3.4.0")
local MKLROOT="/opt/intel/oneapi/mkl/2023.1.0/"
prepend_path("LD_LIBRARY_PATH",pathJoin(MKLROOT,"lib/intel64"))
pushenv("MKLROOT", MKLROOT)

--pushenv("GSI_BINARY_SOURCE_DIR", "/lustre/f2/dev/role.epic/contrib/GSI_data/fix/20230601")
--pushenv("CRAYPE_LINK_TYPE","dynamic")

setenv("CC","cc")
setenv("FC","ftn")
setenv("CXX","CC")
setenv("CMAKE_C_COMPILER","cc")
setenv("CMAKE_CXX_COMPILER","CC")
setenv("CMAKE_Fortran_COMPILER","ftn")
setenv("CMAKE_Platform","gaea_c5.intel")

