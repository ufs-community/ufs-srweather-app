load("python_regional_workflow")

prepend_path("MODULEPATH", os.getenv("modulepath_compiler"))
prepend_path("MODULEPATH", os.getenv("modulepath_mpi"))

load(pathJoin("udunits", os.getenv("udunits_ver")))
load(pathJoin("gsl", os.getenv("gsl_ver")))
load(pathJoin("netcdf", os.getenv("netcdf_ver")))
load(pathJoin("nco", os.getenv("nco_ver")))
