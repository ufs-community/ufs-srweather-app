#!/bin/bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. ${GLOBAL_VAR_DEFNS_FP}
. $USHDIR/source_util_funcs.sh
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
scrfunc_fp=$( $READLINK -f "${BASH_SOURCE[0]}" )
scrfunc_fn=$( basename "${scrfunc_fp}" )
scrfunc_dir=$( dirname "${scrfunc_fp}" )
#
#-----------------------------------------------------------------------
#
# Print message indicating entry into script.
#
#-----------------------------------------------------------------------
#
print_info_msg "
========================================================================
Entering script:  \"${scrfunc_fn}\"
In directory:     \"${scrfunc_dir}\"

This is the ex-script for the task that copies/fetches to a local directory 
either from disk or HPSS) the external model files from which initial or 
boundary condition files for the FV3 will be generated.
========================================================================"
#
#-----------------------------------------------------------------------
#
# Specify the set of valid argument names for this script/function.  Then 
# process the arguments provided to this script/function (which should 
# consist of a set of name-value pairs of the form arg1="value1", etc).
#
#-----------------------------------------------------------------------
#
valid_args=( \
"ics_or_lbcs" \
"use_user_staged_extrn_files" \
"extrn_mdl_cdate" \
"extrn_mdl_lbc_spec_fhrs" \
"extrn_mdl_fns_on_disk" \
"extrn_mdl_fns_in_arcv" \
"extrn_mdl_source_dir" \
"extrn_mdl_staging_dir" \
"extrn_mdl_arcv_fmt" \
"extrn_mdl_arcv_fns" \
"extrn_mdl_arcv_fps" \
"extrn_mdl_arcvrel_dir" \
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
# Set num_files_to_copy to the number of external model files that need
# to be copied or linked to from/at a location on disk.  Then set 
# extrn_mdl_fps_on_disk to the full paths of the external model files 
# on disk.
#
#-----------------------------------------------------------------------
#
num_files_to_copy="${#extrn_mdl_fns_on_disk[@]}"
prefix="${extrn_mdl_source_dir}/"
extrn_mdl_fps_on_disk=( "${extrn_mdl_fns_on_disk[@]/#/$prefix}" )
#
#-----------------------------------------------------------------------
#
# Loop through the list of external model files and check whether they
# all exist on disk.  The counter num_files_found_on_disk keeps track of
# the number of external model files that were actually found on disk in
# the directory specified by extrn_mdl_source_dir.
#
# If the location extrn_mdl_source_dir is a user-specified directory 
# (i.e. if use_user_staged_extrn_files is set to "TRUE"), then if/when we 
# encounter the first file that does not exist, we exit the script with 
# an error message.  If extrn_mdl_source_dir is a system directory (i.e. 
# if use_user_staged_extrn_files is not set to "TRUE"), then if/when we 
# encounter the first file that does not exist or exists but is younger
# than a certain age, we break out of the loop and try to fetch all the 
# necessary external model files from HPSS.  The age cutoff is to ensure
# that files are not still being written to.
#
#-----------------------------------------------------------------------
#
num_files_found_on_disk="0"
min_age="5"  # Minimum file age, in minutes.

for fp in "${extrn_mdl_fps_on_disk[@]}"; do
  #
  # If the external model file exists, then...
  #
  if [ -f "$fp" ]; then
    #
    # Increment the counter that keeps track of the number of external
    # model files found on disk and print out an informational message.
    #
    num_files_found_on_disk=$(( num_files_found_on_disk+1 ))
    print_info_msg "
File fp exists on disk:
  fp = \"$fp\""
    #
    # If we are NOT searching for user-staged external model files, then
    # we also check that the current file is at least min_age minutes old.
    # If not, we try searching for all the external model files on HPSS. 
    #
    if [ "${use_user_staged_extrn_files}" != "TRUE" ]; then

      if [ $( find "$fp" -mmin +${min_age} ) ]; then

        print_info_msg "
File fp is older than the minimum required age of min_age minutes:
  fp = \"$fp\"
  min_age = ${min_age} minutes"

      else

        print_info_msg "
File fp is NOT older than the minumum required age of min_age minutes:
  fp = \"$fp\"
  min_age = ${min_age} minutes
Will try fetching all external model files from HPSS.  Not checking 
presence and age of remaining external model files on disk."
        break

      fi

    fi
  #
  # If the external model file does not exist, then...
  #
  else
    #
    # If an external model file is not found and we are searching for it
    # in a user-specified directory, print out an error message and exit.
    #
    if [ "${use_user_staged_extrn_files}" = "TRUE" ]; then

      print_err_msg_exit "\
File fp does NOT exist on disk:
  fp = \"$fp\"
Please ensure that the directory specified by extrn_mdl_source_dir exists 
and that all the files specified in the array extrn_mdl_fns_on_disk exist
within it:
  extrn_mdl_source_dir = \"${extrn_mdl_source_dir}\"
  extrn_mdl_fns_on_disk = ( $( printf "\"%s\" " "${extrn_mdl_fns_on_disk[@]}" ))"
    #
    # If an external model file is not found and we are searching for it
    # in a system directory, give up on the system directory and try instead 
    # to get all the external model files from HPSS.
    #
    else

      print_info_msg "
File fp does NOT exist on disk:
  fp = \"$fp\"
Will try fetching all external model files from HPSS.  Not checking 
presence and age of remaining external model files on disk."
      break

    fi

  fi

done
#
#-----------------------------------------------------------------------
#
# Set the variable (data_src) that determines the source of the external
# model files (either disk or HPSS).
#
#-----------------------------------------------------------------------
#
if [ "${num_files_found_on_disk}" -eq "${num_files_to_copy}" ]; then
  data_src="disk"
else
  data_src="HPSS"
fi

if [ ${NOMADS} == "TRUE" ]; then
  data_src="online"
fi
#
#-----------------------------------------------------------------------
#
# If the source of the external model files is "disk", copy the files
# from the source directory on disk to a staging directory.
#
#-----------------------------------------------------------------------
#
extrn_mdl_fns_on_disk_str="( "$( printf "\"%s\" " "${extrn_mdl_fns_on_disk[@]}" )")"

if [ "${data_src}" = "disk" ]; then

  if [ "${RUN_ENVIR}" = "nco" ]; then

    print_info_msg "
Creating links in staging directory (extrn_mdl_staging_dir) to external 
model files on disk (extrn_mdl_fns_on_disk) in the source directory 
(extrn_mdl_source_dir):
  extrn_mdl_staging_dir = \"${extrn_mdl_staging_dir}\"
  extrn_mdl_source_dir = \"${extrn_mdl_source_dir}\"
  extrn_mdl_fns_on_disk = ${extrn_mdl_fns_on_disk_str}"

    ln_vrfy -sf -t ${extrn_mdl_staging_dir} ${extrn_mdl_fps_on_disk[@]}

  else

    #
    # If the external model files are user-staged, then simply link to 
    # them.  Otherwise, if they are on the system disk, copy them to the
    # staging directory.
    #
    if [ "${use_user_staged_extrn_files}" = "TRUE" ]; then
      print_info_msg "
Creating symlinks in the staging directory (extrn_mdl_staging_dir) to the
external model files on disk (extrn_mdl_fns_on_disk) in the source directory 
(extrn_mdl_source_dir):
  extrn_mdl_source_dir = \"${extrn_mdl_source_dir}\"
  extrn_mdl_fns_on_disk = ${extrn_mdl_fns_on_disk_str}
  extrn_mdl_staging_dir = \"${extrn_mdl_staging_dir}\""
      ln_vrfy -sf -t ${extrn_mdl_staging_dir} ${extrn_mdl_fps_on_disk[@]}
    else
      print_info_msg "
Copying external model files on disk (extrn_mdl_fns_on_disk) from source
directory (extrn_mdl_source_dir) to staging directory (extrn_mdl_staging_dir):
  extrn_mdl_source_dir = \"${extrn_mdl_source_dir}\"
  extrn_mdl_fns_on_disk = ${extrn_mdl_fns_on_disk_str}
  extrn_mdl_staging_dir = \"${extrn_mdl_staging_dir}\""
      cp_vrfy ${extrn_mdl_fps_on_disk[@]} ${extrn_mdl_staging_dir}
    fi

  fi
#
#-----------------------------------------------------------------------
#
# Print message indicating successful completion of script.
#
#-----------------------------------------------------------------------
#
  if [ "${ics_or_lbcs}" = "ICS" ]; then

    print_info_msg "
========================================================================
Successfully copied or linked to external model files on disk needed for
generating initial conditions and surface fields for the FV3 forecast!!!

Exiting script:  \"${scrfunc_fn}\"
In directory:    \"${scrfunc_dir}\"
========================================================================"

  elif [ "${ics_or_lbcs}" = "LBCS" ]; then

    print_info_msg "
========================================================================
Successfully copied or linked to external model files on disk needed for
generating lateral boundary conditions for the FV3 forecast!!!

Exiting script:  \"${scrfunc_fn}\"
In directory:    \"${scrfunc_dir}\"
========================================================================"

  fi
#
#-----------------------------------------------------------------------
#
# If the source of the external model files is "HPSS", fetch them from
# HPSS.
#
#-----------------------------------------------------------------------
#
elif [ "${data_src}" = "HPSS" ]; then
#
#-----------------------------------------------------------------------
#
# Set extrn_mdl_fps_in_arcv to the full paths within the archive files of
# the external model files.
#
#-----------------------------------------------------------------------
#
  prefix=${extrn_mdl_arcvrel_dir:+${extrn_mdl_arcvrel_dir}/}
  extrn_mdl_fps_in_arcv=( "${extrn_mdl_fns_in_arcv[@]/#/$prefix}" )

  extrn_mdl_fps_in_arcv_str="( "$( printf "\"%s\" " "${extrn_mdl_fps_in_arcv[@]}" )")"
  extrn_mdl_arcv_fps_str="( "$( printf "\"%s\" " "${extrn_mdl_arcv_fps[@]}" )")"

  print_info_msg "
Fetching external model files from HPSS.  The full paths to these files 
in the archive file(s) (extrn_mdl_fps_in_arcv), the archive files on HPSS 
in which these files are stored (extrn_mdl_arcv_fps), and the staging
directory to which they will be copied (extrn_mdl_staging_dir) are:
  extrn_mdl_fps_in_arcv = ${extrn_mdl_fps_in_arcv_str}
  extrn_mdl_arcv_fps = ${extrn_mdl_arcv_fps_str}
  extrn_mdl_staging_dir = \"${extrn_mdl_staging_dir}\""
#
#-----------------------------------------------------------------------
#
# Get the number of archive files to consider.
#
#-----------------------------------------------------------------------
#
  num_arcv_files="${#extrn_mdl_arcv_fps[@]}"
#
#-----------------------------------------------------------------------
#
# Consider the case of the archive file to be fetched from HPSS being in
# tar format.
#
#-----------------------------------------------------------------------
#
  if [ "${extrn_mdl_arcv_fmt}" = "tar" ]; then
#
#-----------------------------------------------------------------------
#
# Loop through the set of archive files specified in extrn_mdl_arcv_fps
# and extract a subset of the specified external model files from each.
#
#-----------------------------------------------------------------------
#
    num_files_to_extract="${#extrn_mdl_fps_in_arcv[@]}"

    for (( narcv=0; narcv<${num_arcv_files}; narcv++ )); do

      narcv_formatted=$( printf "%02d" $narcv )
      arcv_fp="${extrn_mdl_arcv_fps[$narcv]}"
#
# Before trying to extract (a subset of) the external model files from 
# the current tar archive file (which is on HPSS), create a list of those 
# external model files that are stored in the current tar archive file.  
# For this purpose, we first use the "htar -tvf" command to list all the 
# external model files that are in the current archive file and store the 
# result in a log file.  (This command also indirectly checks whether the 
# archive file exists on HPSS.)  We then grep this log file for each 
# external model file and create a list containing only those external 
# model files that exist in the current archive.
#
# Note that the "htar -tvf" command will fail if the tar archive file 
# itself doesn't exist on HPSS, but it won't fail if any of the external
# model file names passed to it don't exist in the archive file.  In the
# latter case, the missing files' names simply won't appear in the log
# file.
#
      htar_log_fn="log.htar_tvf.${narcv_formatted}"
      htar -tvf ${arcv_fp} ${extrn_mdl_fps_in_arcv[@]} >& ${htar_log_fn} || \
      print_err_msg_exit "\
htar file list operation (\"htar -tvf ...\") failed.  Check the log file 
htar_log_fn in the staging directory (extrn_mdl_staging_di)r for details:
  extrn_mdl_staging_dir = \"${extrn_mdl_staging_dir}\"
  htar_log_fn = \"${htar_log_fn}\""

      i=0
      files_in_crnt_arcv=()
      for (( nfile=0; nfile<${num_files_to_extract}; nfile++ )); do
        extrn_mdl_fp="${extrn_mdl_fps_in_arcv[$nfile]}"
#        grep -n ${extrn_mdl_fp} ${htar_log_fn} 2>&1 && { \
        grep -n ${extrn_mdl_fp} ${htar_log_fn} > /dev/null 2>&1 && { \
          files_in_crnt_arcv[$i]="${extrn_mdl_fp}"; \
          i=$((i+1)); \
        }
      done
#
# If none of the external model files were found in the current archive
# file, print out an error message and exit.
#
      num_files_in_crnt_arcv=${#files_in_crnt_arcv[@]}
      if [ ${num_files_in_crnt_arcv} -eq 0 ]; then
        extrn_mdl_fps_in_arcv_str="( "$( printf "\"%s\" " "${extrn_mdl_fps_in_arcv[@]}" )")"
        print_err_msg_exit "\
The current archive file (arcv_fp) does not contain any of the external 
model files listed in extrn_mdl_fps_in_arcv:
  arcv_fp = \"${arcv_fp}\"
  extrn_mdl_fps_in_arcv = ${extrn_mdl_fps_in_arcv_str}
The archive file should contain at least one external model file; otherwise, 
it would not be needed."
      fi
#
# Extract from the current tar archive file on HPSS all the external model 
# files that exist in that archive file.  Also, save the output of the 
# "htar -xvf" command in a log file for debugging (if necessary).
#
      htar_log_fn="log.htar_xvf.${narcv_formatted}"
      htar -xvf ${arcv_fp} ${files_in_crnt_arcv[@]} >& ${htar_log_fn} || \
      print_err_msg_exit "\
htar file extract operation (\"htar -xvf ...\") failed.  Check the log 
file htar_log_fn in the staging directory (extrn_mdl_staging_dir) for 
details:
  extrn_mdl_staging_dir = \"${extrn_mdl_staging_dir}\"
  htar_log_fn = \"${htar_log_fn}\""
#
# Note that the htar file extract operation above may return with a 0 
# exit code (success) even if one or more (or all) external model files 
# that it is supposed to contain were not extracted.  The names of those 
# files that were not extracted will not be listed in the log file.  Thus, 
# we now check whether the log file contains the name of each external 
# model file that should have been extracted.  If any are missing, we 
# print out a message and exit the script because initial condition and 
# surface field files needed by FV3 cannot be generated without all the 
# external model files.
#
      for fp in "${files_in_crnt_arcv[@]}"; do
#
# If the file path is absolute (i.e. starts with a "/"), then drop the
# leading "/" because htar strips it before writing the file path to the
# log file.
#
        fp=${fp#/}

        grep -n "${fp}" "${htar_log_fn}" > /dev/null 2>&1 || \
        print_err_msg_exit "\
External model file fp not extracted from tar archive file arcv_fp:
  arcv_fp = \"${arcv_fp}\"
  fp = \"$fp\"
Check the log file htar_log_fn in the staging directory (extrn_mdl_staging_dir) 
for details:
  extrn_mdl_staging_dir = \"${extrn_mdl_staging_dir}\"
  htar_log_fn = \"${htar_log_fn}\""

      done

    done
#
#-----------------------------------------------------------------------
#
# For each external model file that was supposed to have been extracted
# from the set of specified archive files, loop through the extraction 
# log files and check that it appears exactly once in one of the log files.  
# If it doesn't appear at all, then it means that file was not extracted,
# and if it appears more than once, then something else is wrong.  In 
# either case, print out an error message and exit.
#
#-----------------------------------------------------------------------
#
    for (( nfile=0; nfile<${num_files_to_extract}; nfile++ )); do
      extrn_mdl_fp="${extrn_mdl_fps_in_arcv[$nfile]}"
#
# If the file path is absolute (i.e. starts with a "/"), then drop the
# leading "/" because htar strips it before writing the file path to the
# log file.
#
      extrn_mdl_fp=${extrn_mdl_fp#/}

      num_occurs=0
      for (( narcv=0; narcv<${num_arcv_files}; narcv++ )); do
        narcv_formatted=$( printf "%02d" $narcv )
        htar_log_fn="log.htar_xvf.${narcv_formatted}"
        grep -n ${extrn_mdl_fp} ${htar_log_fn} > /dev/null 2>&1 && { \
          num_occurs=$((num_occurs+1)); \
        }
      done

      if [ ${num_occurs} -eq 0 ]; then
        print_err_msg_exit "\
The current external model file (extrn_mdl_fp) does not appear in any of
the archive extraction log files:
  extrn_mdl_fp = \"${extrn_mdl_fp}\"
Thus, it was not extracted, likely because it doesn't exist in any of the 
archive files."
      elif [ ${num_occurs} -gt 1 ]; then
        print_err_msg_exit "\
The current external model file (extrn_mdl_fp) appears more than once in
the archive extraction log files:
  extrn_mdl_fp = \"${extrn_mdl_fp}\"
The number of times it occurs in the log files is:
  num_occurs = ${num_occurs}
Thus, it was extracted from more than one archive file, with the last one
that was extracted overwriting all previous ones.  This should normally 
not happen."
      fi

    done
#
#-----------------------------------------------------------------------
#
# If extrn_mdl_arcvrel_dir is not set to the current directory (i.e. it
# is not equal to "."), then the htar command will have created the 
# subdirectory "./${extrn_mdl_arcvrel_dir}" under the current directory 
# and placed the extracted files there.  In that case, we move these 
# extracted files back to the current directory and then remove the 
# subdirectory created by htar.
#
#-----------------------------------------------------------------------
#
    if [ "${extrn_mdl_arcvrel_dir}" != "." ]; then
#
# The code below works if extrn_mdl_arcvrel_dir starts with a "/" or a 
# "./", which are the only case encountered thus far.  The code may have
# to be modified to accomodate other cases.
#
      if [ "${extrn_mdl_arcvrel_dir:0:1}" = "/" ] || \
         [ "${extrn_mdl_arcvrel_dir:0:2}" = "./" ]; then
#
# Strip the "/" or "./" from the beginning of extrn_mdl_arcvrel_dir to
# obtain the relative directory from which to move the extracted files
# to the current directory.  Then move the files.
#
        rel_dir=$( printf "%s" "${extrn_mdl_arcvrel_dir}" | \
                   $SED -r 's%^(\/|\.\/)([^/]*)(.*)%\2\3%' ) 
        mv_vrfy ${rel_dir}/* .
#
# Get the first subdirectory in rel_dir, i.e. the subdirectory before the 
# first forward slash.  This is the subdirectory that we want to remove 
# since it no longer contains any files (only subdirectories).  Then remove
# it.
#
        subdir_to_remove=$( printf "%s" "${rel_dir}" | \
                            $SED -r 's%^([^/]*)(.*)%\1%' ) 
        rm_vrfy -rf ./${subdir_to_remove}
#
# If extrn_mdl_arcvrel_dir does not start with a "/" (and it is not 
# equal to "."), then print out an error message and exit.
#
      else

        print_err_msg_exit "\
The archive-relative directory specified by extrn_mdl_arcvrel_dir [i.e. 
the directory \"within\" the tar file(s) listed in extrn_mdl_arcv_fps] is
not the current directory (i.e. it is not \".\"), and it does not start 
with a \"/\" or a \"./\":
  extrn_mdl_arcvrel_dir = \"${extrn_mdl_arcvrel_dir}\"
  extrn_mdl_arcv_fps = ${extrn_mdl_arcv_fps_str}
This script must be modified to account for this case."

      fi

    fi
#
#-----------------------------------------------------------------------
#
# Consider the case of the archive file to be fetched from HPSS being in
# zip format.
#
#-----------------------------------------------------------------------
#
  elif [ "${extrn_mdl_arcv_fmt}" = "zip" ]; then
#
#-----------------------------------------------------------------------
#
# For archive files that are in "zip" format files, the array extrn_mdl_arcv_fps 
# containing the list of archive files should contain only one element, 
# i.e. there should be only one archive file to consider.  Check for this.  
# If this ever changes (e.g. due to the way an external model that uses 
# the "zip" format archives its output files on HPSS), the code below must 
# be modified to loop over all archive files.
#
#-----------------------------------------------------------------------
#
    if [ "${num_arcv_files}" -gt 1 ]; then
      print_err_msg_exit "\
Currently, this script is coded to handle only one archive file if the 
archive file format is specified to be \"zip\", but the number of archive 
files (num_arcv_files) passed to this script is greater than 1:
  extrn_mdl_arcv_fmt = \"${extrn_mdl_arcv_fmt}\"
  num_arcv_files = ${num_arcv_files}
Please modify the script to handle more than one \"zip\" archive file.
Note that code already exists in this script that can handle multiple
archive files if the archive file format is specified to be \"tar\", so 
that can be used as a guide for the \"zip\" case."
    else
      arcv_fn="${extrn_mdl_arcv_fns[0]}"
      arcv_fp="${extrn_mdl_arcv_fps[0]}"
    fi
#
#-----------------------------------------------------------------------
#
# Fetch the zip archive file from HPSS.  
#
#-----------------------------------------------------------------------
#
    hsi_log_fn="log.hsi_get"
    hsi get "${arcv_fp}" >& ${hsi_log_fn} || \
    print_err_msg_exit "\
hsi file get operation (\"hsi get ...\") failed.  Check the log file 
hsi_log_fn in the staging directory (extrn_mdl_staging_dir) for details:
  extrn_mdl_staging_dir = \"${extrn_mdl_staging_dir}\"
  hsi_log_fn = \"${hsi_log_fn}\""
#
#-----------------------------------------------------------------------
#
# List the contents of the zip archive file and save the result in a log
# file.
#
#-----------------------------------------------------------------------
#
    unzip_log_fn="log.unzip_lv"
    unzip -l -v ${arcv_fn} >& ${unzip_log_fn} || \
    print_err_msg_exit "\
unzip operation to list the contents of the zip archive file arcv_fn in
the staging directory (extrn_mdl_staging_dir) failed.  Check the log 
file unzip_log_fn in that directory for details:
  arcv_fn = \"${arcv_fn}\"
  extrn_mdl_staging_dir = \"${extrn_mdl_staging_dir}\"
  unzip_log_fn = \"${unzip_log_fn}\""
#
#-----------------------------------------------------------------------
#
# Check that the log file from the unzip command above contains the name
# of each external model file.  If any are missing, then the corresponding 
# files are not in the zip file and thus cannot be extracted.  In that 
# case, print out a message and exit the script because initial condition 
# and surface field files for the FV3-LAM cannot be generated without all 
# the external model files.
#
#-----------------------------------------------------------------------
#
    for fp in "${extrn_mdl_fps_in_arcv[@]}"; do
      grep -n "${fp}" "${unzip_log_fn}" > /dev/null 2>&1 || \
      print_err_msg_exit "\
External model file fp does not exist in the zip archive file arcv_fn in 
the staging directory (extrn_mdl_staging_dir).  Check the log file 
unzip_log_fn in that directory for the contents of the zip archive:
  extrn_mdl_staging_dir = \"${extrn_mdl_staging_dir}\"
  arcv_fn = \"${arcv_fn}\"
  fp = \"$fp\"
  unzip_log_fn = \"${unzip_log_fn}\""
    done
#
#-----------------------------------------------------------------------
#
# Extract the external model files from the zip file on HPSS.  Note that 
# the -o flag to unzip is needed to overwrite existing files.  Otherwise, 
# unzip will wait for user input as to whether the existing files should 
# be overwritten.
#
#-----------------------------------------------------------------------
#
    unzip_log_fn="log.unzip"
    unzip -o "${arcv_fn}" ${extrn_mdl_fps_in_arcv[@]} >& ${unzip_log_fn} || \
    print_err_msg_exit "\
unzip file extract operation (\"unzip -o ...\") failed.  Check the log 
file unzip_log_fn in the staging directory (extrn_mdl_staging_dir) for 
details:
  extrn_mdl_staging_dir = \"${extrn_mdl_staging_dir}\"
  unzip_log_fn = \"${unzip_log_fn}\""
#
# NOTE:
# If extrn_mdl_arcvrel_dir is not empty, the unzip command above will 
# create a subdirectory under extrn_mdl_staging_dir and place the external 
# model files there.  We have not encountered this for the RAP and HRRR 
# models, but it may happen for other models in the future.  In that case, 
# extra code must be included here to move the external model files from 
# the subdirectory up to extrn_mdl_staging_dir and then the subdirectory 
# (analogous to what is done above for the case of extrn_mdl_arcv_fmt set 
# to "tar".
#
 
  fi
#
#-----------------------------------------------------------------------
#
# Print message indicating successful completion of script.
#
#-----------------------------------------------------------------------
#
  if [ "${ics_or_lbcs}" = "ICS" ]; then

    print_info_msg "
========================================================================
External model files needed for generating initial condition and surface 
fields for the FV3-LAM successfully fetched from HPSS!!!

Exiting script:  \"${scrfunc_fn}\"
In directory:    \"${scrfunc_dir}\"
========================================================================"

  elif [ "${ics_or_lbcs}" = "LBCS" ]; then

    print_info_msg "
========================================================================
External model files needed for generating lateral boundary conditions
on the halo of the FV3-LAM's regional grid successfully fetched from 
HPSS!!!

Exiting script:  \"${scrfunc_fn}\"
In directory:    \"${scrfunc_dir}\"
========================================================================"

  fi

elif [ "${data_src}" = "online" ]; then
    print_info_msg "
========================================================================
getting data from online nomads data sources
========================================================================"

#
#-----------------------------------------------------------------------
#
# Set extrn_mdl_fps to the full paths within the archive files of the
# external model output files.
#
#-----------------------------------------------------------------------
#
  prefix=${extrn_mdl_arcvrel_dir:+${extrn_mdl_arcvrel_dir}/}
  extrn_mdl_fps=( "${extrn_mdl_fns_on_disk[@]/#/$prefix}" )

  extrn_mdl_fps_str="( "$( printf "\"%s\" " "${extrn_mdl_fps[@]}" )")"

  print_info_msg " 
Getting external model files from nomads:
  extrn_mdl_fps= ${extrn_mdl_fps_str}"

  num_files_to_extract="${#extrn_mdl_fps[@]}"
  wget_LOG_FN="log.wget.txt"
  for (( nfile=0; nfile<${num_files_to_extract}; nfile++ )); do
    cp ../../../${extrn_mdl_fps[$nfile]} . || \
    print_err_msg_exit "\
    onlie file ${extrn_mdl_fps[$nfile]} not found."
  done


fi
#
#-----------------------------------------------------------------------
#
# Create a variable definitions file (a shell script) and save in it the
# values of several external-model-associated variables generated in this 
# script that will be needed by downstream workflow tasks.
#
#-----------------------------------------------------------------------
#
if [ "${ics_or_lbcs}" = "ICS" ]; then
  extrn_mdl_var_defns_fn="${EXTRN_MDL_ICS_VAR_DEFNS_FN}"
elif [ "${ics_or_lbcs}" = "LBCS" ]; then
  extrn_mdl_var_defns_fn="${EXTRN_MDL_LBCS_VAR_DEFNS_FN}"
fi
extrn_mdl_var_defns_fp="${extrn_mdl_staging_dir}/${extrn_mdl_var_defns_fn}"
check_for_preexist_dir_file "${extrn_mdl_var_defns_fp}" "delete"

if [ "${data_src}" = "disk" ]; then
  extrn_mdl_fns_str="( "$( printf "\"%s\" " "${extrn_mdl_fns_on_disk[@]}" )")"
elif [ "${data_src}" = "HPSS" ]; then
  extrn_mdl_fns_str="( "$( printf "\"%s\" " "${extrn_mdl_fns_in_arcv[@]}" )")"
elif [ "${data_src}" = "online" ]; then
  extrn_mdl_fns_str="( "$( printf "\"%s\" " "${extrn_mdl_fns_on_disk[@]}" )")"
fi

settings="\
DATA_SRC=\"${data_src}\"
EXTRN_MDL_CDATE=\"${extrn_mdl_cdate}\"
EXTRN_MDL_STAGING_DIR=\"${extrn_mdl_staging_dir}\"
EXTRN_MDL_FNS=${extrn_mdl_fns_str}"
#
# If the external model files obtained above were for generating LBCS (as
# opposed to ICs), then add to the external model variable definitions 
# file the array variable EXTRN_MDL_LBC_SPEC_FHRS containing the forecast 
# hours at which the lateral boundary conditions are specified.
#
if [ "${ics_or_lbcs}" = "LBCS" ]; then
  extrn_mdl_lbc_spec_fhrs_str="( "$( printf "\"%s\" " "${extrn_mdl_lbc_spec_fhrs[@]}" )")"
  settings="$settings
EXTRN_MDL_LBC_SPEC_FHRS=${extrn_mdl_lbc_spec_fhrs_str}"
fi

{ cat << EOM >> ${extrn_mdl_var_defns_fp}
$settings
EOM
} || print_err_msg_exit "\
Heredoc (cat) command to create a variable definitions file associated
with the external model from which to generate ${ics_or_lbcs} returned with a 
nonzero status.  The full path to this variable definitions file is:
  extrn_mdl_var_defns_fp = \"${extrn_mdl_var_defns_fp}\""
#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script/function.
#
#-----------------------------------------------------------------------
#
{ restore_shell_opts; } > /dev/null 2>&1

