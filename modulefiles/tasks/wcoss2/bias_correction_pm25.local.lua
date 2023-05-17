load("python_srw")

load(pathJoin("PrgEnv-intel", os.getenv("PrgEnv_intel_ver")))
load(pathJoin("intel", os.getenv("intel_ver")))
load(pathJoin("craype", os.getenv("craype_ver")))
load(pathJoin("cray-mpich", os.getenv("cray_mpich_ver")))
load(pathJoin("cmake", os.getenv("cmake_ver")))

load(pathJoin("hdf5", os.getenv("hdf5_ver")))
load(pathJoin("netcdf", os.getenv("netcdf_ver")))
load(pathJoin("libjpeg", os.getenv("libjpeg_ver")))
load(pathJoin("wgrib2", os.getenv("wgrib2_ver")))
load(pathJoin("bufr", os.getenv("bufr_ver")))

load(pathJoin("cray-pals", os.getenv("cray_pals_ver")))
load(pathJoin("grib_util", os.getenv("grib_util_ver")))
load(pathJoin("prod_util", os.getenv("prod_util_ver")))
