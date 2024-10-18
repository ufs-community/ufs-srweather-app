help([[
This module loads python environement for running the UFS SRW-AQM/SD/FB on
the NOAA RDHPC machine Hera
]])

whatis([===[Loads libraries needed for running the UFS SRW-AQM/SD/FB on Hera ]===])

--prepend_path("MODULEPATH","/contrib/sutils/modulefiles")
--load("sutils")

prepend_path("MODULEPATH", os.getenv("modulepath_spack_stack"))

load(pathJoin("stack-intel", stack_intel_ver))
load(pathJoin("stack-intel-oneapi-mpi", stack_intel_oneapi_mpi_ver))

load(pathJoin("py-f90nml", py_f90nml_ver))
load(pathJoin("py-jinja2", py_jinja2_ver))
load(pathJoin("py-numpy", py_numpy_ver))
load(pathJoin("py-pyyaml", py_pyyaml_ver))

load("rocoto")
