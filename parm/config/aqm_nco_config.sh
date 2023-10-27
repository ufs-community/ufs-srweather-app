set -eux

# This utility is to replace configuration temperate with production setting before running ecflow workflow
# Usage: 
#       cd $HOMEaqm/parm/config
#       vi aqm_nco_config.sh and modify General parameter
#       sh aqm_nco_config.sh

# Load module
set +x
module load prod_envir prod_util
module list
set -x

# General parameter must to be modified by NCEP/NCO/SPA
#   Remove the remark and modify with running environment
#### OPSROOT="/lfs/h1/ops/prod"
#### COMROOT="..."
#### WARMSTART_PDY="20231017"

####################################################################################
# No need to modify any line below
####################################################################################

# Target files to modify
File_to_modify_source="var_defns.sh input.nml"

# Configure HOMEaqm using relative path assignment
pwd=$(pwd -P)
cd ../..
HOMEaqm=$(pwd -P)

# Source run.ver
source $HOMEaqm/versions/run.ver

# Assign COMaqm using production utility
COMROOT=${COMROOT:-${OPSROOT}/com}
COMaqm=$(compath.py -o aqm/${aqm_ver})
COMINgefs=$(compath.py gefs/${gefs_ver})

# Replace special characters with backslash
OPSROOT=$(echo ${OPSROOT} | sed 's/[^[:alnum:]_-]/\\&/g')
HOMEaqm=$(echo ${HOMEaqm} | sed 's/[^[:alnum:]_-]/\\&/g')
COMROOT=$(echo ${COMROOT} | sed 's/[^[:alnum:]_-]/\\&/g')
COMaqm=$(echo ${COMaqm} | sed 's/[^[:alnum:]_-]/\\&/g')
COMINgefs=$(echo ${COMINgefs} | sed 's/[^[:alnum:]_-]/\\&/g')

# Dynamically generate target files
cd ${pwd}
for file_in in ${File_to_modify_source}; do
  cp ${file_in}.nco.static ${file_in}.nco.static-BACKUP
  sed -i -e "s/@HOMEaqm@/${HOMEaqm}/g" ${file_in}.nco.static
  sed -i -e "s/@COMaqm@/${COMaqm}/g" ${file_in}.nco.static
  sed -i -e "s/@WARMSTART_PDY@/${WARMSTART_PDY}/g" ${file_in}.nco.static
  sed -i -e "s/@OPSROOT@/${OPSROOT}/g" ${file_in}.nco.static
  sed -i -e "s/@COMINgefs@/${COMINgefs}/g" ${file_in}.nco.static
  mv ${file_in}.nco.static ${file_in}
done
