#!/bin/sh -l

set -u
. ./print_msg.sh
#
#-----------------------------------------------------------------------
#
# Set the usage message to print out if necessary.
#
#-----------------------------------------------------------------------
#
usage_msg=$(printf "%s" "\
Usage:

  $0 head_or_hash

where head_or_hash is an optional argument that must be either \"head\" 
(to check out heads of branches) or \"hash\" (to check out specific com-
mits).  If head_or_hash is unspecified, it defaults to \"head\".")
#
#-----------------------------------------------------------------------
#
# Check argument count (must be 0 or 1).
#
#-----------------------------------------------------------------------
#
  if [ "$#" -gt 1 ]; then
    print_err_msg_exit "\
Script \"$0\":  Incorrect number of arguments specified.
$usage_msg"
  fi
#
#-----------------------------------------------------------------------
#
# Set the variable that determines whether the head of a branch or a 
# specific commit (identified by a unique hash number) will be checked
# out from each repository (i.e. the main NEMSfv3gfs repository and each
# of its submodules).  Then ensure that this variable has been set to a
# valid value.
#
#-----------------------------------------------------------------------
#
head_or_hash=${1:-"head"}

if [ "$head_or_hash" != "head" ] && \
   [ "$head_or_hash" != "hash" ]; then
  print_err_msg_exit "\
Script \"$0\":  The (optional) argument must be either \"head\" or \"hash\".
$usage_msg"
fi
#
#-----------------------------------------------------------------------
#
# Set the branch names or commit hashes to check out according to the 
# setting of head_or_hash.
#
#-----------------------------------------------------------------------
#
case $head_or_hash in
#
"head") 
  branch_NEMSfv3gfs="regional_fv3_nemsfv3gfs"
  branch_FV3="regional_fv3"
  branch_FMS="GFS-FMS"
  branch_NEMS="master"
  ;;
#
"hash")
  branch_NEMSfv3gfs="8c97373"
  branch_FV3="3ef9be7"
  branch_FMS="d4937c8"
  branch_NEMS="10325d4"
  ;;
#
esac
#
#-----------------------------------------------------------------------
#
# Recursively clone the FV3GFS repository.
#
#-----------------------------------------------------------------------
#
BASEDIR="$( cd ../..; pwd; )"
cd $BASEDIR
git clone --recursive ssh://${USER}@vlab.ncep.noaa.gov:29418/NEMSfv3gfs
#
#-----------------------------------------------------------------------
#
# Check out branches or specific hashes.
#
#-----------------------------------------------------------------------
#
cd $BASEDIR/NEMSfv3gfs
git checkout ${branch_NEMSfv3gfs}

cd $BASEDIR/NEMSfv3gfs/FV3
git checkout ${branch_FV3}

cd $BASEDIR/NEMSfv3gfs/FMS
git checkout ${branch_FMS}

cd $BASEDIR/NEMSfv3gfs/NEMS
git checkout ${branch_NEMS}


