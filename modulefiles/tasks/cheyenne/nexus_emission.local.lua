-- Note that nco/5.0.3 is available on cheyenne
-- load(pathJoin("nco", os.getenv("nco_ver") or "4.9.5"))
load("nco/4.9.5")

-- Paddy added for ERROR:
--   /glade/work/paddy/rrfs-cmaq/ufs-srweather-app/exec/nexus: error while loading shared libraries: libmpi++abi1002.so: cannot open shared object file: No such file or directory
load("mpt/2.25")
-- or try:
-- load("openmpi/4.1.1")

load("ncarenv")
load("miniconda_regional_workflow-cmaq")
