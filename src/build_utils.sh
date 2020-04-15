#!/bin/sh
#==========================================================================
#
# Description: Builds chgres, chgres_cube, orog, fre-nctools, sfc_climo_gen,
#              regional_grid, global_equiv_resol, and mosaic_file.
#
#              Note:  This scripts build two chgres_cube from two different 
#              branches of the UFS_UTILS repository.
#
#              Note:  The global_equiv_resol, mosaic_file and regional_grid 
#              reside in the ../regional_workflow/sorc directory and are
#              cloned with that repository.
#
# Usage: ./build_utils.sh
#
#==========================================================================
set -eux
cwd=`pwd`

build_dir="${cwd}"
UFS_UTILS_DEV="${cwd}/UFS_UTILS_develop/sorc"
UFS_UTILS_CHGRES_GRIB2="${cwd}/UFS_UTILS_chgres_grib2/sorc"
build_dir="${cwd}"
export USE_PREINST_LIBS="true"

#------------------------------------
# END USER DEFINED STUFF
#------------------------------------

logs_dir=${cwd}/logs
if [ ! -d $logs_dir  ]; then
  echo "Creating logs folder"
  mkdir $logs_dir
fi

#------------------------------------
# INCLUDE PARTIAL BUILD 
#------------------------------------

. ./partial_build.sh

#------------------------------------
# build chgres
#------------------------------------
$Build_chgres && {
echo " .... Chgres build not currently supported .... "
#echo " .... Building chgres .... "
#./build_chgres.sh > $logs_dir/build_chgres.log 2>&1
}

#------------------------------------
# build chgres_cube
#------------------------------------
$Build_chgres_cube && {
echo " .... Building chgres_cube .... "
cd $UFS_UTILS_CHGRES_GRIB2
./build_chgres_cube.sh > $logs_dir/build_chgres_cube.log 2>&1
if [ $? -eq 0 ] ; then
  echo "chgres_cube build SUCCEEDED"
else
  echo "chgres_cube build FAILED see $logs_dir/build_chgres_cube.log"
  exit 1
fi
}

#------------------------------------
# build orog
#------------------------------------
$Build_orog && {
echo " .... Building orog .... "
cd $UFS_UTILS_DEV
./build_orog.sh > $logs_dir/build_orog.log 2>&1
if [ $? -eq 0 ] ; then
  echo "orog build SUCCEEDED"
else
  echo "orog build FAILED see $logs_dir/build_orog.log"
  exit 1
fi
}

#------------------------------------
# build fre-nctools
#------------------------------------
$Build_nctools && {
echo " .... Building fre-nctools .... "
cd $UFS_UTILS_DEV
./build_fre-nctools.sh > $logs_dir/build_fre-nctools.log 2>&1
if [ $? -eq 0 ] ; then
  echo "fre-nctools build SUCCEEDED"
else
  echo "fre-nctools build FAILED see $logs_dir/build_fre-nctools.log"
  exit 1
fi
}

#------------------------------------
# build sfc_climo_gen
#------------------------------------
$Build_sfc_climo_gen && {
echo " .... Building sfc_climo_gen .... "
cd $UFS_UTILS_DEV
./build_sfc_climo_gen.sh > $logs_dir/build_sfc_climo_gen.log 2>&1
if [ $? -eq 0 ] ; then
  echo "sfc_climo_gen build SUCCEEDED"
else
  echo "sfc_climo_gen build FAILED see $logs_dir/build_sfc_climo_gen.log"
  exit 1
fi
}

#------------------------------------
# build regional_grid
#------------------------------------
$Build_regional_grid && {
echo " .... Building regional_grid .... "
cd $build_dir
./build_regional_grid.sh > $logs_dir/build_regional_grid.log 2>&1
if [ $? -eq 0 ] ; then
  echo "regional_grid build SUCCEEDED"
else
  echo "regional_grid build FAILED see $logs_dir/build_regional_grid.log"
  exit 1
fi
}

#------------------------------------
# build global_equiv_resol
#------------------------------------
$Build_global_equiv_resol && {
echo " .... Building global_equiv_resol .... "
cd $build_dir
./build_global_equiv_resol.sh > $logs_dir/build_global_equiv_resol.log 2>&1
if [ $? -eq 0 ] ; then
  echo "global_equiv_resol build SUCCEEDED"
else
  echo "global_equiv_resol build FAILED see $logs_dir/build_global_equiv_resol.log"
  exit 1
fi
}

#------------------------------------
# build mosaic file
#------------------------------------
$Build_mosaic_file && {
echo " .... Building mosaic_file .... "
cd $build_dir
./build_mosaic_file.sh > $logs_dir/build_mosaic_file.log 2>&1
if [ $? -eq 0 ] ; then
  echo "mosaic_file build SUCCEEDED"
else
  echo "mosaic_file build FAILED see $logs_dir/build_mosaic.log"
  exit 1
fi
}

cd $build_dir

echo 'Building utils done'
