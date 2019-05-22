#!/bin/sh -l

set -u
. ./source_funcs.sh
#
#-----------------------------------------------------------------------
#
# Set the usage message to print out if necessary.
#
#-----------------------------------------------------------------------
#
usage_msg=$(printf "%s" "\
Usage:

  $0  software_name  head_or_hash

where:

  software_name:
  String that specifies the software whose repository we will cloned.
  Valid values for this are:

    \"NEMSfv3gfs\"
    To clone the (non-CCPP-enabled) version of the FV3 model code (run 
    under NEMS) from the appropriate VLab git repository.

    \"NEMSfv3gfs-CCPP\"
    To clone the CCPP-enabled version of the FV3 model code (run under 
    NEMS) from the appropriate github repository.

    \"UFS_UTILS\"
    To clone the UFS_UTILS (UFS common utilities) code from the appro-
    priate VLab repository.

    \"UPP\"
    To clone the UPP (Unified Post Processor) model code from the appro-
    priate VLab repository.

  head_or_hash:
  Optional flag that determines whether to check out the head or speci-
  fic commits of the appropriate branch in the repo containing the spe-
  cified software as well as of the branches in the repos containing
  the submodules, if any.  If specified, it must be set to \"head\" [to
  check out the head(s) of the branch(es)] or to \"hash\" [to check out
  a specific commit(s) of the branch(es)].  If not specified, it de-
  faults to \"head\".  The commit(s) that head_or_hash=\"hash\" will check
  out comprise a set that is known to result in a successful end-to-end
  run of the workflow.  The hard-coded hashes in this scrip correspond-
  ing to these commits may be updated from time to time.
 
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

  software_name="$1"
  head_or_hash=${2:-"head"}

  valid_vals_software_name=( "NEMSfv3gfs" "NEMSfv3gfs-CCPP" "UFS_UTILS" "UPP" )
  iselementof "$software_name" valid_vals_software_name || { \
  valid_vals_software_name_str=$(printf "\"%s\" " "${valid_vals_software_name[@]}");
  print_err_msg_exit "\
Software package specified in \"software_name\" is not supported:
  software_name = \"$software_name\"
software_name must be set to one of the following:
  $valid_vals_software_name_str

$usage_msg
";
  }

  valid_vals_head_or_hash=( "head" "hash" )
  iselementof "$head_or_hash" valid_vals_head_or_hash || { \
  valid_vals_head_or_hash_str=$(printf "\"%s\" " "${valid_vals_head_or_hash[@]}");
  print_err_msg_exit "\
Value specified for \"head_or_hash\" is not supported:
  head_or_hash = \"$head_or_hash\"
head_or_hash must be set to one of the following:
  $valid_vals_head_or_hash_str

$usage_msg
";
  }

fi
#
print_info_msg "\
Input values are:
  software_name = \"$software_name\"
  head_or_hash = \"$head_or_hash\"
"
#
#-----------------------------------------------------------------------
#
# Depending on the software package specified, set:
#
# 1) The name of the remote repository containing the specified soft-
#    ware (repo_name).
#
# 2) The URL of the remote repository (remote_URL).
#
# 3) The full path of the local directory in which to clone the reposi-
#    tory (clone_path).
#
# 4) The name of the branch in the remote repository to check out
#    (branch_name).
#
# 5) The directories under clone_path in which to clone submodules, if
#    any (submod_subdirs).
#
# 6) The names of the branches of the various submodule repositories to
#    check out (submod_branch_names).
#
# 7) If head_or_hash is set to "hash":
#    a) The hash of the commit of the branch in the remote repository to
#       check out (branch_hash).
#    b) If the branch contains submodules, the hashes of the commits of
#       the branches in the submodule repositories to check out (sub-
#       dom_branch_hashes).
#    The case of head_or_hash set to "head" is considered later.
#
#-----------------------------------------------------------------------
#
BASEDIR="$( cd ../..; pwd; )"

if [ "$software_name" = "NEMSfv3gfs" ]; then

  repo_name="NEMSfv3gfs"
  remote_URL="ssh://${USER}@vlab.ncep.noaa.gov:29418/$repo_name"

  clone_path="$BASEDIR/${repo_name}"
  branch_name="master"

  submod_subdirs=( "FV3" "FMS" "NEMS" )
  submod_branch_names=( "master" "GFS-FMS" "master" )

  if [ "$head_or_hash" = "hash" ]; then
    branch_hash="8c97373"
    submod_branch_hashes=( "3ef9be7" "d4937c8" "10325d4" )
  fi

elif [ "$software_name" = "NEMSfv3gfs-CCPP" ]; then

  repo_name="NEMSfv3gfs"
  remote_URL="https://github.com/NCAR/$repo_name"

  clone_path="$BASEDIR/${repo_name}-CCPP"
  branch_name="gmtb/ccpp"

  submod_subdirs=( "FV3" "FMS" "NEMS" "ccpp/framework" "ccpp/physics" )
  submod_branch_names=( "gmtb/ccpp" "GFS-FMS" "gmtb/ccpp" "master" "master" )

  if [ "$head_or_hash" = "hash" ]; then
    branch_hash="6712a95"
    submod_branch_hashes=( "e98172b" "d4937c8" "e909ca1" "ec6498f" "16a0b6a" )
  fi 

