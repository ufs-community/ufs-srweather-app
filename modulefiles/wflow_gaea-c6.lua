help([[
This module loads python environement for running the UFS SRW-AQM/SD/FB on
the NOAA RDHPC machine Gaea C6
]])

whatis([===[Loads libraries needed for running the UFS SRW-AQM/SD/FB on Gaea C6 ]===])

unload("python")
prepend_path("MODULEPATH","/ncrc/proj/epic/rocoto/modulefiles")
load("rocoto")

pushenv("MKLROOT", "/opt/intel/oneapi/mkl/2023.2.0")

prepend_path("MODULEPATH", os.getenv("modulepath_spack_stack"))

load(pathJoin("stack-intel", stack_intel_ver))
load(pathJoin("stack-cray-mpich", stack_cray_mpich_ver))

load(pathJoin("py-f90nml", py_f90nml_ver))
load(pathJoin("py-jinja2", py_jinja2_ver))
load(pathJoin("py-numpy", py_numpy_ver))
load(pathJoin("py-pyyaml", py_pyyaml_ver))

