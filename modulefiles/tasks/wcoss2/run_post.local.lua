load("python_srw")

unload("PrgEnv-intel")
unload("netcdf")

load(pathJoin("intel", os.getenv("intel_ver")))
load(pathJoin("PrgEnv-intel", os.getenv("PrgEnv_intel_ver")))
load(pathJoin("craype", os.getenv("craype_ver")))
load(pathJoin("cray-mpich", os.getenv("cray_mpich_ver")))
load(pathJoin("cray-pals", os.getenv("cray_pals_ver")))
load(pathJoin("hdf5", os.getenv("hdf5_ver")))
load(pathJoin("netcdf", os.getenv("netcdf_ver")))
load(pathJoin("libjpeg", os.getenv("libjpeg_ver")))
load(pathJoin("prod_util", os.getenv("prod_util_ver")))
