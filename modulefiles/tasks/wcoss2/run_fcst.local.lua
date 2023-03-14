load("python_regional_workflow")

unload("cray_mpich")
unload("netcdf")
load(pathJoin("cray-mpich", os.getenv("cray_mpich_ver")))
load(pathJoin("netcdf", os.getenv("netcdf_ver")))

load(pathJoin("envvar", os.getenv("envvar_ver")))
load(pathJoin("libjpeg", os.getenv("libjpeg_ver")))
load(pathJoin("cray-pals", os.getenv("cray_pals_ver")))
