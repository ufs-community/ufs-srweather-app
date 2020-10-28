#Setup instructions for NOAA RDHPC Hera using Intel-18.0.5.274 (bash shell)

git clone -b release/public-v1 git@github.com:ufs-community/ufs-srweather-app

cd ufs-srweather-app/
./manage_externals/checkout_externals

module purge
module load intel/18.0.5.274
module load impi/2018.0.4
module load cmake/3.16.1

module use -a /scratch1/BMC/gmtb/software/NCEPLIBS-ufs-v2.0.0/intel-18.0.5.274/impi-2018.0.4/modules
module load NCEPLIBS/2.0.0
module load esmf/8.0.0

export CMAKE_C_COMPILER=mpiicc
export CMAKE_CXX_COMPILER=mpiicpc
export CMAKE_Fortran_COMPILER=mpiifort
export CMAKE_Platform=hera.intel

mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=..
make -j 8
