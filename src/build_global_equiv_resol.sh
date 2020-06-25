#!/bin/sh
set -eux
#
# Check for input argument: this should be the "platform" if it exists.
#
if [ $# -eq 0 ]; then
  echo
  echo "No 'platform' argument supplied"
  echo "Using directory structure to determine machine settings"
  platform=''
else
  platform=$1
fi
#
source ./machine-setup.sh > /dev/null 2>&1
if [ $platform = "wcoss_cray" ]; then
  platform="cray"
fi
#
# Set the name of the package.  This will also be the name of the execu-
# table that will be built.
#
package_name="global_equiv_resol"
#
# Make an exec folder if it doesn't already exist.
#
exec_dir=`pwd`/../exec
mkdir -p ${exec_dir}
#
# Change directory to where the source code is located.
#
srcDir=`pwd`/../regional_workflow/sorc/${package_name}.fd/
cd ${srcDir}
#
# The build will be performed in a temporary directory.  If the build is
# successful, the temporary directory will be removed.
#
tmpDir=`pwd`/build
mkdir -p $tmpDir
cd $tmpDir
#
# Load modules.
#
set +x
module list
#module use ../../../modulefiles/global_equiv_resol
#module load ${package_name}.${target}
module use ../../../modulefiles/codes/${target}
module load ${package_name}
module list
set -x
#
MPICH_UNEX_BUFFER_SIZE=256m
MPICH_MAX_SHORT_MSG_SIZE=64000
MPICH_PTL_UNEX_EVENTS=160k
KMP_STACKSIZE=2g
F_UFMTENDIAN=big
#
# HDF5 and NetCDF directories.
#
if [ $platform = "cray" ]; then
  HDF5=${HDF5_DIR}
  NETCDF=${NETCDF_DIR}
elif [ $platform = "theia" ]; then
  HDF5_DIR=$HDF5
  NETCDF_DIR=$NETCDF
elif [ $platform = "hera" ]; then
  HDF5_DIR=$HDF5
  NETCDF_DIR=$NETCDF
elif [ $platform = "cheyenne" ]; then
  NETCDF_DIR=$NETCDF
  HDF5_DIR=$NETCDF #HDF5 resides with NETCDF on Cheyenne
  export HDF5=$NETCDF     #HDF5 used in Makefile_cheyenne
elif [ $platform = "jet" ]; then
  HDF5_DIR=$HDF5
  NETCDF_DIR=$NETCDF
elif [ $platform = "stampede" ]; then
  HDF5_DIR=$TACC_HDF5_DIR
  NETCDF_DIR=$TACC_NETCDF_DIR
fi
#
# Create alias for "make".
#
if [ $platform = "cray" ]; then
  alias make="make HDF5_HOME=${HDF5} NETCDF_HOME=${NETCDF} NC_BLKSZ=64K SITE=${platform}"
else
  alias make="make HDF5_HOME=${HDF5_DIR} NETCDF_HOME=${NETCDF_DIR} NC_BLKSZ=64K SITE=${platform}"
fi

set +x
echo
echo "////////////////////////////////////////////////////////////////////////////////"
echo "Building package \"$package_name\" for platform \"$platform\" ..."
echo "////////////////////////////////////////////////////////////////////////////////"
echo
set -x
#
# Copy all source code and the makefile to the temporary directory.
# Then clean and build from scratch.
#
cp $srcDir/*.f90 $tmpDir
cp $srcDir/Makefile_${platform} $tmpDir/Makefile
make clean
make
#
# Check if the executable was successfully built.  If so, move it to the
# exec subdirectory under the home directory.  If not, exit with an er-
# ror message.
#
target="${package_name}"
if [ -f $target ]; then
  mv $target $exec_dir
else
  echo "Error during '$target' build"
  exit 1
fi
#
# Remove the temporary build directory.
#
set +x
echo
echo "Removing temporary build directory ..."
echo
rm -fr $tmpDir

echo "Done."

exit
