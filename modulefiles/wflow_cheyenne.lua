help([[
This module loads python environement for running the UFS SRW App on
on the CISL machine Cheyenne
]])

whatis([===[Loads libraries needed for running the UFS SRW App on Cheyenne ]===])

append_path("MODULEPATH","/glade/p/ral/jntp/UFS_SRW_app/modules")
load("rocoto")

prepend_path("MODULEPATH","/glade/work/epicufsrt/contrib/spack-stack/spack-stack-1.3.0/envs/unified-env/install/modulefiles/Core")
load("stack-intel/19.1.1.217")
load("stack-intel-mpi/2019.7.217")

prepend_path("MODULEPATH", "/glade/work/jedipara/cheyenne/spack-stack/modulefiles/misc")
load("stack-python/3.9.12")

load("ufs-pyenv")
