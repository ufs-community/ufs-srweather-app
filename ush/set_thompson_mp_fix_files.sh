#
#-----------------------------------------------------------------------
#
# This file defines a function that first checks whether the Thompson
# microphysics parameterization is being called by the selected physics
# suite.  If not, it sets the output variable specified by
# output_varname_thompson_mp_used to "FALSE" and exits.  If so, it sets
# this variable to "TRUE" and modifies the workflow arrays
# FIXgsm_FILES_TO_COPY_TO_FIXam and CYCLEDIR_LINKS_TO_FIXam_FILES_MAPPING
# to ensure that fixed files needed by the Thompson microphysics
# parameterization are copied to the FIXam directory and that appropriate
# symlinks to these files are created in the run directories.
#
#-----------------------------------------------------------------------
#
function set_thompson_mp_fix_files() {
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
  local scrfunc_fp=$( readlink -f "${BASH_SOURCE[0]}" )
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
    "thompson_mp_climo_fn" \
    "output_varname_thompson_mp_used" \
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
  local thompson_mp_name \
        regex_search \
        thompson_mp_name_or_null \
        thompson_mp_used \
        thompson_mp_fix_files \
        num_files \
        mapping \
        msg
#
#-----------------------------------------------------------------------
#
# Check the suite definition file to see whether the Thompson microphysics
# parameterization is being used.
#
#-----------------------------------------------------------------------
#
  thompson_mp_name="mp_thompson"
  regex_search="^[ ]*<scheme>(${thompson_mp_name})<\/scheme>[ ]*$"
  thompson_mp_name_or_null=$( sed -r -n -e "s/${regex_search}/\1/p" "${ccpp_phys_suite_fp}" )

  if [ "${thompson_mp_name_or_null}" = "${thompson_mp_name}" ]; then
    thompson_mp_used="TRUE"
  elif [ -z "${thompson_mp_name_or_null}" ]; then
    thompson_mp_used="FALSE"
  else
    print_err_msg_exit "\
Unexpected value returned for thompson_mp_name_or_null:
  thompson_mp_name_or_null = \"${thompson_mp_name_or_null}\"
This variable should be set to either \"${thompson_mp_name}\" or an empty 
string."
  fi
#
#-----------------------------------------------------------------------
#
# If the Thompson microphysics parameterization is being used, then...
#
#-----------------------------------------------------------------------
#
  if [ "${thompson_mp_used}" = "TRUE" ]; then
#
#-----------------------------------------------------------------------
#
# Append the names of the fixed files needed by the Thompson microphysics
# parameterization to the workflow array FIXgsm_FILES_TO_COPY_TO_FIXam, 
# and append to the workflow array CYCLEDIR_LINKS_TO_FIXam_FILES_MAPPING 
# the mappings between these files and the names of the corresponding 
# symlinks that need to be created in the run directories.
#
#-----------------------------------------------------------------------
#
    thompson_mp_fix_files=( \
      "CCN_ACTIVATE.BIN" \
      "freezeH2O.dat" \
      "qr_acr_qg.dat" \
      "qr_acr_qs.dat" \
      )

    if [ "${EXTRN_MDL_NAME_ICS}" != "HRRR" -a "${EXTRN_MDL_NAME_ICS}" != "RAP" ] || \
       [ "${EXTRN_MDL_NAME_LBCS}" != "HRRR" -a "${EXTRN_MDL_NAME_LBCS}" != "RAP" ]; then
      thompson_mp_fix_files+=( "${thompson_mp_climo_fn}" )
    fi  

    FIXgsm_FILES_TO_COPY_TO_FIXam+=( "${thompson_mp_fix_files[@]}" )

    num_files=${#thompson_mp_fix_files[@]} 
    for (( i=0; i<${num_files}; i++ )); do
      mapping="${thompson_mp_fix_files[i]} | ${thompson_mp_fix_files[i]}"
      CYCLEDIR_LINKS_TO_FIXam_FILES_MAPPING+=( "${mapping}" )
    done

    msg="
Since the Thompson microphysics parameterization is being used by this 
physics suite (CCPP_PHYS_SUITE), the names of the fixed files needed by
this scheme have been appended to the array FIXgsm_FILES_TO_COPY_TO_FIXam, 
and the mappings between these files and the symlinks that need to be 
created in the cycle directories have been appended to the array
CYCLEDIR_LINKS_TO_FIXam_FILES_MAPPING.  After these modifications, the 
values of these parameters are as follows:

  CCPP_PHYS_SUITE = \"${CCPP_PHYS_SUITE}\"

  FIXgsm_FILES_TO_COPY_TO_FIXam = ( \\
"
    msg="$msg"$( printf "\"%s\" \\\\\n" "${FIXgsm_FILES_TO_COPY_TO_FIXam[@]}" )
    msg="$msg"$( printf "\n)" )
    msg="$msg

  CYCLEDIR_LINKS_TO_FIXam_FILES_MAPPING = ( \\
"
    msg="$msg"$( printf "\"%s\" \\\\\n" "${CYCLEDIR_LINKS_TO_FIXam_FILES_MAPPING[@]}" )
    msg="$msg"$( printf "\n)" )
    print_info_msg "$msg"

  fi
#
#-----------------------------------------------------------------------
#
# Set output variables.
#
#-----------------------------------------------------------------------
#
  eval ${output_varname_thompson_mp_used}="${thompson_mp_used}"
#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script/function.
#
#-----------------------------------------------------------------------
#
  { restore_shell_opts; } > /dev/null 2>&1

}

