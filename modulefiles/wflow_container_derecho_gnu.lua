help([[
This module loads python environement for running the UFS SRW App in
a singularity/apptainer container
]])

whatis([===[Loads libraries needed for running the UFS SRW App in
a singularity/apptainer container]===])

append_path("MODULEPATH","/glade/work/epicufsrt/contrib/derecho/modulefiles")
load("rocoto/1.3.7")

unload("python")

load("conda")
load("apptainer")
load("gcc/14.3.0")
load("openmpi/5.0.9")

if mode() == "load" then
   execute{cmd="conda activate srw_app", modeA={"load"}}
end