elif [ "$software_name" = "UFS_UTILS" ]; then

  repo_name="UFS_UTILS"
  remote_URL="ssh://${USER}@vlab.ncep.noaa.gov:29418/$repo_name"

  clone_path="$BASEDIR/${repo_name}"
#
# How to get just the chgres_cube code, not the rest of the codes in 
# UFS_UTILS?  Also, want to put the chgres_cube code under 
#   ${BASEDIR}/fv3sar_workflow/sorc/chgres_cube.fd.
# How to do that?
#
#  clone_path="$BASEDIR/fv3sar_workflow/sorc/UFS_UTILS.fd"
  branch_name="feature/chgres_grib2"

  submod_subdirs=()
  submod_branch_names=()

  if [ "$head_or_hash" = "hash" ]; then
    branch_hash=""
    submod_branch_hashes=()
    print_err_msg_exit "\
Hashes corresponding to previous (i.e. before HEAD) commits that are 
known to work with the FV3SAR workflow have not yet been specified for 
this repository:
  repo_name = \"${repo_name}\"
  branch_name = \"${branch_name}\"
  branch_hash = \"${branch_hash}\"
Please specify hash values for \"branch_hash\" (and, if the repository 
contains submodules, for the elements of the array \"submod_branch_hash-
es\") in the script and rerun.
"
  fi

elif [ "$software_name" = "UPP" ]; then

  repo_name="EMC_post"
  remote_URL="ssh://${USER}@vlab.ncep.noaa.gov:29418/$repo_name"

#  clone_path="$BASEDIR/${repo_name}"
  clone_path="$BASEDIR/fv3sar_workflow/sorc/gfs_post.fd"
  branch_name="master"

  submod_subdirs=()
  submod_branch_names=()

  if [ "$head_or_hash" = "hash" ]; then
    branch_hash=""
    submod_branch_hashes=()
    print_err_msg_exit "\
Hashes corresponding to previous (i.e. before HEAD) commits that are 
known to work with the FV3SAR workflow have not yet been specified for 
this repository:
  repo_name = \"${repo_name}\"
  branch_name = \"${branch_name}\"
  branch_hash = \"${branch_hash}\"
Please specify hash values for \"branch_hash\" (and, if the repository 
contains submodules, for the elements of the array \"submod_branch_hash-
es\") in the script and rerun.
"
  fi

fi
#
#-----------------------------------------------------------------------
#
# If head_or_hash is set to "head", set the hashes of the commits of the
# branches in the main repository and any submodule repositories to just
# the branch names.  This will cause the "git checkout" command to check
# out the branch heads.
#
#-----------------------------------------------------------------------
#
if [ "$head_or_hash" = "head" ]; then

  branch_hash="HEAD"

  num_submods=${#submod_subdirs[@]}
  if [ $num_submods -gt 0 ]; then
    for i in "${!submod_subdirs[@]}"; do 
      submod_branch_hashes[$i]="HEAD"
    done
  else
    submod_branch_hashes=()
  fi

fi 
#
#-----------------------------------------------------------------------
#
# Create the directory in which to clone the repository.  Note that this 
# will fail if the directory already exists (intentional make the user
# aware that the exisiting directory must be renamed or removed).  Then
# change location to that directory and recursively clone the appropri-
# ate branch of the specified software's repository in that directory.
#
#-----------------------------------------------------------------------
#
mkdir_vrfy $clone_path
cd_vrfy $clone_path

print_info_msg "\
In directory \"${clone_path}\".
Cloning repository 
  \"${remote_URL}\" 
and recursively checking out branch \"${branch_name}\" ...
 
"
git clone -b ${branch_name} --recursive $remote_URL .
#
#-----------------------------------------------------------------------
#
# Check out the specified commit (which may be just the head of the 
# branch).
#
#-----------------------------------------------------------------------
#
print_info_msg "\
In directory \"${clone_path}\".  
Checking out commit \"${branch_hash}\" of branch \"${branch_name}\" in repository 
  ${remote_URL} ..."

git checkout ${branch_hash} || print_err_msg_exit "\
Checkout of commit \"${branch_hash}\" of branch \"${branch_name}\" in repository 
  ${remote_URL} 
failed.  Please verify that \"${branch_hash}\" is a valid hash/commit in this
repository."
#
#-----------------------------------------------------------------------
#
# Chage location to the subdirectory of each submodule and check out the
# specified commit of each (which may be just the head of the branch).
#
#-----------------------------------------------------------------------
#
for i in "${!submod_subdirs[@]}"; do 

  cd_vrfy $clone_path/${submod_subdirs[$i]}
  submod_remote_URL=$( git remote -v | sed -r -n -e "s/^(origin\s)(.*)\s\(fetch\)/\2/p" )

  print_info_msg "\
In directory \"$clone_path/${submod_subdirs[$i]}\".  
Checking out commit \"${submod_branch_hashes[$i]}\" of branch \"${submod_branch_names[$i]}\" in repository
  ${submod_remote_URL} ..."

  git checkout ${submod_branch_hashes[$i]} || print_err_msg_exit "\
Checkout of commit \"${submod_branch_hashes[$i]}\" of branch \"${submod_branch_names[$i]}\" in repository
  ${submod_remote_URL} 
failed.  Please verify that \"${submod_branch_hashes[$i]}\" is a valid hash/commit in this
repository."

done

print_info_msg "\
Done."




