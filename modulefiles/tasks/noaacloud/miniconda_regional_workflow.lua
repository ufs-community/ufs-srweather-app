prepend_path("MODULEPATH", "/contrib/GST/miniconda3/modulefiles")
load(pathJoin("miniconda3", os.getenv("miniconda3_ver") or "4.10.3"))

setenv("SRW_ENV", "regional_workflow")
