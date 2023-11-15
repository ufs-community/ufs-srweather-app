prepend_path("MODULEPATH", "/contrib/miniconda3/modulefiles")
load(pathJoin("miniconda3", os.getenv("miniconda3_ver") or "4.12.0"))

setenv("AQM_ENV_FP", "/scratch2/NCEPDEV/naqfc/RRFS_CMAQ/PY_VENV")
setenv("AQM_ENV", "online-cmaq")
