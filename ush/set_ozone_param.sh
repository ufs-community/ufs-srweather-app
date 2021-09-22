#
#-----------------------------------------------------------------------
#
# This file defines a function that:
# 
# (1) Determines the ozone parameterization being used by checking in the
#     CCPP physics suite XML.
#
# (2) Sets the name of the global ozone production/loss file in the FIXgsm
#     FIXgsm system directory to copy to the experiment's FIXam directory.
#
# (3) Resets the last element of the workflow array variable
#     FIXgsm_FILES_TO_COPY_TO_FIXam that contains the files to copy from
#     FIXgsm to FIXam (this last element is initially set to a dummy 
#     value) to the name of the ozone production/loss file set in the
#     previous step.
#
# (4) Resets the element of the workflow array variable 
#     CYCLEDIR_LINKS_TO_FIXam_FILES_MAPPING (this array contains the 
#     mapping between the symlinks to create in any cycle directory and
#     the files in the FIXam directory that are their targets) that 
#     specifies the mapping for the ozone symlink/file such that the 
#     target FIXam file name is set to the name of the ozone production/
#     loss file set above.
#
#-----------------------------------------------------------------------
#
function set_ozone_param() {
#
#-----------------------------------------------------------------------
#
# Save current shell options (in a global array).  Then set new options
# for this script/function.
#
#-----------------------------------------------------------------------
#
  { save_shell_opts; set -u -x; } > /dev/null 2>&1
#
#-----------------------------------------------------------------------
#
# Get the full path to the file in which this script/function is located 
# (scrfunc_fp), the name of that file (scrfunc_fn), and the directory in
# which the file is located (scrfunc_dir).
#
#-----------------------------------------------------------------------
#
  local scrfunc_fp=$( $READLINK -f "${BASH_SOURCE[0]}" )
  local scrfunc_fn=$( basename "${scrfunc_fp}" )
  local scrfunc_dir=$( dirname "${scrfunc_fp}" )
#
#-----------------------------------------------------------------------
#
# Get the name of this function.
#
#-----------------------------------------------------------------------
#
  local func_name="${FUNCNAME[0]}"
#
#-----------------------------------------------------------------------
#
# Specify the set of valid argument names for this script/function.  Then
# process the arguments provided to this script/function (which should 
# consist of a set of name-value pairs of the form arg1="value1", etc).
#
#-----------------------------------------------------------------------
#
  local valid_args=( \
"ccpp_phys_suite_fp" \
"output_varname_ozone_param" \
  )
  process_args valid_args "$@"
#
#-----------------------------------------------------------------------
#
# For debugging purposes, print out values of arguments passed to this
# script.  Note that these will be printed out only if VERBOSE is set to
# TRUE.
#
#-----------------------------------------------------------------------
#
  print_input_args valid_args
#
#-----------------------------------------------------------------------
#
# Declare local variables.
#
#-----------------------------------------------------------------------
#
  local ozone_param \
        regex_search \
        fixgsm_ozone_fn \
        i \
        ozone_symlink \
        fixgsm_ozone_fn_is_set \
        regex_search \
        num_symlinks \
        mapping \
        symlink \
        mapping_ozone \
        msg
#
#-----------------------------------------------------------------------
#
# Get the name of the ozone parameterization being used.  There are two
# possible ozone parameterizations:  
#
# (1) A parameterization developed/published in 2015.  Here, we refer to
#     this as the 2015 parameterization.  If this is being used, then we
#     set the variable ozone_param to the string "ozphys_2015".
#
# (2) A parameterization developed/published sometime after 2015.  Here,
#     we refer to this as the after-2015 parameterization.  If this is
#     being used, then we set the variable ozone_param to the string 
#     "ozphys".
#
# We check the CCPP physics suite definition file (SDF) to determine the 
# parameterization being used.  If this file contains the line
#
#   <scheme>ozphys_2015</scheme>
#
# then the 2015 parameterization is being used.  If it instead contains
# the line
#
#   <scheme>ozphys</scheme>
#
# then the after-2015 parameterization is being used.  (The SDF should
# contain exactly one of these lines; not both nor neither; we check for 
# this.)  
#
#-----------------------------------------------------------------------
#
  regex_search="^[ ]*<scheme>(ozphys.*)<\/scheme>[ ]*$"
  ozone_param=$( $SED -r -n -e "s/${regex_search}/\1/p" "${ccpp_phys_suite_fp}" )

  if [ "${ozone_param}" = "ozphys_2015" ]; then
    fixgsm_ozone_fn="ozprdlos_2015_new_sbuvO3_tclm15_nuchem.f77"
  elif [ "${ozone_param}" = "ozphys" ]; then
    fixgsm_ozone_fn="global_o3prdlos.f77"
  else
    print_err_msg_exit "\
Unknown ozone parameterization (ozone_param) or no ozone parameterization 
specified in the CCPP physics suite file (ccpp_phys_suite_fp):
  ccpp_phys_suite_fp = \"${ccpp_phys_suite_fp}\"
  ozone_param = \"${ozone_param}\""
  fi
#
#-----------------------------------------------------------------------
#
# Set the last element of the array FIXgsm_FILES_TO_COPY_TO_FIXam to the
# name of the ozone production/loss file to copy from the FIXgsm to the
# FIXam directory.
#
#-----------------------------------------------------------------------
#
i=$(( ${#FIXgsm_FILES_TO_COPY_TO_FIXam[@]} - 1 ))
FIXgsm_FILES_TO_COPY_TO_FIXam[$i]="${fixgsm_ozone_fn}"
#
#-----------------------------------------------------------------------
#
# Set the element in the array CYCLEDIR_LINKS_TO_FIXam_FILES_MAPPING that
# specifies the mapping between the symlink for the ozone production/loss
# file that must be created in each cycle directory and its target in the 
# FIXam directory.  The name of the symlink is alrady in the array, but
# the target is not because it depends on the ozone parameterization that 
# the physics suite uses.  Since we determined the ozone parameterization
# above, we now set the target of the symlink accordingly.
#
#-----------------------------------------------------------------------
#
ozone_symlink="global_o3prdlos.f77"
fixgsm_ozone_fn_is_set="FALSE"
regex_search="^[ ]*([^| ]*)[ ]*[|][ ]*([^| ]*)[ ]*$"
num_symlinks=${#CYCLEDIR_LINKS_TO_FIXam_FILES_MAPPING[@]}

for (( i=0; i<${num_symlinks}; i++ )); do
  mapping="${CYCLEDIR_LINKS_TO_FIXam_FILES_MAPPING[$i]}"
  symlink=$( printf "%s\n" "$mapping" | \
             $SED -n -r -e "s/${regex_search}/\1/p" )
  if [ "$symlink" = "${ozone_symlink}" ]; then
    regex_search="^[ ]*([^| ]+[ ]*)[|][ ]*([^| ]*)[ ]*$"
    mapping_ozone=$( printf "%s\n" "$mapping" | \
                     $SED -n -r -e "s/${regex_search}/\1/p" )
    mapping_ozone="${mapping_ozone}| ${fixgsm_ozone_fn}"
    CYCLEDIR_LINKS_TO_FIXam_FILES_MAPPING[$i]="${mapping_ozone}"
    fixgsm_ozone_fn_is_set="TRUE"
    break
  fi
done
#
#-----------------------------------------------------------------------
#
# If fixgsm_ozone_fn_is_set is set to "TRUE", then the appropriate element
# of the array CYCLEDIR_LINKS_TO_FIXam_FILES_MAPPING was set successfully.
# In this case, print out the new version of this array.  Otherwise, print
# out an error message and exit.
#
#-----------------------------------------------------------------------
#
if [ "${fixgsm_ozone_fn_is_set}" = "TRUE" ]; then

  msg="
After setting the file name of the ozone production/loss file in the
FIXgsm directory (based on the ozone parameterization specified in the
CCPP suite definition file), the array specifying the mapping between
the symlinks that need to be created in the cycle directories and the
files in the FIXam directory is:

  CYCLEDIR_LINKS_TO_FIXam_FILES_MAPPING = ( \\
"
  msg="$msg"$( printf "\"%s\" \\\\\n" "${CYCLEDIR_LINKS_TO_FIXam_FILES_MAPPING[@]}" )
  msg="$msg"$( printf "\n)" )
  print_info_msg "$msg"

else

  print_err_msg_exit "\
Unable to set name of the ozone production/loss file in the FIXgsm directory
in the array that specifies the mapping between the symlinks that need to
be created in the cycle directories and the files in the FIXgsm directory:
  fixgsm_ozone_fn_is_set = \"${fixgsm_ozone_fn_is_set}\""

fi
#
#-----------------------------------------------------------------------
#
# Set output variables.
#
#-----------------------------------------------------------------------
#
  eval ${output_varname_ozone_param}="${ozone_param}"
#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script/function.
#
#-----------------------------------------------------------------------
#
  { restore_shell_opts; } > /dev/null 2>&1

}

