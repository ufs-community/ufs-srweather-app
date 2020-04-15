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

# Check final exec folder exists
if [ ! -d "../exec" ]; then
  echo "Creating ../exec folder"
  mkdir ../exec
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
# build utils
#------------------------------------
$Build_utils && {
echo " .... Building utils .... "
./build_utils.sh > $logs_dir/build_utils.log 2>&1
if [ $? -eq 0 ] ; then
  echo "Utils build SUCCEEDED"
else
  echo "Utils build FAILED see $logs_dir/build_utils.log"
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
