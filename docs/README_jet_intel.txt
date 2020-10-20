#Setup instructions for NOAA RDHPC Jet using Intel-18.0.5.274 (bash shell)

module purge

module use -a /contrib/sutils/modulefiles
module load sutils

module load intel/18.0.5.274
module load impi/2018.4.274
module load hdf5/1.10.4
module load netcdf/4.6.1
module load cmake/3.16.1

export CC=icc
export CXX=icpc
export FC=ifort

NCEPLIBS_INSTALL=/lfs4/HFIP/hfv3gfs/software/NCEPLIBS-ufs-v2.0.0/intel-18.0.5.274/impi-2018.4.274

module use -a ${NCEPLIBS_INSTALL}/modules

module load bacio/2.4.1
module load crtm/2.3.0
module load g2/3.4.1
module load g2tmpl/1.9.1
module load ip/3.3.3
module load landsfcutil/2.4.1
module load nceppost/dceca26
module load nemsio/2.5.2
module load nemsiogfs/2.5.3
module load sp/2.3.3
module load w3emc/2.7.3
module load w3nco/2.4.1

module load gfsio/1.4.1
module load sfcio/1.4.1
module load sigio/2.3.2
module load esmf/8.0.0
module load wgrib2/2.0.8

export CMAKE_C_COMPILER=mpiicc
export CMAKE_CXX_COMPILER=mpiicpc
export CMAKE_Fortran_COMPILER=mpiifort
export CMAKE_Platform=jet.intel

git clone -b release/public-v1 git@github.com:ufs-community/ufs-srweather-app

cd ufs-srweather-app/
./manage_externals/checkout_externals

mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=..
make -j 4
