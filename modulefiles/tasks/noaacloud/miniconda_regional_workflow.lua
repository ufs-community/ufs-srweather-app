--prepend_path("MODULEPATH", "/contrib/GST/miniconda3/modulefiles")
--load(pathJoin("miniconda3", os.getenv("miniconda3_ver") or "4.10.3"))

prepend_path("PATH", "/apps/oneapi/mpi/2021.3.0/bin")
prepend_path("PATH", "/contrib/EPIC/miniconda3/4.12.0/envs/regional_workflow/bin")
--prepend_path("LD_LIBRARY_PATH", "/lib64")
--setenv("SRW_ENV", "regional_workflow")
