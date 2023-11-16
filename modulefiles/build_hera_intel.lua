help([[
This module loads libraries for building the RRFS workflow on
the NOAA RDHPC machine Hera using Intel-2022.1.2
]])

whatis([===[Loads libraries needed for building the RRFS workflow on Hera ]===])

load(pathJoin("cmake", "3.20.1"))

prepend_path("MODULEPATH", "/scratch1/NCEPDEV/nems/role.epic/hpc-stack/libs/intel-2022.1.2/modulefiles/stack")
load(pathJoin("hpc", "1.2.0"))
load(pathJoin("hpc-intel", "2022.1.2"))
load(pathJoin("hpc-impi", "2022.1.2"))

load(pathJoin("jasper", "2.0.25"))
load(pathJoin("zlib", "1.2.11"))
load(pathJoin("libpng", "1.6.37"))
load(pathJoin("hdf5", "1.10.6"))
load(pathJoin("netcdf", "4.7.4"))
load(pathJoin("pio", "2.5.3"))
load(pathJoin("esmf", "8.3.0b09"))
load(pathJoin("fms", "2023.01"))

load(pathJoin("bacio", "2.4.1"))
load(pathJoin("crtm", "2.4.0"))
load(pathJoin("g2", "3.4.5"))
load(pathJoin("g2tmpl", "1.10.2"))
load(pathJoin("ip", "3.3.3"))
load(pathJoin("sp", "2.3.3"))

load(pathJoin("gftl-shared", "v1.5.0"))
load(pathJoin("yafyaml", "v0.5.1"))
load(pathJoin("mapl", "2.22.0-esmf-8.3.0b09"))
load(pathJoin("scotch", "7.0.3"))

load(pathJoin("bufr", "11.7.0"))
load(pathJoin("gfsio", "1.4.1"))
load(pathJoin("landsfcutil", "2.4.1"))
load(pathJoin("nemsiogfs", "2.5.3"))
load(pathJoin("sigio", "2.3.2"))
load(pathJoin("sfcio", "1.4.1"))
load(pathJoin("nemsio", "2.5.4"))
load(pathJoin("wrf_io", "1.2.0"))
load(pathJoin("ncio", "1.1.2"))
load(pathJoin("ncdiag", "1.1.1"))
load(pathJoin("w3emc", "2.9.2"))
load(pathJoin("w3nco", "2.4.1"))

load(pathJoin("nco", "5.0.6"))
load(pathJoin("prod_util", "2.0.14"))
load(pathJoin("wgrib2", "2.0.8"))

prepend_path("MODULEPATH", "/scratch2/BMC/ifi/modulefiles")
try_load("ifi/20230511-intel-2022.1.2")

setenv("CMAKE_C_COMPILER","mpiicc")
setenv("CMAKE_CXX_COMPILER","mpiicpc")
setenv("CMAKE_Fortran_COMPILER","mpiifort")
setenv("CMAKE_Platform","hera.intel")
