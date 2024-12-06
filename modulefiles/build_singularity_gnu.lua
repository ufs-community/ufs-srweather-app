help([[
This module loads libraries for building the UFS SRW App in
a singularity container
]])

whatis([===[Loads libraries needed for building the UFS SRW App in singularity container ]===])

prepend_path("MODULEPATH","/opt/hpc-modules/modulefiles/stack")

load("hpc")
load("hpc-gnu")
load("hpc-openmpi")

load("netcdf")
load("hdf5")
load("bacio")
load("sfcio")
load("sigio")
load("nemsio")
load("w3emc")
load("esmf")
load("fms")
load("crtm")
load("g2")
load("png")
load("zlib")
load("g2tmpl")
load("ip")
load("sp")
load("w3nco")
load("cmake")
load("gfsio")
load("wgrib2")
load("upp")

setenv("FC", "mpif90")

setenv("CMAKE_C_COMPILER","mpiicc")
setenv("CMAKE_CXX_COMPILER","mpicxx")
setenv("CMAKE_Fortran_COMPILER","mpif90")
setenv("CMAKE_Platform","singularity.gnu")

