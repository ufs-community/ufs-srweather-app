#!/bin/sh -l

set -u
#. ./print_msg.sh
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
  fic hashes of the non-CCPP-enabled version of FV3.  If specified, it
  must be set to either \"head\" (to check out heads of branches) or 
  \"hash\" (to check out specific commits).  If not specified, it de-
  faults to \"head\".  Note that this has no effect if CCPP is set to
  \"false\".
 
"
)
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

elif [ "$CCPP" = "false" ]; then

  remote_path="ssh://${USER}@vlab.ncep.noaa.gov:29418/$repo_name"
  local_dir="$BASEDIR/${repo_name}"

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

fi
#
#-----------------------------------------------------------------------
#
# Create the directory in which to clone the repository.  Note that this 
# will fail if the directory already exists.  Then recursively clone the
# appropriate FV3GFS repository.
#
#-----------------------------------------------------------------------
#
mkdir_vrfy $local_dir
cd_vrfy $local_dir
git clone --recursive $remote_path .
#
#-----------------------------------------------------------------------
#
# Check out branches or specific hashes.
#
#-----------------------------------------------------------------------
#
cd_vrfy $local_dir
git checkout ${branch_NEMSfv3gfs}

cd_vrfy $local_dir/FV3
git checkout ${branch_FV3}

cd_vrfy $local_dir/FMS
git checkout ${branch_FMS}

cd_vrfy $local_dir/NEMS
git checkout ${branch_NEMS}

if [ "$CCPP" = "true" ]; then

  cd_vrfy $local_dir/ccpp/framework
  git checkout ${branch_ccpp_framework}

  cd_vrfy $local_dir/ccpp/physics
  git checkout ${branch_ccpp_physics}

fi

