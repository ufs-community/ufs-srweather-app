#!/bin/sh -l
#-----------------------------------------------------------------------
#  Description:  Compare experiment to a baseline.  Can be run with one
#                or two command line arguments.  With one argument, it
#                assumes this is your experiment directory and creates a
#                directory for the baseline based on your experiment's
#                setup (by reading in the var_defns.sh file in your ex-
#                periment directory).  With two arguments, it takes the
#                first one to be your experiment directory and the second
#                the baseline directory.
#
#  Usage: ./cmp_expt_to_baseline.sh ${expt_dir} [${baseline_dir}]
#
#  Assumptions:  RUNDIR1 and RUNDIR2 have the same subdirectory structure.
#                nccmp is available as module load
#                Script has only been tested on theia
#-----------------------------------------------------------------------

# Do these need to be machine specific, e.g. by using modulefiles?
module load intel
module load nccmp
#
#-----------------------------------------------------------------------
#
# Get the full path to the file in which this script/function is located 
# (scrfunc_fp), the name of that file (scrfunc_fn), and the directory in
# which the file is located (scrfunc_dir).
#
#-----------------------------------------------------------------------
#
scrfunc_fp=$( $READLINK -f "${BASH_SOURCE[0]}" )
scrfunc_fn=$( basename "${scrfunc_fp}" )
scrfunc_dir=$( dirname "${scrfunc_fp}" )
#
#-----------------------------------------------------------------------
#
# Source bash utility functions.
#
#-----------------------------------------------------------------------
#
. ${scrfunc_dir}/source_util_funcs.sh
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
# Process arguments.
#
#-----------------------------------------------------------------------
#
if [ $# -eq 0 ] || [ $# -gt 2 ]; then

  printf "
ERROR from script ${scrfunc_fn}:
Only 1 or 2 arguments may be specified.  Usage:

  > ${scrfunc_fn}  expt_dir  [baseline_dir]

where expt_dir is the experiment directory and baseline_dir is an op-
tional baseline directory.
Exiting with nonzero exit code.
"
  exit 1

fi
#
#-----------------------------------------------------------------------
#
# Set the experiment directory and make sure that it exists.
#
#-----------------------------------------------------------------------
#
expt_dir="$1"
if [ ! -d "${expt_dir}" ]; then
  print_err_msg_exit "\
The specified experiment directory (expt_dir) does not exist:
  expt_dir = \"$expt_dir\"
Exiting script with nonzero return code."
fi
#
#-----------------------------------------------------------------------
#
# Read the variable definitions file in the experiment directory.
#
#-----------------------------------------------------------------------
#
. ${expt_dir}/var_defns.sh
CDATE="${DATE_FIRST_CYCL[0]}${CYCL_HRS[0]}"
#
#-----------------------------------------------------------------------
#
# If two arguments are specified, then take the second one to be the di-
# rectory for the baseline.  If only one argument is specified, form a
# baseline directory name from the parameters used in the experiment di-
# rectory.  If any other number of arguments is specified, print out an
# error message and exit.
#
#-----------------------------------------------------------------------
#
if [ $# -eq 2 ]; then

  baseline_dir="$2"

else

  baseline_dir="/scratch2/BMC/det/regional_FV3/regr_baselines"
  if [ -n ${PREDEF_GRID_NAME} ]; then
    baseline_dir="${baseline_dir}/${PREDEF_GRID_NAME}"
  else
    printf "\
The experiment must be run on one of the predefined domains.  Thus, 
PREDEF_GRID_NAME cannot be empty:
  PREDEF_GRID_NAME = \"${PREDEF_GRID_NAME}\"
Exiting script with nonzero return code.
"
    exit 1
  fi
  baseline_dir="${baseline_dir}/${CCPP_PHYS_SUITE}phys"
  baseline_dir="${baseline_dir}/ICs-${EXTRN_MDL_NAME_ICS}_LBCs-${EXTRN_MDL_NAME_LBCS}"
  baseline_dir="${baseline_dir}/$CDATE"

fi
#
# Make sure that the baseline directory exists.
#
if [ ! -d "${baseline_dir}" ]; then
  printf "\n
A baseline directory corresponding to the configuration used in the ex-
periment directory (expt_dir) does not exist:
  expt_dir = \"$expt_dir\"
  baseline_dir (missing) = \"$baseline_dir\"
Exiting script with nonzero return code."
  exit 1
fi
#
#-----------------------------------------------------------------------
#
# Print out the experiment and baseline directories.
#
#-----------------------------------------------------------------------
#
print_info_msg "
The experiment and baseline directories are:
  expt_dir = \"$expt_dir\"
  baseline_dir = \"$baseline_dir\""
#
#-----------------------------------------------------------------------
#
# Set the array containing the names of the subdirectories that will be
# compared.
#
#-----------------------------------------------------------------------
#
# This list should also include $CDATE/postprd since that contains the 
# post-processed grib files, but those files' names don't end in a 
# standard file extension, e.g. .grb, etc.  Must look into this more.
#          "grid" \
#          "orog" \
#          "sfc_climo" \
subdirs=( "." \
          "fix_lam" \
          "$CDATE/${EXTRN_MDL_NAME_ICS}/ICS" \
          "$CDATE/${EXTRN_MDL_NAME_LBCS}/LBCS" \
          "$CDATE/INPUT" \
          "$CDATE/RESTART" \
          "$CDATE" \
          )
#
#-----------------------------------------------------------------------
#
# Set the array that defines the file extensions to compare in each sub-
# directory.
#
#-----------------------------------------------------------------------
#
#declare -a file_extensions=( "nc" "nemsio" "grb" )
declare -a file_extensions=( "nc" "grb" )
#declare -a file_extensions=( "nc" )
#
#-----------------------------------------------------------------------
# 
# Initialize file counts to 0.  These are defined as follows:
# 
# nfiles_total:
# The number of files in the experiment directory that we attempted to 
# compare to the corresponding file in the baseline directory.
# 
# nfiles_missing:
# The number of files (out of nfiles_total) that are missing from the
# baseline directory.
#
# nfiles_different:
# The number of files that exist in both the experiment and baseline di-
# rectories and are different.
#
#-----------------------------------------------------------------------
#
nfiles_total=0
nfiles_missing=0
nfiles_different=0
#
#-----------------------------------------------------------------------
#
# Loop over the specified subdirectories.  For each subdirectory, com-
# pare files having the specified extensions for the experiment and the
# baseline.
#
#-----------------------------------------------------------------------
#
for subdir in "${subdirs[@]}"; do

  msg="Comparing files in subdirectory \"$subdir\" ..."
  msglen=${#msg}
  printf "\n%s\n" "$msg"
  printf "%0.s=" $(seq 1 $msglen)
  printf "\n"

  for file_ext in "${file_extensions[@]}"; do

    msg="Comparing files with extension \"${file_ext}\" ..."
    msglen=${#msg}
    printf "\n%s\n" "  $msg"
    printf "  "
    printf "%0.s~" $(seq 1 $msglen)
    printf "\n"

#    cmp_files_btwn_dirs "$expt_dir/$subdir" "${baseline_dir}/$subdir" "${ext}" || { \
#    printf "
#Call to file comparison function failed.  Exiting with nonzero exit code.
#"; 
#    exit 1; }
#
#-----------------------------------------------------------------------
#
#
#-----------------------------------------------------------------------
#
    if [ "$file_ext" = "nemsio" ] || [ "$file_ext" = "grb" ]; then
      compare_tool="cmp"
    elif [ "$file_ext" = "nc" ]; then
      compare_tool="nccmp -d"
    else
      printf "\
The file comparison tool to use for this file extension has not been 
specified:
  file_ext = \"${file_ext}\"
Please specify the compare tool and rerun.
Exiting script with nonzero exit code.
"
    fi
#
#-----------------------------------------------------------------------
#
#
#
#-----------------------------------------------------------------------
#
    cd ${expt_dir}/$subdir
    num_files=$( ls -1 *.${file_ext} 2>/dev/null | wc -l )
#   num_files=$( count_files *.${file_ext} 2>/dev/null | wc -l )
    printf "
    Number of files with extension \"${file_ext}\" in subdirectory \"$subdir\" 
    of the experiment directory is:  ${num_files}
"

    if [ "${num_files}" -eq "0" ]; then
      printf "\
    Skipping comparison of files with extension \"${file_ext}\" in this subdirectory.
"
    else

      fn_len_max=0
      for fn in *.${file_ext}; do
        fn_len=${#fn}
        if [ ${fn_len} -gt ${fn_len_max} ]; then
          fn_len_max=${fn_len}
        fi
      done
      compare_msg_pre="      Comparing file "
      msg_len_max=$(( fn_len_max + ${#compare_msg_pre} ))
  
      for fn in *.${file_ext}; do
  
        nfiles_total=$(( $nfiles_total + 1 ))
  
        fn1="$fn" 
        fn2="${baseline_dir}/$subdir/$fn"
        if [ ! -e "$fn2" ]; then  # Check if file exists in baseline directory.
  
          printf "
        File specified by fn exists in subdirectory \"$subdir\" of the
        experiment directory but not in that of the the baseline directory:
          fn = \"$fn\"
          subdir = \"$subdir\"
        Incrementing missing file count and moving to next file or sub-
        directory.\n"
          nfiles_missing=$(( nfiles_missing + 1 ))
  
        else
  
          msg="${compare_msg_pre}\"$fn\""
          msg_len="${#msg}"
          num_dots=$(( msg_len_max - msg_len + 7 ))
          dots_str=$( printf "%0.s." $(seq 1 ${num_dots} ) )
          msg="${msg} ${dots_str}"
  
          printf "$msg"
          eval_output=$( eval ${compare_tool} $fn1 $fn2 2>&1 ) 
  
          if [ $? -eq 0 ]; then
            printf " Files are identical.\n"
          else
            printf " FILES ARE DIFFERENT!!!\n"
            printf "\
        Error message from \"${compare_tool}\" command is:
${eval_output}
"
            nfiles_different=$(( $nfiles_different + 1 ))
          fi
    
        fi
  
      done # Loop over files of the same extension.

    fi # Number of files > 0

  done # Loop over file extensions.

done # Loop over subdirectories.
#
#-----------------------------------------------------------------------
#
# Print out final results.
#
#-----------------------------------------------------------------------
#
msg="Summary of regression test:"
msglen=${#msg}
msg="$msg"
printf "\n%s\n" "$msg"
printf "%0.s=" $(seq 1 $msglen)
printf "\n"

file_extensions_str=$(printf "\"%s\" " "${file_extensions[@]}");
file_extensions_str="( ${file_extensions_str})"

printf "
  expt_dir = \"$expt_dir\"
  baseline_dir = \"$baseline_dir\"

  file_extensions = ${file_extensions_str}
  nfiles_total = ${nfiles_total}
  nfiles_missing = ${nfiles_missing}
  nfiles_different = ${nfiles_different}

where

  file_extensions:
  Array containing the file extensions considered when comparing files.  
  Only files ending with one of these extensions are compared.

  nfiles_total:
  The number of files in the experiment directory that we attempted to 
  compare to the corresponding file in the baseline directory.

  nfiles_missing:
  The number of files (out of nfiles_total) that are missing from the
  baseline directory.

  nfiles_different:
  The number of files that exist in both the experiment and baseline di-
  rectories and are different.

"

if [ ${nfiles_missing} -eq 0 ] && [ ${nfiles_different} -eq 0 ]; then
  result_str="PASS :)"
  exit_code=0
else

  exit_code=1
  if [ ${nfiles_missing} -ne 0 ] && [ ${nfiles_different} -eq 0 ]; then
    result_str="FAIL (due to missing files)"
  elif [ ${nfiles_missing} -eq 0 ] && [ ${nfiles_different} -ne 0 ]; then
    result_str="FAIL (due to differing files)"
  elif [ ${nfiles_missing} -ne 0 ] && [ ${nfiles_different} -ne 0 ]; then
    result_str="FAIL (due to missing and differing files)"
  fi

fi

printf "Final result of regression test:  ${result_str}\n"
#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script/func-
# tion.
#
#-----------------------------------------------------------------------
#
{ restore_shell_opts; } > /dev/null 2>&1

exit ${exit_code}

