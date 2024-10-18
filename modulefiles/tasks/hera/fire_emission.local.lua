prepend_path("MODULEPATH", os.getenv("modulepath_spack_stack"))

load(pathJoin("stack-intel", stack_intel_ver))
load(pathJoin("stack-intel-oneapi-mpi", stack_intel_oneapi_mpi_ver))

load(pathJoin("hdf5", hdf5_ver))
load(pathJoin("netcdf-c", netcdf_c_ver))
load(pathJoin("netcdf-fortran", netcdf_fortran_ver))
load(pathJoin("nco", nco_ver))
load(pathJoin("prod_util", prod_util_ver))

load(pathJoin("py-f90nml", py_f90nml_ver))
load(pathJoin("py-jinja2", py_jinja2_ver))
load(pathJoin("py-netcdf4", py_netcdf4_ver))
load(pathJoin("py-numpy", py_numpy_ver))
load(pathJoin("py-pyyaml", py_pyyaml_ver))
load(pathJoin("py-xarray", py_xarray_ver))

