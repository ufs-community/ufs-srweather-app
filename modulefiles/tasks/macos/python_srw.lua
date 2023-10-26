prepend_path("MODULEPATH","/Users/username/miniconda3/modulefiles")
load(pathJoin("miniconda3", os.getenv("miniconda3_ver") or "23.9.0"))

setenv("SRW_ENV", "workflow_tools")
