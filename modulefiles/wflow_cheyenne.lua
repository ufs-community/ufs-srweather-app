help([[
This module loads python environement for running the UFS SRW App on
on the CISL machine Cheyenne
]])

whatis([===[Loads libraries needed for running the UFS SRW App on Cheyenne ]===])

load("ncarenv")

append_path("MODULEPATH","/glade/p/ral/jntp/UFS_SRW_app/modules")
load("rocoto")

load(pathJoin("conda", os.getenv("conda_ver") or "latest"))

if mode() == "load" then
   LmodMsgRaw([===[Please do the following to activate conda:
       > conda activate /glade/p/ral/jntp/UFS_SRW_app/conda/regional_workflow
]===])
end

