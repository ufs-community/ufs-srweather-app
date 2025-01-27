#!/usr/bin/env bash
  
# usage instructions
usage () {
cat << EOF_USAGE

Clean the UFS-SRW Application build.

NOTE: If user included custom directories at build time, those directories must be deleted manually

Usage: $0 [OPTIONS] ...

OPTIONS
  -h, --help
      Show this help guide
  -a, --all
      Remove all build artifacts, conda and submodules (equivalent to \`-b -c -s\`)
  -b, --build
      Remove build directories and artifacts:  build/ exec/ share/ include/ lib/ lib64/
  -c, --conda
      Remove "conda" directory and conda_loc file in SRW main directory
  --container
      For cleaning builds within the SRW containers, will remove the "container-bin"
      directory rather than "exec". Has no effect if \`-b\` is not specified.
  -f, --force
      Remove directories as requested, without asking for user confirmation of their deletion.
  -s, --sub-modules
      Remove sub-module directories. They need to be checked out again by sourcing "\${SRW_DIR}/manage_externals/checkout_externals" before attempting subsequent builds
  -v, --verbose
      Provide more verbose output
      
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
REMOVE_BUILD=false
REMOVE_CONDA=false
REMOVE_SUB_MODULES=false
CONTAINER=false

# process arguments
while :; do
  case $1 in
    --help|-h) usage; exit 0 ;;
    --all|-a) REMOVE_BUILD=true; REMOVE_CONDA=true; REMOVE_SUB_MODULES=true ;;
    --build|-b) REMOVE_BUILD=true ;;
    --conda|-c) REMOVE_CONDA=true ;;
    --container) CONTAINER=true ;;
    --force) REMOVE=true ;;
    --force=?*|--force=) usage_error "$1 argument ignored." ;;
    --sub-modules|-s) REMOVE_SUB_MODULES=true ;;
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

# Populate "removal_list" as an array of files/directories to remove, based on user selections
declare -a removal_list='()'

# Clean standard build artifacts
if [ ${REMOVE_BUILD} == true ]; then
  removal_list=( \
    "${SRW_DIR}/build" \
    "${SRW_DIR}/share" \
    "${SRW_DIR}/include" \
    "${SRW_DIR}/lib" \
    "${SRW_DIR}/lib64" \
  )
  if [ ${CONTAINER} == true ]; then
    removal_list+=("${SRW_DIR}/container-bin")
  else
    removal_list+=("${SRW_DIR}/exec")
  fi
fi

# Clean all the submodules if requested.
if [ ${REMOVE_SUB_MODULES} == true ]; then
  declare -a submodules='()'
  submodules=(./sorc/*)
  # Only add directories to make sure we don't delete CMakeLists.txt
  for sub in ${submodules[@]}; do [[ -d "${sub}" ]] && removal_list+=( "${sub}" ); done
  if [ "${VERBOSE}" = true ] ; then
    printf '%s\n' "Note: Need to check out submodules again for any subsequent builds, " \
      " by running ${SRW_DIR}/manage_externals/checkout_externals "
  fi
fi

# Clean conda if requested
if [ "${REMOVE_CONDA}" = true ] ; then
  # Do not read "conda_loc" file to determine location of conda install; if the user has changed it to a different location
  # they likely do not want to remove it!
  conda_location=$(<${SRW_DIR}/conda_loc)
  if [ "${VERBOSE}" = true ] ; then
    echo "conda_location=$conda_location"
  fi
  if [ "${conda_location}" == "${SRW_DIR}/conda" ]; then
    removal_list+=("${SRW_DIR}/conda_loc")
    removal_list+=("${SRW_DIR}/conda")
  else
    echo "WARNING: location of conda build in ${SRW_DIR}/conda_loc is not the default location!"
    echo "Will not attempt to remove conda!"
  fi
fi

# If array is empty, that means user has not selected any removal options
if [ ${#removal_list[@]} -eq 0 ]; then
  usage_error "No removal options specified"
fi

while [ ${REMOVE} == false ]; do
  # Make user confirm deletion of directories unless '--force' option was provided
  printf "The following files/directories will be deleted:\n\n"
  for i in "${removal_list[@]}"; do
     echo "$i"
  done
  echo ""
  read -p "Confirm that you want to delete these files/directories! (Yes/No): " choice
  case ${choice} in
    [Yy]* ) REMOVE=true ;;
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

