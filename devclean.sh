#!/bin/bash
  
# usage instructions
usage () {
cat << EOF_USAGE

Clean the UFS-SRW Application build. If no arguments are provided, will only delete standard build
artifacts; to delete submodules and/or conda, see optional arguments below.

NOTE: If user included custom directories at build time, those directories must be deleted manually

Usage: $0 [OPTIONS] ...

OPTIONS
  -h, --help
      show this help guide
  --force
      removes files and directories without confirmation. Use with caution!
  -v, --verbose
      provide more verbose output

  -a, --all
      removes all build artifacts, including conda and submodules
  --conda
      removes "conda" directory and conda_loc file in SRW
  --sub-modules
      remove sub-module directories. They will need to be checked out again by running "\${SRW_DIR}/manage_externals/checkout_externals" before attempting subsequent builds

EOF_USAGE
}

# print settings
settings () {
cat << EOF_SETTINGS
Settings:

  FORCE=${REMOVE}
  VERBOSE=${VERBOSE}
  REMOVE_SUB_MODULES=${REMOVE_SUB_MODULES}
  REMOVE_CONDA=${REMOVE_CONDA}  

EOF_SETTINGS
}

# print usage error and exit
usage_error () {
  printf "ERROR: $1\n" >&2
  usage >&2
  exit 1
}

# default settings
SRW_DIR=$(cd "$(dirname "$(readlink -f -n "${BASH_SOURCE[0]}" )" )" && pwd -P)
VERBOSE=false

# default clean options
REMOVE=false
REMOVE_CONDA=false
REMOVE_SUB_MODULES=false

# process arguments
while :; do
  case $1 in
    --help|-h) usage; exit 0 ;;
    --all|-a) REMOVE_CONDA=true; REMOVE_SUB_MODULES=true ;;
    --conda) REMOVE_CONDA=true ;;
    --force) REMOVE=true ;;
    --force=?*|--force=) usage_error "$1 argument ignored." ;;
    --sub-modules) REMOVE_SUB_MODULES=true ;;
    --sub-modules=?*|--sub-modules=) usage_error "$1 argument ignored." ;;
    --verbose|-v) VERBOSE=true ;;
    # unknown
    -?*|?*) usage_error "Unknown option $1" ;;
    *) break ;;
  esac
  shift
done


# print settings
if [ "${VERBOSE}" = true ] ; then
  settings
fi

# Populate "removal_list" as an array of files/directories to remove

# Standard build artifacts
  removal_list=( \
    "${SRW_DIR}/build" \
    "${SRW_DIR}/exec" \
    "${SRW_DIR}/share" \
    "${SRW_DIR}/include" \
    "${SRW_DIR}/lib" \
    "${SRW_DIR}/lib64" \
  )

# Clean all the submodules if requested.
if [ ${REMOVE_SUB_MODULES} == true ]; then
  declare -a submodules='()'
  submodules=(./sorc/*)
  # Only add directories to make sure we don't delete CMakeLists.txt
  for sub in ${submodules[@]}; do [[ -d "${sub}" ]] && removal_list+=( "${sub}" ); done
  if [ "${VERBOSE}" = true ] ; then
    printf '%s\n' "Note: Need to check out submodules again for any subsequent builds, " \
      " by running ${SRW_DIR}/manage_externals/checkout_externals "
#    removal_list+=( "${removal_list[@]}" "${submodules[@]}" )
  fi
fi

# Clean conda if requested
if [ "${REMOVE_CONDA}" = true ] ; then
  # Do not read "conda_loc" file to determine location of conda install; if the user has changed it to a different location
  # they likely do not want to remove it!
  removal_list+=("${SRW_DIR}/conda_loc")
  removal_list+=("${SRW_DIR}/conda")
fi

while [ ${REMOVE} == false ]; do
  # Make user confirm deletion of directories unless '--force' option was provided
  printf "The following files/directories will be deleted:\n\n"
  for i in "${removal_list[@]}"; do
     echo "$i"
  done
  echo ""
  read -p "Confirm that you want to delete these files/directories! (Yes/No):" choice
  case ${choice} in
    Yes ) REMOVE=true ;;
    [Nn]* ) echo "User chose not to delete, exiting..."; exit ;;
    * ) printf "Invalid option selected.\n" ;;
  esac
done

if [ ${REMOVE} == true ]; then
  for dir in ${removal_list[@]}; do
    echo "Removing ${dir}"
    if [ "${VERBOSE}" = true ] ; then 
      rm -rfv ${dir}
    else
      rm -rf ${dir}
    fi
  done
  echo " "
  echo "All the requested cleaning tasks have been completed"
  echo " "
fi


exit 0

