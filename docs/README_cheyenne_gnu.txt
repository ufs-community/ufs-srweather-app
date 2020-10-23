#Setup instructions for CISL Cheyenne using Intel-19.1.1 (bash shell)

git clone -b release/public-v1 git@github.com:ufs-community/ufs-srweather-app

cd ufs-srweather-app/
./manage_externals/checkout_externals


module purge
module load ncarenv/1.3
module load gnu/9.1.0
module load mpt/2.19
module load ncarcompilers/0.5.0
module load cmake/3.16.4

module use -a /glade/p/ral/jntp/UFS_SRW_app/temp/NCEPLIBS-ufs-v2.0.0/gnu-9.1.0/mpt-2.19/modules/
module load esmf/8.0.0
module load NCEPLIBS/2.0.0

export CMAKE_C_COMPILER=mpicc
export CMAKE_CXX_COMPILER=mpicxx
export CMAKE_Fortran_COMPILER=mpif90
export CMAKE_Platform=cheyenne.intel

mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=..
make -j 4
