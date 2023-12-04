load(pathJoin("intel", os.getenv("intel_ver")))
load(pathJoin("python", os.getenv("python_ver")))
load(pathJoin("prod_util", os.getenv("prod_util_ver")))

load(pathJoin("intel", "19.1.3.304"))
load(pathJoin("craype", "2.7.13"))
load(pathJoin("cray-mpich", "8.1.7"))

setenv("HPC_OPT", "/apps/ops/para/libs")
prepend_path("MODULEPATH", "/apps/ops/para/libs/modulefiles/compiler/intel/19.1.3.304")
prepend_path("MODULEPATH", "/apps/ops/para/libs/modulefiles/mpi/intel/19.1.3.304/cray-mpich/8.1.7")

load(pathJoin("hdf5", "1.10.6"))
load(pathJoin("netcdf", "4.7.4"))
load(pathJoin("udunits", "2.2.28"))
load(pathJoin("gsl", "2.7"))
load(pathJoin("nco", "4.9.7"))
