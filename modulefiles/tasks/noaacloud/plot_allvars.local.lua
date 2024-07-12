unload("python")
append_path("MODULEPATH","/contrib/EPIC/miniconda3/modulefiles")
load(pathJoin("miniconda3", os.getenv("miniconda3_ver") or "4.12.0"))

setenv("SRW_GRAPHICS_ENV", "regional_workflow")
