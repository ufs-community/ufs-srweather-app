#Setup instructions for macOS Mojave or Catalina using gcc-10.2.0 + gfortran-10.2.0

# This path should point to your NCEPLIBS install directory
export NCEPLIBS=/usr/local/NCEPLIBS-ufs-v2.0.0

# Need this environment script to be executable
chmod +x ${NCEPLIBS}/bin/setenv_nceplibs.sh
${NCEPLIBS}/bin/setenv_nceplibs.sh

export CC=gcc-10
export FC=gfortran-10
export CXX=g++-10
ulimit -S -s unlimited

export NETCDF=${NCEPLIBS}
export ESMFMKFILE=${NCEPLIBS}/lib/esmf.mk
export CMAKE_PREFIX_PATH=${NCEPLIBS}

export CMAKE_C_COMPILER=mpicc
export CMAKE_CXX_COMPILER=mpicxx
export CMAKE_Fortran_COMPILER=mpifort
export CMAKE_Platform=macosx.gnu

