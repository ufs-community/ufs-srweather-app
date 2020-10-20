#Setup instructions for NOAA RDHPC Hera using Intel-18.0.5.274 (bash shell)

module purge
module load intel/18.0.5.274
module load impi/2018.0.4
module load cmake/3.16.1

export CC=icc
export CXX=icpc
export FC=ifort

NCEPLIBS_INSTALL=/scratch1/BMC/gmtb/software/NCEPLIBS-ufs-v2.0.0/intel-18.0.5.274/impi-2018.0.4

module use ${NCEPLIBS_INSTALL}/modules

module load libpng/1.6.35

module load bacio/2.4.1
module load g2/3.4.1
module load g2tmpl/1.9.1
module load ip/3.3.3
module load nemsio/2.5.2
module load sp/2.3.3
module load w3emc/2.7.3
module load w3nco/2.4.1
module load sigio/2.3.2

module load sfcio/1.4.1
module load gfsio/1.4.1
module load nemsiogfs/2.5.3
module load landsfcutil/2.4.1
module load wgrib2/2.0.8
module load netcdf/4.7.4
module load esmf/8.0.0
module load crtm/2.3.0

export CMAKE_C_COMPILER=mpiicc
export CMAKE_CXX_COMPILER=mpiicpc
export CMAKE_Fortran_COMPILER=mpiifort
export CMAKE_Platform=hera.intel

git clone -b release/public-v1 git@github.com:ufs-community/ufs-srweather-app

cd ufs-srweather-app/
./manage_externals/checkout_externals

mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=..
make -j 4
