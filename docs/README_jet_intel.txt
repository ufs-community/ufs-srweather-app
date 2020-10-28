#Setup instructions for NOAA RDHPC Jet using Intel-18.0.5.274 (bash shell)

git clone -b release/public-v1 git@github.com:ufs-community/ufs-srweather-app

cd ufs-srweather-app/
./manage_externals/checkout_externals

module purge
module use /contrib/sutils/modulefiles
module load sutils
module load intel/18.0.5.274
module load impi/2018.4.274
module load hdf5/1.10.5
module load cmake/3.16.1

module use /lfs4/HFIP/hfv3gfs/software/NCEPLIBS-ufs-v2.0.0/intel-18.0.5.274/impi-2018.4.274/modules

module load NCEPLIBS/2.0.0
module load esmf/8.0.0

export CMAKE_C_COMPILER=mpiicc
export CMAKE_CXX_COMPILER=mpiicpc
export CMAKE_Fortran_COMPILER=mpiifort
export CMAKE_Platform=jet.intel

mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=..
make -j 8
