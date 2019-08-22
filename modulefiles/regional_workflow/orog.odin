#%Module#####################################################
#############################################################
## Fanglin.Yang@noaa.gov
## NOAA/NWS/NCEP/EMC
#############################################################
#proc ModulesHelp { } {
#puts stderr "Set environment veriables for orog\n"
#}
#module-whatis "orog"

module use /oldscratch/ywang/external/modulefiles

# Load ncep environment
#module load ncep/1.0

# Load Intel environment
#module load PrgEnv-intel/5.2.56
#module rm intel
#module load intel/16.3.210

#module load cray-mpich/7.2.0
#module load craype-haswell
#module load cray-netcdf

# Load NCEPLIBS modules
module load w3emc/v2.3.0
module load ip/v3.0.0
module load sp/v2.0.2
module load w3nco/v2.0.6
module load bacio/v2.0.2

export FCMP=ftn
export CCMP=cc
