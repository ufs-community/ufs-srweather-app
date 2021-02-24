#Setup instructions for CISL Cheyenne using Intel-19.1.1 (bash shell)

module purge
module load ncarenv/1.3
module load intel/19.1.1
module load mpt/2.19
module load ncarcompilers/0.5.0
module load cmake/3.16.4

module use /glade/p/ral/jntp/GMTB/tools/NCEPLIBS-ufs-v2.0.0/intel-19.1.1/mpt-2.19/modules
module load NCEPLIBS/2.0.0

export CMAKE_C_COMPILER=mpicc
export CMAKE_CXX_COMPILER=mpicxx
export CMAKE_Fortran_COMPILER=mpif90
export CMAKE_Platform=cheyenne.intel