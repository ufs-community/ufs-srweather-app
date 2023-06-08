help([[
This module loads python environement for running the UFS SRW App on
on the CISL machine Cheyenne
]])

whatis([===[Loads libraries needed for running the UFS SRW App on Cheyenne ]===])

load("ncarenv")

append_path("MODULEPATH","/glade/p/ral/jntp/UFS_SRW_app/modules")
load("rocoto")

unload("python")

load("set_pythonpath")
prepend_path("MODULEPATH","/glade/work/epicufsrt/contrib/miniconda3/modulefiles")
load(pathJoin("miniconda3", os.getenv("miniconda3_ver") or "4.12.0"))

if mode() == "load" then
   LmodMsgRaw([===[Please do the following to activate conda:
       > conda activate workflow_tools
]===])
end

