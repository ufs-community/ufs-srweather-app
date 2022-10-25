help([[
This module needs to be customized for the user's Linux environment:
specify compilers, path for HPC-stack, load the modules, set compiler and linker flags
   Option 1: M1/arm64 platform, OS BigSur, Monterey (Darwin 20,21)
   Option 2: Intel/x86_64 platform, OS Catalina (Darwin 19)
]])

whatis([===[Loads libraries needed for building the UFS SRW App on macos ]===])

if mode() == "load" then
   execute{cmd="ulimit -S -s unlimited", modeA={"load"}}
end

-- This path should point to your HPCstack installation directory
local HPCstack="/Users/username/hpc-stack/install"

-- Load HPC stack 
prepend_path("MODULEPATH", pathJoin(HPCstack, "modulefiles/stack"))
load("hpc")
load("hpc-python")

load("hpc-gnu")
load("openmpi")
load("hpc-openmpi")

load("jasper/2.0.25")
load("zlib/1.2.11")

load("hdf5/1.10.6")
load("netcdf/4.7.4")
load("pio/2.5.3")
load("esmf/8.3.0b09")
load("fms/2022.01")

load("bacio/2.4.1")
load("crtm/2.3.0")
load("g2/3.4.3")
load("g2tmpl/1.10.0")
load("ip/3.3.3")
load("sp/2.3.3")
load("w3nco/2.4.1")
load("upp/10.0.10")

load("gftl-shared/1.3.3")
load("yafyaml/0.5.1")
load("mapl/2.12.2-esmf-8.3.0b09")
load("gfsio/1.4.1")
load("landsfcutil/2.4.1")
load("nemsio/2.5.4")
load("nemsiogfs/2.5.3")
load("sfcio/1.4.1")
load("sigio/2.3.2")
load("w3emc/2.9.2")
load("wgrib2/2.0.8")

-- Option 1 compiler paths: 
setenv("CC", "/opt/homebrew/bin/gcc")
setenv("FC", "/opt/homebrew/bin/gfortran")
setenv("CXX", "/opt/homebrew/bin/g++")

-- Option 2 compiler paths:
--[[
setenv("CC", "/usr/local/bin/gcc")
setenv("FC", "/usr/local/bin/gfortran")
setenv("CXX", "/usr/local/bin/g++")
--]]
--
-- Set MPI compilers depending on the MPI libraries built:
local MPI_CC="mpicc"
local MPI_CXX="mpicxx"
local MPI_FC="mpif90"


-- Set compilers and platform names for CMake:
setenv("CMAKE_C_COMPILER", MPI_CC)
setenv("CMAKE_CXX_COMPILER", MPI_CXX)
setenv("CMAKE_Fortran_COMPILER", MPI_FC)

setenv("CMAKE_Platform", "macos.gnu")
--setenv("CMAKE_Platform", "macos.intel")

setenv("CMAKE_Fortran_COMPILER_ID", "GNU")
--setenv("CMAKE_Fortran_COMPILER_ID", "Intel")

-- Set compiler and linker flags if needed: 
setenv("FFLAGS", " -DNO_QUAD_PRECISION -fallow-argument-mismatch ")

-- export the env. variable LDFLAGS after loading the current module
-- export LDFLAGS="-L$MPI_ROOT/lib"
if mode() == "load" then
  LmodMsgRaw([===[
   Please export env. variable LDFLAGS after the module is successfully loaded:
       > export LDFLAGS=\"-L\$MPI_ROOT/lib \" "
  ]===])
end


