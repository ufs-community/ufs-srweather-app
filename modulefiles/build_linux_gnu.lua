help([[
This module needs to be customized for the user's Linux environment:
specify compilers, path for HPC-stack, load the modules, set compiler and linker flags
]])

whatis([===[Loads libraries needed for building the UFS SRW App on Linux ]===])

-- This path should point to your HPCstack installation directory
local HPCstack="/home/username/hpc-stack/install"

-- Load HPC stack 
prepend_path("MODULEPATH", pathJoin(HPCstack, "modulefiles/stack"))
load("hpc")

load("hpc-gnu")
load("hpc-openmpi")

load("srw_common")

-- Set the env. variables for the serial compilers (CC, FC, CXX)
setenv("CC", "gcc")
setenv("FC", "gfortran")
setenv("CXX", "g++")

-- Set MPI compilers depending on the MPI libraries built:
local MPI_CC="mpicc"
local MPI_CXX="mpicxx"
local MPI_FC="mpif90"

-- Set compilers and platform names for CMake:
setenv("CMAKE_C_COMPILER", MPI_CC)
setenv("CMAKE_CXX_COMPILER", MPI_CXX)
setenv("CMAKE_Fortran_COMPILER", MPI_FC)

setenv("CMAKE_Platform", "linux.gnu")
--setenv("CMAKE_Platform", "linux.intel")

setenv("CMAKE_Fortran_COMPILER_ID", "GNU")
--setenv("CMAKE_Fortran_COMPILER_ID", "Intel")

-- Set compiler and linker flags if needed: 
setenv("FFLAGS", " -fallow-argument-mismatch")

if mode() == "load" then
  LmodMsgRaw([===[
  This module needs to be customized for the user's Linux environment:
  load the environment modules if present, hpc-stack modules,
  specify compilers, path for HPC-stack and SRW directory on Linux systems
  1) env. variable HPCstack is the hpc-stack installation directory
  2) Load the modules build with the hpc-stack on your system
  3) Specify compilers, compiler and linker flags, and a platform name
     The example below is for the GNU compilers built with OpenMPI libraries
  NB: After the module is customized, comment out the this line and lines above
  Please export env. variable LDFLAGS after the module is successfully loaded:
       > export LDFLAGS+=" -L$MPI_ROOT/lib "
  ]===])
end
