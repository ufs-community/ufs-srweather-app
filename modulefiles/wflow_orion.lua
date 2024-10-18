help([[
This module loads python environement for running SRW on
the MSU machine Orion
]])

whatis([===[Loads libraries needed for running SRW-AQM/SD/FB on Orion ]===])

load("contrib")
load(pathJoin("ruby", ruby_ver))
load(pathJoin("rocoto", rocoto_ver))
unload("python")

prepend_path("MODULEPATH", os.getenv("modulepath_spack_stack"))

load(pathJoin("stack-intel", stack_intel_ver))
load(pathJoin("stack-intel-oneapi-mpi", stack_intel_oneapi_mpi_ver))

load(pathJoin("py-f90nml", py_f90nml_ver))
load(pathJoin("py-jinja2", py_jinja2_ver))
load(pathJoin("py-numpy", py_numpy_ver))
load(pathJoin("py-pyyaml", py_pyyaml_ver))

