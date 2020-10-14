#!/bin/sh
set -eux
#==========================================================================
# Description:  This script calls a series of build scripts depending on 
#               settings in regional_build.cfg.  The forecast model, the
#               pre-processing tasks, and the post-processor can be built
#               from this script.
#
# Usage: ./build_all >& build.out &
#==========================================================================
#------------------------------------
# USER DEFINED STUFF:
#
# USE_PREINST_LIBS: set to "true" to use preinstalled libraries.
#                   Library build is not currently supported within this script.
#------------------------------------

export USE_PREINST_LIBS="true"

#------------------------------------
# END USER DEFINED STUFF
#------------------------------------

build_dir=`pwd`
logs_dir=$build_dir/logs
if [ ! -d $logs_dir  ]; then
  echo "Creating logs folder"
  mkdir $logs_dir
fi

#
# Set the full path of the directory where the binaries (executables) 
# will be placed (and where the workflow scripts will look for them).
#
export BIN_DIR=$( readlink -m "../bin" )
#
# If the binaries directory doesn't already exist, create it.
#
if [ ! -d "${BIN_DIR}" ]; then
  echo "Creating binaries directory: BIN_DIR = \"${BIN_DIR}\""
  mkdir "${BIN_DIR}"
fi

#------------------------------------
# INCLUDE PARTIAL BUILD 
#------------------------------------

. ./partial_build.sh

#------------------------------------
# build libraries first
#------------------------------------
$Build_libs && {
echo " .... Library build not currently supported .... "
#echo " .... Building libraries .... "
#./build_libs.sh > $logs_dir/build_libs.log 2>&1
}

#------------------------------------
# build forecast
#------------------------------------
$Build_forecast && {
echo " .... Building forecast .... "
./build_forecast.sh > $logs_dir/build_forecast.log 2>&1
if [ $? -eq 0 ] ; then
  echo "Forecast build SUCCEEDED"
else
  echo "Forecast build FAILED see $logs_dir/build_forecast.log"
  exit 1
fi
}

#------------------------------------
# build post
#------------------------------------
$Build_post && {
echo " .... Building post .... "
./build_post.sh > $logs_dir/build_post.log 2>&1
if [ $? -eq 0 ] ; then
  echo "Post build SUCCEEDED"
else
  echo "Post build FAILED see $logs_dir/build_post.log"
  exit 1
fi
}

#------------------------------------
# build UTILS
#------------------------------------
$Build_UFS_UTILS && {
echo " .... Building UFS_UTILS .... "
./build_UFS_UTILS.sh > $logs_dir/build_UFS_UTILS.log 2>&1
if [ $? -eq 0 ] ; then
  echo "UFS_UTILS build SUCCEEDED"
else
  echo "UFS_UTILS build FAILED see $logs_dir/build_UFS_UTILS.log"
  exit 1
fi
}

#------------------------------------
# build gsi
#------------------------------------
$Build_gsi && {
echo " .... GSI build not currently supported .... "
#echo " .... Building gsi .... "
#./build_gsi.sh > $logs_dir/build_gsi.log 2>&1
}

echo;echo " .... Build system finished .... "
echo;echo " .... Installing executables .... "

./install_all.sh

echo;echo " .... Installation finished .... "
echo;echo " .... Linking fix files .... "

./link_fix.sh

echo;echo " .... Linking fix files finished .... "

exit 0
