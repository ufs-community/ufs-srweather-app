help([[
This module loads libraries for building the RRFS workflow on
the NOAA RDHPC machine Hera using Intel-2022.1.2
]])

whatis([===[Loads libraries needed for building the RRFS workflow on Hera ]===])

load(pathJoin("cmake", os.getenv("cmake_ver") or "3.20.1"))

prepend_path("MODULEPATH", "/scratch1/NCEPDEV/nems/role.epic/hpc-stack/libs/intel-2022.1.2/modulefiles/stack")
load(pathJoin("hpc", os.getenv("hpc_ver") or "1.2.0"))
load(pathJoin("hpc-intel", os.getenv("hpc_intel_ver") or "2022.1.2"))
load(pathJoin("hpc-impi", os.getenv("hpc_impi_ver") or "2022.1.2"))

load(pathJoin("jasper", os.getenv("jasper_ver") or "2.0.25"))
load(pathJoin("zlib", os.getenv("zlib_ver") or "1.2.11"))
load(pathJoin("libpng", os.getenv("libpng_ver") or "1.6.37"))
load(pathJoin("hdf5", os.getenv("hdf5_ver") or "1.10.6"))
load(pathJoin("netcdf", os.getenv("netcdf_ver") or "4.7.4"))
load(pathJoin("pio", os.getenv("pio_ver") or "2.5.3"))
load(pathJoin("esmf", os.getenv("esmf_ver") or "8.3.0b09"))
load(pathJoin("fms", os.getenv("fms_ver") or "2023.01"))

load(pathJoin("bacio", os.getenv("bacio_ver") or "2.4.1"))
load(pathJoin("crtm", os.getenv("crtm_ver") or "2.4.0"))
load(pathJoin("g2", os.getenv("g2_ver") or "3.4.5"))
load(pathJoin("g2tmpl", os.getenv("g2tmpl_ver") or "1.10.2"))
load(pathJoin("ip", os.getenv("ip_ver") or "3.3.3"))
load(pathJoin("sp", os.getenv("sp_ver") or "2.3.3"))

load(pathJoin("gftl-shared", os.getenv("gftl-shared_ver") or "v1.5.0"))
load(pathJoin("yafyaml", os.getenv("yafyaml_ver") or "v0.5.1"))
load(pathJoin("mapl", os.getenv("mapl_ver") or "2.22.0-esmf-8.3.0b09"))
load(pathJoin("scotch", os.getenv("scotch_ver") or "7.0.3"))

load(pathJoin("bufr", os.getenv("bufr_ver") or "11.7.0"))
load(pathJoin("gfsio", os.getenv("gfsio_ver") or "1.4.1"))
load(pathJoin("landsfcutil", os.getenv("landsfcutil_ver") or "2.4.1"))
load(pathJoin("nemsiogfs", os.getenv("nemsiogfs_ver") or "2.5.3"))
load(pathJoin("sigio", os.getenv("sigio_ver") or "2.3.2"))
load(pathJoin("sfcio", os.getenv("sfcio_ver") or "1.4.1"))
load(pathJoin("nemsio", os.getenv("nemsio_ver") or "2.5.4"))
load(pathJoin("wrf_io", os.getenv("wrf_io_ver") or "1.2.0"))
load(pathJoin("ncio", os.getenv("ncio_ver") or "1.1.2"))
load(pathJoin("ncdiag", os.getenv("ncdiag_ver") or "1.1.1"))
load(pathJoin("w3emc", os.getenv("w3emc_ver") or "2.9.2"))
load(pathJoin("w3nco", os.getenv("w3nco_ver") or "2.4.1"))

load(pathJoin("nco", os.getenv("nco_ver") or "4.9.3"))
load(pathJoin("prod_util", os.getenv("prod_util_ver") or "2.0.14"))
load(pathJoin("wgrib2", os.getenv("wgrib2_ver") or "2.0.8"))

prepend_path("MODULEPATH", "/scratch2/BMC/ifi/modulefiles")
try_load("ifi/20230511-intel-2022.1.2")

setenv("CMAKE_C_COMPILER","mpiicc")
setenv("CMAKE_CXX_COMPILER","mpiicpc")
setenv("CMAKE_Fortran_COMPILER","mpiifort")
setenv("CMAKE_Platform","hera.intel")
