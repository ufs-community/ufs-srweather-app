unload("python")
append_path("MODULEPATH","/work/noaa/epic/role-epic/contrib/hercules/miniconda3/modulefiles")
load(pathJoin("miniconda3", os.getenv("miniconda_ver") or "4.12.0"))

setenv("AQM_ENV_FP", "/work/noaa/fv3-cam/RRFS_CMAQ/PY_VENV_hercules")
setenv("AQM_ENV", "online-cmaq")
