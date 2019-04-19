#!/bin/sh -l

set -u
. ./source_funcs.sh
#set -x
#
#-----------------------------------------------------------------------
#
# Set the usage message to print out if necessary.
#
#-----------------------------------------------------------------------
#
usage_msg=$(printf "%s" "\
Usage:

  $0  CCPP  head_or_hash

where:

  CCPP:
  Flag that determines whether or not to clone the CCPP-enabled version
  of FV3.  It must be set to either \"true\" or \"false\".  If set to 
  \"true\", the CCPP-enabled version of FV3 is cloned from the appropri-
  ate GitHUB repository.  If set to \"false\", the non-CCPP-enabled ver-
  sion of FV3 is cloned from the appropriate VLab repository. 

  head_or_hash:
  Optional flag that determines whether to check out the head or speci-
  fic commits whose hashes are hard-coded in this script.  If specified,
  it must be set to either \"head\" (to check out the heads of branches)
  or \"hash\" (to check out the specific commits).  If not specified, it
  defaults to \"head\".  The commits that head_or_hash=\"hash\" will 
  check out comprise a set that is known to result in a successful end-
  to-end run of the workflow.  The hard-coded hashes corresponding to
  these commits may be updated from time to time.
 
"
)
# of the non-CCPP-enabled version of FV3.  
# Note that this has no effect if CCPP is set to
#  \"false\".
#
#-----------------------------------------------------------------------
#
# Check argument count (must be 1 or 2).
#
#-----------------------------------------------------------------------
#
  if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then

    print_err_msg_exit "\
Script \"$0\":  Incorrect number of arguments specified.
$usage_msg"
#
#-----------------------------------------------------------------------
#
# If the number of arguments is correct (1 or 2), set variables to argu-
# ments and check that they have vaild values.
#
#-----------------------------------------------------------------------
#
  else

    CCPP=${1}
    if [ "$CCPP" != "true" ] && \
       [ "$CCPP" != "false" ]; then
      print_err_msg_exit "\
Script \"$0\":  The first argument (CCPP) must be set to \"true\" or \"false\":

  CCPP = \"$CCPP\"

$usage_msg"
    fi 

    head_or_hash=${2:-"head"}
    if [ "$head_or_hash" != "head" ] && \
       [ "$head_or_hash" != "hash" ]; then
      print_err_msg_exit "\
Script \"$0\":  The second argument (head_or_hash) must be set to \"head\" or \"hash\":

  head_or_hash = \"$head_or_hash\"

$usage_msg"
    fi 

  fi

echo
echo "CCPP = \"$CCPP\""
echo "head_or_hash = \"$head_or_hash\""
echo

#
#-----------------------------------------------------------------------
#
# Set the base directory in which we will clone the repository, the re-
# mote repository name, the local directory in which the clone will be
# placed, and the branch names or commit hashes to checkout after clon-
# ing.
#
#-----------------------------------------------------------------------
#
BASEDIR="$( cd ../..; pwd; )"
repo_name="NEMSfv3gfs"

if [ "$CCPP" = "true" ]; then

  remote_path="https://github.com/NCAR/$repo_name"
  local_dir="$BASEDIR/${repo_name}-CCPP"

  branch_NEMSfv3gfs="gmtb/ccpp"
  branch_FV3="gmtb/ccpp"
  branch_FMS="GFS-FMS"
  branch_NEMS="gmtb/ccpp"
  branch_ccpp_framework="master"
  branch_ccpp_physics="master"

  case $head_or_hash in
#
  "head")
    hash_NEMSfv3gfs="${branch_NEMSfv3gfs}"
    hash_FV3="${branch_FV3}"
    hash_FMS="${branch_FMS}"
    hash_NEMS="${branch_NEMS}"
    hash_ccpp_framework="${branch_ccpp_framework}"
    hash_ccpp_physics="${branch_ccpp_physics}"
    ;;
#
  "hash")
    hash_NEMSfv3gfs="6712a95"
    hash_FV3="e98172b"
    hash_FMS="d4937c8"
    hash_NEMS="e909ca1"
    hash_ccpp_framework="ec6498f"
    hash_ccpp_physics="16a0b6a"
    ;;
#
  esac
  
elif [ "$CCPP" = "false" ]; then

  remote_path="ssh://${USER}@vlab.ncep.noaa.gov:29418/$repo_name"
  local_dir="$BASEDIR/${repo_name}"

  branch_NEMSfv3gfs="master"
  branch_FV3="master"
  branch_FMS="GFS-FMS"
  branch_NEMS="master"

  case $head_or_hash in
#
  "head")
    hash_NEMSfv3gfs="${branch_NEMSfv3gfs}"
    hash_FV3="${branch_FV3}"
    hash_FMS="${branch_FMS}"
    hash_NEMS="${branch_NEMS}"
    ;;
#
  "hash")
    hash_NEMSfv3gfs="8c97373"
    hash_FV3="3ef9be7"
    hash_FMS="d4937c8"
    hash_NEMS="10325d4"
    ;;
#
  esac

fi
#
#-----------------------------------------------------------------------
#
# Create the directory in which to clone the repository.  Note that this 
# will fail if the directory already exists.  Then recursively clone the
# appropriate branch of the appropriate FV3GFS repository into that di-
# rectory.
#
#-----------------------------------------------------------------------
#
set -x
mkdir_vrfy $local_dir
cd_vrfy $local_dir
git clone -b ${branch_NEMSfv3gfs} --recursive $remote_path .
#if [ "$CCPP" = "true" ]; then
#  git clone -b ${branch_NEMSfv3gfs} --recursive $remote_path .
#else
#  git clone --recursive $remote_path .
#fi
#
#-----------------------------------------------------------------------
#
# Check out branches or specific hashes.
#
#-----------------------------------------------------------------------
#

cd_vrfy $local_dir
git remote -v
git checkout ${hash_NEMSfv3gfs}

cd_vrfy $local_dir/FV3
git checkout ${hash_FV3}

cd_vrfy $local_dir/FMS
git checkout ${hash_FMS}

cd_vrfy $local_dir/NEMS
git checkout ${hash_NEMS}

if [ "$CCPP" = "true" ]; then

  cd_vrfy $local_dir/ccpp/framework
  git checkout ${hash_ccpp_framework}

  cd_vrfy $local_dir/ccpp/physics
  git checkout ${hash_ccpp_physics}

fi

