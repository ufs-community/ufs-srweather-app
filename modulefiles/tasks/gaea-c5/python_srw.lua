unload("miniconda3")
prepend_path("MODULEPATH","/lustre/f2/dev/role.epic/contrib/C5/miniconda3/modulefiles")
load(pathJoin("miniconda3", os.getenv("miniconda3_ver") or "4.12.0"))

setenv("SRW_ENV", "workflow_tools")

load("darshan-runtime/3.4.0")
