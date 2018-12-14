#!/bin/sh -l

set -u
. ./print_msg.sh
#
#-----------------------------------------------------------------------
#
# Check arguments.
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
# Set variable that determines whether the head branches or specific 
# commits will be checked out.  Then ensure that it has an allowed val-
# ue.
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
# Clone the repository.
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
cd NEMSfv3gfs
git checkout ${branch_NEMSfv3gfs}

cd $BASEDIR/NEMSfv3gfs/FV3
git checkout ${branch_FV3}

cd $BASEDIR/NEMSfv3gfs/FMS
git checkout ${branch_FMS}

cd $BASEDIR/NEMSfv3gfs/NEMS
git checkout ${branch_NEMS}

