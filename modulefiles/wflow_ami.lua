help([[
This module loads python environement for running the UFS SRW App on
the NOAA cloud
]])

whatis([===[Loads libraries needed for running the UFS SRW App on NOAA cloud ]===])

--prepend_path("MODULEPATH","/apps/modules/modulefiles")
--load("rocoto")

--prepend_path("MODULEPATH","/contrib/EPIC/miniconda3/modulefiles")
--load(pathJoin("miniconda3", os.getenv("miniconda3_ver") or "4.12.0"))

setenv("PROJ_LIB","/opt/miniconda/envs/regional_workflow/share/proj")
--setenv("OPT","/contrib/EPIC/hpc-modules")
prepend_path("PATH","/opt/miniconda/envs/regional_workflow/bin")

--if mode() == "load" then
--   LmodMsgRaw([===[Please do the following to activate conda:
--       > conda activate regional_workflow
--]===])
--end
