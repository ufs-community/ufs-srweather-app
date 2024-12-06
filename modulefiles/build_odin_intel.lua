help([[
This module loads libraries for building the UFS SRW App on
the NSSL machine Odin using Intel
]])

whatis([===[Loads libraries needed for building the UFS SRW App on Odin ]===])

prepend_path("PATH","/home/yunheng.wang/tools/cmake-3.23.0-rc2/bin")
setenv("CMAKE","/home/yunheng.wang/tools/cmake-3.23.0-rc2/bin/cmake")

load("hpc/1.2.0")
load("hpc-intel")
load("hpc-cray-mpich")

--load("srw_common")

load("jasper")
load("zlib")
load("png")

--load("cray-hdf5")
--load("cray-netcdf")
load("esmf")
load("fms")

load("bacio")
load("crtm")
load("g2")
load("g2tmpl")
load("ip")
load("sp")
load("w3nco")
load("upp")

load("gftl-shared")
load("yafyaml")
load("mapl")

load("gfsio")
load("landsfcutil")
load("nemsio")
load("nemsiogfs")
load("sfcio")
load("sigio")
load("w3emc")
load("wgrib2")

setenv("FC", "ftn")

setenv("CMAKE_C_COMPILER","cc")
setenv("CMAKE_CXX_COMPILER","CC")
setenv("CMAKE_Fortran_COMPILER","ftn")
setenv("CMAKE_Platform","odin.intel")

