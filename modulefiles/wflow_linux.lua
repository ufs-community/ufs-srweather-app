help([[
This module sets a path to activate conda environment needed for running the UFS SRW App on Linux
]])

whatis([===[This module sets a path for conda environment needed for running the UFS SRW App on Linux]===])

setenv("CMAKE_Platform", "linux")

load("conda")

-- add rocoto to path
local rocoto_path="/home/username/rocoto"
prepend_path("PATH", pathJoin(rocoto_path,"bin"))

-- add fake slurm commands
local srw_path="/home/username/ufs-srweather-app"
prepend_path("PATH", pathJoin(srw_path, "ush/rocoto_fake_slurm"))

-- set python path
load("set_pythonpath")

-- display conda activation message
if mode() == "load" then
     LmodMsgRaw([===[Please do the following to activate conda:
       > conda activate srw_app
]===])
end
