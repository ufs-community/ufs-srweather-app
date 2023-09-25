unload("python")
append_path("MODULEPATH","/work/noaa/epic/role-epic/contrib/hercules/miniconda3/modulefiles")
load(pathJoin("miniconda3", os.getenv("miniconda3_ver") or "4.12.0"))

setenv("SRW_ENV", "workflow_tools")
