set -eux

# This utility is to replace configuration temperate with production setting before running ecflow workflow
# Usage: 
#       cd $HOMEaqm/parm/config
#       vi aqm_nco_config.sh and modify General parameter
#       sh aqm_nco_config.sh

# File to modify
File_to_modify_source="var_defns.sh input.nml"

# General parameter example
#  ACCOUNT="AQM-DEV"
#  HOMEaqm="\/lfs\/h1\/ops\/para\/packages\/aqm\.v7\.0"
#  ENVIR_NCO="dev"
#  COMaqm="\/lfs\/h1\/ops\/para\/com\/aqm\/v7\.0"
#  WARMSTART_PDY="20231017"

for file_in in ${File_to_modify_source}; do
  cp ${file_in}.nco.static ${file_in}.nco.static-BACKUP
  sed -i -e "s/@ACCOUNT@/${ACCOUNT}/g" ${file_in}.nco.static
  sed -i -e "s/@HOMEaqm@/${HOMEaqm}/g" ${file_in}.nco.static
  sed -i -e "s/@ENVIR_NCO@/${ENVIR_NCO}/g" ${file_in}.nco.static
  sed -i -e "s/@COMaqm@/${COMaqm}/g" ${file_in}.nco.static
  sed -i -e "s/@WARMSTART_PDY@/${WARMSTART_PDY}/g" ${file_in}.nco.static
  mv ${file_in}.nco.static ${file_in}
done
