unload("python")
append_path("MODULEPATH","/work/noaa/epic/role-epic/contrib/orion/miniconda3/modulefiles")
load(pathJoin("miniconda", os.getenv("miniconda_ver") or "4.12.0"))

setenv("AQM_ENV_FP", "/work/noaa/fv3-cam/RRFS_CMAQ/PY_VENV")
setenv("AQM_ENV", "online-cmaq")
