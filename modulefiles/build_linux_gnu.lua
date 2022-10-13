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
load("mapl/2.11.0-esmf-8.3.0b09")
load("gfsio/1.4.1")
load("landsfcutil/2.4.1")
load("nemsio/2.5.2")
load("nemsiogfs/2.5.3")
load("sfcio/1.4.1")
load("sigio/2.3.2")
load("w3emc/2.7.3")
load("wgrib2/2.0.8")

-- Set the env. variables for the serial compilers (CC, FC, CXX), if not present
setenv("CC", "/usr/local/bin/gcc")
setenv("FC", "/usr/local/bin/gfortran")
setenv("CXX", "/usr/local/bin/g++")

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
       > export LDFLAGS=\"-L\$MPI_ROOT/lib \"
  ]===])
end
