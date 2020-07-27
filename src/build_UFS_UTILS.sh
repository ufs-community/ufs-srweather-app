#!/bin/sh
#==========================================================================
#
# Description: Builds chgres, chgres_cube, orog, fre-nctools, sfc_climo_gen,
#              regional_grid, global_equiv_resol, and mosaic_file.
#
#              Note:  The global_equiv_resol, mosaic_file and regional_grid 
#              reside in the ../regional_workflow/sorc directory and are
#              cloned with that repository.
#
# Usage: ./build_UFS_UTILS.sh
#
#==========================================================================
set -eux
cwd=`pwd`

build_dir="${cwd}"
UFS_UTILS="${cwd}/UFS_UTILS"
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
# build UFS_UTILS
#------------------------------------
$Build_UFS_UTILS && {
echo " .... Building UFS_UTILS .... "
cd $UFS_UTILS
./build_all.sh > $logs_dir/build_UFS_UTILS.log 2>&1
if [ $? -eq 0 ] ; then
  echo "UFS_UTILS build SUCCEEDED"
else
  echo "UFS_UTILS build FAILED see $logs_dir/build_regional_grid.log"
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

echo 'Building UFS_UTILS done'
