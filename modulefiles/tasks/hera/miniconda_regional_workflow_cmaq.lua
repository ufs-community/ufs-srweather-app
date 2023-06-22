prepend_path("MODULEPATH","/scratch1/NCEPDEV/nems/role.epic/miniconda3/modulefiles")
load(pathJoin("miniconda3", os.getenv("miniconda3_ver") or "4.12.0"))

setenv("SRW_ENV", "regional_workflow_cmaq")
