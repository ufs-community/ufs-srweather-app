#!/bin/sh
#==========================================================================
#
# Description: Builds chgres, chgres_cube, orog, fre-nctools, sfc_climo_gen,
#              regional_esg_grid, global_equiv_resol, and make_solo_mosaic.
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
  echo "UFS_UTILS build FAILED see $logs_dir/build_UFS_UTILS.log"
  exit 1
fi
}

cd $build_dir

echo 'Building UFS_UTILS done'
