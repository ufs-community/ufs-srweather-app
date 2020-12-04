#Setup instructions for NOAA RDHPC Hera using Intel-18.0.5.274 (bash shell)

module purge

module use /contrib/sutils/modulefiles
module load sutils
module load cmake/3.16.1

module use /scratch2/NCEPDEV/nwprod/hpc-stack/test/modulefiles/stack

module load hpc/1.0.0-beta1
module load hpc-intel/18.0.5.274
module load hpc-impi/2018.0.4
module load jasper/2.0.22
module load zlib/1.2.11
module load png/1.6.35
module load hdf5/1.10.6
module load netcdf/4.7.4
module load pio/2.5.1
module load esmf/8_1_0_beta_snapshot_27
module load bacio/2.4.1
module load crtm/2.3.0
module load g2/3.4.1
module load g2tmpl/1.9.1
module load ip/3.3.3
module load nemsio/2.5.2
module load sp/2.3.3
module load w3emc/2.7.3
module load w3nco/2.4.1
module load upp/10.0.0

module load gfsio/1.4.1
module load sfcio/1.4.1
module load landsfcutil/2.4.1
module load nemsiogfs/2.5.3
module load wgrib2/2.0.8


export CMAKE_C_COMPILER=mpiicc
export CMAKE_CXX_COMPILER=mpiicpc
export CMAKE_Fortran_COMPILER=mpiifort
export CMAKE_Platform=hera.intel

