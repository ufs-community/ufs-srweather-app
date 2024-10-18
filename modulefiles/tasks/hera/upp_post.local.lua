prepend_path("MODULEPATH", os.getenv("modulepath_spack_stack"))

load(pathJoin("stack-intel", stack_intel_ver))
load(pathJoin("stack-intel-oneapi-mpi", stack_intel_oneapi_mpi_ver))

load(pathJoin("jasper", jasper_ver))
load(pathJoin("hdf5", hdf5_ver))
load(pathJoin("netcdf-c", netcdf_c_ver))
load(pathJoin("netcdf-fortran", netcdf_fortran_ver))
load(pathJoin("g2", g2_ver))
load(pathJoin("wgrib2", wgrib2_ver))
load(pathJoin("prod_util", prod_util_ver))

load(pathJoin("py-numpy", py_numpy_ver))
load(pathJoin("py-pyyaml", py_pyyaml_ver))

