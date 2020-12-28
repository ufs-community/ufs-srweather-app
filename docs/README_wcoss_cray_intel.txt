#Setup instructions for WCOSS-Cray using Intel-19.0.5.281 (bash shell)

. /opt/modules/3.2.10.3/init/sh
module purge
module load PrgEnv-intel/5.2.82
module rm intel
module rm NetCDF-intel-sandybridge/4.2
module load intel/19.0.5.281
module load xt-lsfhpc/9.1.3
module load craype-sandybridge
module load python/2.7.14
module load cmake/3.16.2
module load git/2.18.0

module use /usrx/local/nceplibs/NCEPLIBS/NCEPLIBS-ufs-v2.0.0/intel-19.0.5.281/impi-2019/modules
module load NCEPLIBS/2.0.0
module load esmf jasper libpng libjpeg netcdf

export CC=cc
export FC=ftn
export CXX=CC

export CMAKE_C_COMPILER=cc
export CMAKE_CXX_COMPILER=CC
export CMAKE_Fortran_COMPILER=ftn
export CMAKE_Platform=wcoss_cray
