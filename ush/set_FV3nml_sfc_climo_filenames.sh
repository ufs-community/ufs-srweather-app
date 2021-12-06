#
#-----------------------------------------------------------------------
#
# This file defines a function that sets the values of the variables in
# the forecast model's namelist file that specify the paths to the surface
# climatology files on the FV3LAM native grid (which are either pregenerated
# or created by the MAKE_SFC_CLIMO_TN task).  Note that the workflow
# generation scripts create symlinks to these surface climatology files
# in the FIXLAM directory, and the values in the namelist file that get
# set by this function are relative or full paths to these links.
#
#-----------------------------------------------------------------------
#
function set_FV3nml_sfc_climo_filenames() {
#
#-----------------------------------------------------------------------
#
# Save current shell options (in a global array).  Then set new options
# for this script/function.
#
#-----------------------------------------------------------------------
#
  { save_shell_opts; set -u +x; } > /dev/null 2>&1
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
  local valid_args=()
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
  local regex_search \
        suffix \
        num_nml_vars \
        mapping \
        nml_var_name \
        sfc_climo_field_name \
        fp
#
#-----------------------------------------------------------------------
#
# In the forecast model's namelist file, set those variables representing
# the name of a fixed file that has associated with it a surface climatology
# file to the path to that surface climatology file.
#
# Note:
# The following symlinks that contain no "halo" in their names currently
# point to the halo4 surface climatology files.  But it is not clear whether
# these should be pointing to the halo0 or halo4 files.  Ask!!!
#
#-----------------------------------------------------------------------
#
# The regular expression regex_search set below will be used to extract
# from the elements of the array FV3_NML_VARNAME_TO_SFC_CLIMO_FIELD_MAPPING
# the name of the namelist variable to set and the corresponding surface
# climatology field from which to form the name of the surface climatology
# file.  This regular expression matches any string that consists of the
# following sequence:
#
# 1) Zero or more spaces at the beginning of the string, followed by
# 2) A sequence of one or more characters that does not include a space
#    or a pipe (i.e. the "|" character; this sequence is the namelist
#    variable name), followed by
# 3) Zero or more spaces, followed by
# 4) A pipe, followed by
# 5) A sequence of one or more characters that does not include a space
#    or a pipe (this sequence is the surface climatology field associated
#    with the namelist variable), followed by
# 6) Zero or more spaces at the end of the string.
#
regex_search="^[ ]*([^| ]+)[ ]*[|][ ]*([^| ]+)[ ]*$"
#
# Set the suffix of the surface climatology files.
#
# Questions:
# 1) Should we be using the halo0 or halo4 files?
# 2) For clarity, is it possible to use the actual name of the file (i.e.
#    the actual ending that is either "tile7.halo0.nc" or "tile7.halo4.nc"
#    instead of "tileX.nc"?
#
#suffix="tile${TILE_RGNL}.halo4.nc"
suffix="tileX.nc"
#
# Create a multiline variable that consists of a yaml-compliant string
# specifying the values that the namelist variables that specify the
# surface climatology file paths need to be set to (one namelist variable
# per line, plus a header and footer).  Below, this variable will be
# passed to a python script that will create the namelist file.
#
# Note that the array FV3_NML_VARNAME_TO_SFC_CLIMO_FIELD_MAPPING contains
# the mapping between the namelist variables and the surface climatology
# fields.  Here, we loop through this array and process each element to
# construct each line of "settings".
#
settings="\
'namsfc': {"

dummy_run_dir="$EXPTDIR/any_cyc"
if [ "${DO_ENSEMBLE}" = "TRUE" ]; then
  dummy_run_dir="${dummy_run_dir}/any_ensmem"
fi

num_nml_vars=${#FV3_NML_VARNAME_TO_SFC_CLIMO_FIELD_MAPPING[@]}
for (( i=0; i<${num_nml_vars}; i++ )); do

  mapping="${FV3_NML_VARNAME_TO_SFC_CLIMO_FIELD_MAPPING[$i]}"
  nml_var_name=$( printf "%s\n" "$mapping" | \
                  $SED -n -r -e "s/${regex_search}/\1/p" )
  sfc_climo_field_name=$( printf "%s\n" "$mapping" |
                          $SED -n -r -e "s/${regex_search}/\2/p" )
#
# Check that the surface climatology field associated with the current
# namelist variable is valid.
#
  check_var_valid_value "sfc_climo_field_name" "SFC_CLIMO_FIELDS"
#
# Set the full path to the surface climatology file.
#
  fp="${FIXLAM}/${CRES}.${sfc_climo_field_name}.$suffix"
#
# If not in NCO mode, for portability and brevity change fp so that it
# is a relative path (relative to any cycle directory immediately under
# the experiment directory).
#
  if [ "${RUN_ENVIR}" != "nco" ]; then
    fp=$( realpath --canonicalize-missing --relative-to="${dummy_run_dir}" "$fp" )
  fi
#
# Add a line to the variable "settings" that specifies (in a yaml-compliant
# format) the name of the current namelist variable and the value it should
# be set to.
#
  settings="$settings
    '${nml_var_name}': $fp,"

done

settings="$settings
  }"
#
# For debugging purposes, print out what "settings" has been set to.
#
print_info_msg $VERBOSE "
The variable \"settings\" specifying values of the namelist variables
has been set as follows:

settings =
$settings"
#
#-----------------------------------------------------------------------
#
# Rename the FV3 namelist file for the experiment by appending the string
# ".base" to its name.  The call to the set_namelist.py script below will
# use this file as the base (i.e. starting) namelist file, and it will
# modify it as specified by the varaible "settings" above, saving the
# result in a new FV3 namelist file for the experiment.  Once this is
# done, we remove the base namelist file since it is no longer needed.
#
#-----------------------------------------------------------------------
#
fv3_nml_base_fp="${FV3_NML_FP}.base"
mv_vrfy "${FV3_NML_FP}" "${fv3_nml_base_fp}"

$USHDIR/set_namelist.py -q \
                        -n ${fv3_nml_base_fp} \
                        -u "$settings" \
                        -o ${FV3_NML_FP} || \
  print_err_msg_exit "\
Call to python script set_namelist.py to set the variables in the FV3
namelist file that specify the paths to the surface climatology files
failed.  Parameters passed to this script are:
  Full path to base namelist file:
    fv3_nml_base_fp = \"${fv3_nml_base_fp}\"
  Full path to output namelist file:
    FV3_NML_FP = \"${FV3_NML_FP}\"
  Namelist settings specified on command line (these have highest precedence):
    settings =
$settings"

rm_vrfy "${fv3_nml_base_fp}"
#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script/function.
#
#-----------------------------------------------------------------------
#
  { restore_shell_opts; } > /dev/null 2>&1

}

