#Setup instructions for NOAA WCOSS Dell using Intel-18.0.1.163 (bash shell)

. /usrx/local/prod/lmod/lmod/init/sh

module purge
module load EnvVars/1.0.3
module load ips/18.0.1.163
module load impi/18.0.1
module load lsf/10.1
module load cmake/3.16.2
module load python/2.7.14

module use /usrx/local/nceplibs/dev/NCEPLIBS/cmake/install/NCEPLIBS-ufs-v2.0.0/ips-18.0.1.163/impi-18.0.1/modules
module load NCEPLIBS/2.0.0

export CMAKE_C_COMPILER=mpiicc
export CMAKE_CXX_COMPILER=mpiicpc
export CMAKE_Fortran_COMPILER=mpiifort
export CMAKE_Platform=wcoss_dell_p3
