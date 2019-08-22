#%Module#####################################################
#############################################################
## shave component - wcoss_cray
#############################################################
# Load ncep environment
#module load ncep/1.0

# Load Intel environment
#module load PrgEnv-intel/5.2.56
#module rm intel
#module load intel/16.3.210

#module load cray-mpich/7.2.0
#module load craype-haswell
#module load cray-netcdf

export FCMP=ftn
export FFLAGS="-O0"
