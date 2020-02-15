#
#-----------------------------------------------------------------------
#
# This file defines a function that:
# 
# (1) Determines the ozone parameterization being used.
#
# (2) Sets the names of the global fixed files in the FIXgsm system 
#     directory and the FIXam directory (which is under the experiment
#     directory).  Note that the files in FIXgsm are either copied to
#     FIXam, or symlinks are created in FIXam that point to the files in
#     FIXgsm.  However, if copying files, they may get renamed, and if 
#     linking to the files, the symlinks in FIXam may have different names
#     than the files in FIXgsm.  For this reason, this function sets two
#     filename arrays.  The first (fixgsm_fns) contains the names of the
#     files in the FIXgsm directory, and the second (fixam_fns) contains
#     the names of the corresponding files or symlinks in the FIXsam
#     directory.  Note also that the name of the ozone production/loss
#     file in FIXgsm depends on the ozone parameterization being used.
#
# (3) Checks that the number of file names in fixgsm_fns is the same as
#     the one in fixam_fns.
#
#-----------------------------------------------------------------------
#
function set_fix_filenames() {
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
"ozone_param_no_ccpp" \
"output_varname_ozone_param" \
"output_varname_num_fixam_files" \
"output_varname_fixgsm_fns" \
"output_varname_fixam_fns" \
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
        fixgsm_fns \
        fixam_fns \
        num_fixgsm_files \
        num_fixam_files \
        fixgsm_fns_str \
        fixam_fns_str
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
# If the forecast model executable is CCPP-enabled, then we check the 
# CCPP physics suite file to determine the parameterization being used.
# If this file contains the line
#
#   <scheme>ozphys_2015</scheme>
#
# then the 2015 parameterization is being used.  If it instead contains
# the line
#
#   <scheme>ozphys</scheme>
#
# then the after-2015 parameterization is being used.  (The suite file 
# should contain exactly one of these lines; not both or neither; check
# for this.)  If the forecast model executable is not CCPP-enabled, then
# the ozone parameterization must be specified by the user.  This user-
# specified value is passed in as an argument (ozone_param_no_ccpp), and
# ozone_param simply gets set to this value.
#
#-----------------------------------------------------------------------
#
  if [ "${USE_CCPP}" = "FALSE" ]; then
    ozone_param="${ozone_param_no_ccpp}"
  else
    regex_search="^[ ]*<scheme>(ozphys.*)<\/scheme>[ ]*$"
    ozone_param=$( sed -r -n -e "s/${regex_search}/\1/p" "${ccpp_phys_suite_fp}" )
  fi

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
# Set the arrays that specify the file names in the system's FIXgsm and
# the experiment's FIXam directories.  Note that these files are copied
# from the FIXgsm to FIXam directory, or symlinks are created in the FIXam
# directory that point to the files in the FIXgsm directory.  
#
# First, set the array fixgsm_fns.  This contains the names of the fixed
# files in the system's FIXgsm directory that the experiment generation
# script will either copy or create links to. 
#
#-----------------------------------------------------------------------
#
  fixgsm_fns=( \
"$FNGLAC" \
"$FNMXIC" \
"$FNTSFC" \
"$FNSNOC" \
"$FNALBC" \
"$FNALBC2" \
"$FNAISC" \
"$FNTG3C" \
"$FNVEGC" \
"$FNVETC" \
"$FNSOTC" \
"$FNSMCC" \
"$FNMSKH" \
"$FNVMNC" \
"$FNVMXC" \
"$FNSLPC" \
"$FNABSC" \
"global_climaeropac_global.txt" \
"global_h2o_pltc.f77" \
"global_zorclim.1x1.grb" \
"global_sfc_emissivity_idx.txt" \
"global_solarconstant_noaa_an.txt" \
"fix_co2_proj/global_co2historicaldata_2010.txt" \
"fix_co2_proj/global_co2historicaldata_2011.txt" \
"fix_co2_proj/global_co2historicaldata_2012.txt" \
"fix_co2_proj/global_co2historicaldata_2013.txt" \
"fix_co2_proj/global_co2historicaldata_2014.txt" \
"fix_co2_proj/global_co2historicaldata_2015.txt" \
"fix_co2_proj/global_co2historicaldata_2016.txt" \
"fix_co2_proj/global_co2historicaldata_2017.txt" \
"fix_co2_proj/global_co2historicaldata_2018.txt" \
"global_co2historicaldata_glob.txt" \
"co2monthlycyc.txt" \
  )

  fixgsm_fns+=( "${fixgsm_ozone_fn}" )
#
#-----------------------------------------------------------------------
#
# Next, set the array fixam_fns.  This contains the names of the files in
# the experiment's FIXam directory that are either copies of or symlinks
# to the files listed in the fixgsm_fns array in the FIXgsm directory.
# Note that the ozone production/loss file in the FIXam directory should
# always be named "global_o3prdlos.f77" (because that's the file the 
# forecast model tries to read in).
#
#-----------------------------------------------------------------------
#
  fixam_fns=( \
"$FNGLAC" \
"$FNMXIC" \
"$FNTSFC" \
"$FNSNOC" \
"$FNALBC" \
"$FNALBC2" \
"$FNAISC" \
"$FNTG3C" \
"$FNVEGC" \
"$FNVETC" \
"$FNSOTC" \
"$FNSMCC" \
"$FNMSKH" \
"$FNVMNC" \
"$FNVMXC" \
"$FNSLPC" \
"$FNABSC" \
"aerosol.dat" \
"global_h2oprdlos.f77" \
"global_zorclim.1x1.grb" \
"sfc_emissivity_idx.txt" \
"solarconstant_noaa_an.txt" \
"co2historicaldata_2010.txt" \
"co2historicaldata_2011.txt" \
"co2historicaldata_2012.txt" \
"co2historicaldata_2013.txt" \
"co2historicaldata_2014.txt" \
"co2historicaldata_2015.txt" \
"co2historicaldata_2016.txt" \
"co2historicaldata_2017.txt" \
"co2historicaldata_2018.txt" \
"co2historicaldata_glob.txt" \
"co2monthlycyc.txt" \
"global_o3prdlos.f77" \
  )
#
#-----------------------------------------------------------------------
#
# Ensure that the number of fixed file names in the array fixgsm_fns is
# equal to the number in the array fixam_fns.
#
#-----------------------------------------------------------------------
#
  num_fixgsm_files="${#fixgsm_fns[@]}"
  num_fixam_files="${#fixam_fns[@]}"
  if [ "${num_fixgsm_files}" -ne "${num_fixam_files}" ]; then
    print_err_msg_exit "\
The number of fixed files specified in the array fixgsm_fns (num_fixgsm_files)
must be equal to that specified in the array fixam_fns (num_fixam_files):
  num_fixgsm_files = ${num_fixgsm_files}
  num_fixam_files = ${num_fixam_files}"
  fi
#
#-----------------------------------------------------------------------
#
# Set output variables.
#
#-----------------------------------------------------------------------
#
  fixgsm_fns_str="("$( printf "\"%s\" " "${fixgsm_fns[@]}" )")"
  fixam_fns_str="("$( printf "\"%s\" " "${fixam_fns[@]}" )")"

  eval ${output_varname_ozone_param}="${ozone_param}"
  eval ${output_varname_num_fixam_files}=${num_fixam_files}
  eval ${output_varname_fixgsm_fns}=${fixgsm_fns_str}
  eval ${output_varname_fixam_fns}=${fixam_fns_str}
#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script/function.
#
#-----------------------------------------------------------------------
#
  { restore_shell_opts; } > /dev/null 2>&1

}

