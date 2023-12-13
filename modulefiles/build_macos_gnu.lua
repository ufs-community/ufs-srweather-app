help([[
This module needs to be customized for the user's MacOS environment:
specify compilers, path for HPC-stack, load the modules, set compiler and linker flags
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

load("hpc-gnu")
load("hpc-openmpi")

load("srw_common")

-- MacOS with arm64 architecture: `uname -m` expands to arm64
-- MacOS with Intel architecture: `uname -m` expands to x86_64
local arch = 'eval $(uname -m)'
if (arch == "arm64") then
  setenv("CC", "/opt/homebrew/bin/gcc")
  setenv("FC", "/opt/homebrew/bin/gfortran")
  setenv("CXX", "/opt/homebrew/bin/g++")
else
  setenv("CC", "/usr/local/bin/gcc")
  setenv("FC", "/usr/local/bin/gfortran")
  setenv("CXX", "/usr/local/bin/g++")
end

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
       > export LDFLAGS+=" -L$MPI_ROOT/lib " 
  ]===])
end


