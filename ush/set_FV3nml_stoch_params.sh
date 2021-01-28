#
#-----------------------------------------------------------------------
#
# This file defines a function that, for an ensemble-enabled experiment 
# (i.e. for an experiment for which the workflow configuration variable 
# DO_ENSEMBLE has been set to "TRUE"), adds to a base FV3 namelist file
# a set of stochastic "seed" parameters that is unique to each ensemble
# member to generate a new namelist file for each member.  The namelist
# files of any two ensemble members differ only in their stochastic "seed" 
# parameter values.  Each such member-specific namelist file is placed at 
# the top level of the experiment directory.  (Then, during the RUN_FCST_TN 
# step of the workflow, links are created from the run directories to these 
# member-specific namelist files.)
#
#-----------------------------------------------------------------------
#
function set_FV3nml_stoch_params() {
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
  local cdate \
        i \
        ip1 \
        fv3_nml_ens_fp \
        iseed_shum \
        iseed_skeb \
        iseed_sppt \
        iseed_spp \
        settings
#
#-----------------------------------------------------------------------
#
# At this point, there should exist a namelist file with full path as 
# specified in the workflow variable FV3_NML_FP.  This is the namelist 
# file for a non-ensmble-enabled experiment.  This file will be used below 
# as the base namelist file to which we will add the stochastic "seed" 
# parameters to obtain the final namelist file for each ensemble member.
# To clarify that this namelist file is not the final namelist file that
# FV3 will read in, we now rename it to the name specified in FV3_NML_BASE_ENS_FP.
#
#-----------------------------------------------------------------------
#
mv_vrfy "${FV3_NML_FP}" "${FV3_NML_BASE_ENS_FP}"
#
#-----------------------------------------------------------------------
#
# Select a cdate (date and hour, in the 10-digit format YYYYMMDDHH) to
# use in the formula for generating the stochastic seed values below.  
# Here, we form cdate the starting date and time of the first forecast.
#
#-----------------------------------------------------------------------
#
cdate="${DATE_FIRST_CYCL}${CYCL_HRS[0]}"
#
#-----------------------------------------------------------------------
#
# Now loop through the ensemble members and generate a namelist file for
# each one.
#
#-----------------------------------------------------------------------
#
for (( i=0; i<${NUM_ENS_MEMBERS}; i++ )); do

  fv3_nml_ensmem_fp="${FV3_NML_ENSMEM_FPS[$i]}"

  ip1=$(( i+1 ))
  iseed_shum=$(( cdate*1000 + ip1*10 + 2 ))
  iseed_skeb=$(( cdate*1000 + ip1*10 + 3 ))
  iseed_sppt=$(( cdate*1000 + ip1*10 + 1 ))
  iseed_spp=$(( cdate*1000 + ip1*10 + 4 ))

  settings="\
'nam_stochy': {
    'iseed_shum': ${iseed_shum},
    'iseed_skeb': ${iseed_skeb},
    'iseed_sppt': ${iseed_sppt},
  }
'nam_spperts': {
    'iseed_spp': ${iseed_spp},
  }"

  $USHDIR/set_namelist.py -q \
                          -n ${FV3_NML_BASE_ENS_FP} \
                          -u "$settings" \
                          -o ${fv3_nml_ensmem_fp} || \
    print_err_msg_exit "\
Call to python script set_namelist.py to set the variables in the FV3
namelist file that specify the paths to the surface climatology files
failed.  Parameters passed to this script are:
  Full path to base namelist file:
    FV3_NML_BASE_ENS_FP = \"${FV3_NML_BASE_ENS_FP}\"
  Full path to output namelist file:
    fv3_nml_ensmem_fp = \"${fv3_nml_ensmem_fp}\"
  Namelist settings specified on command line (these have highest precedence):
    settings =
$settings"

done
#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script/function.
#
#-----------------------------------------------------------------------
#
  { restore_shell_opts; } > /dev/null 2>&1

}

