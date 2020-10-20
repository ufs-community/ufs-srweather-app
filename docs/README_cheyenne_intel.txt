#Setup instructions for CISL Cheyenne using Intel-19.1.1 (bash shell)

module purge
module load ncarenv/1.3
module load intel/19.1.1
module load mpt/2.19
module load ncarcompilers/0.5.0
module load cmake/3.16.4

export CC=mpicc
export FC=mpif90
export CXX=mpicxx

NCEPLIBS_INSTALL=/glade/p/ral/jntp/GMTB/tools/NCEPLIBS-ufs-v2.0.0/intel-19.1.1/mpt-2.19

module use -a ${NCEPLIBS_INSTALL}/modules

module load bacio/2.4.1
module load g2/3.4.1
module load ip/3.3.3
module load nemsio/2.5.2
module load sp/2.3.3
module load w3emc/2.7.3
module load w3nco/2.4.1
module load sigio/2.3.2
module load g2tmpl/1.9.1
module load sfcio/1.4.1
module load gfsio/1.4.1
module load nemsiogfs/2.5.3
module load landsfcutil/2.4.1
module load wgrib2/2.0.8
module load netcdf/4.7.4
module load crtm/2.3.0

export ESMFMKFILE=/glade/p/ral/jntp/GMTB/tools/NCEPLIBS-ufs-v2.0.0/intel-19.1.1/mpt-2.19/lib64/esmf.mk

export CMAKE_C_COMPILER=mpicc
export CMAKE_CXX_COMPILER=mpicxx
export CMAKE_Fortran_COMPILER=mpif90
export CMAKE_Platform=cheyenne.intel

git clone -b release/public-v1 git@github.com:ufs-community/ufs-srweather-app

cd ufs-srweather-app/
./manage_externals/checkout_externals

mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=..
make -j 4
