#Setup instructions for MSU Orion using Intel-19.1.0.166 (bash shell)

module purge
module load intel/2020
module load impi/2020
module load cmake/3.15.4

module use /apps/contrib/NCEP/libs/NCEPLIBS-ufs-v2.0.0/intel-19.1.0.166/impi-2020.0.166/modules

module load NCEPLIBS/2.0.0
module load esmf/8.0.0

export CMAKE_C_COMPILER=mpiicc
export CMAKE_CXX_COMPILER=mpiicpc
export CMAKE_Fortran_COMPILER=mpiifort
export CMAKE_Platform=orion.intel

