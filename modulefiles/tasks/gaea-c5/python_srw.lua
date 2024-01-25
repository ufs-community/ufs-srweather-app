unload("miniconda3")
unload("python")
prepend_path("MODULEPATH","/ncrc/proj/epic/miniconda3/modulefiles")
load(pathJoin("miniconda3", os.getenv("miniconda3_ver") or "4.12.0"))

setenv("SRW_ENV", "workflow_tools")

load("darshan-runtime/3.4.0")
