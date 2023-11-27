load("python_regional_workflow")

prepend_path("MODULEPATH", os.getenv("modulepath_compiler"))
prepend_path("MODULEPATH", os.getenv("modulepath_mpi"))

load(pathJoin("libjpeg", os.getenv("libjpeg_ver")))
load(pathJoin("netcdf", os.getenv("netcdf_ver")))
load(pathJoin("bacio", os.getenv("bacio_ver")))
load(pathJoin("w3emc", os.getenv("w3emc_ver")))
load(pathJoin("w3nco", os.getenv("w3nco_ver")))
load(pathJoin("nemsio", os.getenv("nemsio_ver")))
load(pathJoin("udunits", os.getenv("udunits_ver")))
load(pathJoin("gsl", os.getenv("gsl_ver")))
load(pathJoin("nco", os.getenv("nco_ver")))
