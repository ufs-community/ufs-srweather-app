help([[
This module loads python environement for running the UFS SRW App on
the NOAA cloud
]])

whatis([===[Loads libraries needed for running the UFS SRW App on NOAA cloud ]===])

prepend_path("MODULEPATH","/apps/modules/modulefiles")
load("rocoto")



load("conda")

setenv("PROJ_LIB","/contrib/EPIC/miniconda3/4.12.0/envs/regional_workflow/share/proj")
setenv("OPT","/contrib/EPIC/hpc-modules")
append_path("PATH","/contrib/EPIC/miniconda3/4.12.0/envs/regional_workflow/bin")
prepend_path("PATH","/contrib/EPIC/bin")

-- Add missing libstdc binary for Azure
if os.getenv("PW_CSP") == "azure" then
   setenv("LD_PRELOAD","/opt/nvidia/nsight-systems/2023.1.2/host-linux-x64/libstdc++.so.6")
end

if mode() == "load" then
   LmodMsgRaw([===[Please do the following to activate conda:
       > conda activate srw_app
]===])
end
