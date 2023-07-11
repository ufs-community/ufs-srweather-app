prepend_path("MODULEPATH","/work/noaa/epic-ps/role-epic-ps/miniconda3/modulefiles")
load(pathJoin("miniconda3", os.getenv("miniconda3_ver") or "4.12.0"))

setenv("SRW_ENV", "regional_workflow_cmaq")
