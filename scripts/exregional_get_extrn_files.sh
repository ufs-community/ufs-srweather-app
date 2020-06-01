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
scrfunc_fp=$( readlink -f "${BASH_SOURCE[0]}" )
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

This is the ex-script for the task that copies/fetches to a local direc-
tory (either from disk or HPSS) the external model files from which ini-
tial or boundary condition files for the FV3 will be generated.
========================================================================"
#
#-----------------------------------------------------------------------
#
# Specify the set of valid argument names for this script/function.  
# Then process the arguments provided to this script/function (which 
# should consist of a set of name-value pairs of the form arg1="value1",
# etc).
#
#-----------------------------------------------------------------------
#
valid_args=( \
"EXTRN_MDL_FNS" \
"EXTRN_MDL_SYSDIR" \
"EXTRN_MDL_FILES_DIR" \
"EXTRN_MDL_ARCV_FNS" \
"EXTRN_MDL_ARCV_FPS" \
"EXTRN_MDL_ARCV_FMT" \
"EXTRN_MDL_ARCVREL_DIR" \
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
# We first check whether the external model output files exist on the 
# system disk (and are older than a certain age).  If so, we simply copy
# them from the system disk to the location specified by EXTRN_MDL_-
# FILES_DIR.  If not, we try to fetch them from HPSS.
#
# Start by setting EXTRN_MDL_FPS to the full paths that the external mo-
# del output files would have if they existed on the system disk.  Then
# count the number of such files that actually exist on disk (i.e. have
# not yet been scrubbed) and are older than a specified age (to make 
# sure that they are not still being written to).
#
#-----------------------------------------------------------------------
#
num_files_to_copy="${#EXTRN_MDL_FNS[@]}"
prefix="${EXTRN_MDL_SYSDIR}/"
EXTRN_MDL_FPS=( "${EXTRN_MDL_FNS[@]/#/$prefix}" )

num_files_found_on_disk="0"
min_age="5"  # Minimum file age, in minutes.
for FP in "${EXTRN_MDL_FPS[@]}"; do

  if [ -f "$FP" ]; then

    if [ $( find "$FP" -mmin +${min_age} ) ]; then

      num_files_found_on_disk=$(( num_files_found_on_disk+1 ))
      print_info_msg "
File FP exists on system disk and is older than the minimum required age
of min_age minutes:
  FP = \"$FP\"
  min_age = ${min_age} minutes"

    else

      print_info_msg "
File FP exists on system disk and but is NOT older than the minumum re-
quired age of min_age minutes:
  FP = \"$FP\"
  min_age = ${min_age} minutes
Will try fetching all external model files from HPSS.  Not checking pre-
sence and age of remaining external model files on system disk."
      break

    fi

  else

    print_info_msg "
File FP does NOT exist on system disk:
  FP = \"$FP\"
Will try fetching all external model files from HPSS.  Not checking pre-
sence and age of remaining external model files on system disk."
    break

  fi

done
#
#-----------------------------------------------------------------------
#
# Set the variable (DATA_SRC) that determines the source of the external
# model files (either disk or HPSS).
#
#-----------------------------------------------------------------------
#
if [ "${num_files_found_on_disk}" -eq "${num_files_to_copy}" ]; then
  DATA_SRC="disk"
else
  DATA_SRC="HPSS"
fi
#
#-----------------------------------------------------------------------
#
# If the source of the external model files is "disk", copy the files
# from the system disk to a local directory.
#
#-----------------------------------------------------------------------
#
EXTRN_MDL_FNS_str="( "$( printf "\"%s\" " "${EXTRN_MDL_FNS[@]}" )")"

if [ "${DATA_SRC}" = "disk" ]; then

  if [ "${RUN_ENVIR}" = "nco" ]; then

    print_info_msg "
Creating links in local directory (EXTRN_MDL_FILES_DIR) to external mo-
del files (EXTRN_MDL_FNS) in the system directory on disk (EXTRN_MDL_-
SYSDIR):
  EXTRN_MDL_FILES_DIR = \"${EXTRN_MDL_FILES_DIR}\"
  EXTRN_MDL_SYSDIR = \"${EXTRN_MDL_SYSDIR}\"
  EXTRN_MDL_FNS = ${EXTRN_MDL_FNS_str}"

    ln_vrfy -sf -t ${EXTRN_MDL_FILES_DIR} ${EXTRN_MDL_FPS[@]}

  else

    print_info_msg "
Copying external model files (EXTRN_MDL_FNS) from the system directory 
on disk (EXTRN_MDL_SYSDIR) to local directory (EXTRN_MDL_FILES_DIR):
  EXTRN_MDL_SYSDIR = \"${EXTRN_MDL_SYSDIR}\"
  EXTRN_MDL_FNS = ${EXTRN_MDL_FNS_str}
  EXTRN_MDL_FILES_DIR = \"${EXTRN_MDL_FILES_DIR}\""

    cp_vrfy ${EXTRN_MDL_FPS[@]} ${EXTRN_MDL_FILES_DIR}

  fi
#
#-----------------------------------------------------------------------
#
# Print message indicating successful completion of script.
#
#-----------------------------------------------------------------------
#
  if [ "${ICS_OR_LBCS}" = "ICS" ]; then

    print_info_msg "
========================================================================
Successfully copied or linked to external model files on system disk 
needed for generating initial conditions and surface fields for the FV3
forecast!!!

Exiting script:  \"${scrfunc_fn}\"
In directory:    \"${scrfunc_dir}\"
========================================================================"

  elif [ "${ICS_OR_LBCS}" = "LBCS" ]; then

    print_info_msg "
========================================================================
Successfully copied or linked to external model files on system disk 
needed for generating lateral boundary conditions for the FV3 fore-
cast!!!

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
elif [ "${DATA_SRC}" = "HPSS" ]; then
#
#-----------------------------------------------------------------------
#
# Reset EXTRN_MDL_FPS to the full paths within the archive files of the
# external model output files.
#
#-----------------------------------------------------------------------
#
  if [ "${MACHINE}" = "JET" ]; then
    searchstring="gfs"
    icount=0
    echo ${EXTRN_MDL_FNS[@]}
    for ss in ${EXTRN_MDL_FNS[@]}; do
        trest=${ss#*$searchstring}
        EXTRN_MDL_FNS[$icount]=gfs$trest
        icount=$(( $icount + 1 ))
	echo "icount=" $icount
    done
    echo ${EXTRN_MDL_FNS[@]}
  fi
  prefix=${EXTRN_MDL_ARCVREL_DIR:+${EXTRN_MDL_ARCVREL_DIR}/}
  EXTRN_MDL_FPS=( "${EXTRN_MDL_FNS[@]/#/$prefix}" )

  EXTRN_MDL_FPS_str="( "$( printf "\"%s\" " "${EXTRN_MDL_FPS[@]}" )")"
  EXTRN_MDL_ARCV_FPS_str="( "$( printf "\"%s\" " "${EXTRN_MDL_ARCV_FPS[@]}" )")"

  print_info_msg "
Fetching model output files from HPSS.  The model output files (EXTRN_-
MDL_FPS), the archive files on HPSS in which these output files are 
stored (EXTRN_MDL_ARCV_FPS), and the local directory into which they 
will be copied (EXTRN_MDL_FILES_DIR) are:
  EXTRN_MDL_FPS = ${EXTRN_MDL_FPS_str}
  EXTRN_MDL_ARCV_FPS = ${EXTRN_MDL_ARCV_FPS_str}
  EXTRN_MDL_FILES_DIR = \"${EXTRN_MDL_FILES_DIR}\""
#
#-----------------------------------------------------------------------
#
# Get the number of archive files to consider.
#
#-----------------------------------------------------------------------
#
  num_arcv_files="${#EXTRN_MDL_ARCV_FPS[@]}"
#
#-----------------------------------------------------------------------
#
# Consider the case of the archive file to be fetched from HPSS being 
# in tar format.
#
#-----------------------------------------------------------------------
#
  if [ "${EXTRN_MDL_ARCV_FMT}" = "tar" ]; then
#
#-----------------------------------------------------------------------
#
# Loop through the set of archive files specified in EXTRN_MDL_ARCV_FPS
# and extract a subset of the specified external model files from each.
#
#-----------------------------------------------------------------------
#
    num_files_to_extract="${#EXTRN_MDL_FPS[@]}"

    for (( narcv=0; narcv<${num_arcv_files}; narcv++ )); do

      narcv_formatted=$( printf "%02d" $narcv )
      ARCV_FP="${EXTRN_MDL_ARCV_FPS[$narcv]}"
#
# Before trying to extract (a subset of) the external model output files
# from the current tar archive file (which is on HPSS), create a list of
# those external model files that are stored in the current tar archive 
# file.  For this purpose, we first use the "htar -tvf" command to list
# all the external model files that are in the current archive file and
# store the result in a log file.  (This command also indirectly checks
# whether the archive file exists on HPSS.)  We then grep this log file
# for each external model file and create a list containing only those
# external model files that exist in the current archive.
#
# Note that the "htar -tvf" command will fail if the tar archive file 
# itself doesn't exist on HPSS, but it won't fail if any of the external
# model file names passed to it don't exist in the archive file.  In the
# latter case, the missing files' names simply won't appear in the log
# file.
#
      HTAR_LOG_FN="log.htar_tvf.${narcv_formatted}"
      htar -tvf ${ARCV_FP} ${EXTRN_MDL_FPS[@]} >& ${HTAR_LOG_FN} || \
      print_err_msg_exit "\
htar file list operation (\"htar -tvf ...\") failed.  Check the log file 
HTAR_LOG_FN in the directory EXTRN_MDL_FILES_DIR for details:
  EXTRN_MDL_FILES_DIR = \"${EXTRN_MDL_FILES_DIR}\"
  HTAR_LOG_FN = \"${HTAR_LOG_FN}\""

      i=0
      files_in_crnt_arcv=()
      for (( nfile=0; nfile<${num_files_to_extract}; nfile++ )); do
        extrn_mdl_fp="${EXTRN_MDL_FPS[$nfile]}"
#        grep -n ${extrn_mdl_fp} ${HTAR_LOG_FN} 2>&1 && { \
        grep -n ${extrn_mdl_fp} ${HTAR_LOG_FN} > /dev/null 2>&1 && { \
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
        EXTRN_MDL_FPS_str="( "$( printf "\"%s\" " "${EXTRN_MDL_FPS[@]}" )")"
        print_err_msg_exit "\
The current archive file (ARCV_FP) does not contain any of the external 
model files listed in EXTRN_MDL_FPS:
  ARCV_FP = \"${ARCV_FP}\"
  EXTRN_MDL_FPS = ${EXTRN_MDL_FPS_str}
The archive file should contain at least one external model file; other-
wise, it would not be needed."
      fi
#
# Extract from the current tar archive file on HPSS all the external mo-
# del output files that exist in that archive file.  Also, save the out-
# put of the "htar -xvf" command in a log file for debugging (if neces-
# sary).
#
      HTAR_LOG_FN="log.htar_xvf.${narcv_formatted}"
      htar -xvf ${ARCV_FP} ${files_in_crnt_arcv[@]} >& ${HTAR_LOG_FN} || \
      print_err_msg_exit "\
htar file extract operation (\"htar -xvf ...\") failed.  Check the log 
file HTAR_LOG_FN in the directory EXTRN_MDL_FILES_DIR for details:
  EXTRN_MDL_FILES_DIR = \"${EXTRN_MDL_FILES_DIR}\"
  HTAR_LOG_FN = \"${HTAR_LOG_FN}\""
#
# Note that the htar file extract operation above may return with a 0 
# exit code (success) even if one or more (or all) external model output
# files that it is supposed to contain were not extracted.  The names of
# those files that were not extracted will not be listed in the log 
# file.  Thus, we now check whether the log file contains the name of 
# each external model file that should have been extracted.  If any are
# missing, we print out a message and exit the script because initial 
# condition and surface field files needed by FV3 cannot be generated
# without all the external model output files.
#
      for FP in "${files_in_crnt_arcv[@]}"; do
#
# If the file path is absolute (i.e. starts with a "/"), then drop the
# leading "/" because htar strips it before writing the file path to the
# log file.
#
        FP=${FP#/}

        grep -n "${FP}" "${HTAR_LOG_FN}" > /dev/null 2>&1 || \
        print_err_msg_exit "\
External model output file FP not extracted from tar archive file ARCV_-
FP:
  ARCV_FP = \"${ARCV_FP}\"
  FP = \"$FP\"
Check the log file HTAR_LOG_FN in the directory EXTRN_MDL_FILES_DIR for 
details:
  EXTRN_MDL_FILES_DIR = \"${EXTRN_MDL_FILES_DIR}\"
  HTAR_LOG_FN = \"${HTAR_LOG_FN}\""

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
      extrn_mdl_fp="${EXTRN_MDL_FPS[$nfile]}"
#
# If the file path is absolute (i.e. starts with a "/"), then drop the
# leading "/" because htar strips it before writing the file path to the
# log file.
#
      extrn_mdl_fp=${extrn_mdl_fp#/}

      num_occurs=0
      for (( narcv=0; narcv<${num_arcv_files}; narcv++ )); do
        narcv_formatted=$( printf "%02d" $narcv )
        HTAR_LOG_FN="log.htar_xvf.${narcv_formatted}"
        grep -n ${extrn_mdl_fp} ${HTAR_LOG_FN} > /dev/null 2>&1 && { \
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
# If EXTRN_MDL_ARCVREL_DIR is not set to the current directory (i.e. it
# is not equal to "."), then the htar command will have created the sub-
# directory "./${EXTRN_MDL_ARCVREL_DIR}" under the current directory and
# placed the extracted files there.  In that case, we move these ex-
# tracted files back to the current directory and then remove the subdi-
# rectory created by htar.
#
#-----------------------------------------------------------------------
#
    if [ "${EXTRN_MDL_ARCVREL_DIR}" != "." ]; then
#
# The code below works if EXTRN_MDL_ARCVREL_DIR starts with a "/" or a 
# "./", which are the only case encountered thus far.  The code may have
# to be modified to accomodate other cases.
#
      if [ "${EXTRN_MDL_ARCVREL_DIR:0:1}" = "/" ] || \
         [ "${EXTRN_MDL_ARCVREL_DIR:0:2}" = "./" ]; then
#
# Strip the "/" or "./" from the beginning of EXTRN_MDL_ARCVREL_DIR to
# obtain the relative directory from which to move the extracted files
# to the current directory.  Then move the files.
#
        rel_dir=$( printf "%s" "${EXTRN_MDL_ARCVREL_DIR}" | \
                   sed -r 's%^(\/|\.\/)([^/]*)(.*)%\2\3%' ) 
        mv_vrfy ${rel_dir}/* .
#
# Get the first subdirectory in rel_dir, i.e. the subdirectory before 
# the first forward slash.  This is the subdirectory that we want to re-
# move since it no longer contains any files (only subdirectories).  
# Then remove it.
#
        subdir_to_remove=$( printf "%s" "${rel_dir}" | \
                            sed -r 's%^([^/]*)(.*)%\1%' ) 
        rm_vrfy -rf ./${subdir_to_remove}
#
# If EXTRN_MDL_ARCVREL_DIR does not start with a "/" (and it is not 
# equal to "."), then print out an error message and exit.
#
      else

        print_err_msg_exit "\
The archive-relative directory specified by EXTRN_MDL_ARCVREL_DIR [i.e. 
the directory \"within\" the tar file(s) listed in EXTRN_MDL_ARCV_FPS] is
not the current directory (i.e. it is not \".\"), and it does not start 
with a \"/\" or a \"./\":
  EXTRN_MDL_ARCVREL_DIR = \"${EXTRN_MDL_ARCVREL_DIR}\"
  EXTRN_MDL_ARCV_FPS = ${EXTRN_MDL_ARCV_FPS_str}
This script must be modified to account for this case."

      fi

    fi
#
#-----------------------------------------------------------------------
#
# Consider the case of the archive file to be fetched from HPSS being 
# in zip format.
#
#-----------------------------------------------------------------------
#
  elif [ "${EXTRN_MDL_ARCV_FMT}" = "zip" ]; then
#
#-----------------------------------------------------------------------
#
# For archive files that are in "zip" format files, the array EXTRN_-
# MDL_ARCV_FPS containing the list of archive files should contain only
# one element, i.e. there should be only one archive file to consider.  
# Check for this.  If this ever changes (e.g. due to the way an external 
# model that uses the "zip" format stores its output files on HPSS), the
# code below must be modified to loop over all archive files.
#
#-----------------------------------------------------------------------
#
    if [ "${num_arcv_files}" -gt 1 ]; then
      print_err_msg_exit "\
Currently, this script is coded to handle only one archive file if the 
archive file format is specified to be \"zip\", but the number of archive 
files (num_arcv_files) passed to this script is greater than 1:
  EXTRN_MDL_ARCV_FMT = \"${EXTRN_MDL_ARCV_FMT}\"
  num_arcv_files = ${num_arcv_files}
Please modify the script to handle more than one \"zip\" archive file.
Note that code already exists in this script that can handle multiple
archive files if the archive file format is specified to be \"tar\", so 
that can be used as a guide for the \"zip\" case."
    else
      ARCV_FN="${EXTRN_MDL_ARCV_FNS[0]}"
      ARCV_FP="${EXTRN_MDL_ARCV_FPS[0]}"
    fi
#
#-----------------------------------------------------------------------
#
# Fetch the zip archive file from HPSS.  
#
#-----------------------------------------------------------------------
#
    HSI_LOG_FN="log.hsi_get"
    hsi get "${ARCV_FP}" >& ${HSI_LOG_FN} || \
    print_err_msg_exit "\
hsi file get operation (\"hsi get ...\") failed.  Check the log file 
HSI_LOG_FN in the directory EXTRN_MDL_FILES_DIR for details:
  EXTRN_MDL_FILES_DIR = \"${EXTRN_MDL_FILES_DIR}\"
  HSI_LOG_FN = \"${HSI_LOG_FN}\""
#
#-----------------------------------------------------------------------
#
# List the contents of the zip archive file and save the result in a log
# file.
#
#-----------------------------------------------------------------------
#
    UNZIP_LOG_FN="log.unzip_lv"
    unzip -l -v ${ARCV_FN} >& ${UNZIP_LOG_FN} || \
    print_err_msg_exit "\
unzip operation to list the contents of the zip archive file ARCV_FN in
the directory EXTRN_MDL_FILES_DIR failed.  Check the log file UNZIP_-
LOG_FN in that directory for details:
  ARCV_FN = \"${ARCV_FN}\"
  EXTRN_MDL_FILES_DIR = \"${EXTRN_MDL_FILES_DIR}\"
  UNZIP_LOG_FN = \"${UNZIP_LOG_FN}\""
#
#-----------------------------------------------------------------------
#
# Check that the log file from the unzip command above contains the name
# of each external model output file.  If any are missing, then the cor-
# responding files are not in the zip file and thus cannot be extracted.
# In that case, print out a message and exit the script because initial
# condition and surface field files for the FV3SAR cannot be generated
# without all the external model output files.
#
#-----------------------------------------------------------------------
#
    for FP in "${EXTRN_MDL_FPS[@]}"; do
      grep -n "${FP}" "${UNZIP_LOG_FN}" > /dev/null 2>&1 || \
      print_err_msg_exit "\
External model output file FP does not exist in the zip archive file 
ARCV_FN in the directory EXTRN_MDL_FILES_DIR.  Check the log file UN-
ZIP_LOG_FN in that directory for the contents of the zip archive:
  EXTRN_MDL_FILES_DIR = \"${EXTRN_MDL_FILES_DIR}\"
  ARCV_FN = \"${ARCV_FN}\"
  FP = \"$FP\"
  UNZIP_LOG_FN = \"${UNZIP_LOG_FN}\""
    done
#
#-----------------------------------------------------------------------
#
# Extract the external model output files from the zip file on HPSS.
# Note that the -o flag to unzip is needed to overwrite existing files.  
# Otherwise, unzip will wait for user input as to whether the existing
# files should be overwritten.
#
#-----------------------------------------------------------------------
#
    UNZIP_LOG_FN="log.unzip"
    unzip -o "${ARCV_FN}" ${EXTRN_MDL_FPS[@]} >& ${UNZIP_LOG_FN} || \
    print_err_msg_exit "\
unzip file extract operation (\"unzip -o ...\") failed.  Check the log 
file UNZIP_LOG_FN in the directory EXTRN_MDL_FILES_DIR for details:
  EXTRN_MDL_FILES_DIR = \"${EXTRN_MDL_FILES_DIR}\"
  UNZIP_LOG_FN = \"${UNZIP_LOG_FN}\""
#
# NOTE:
# If EXTRN_MDL_ARCVREL_DIR is not empty, the unzip command above will 
# create a subdirectory under EXTRN_MDL_FILES_DIR and place the external 
# model output files there.  We have not encoutntered this for the RAPX 
# and HRRRX models, but it may happen for other models in the future.  
# In that case, extra code must be included here to move the external 
# model output files from the subdirectory up to EXTRN_MDL_FILES_DIR and 
# then the subdirectory (analogous to what is done above for the case of 
# EXTRN_MDL_ARCV_FMT set to "tar".
#
 
  fi
#
#-----------------------------------------------------------------------
#
# Print message indicating successful completion of script.
#
#-----------------------------------------------------------------------
#
  if [ "${ICS_OR_LBCS}" = "ICS" ]; then

    print_info_msg "
========================================================================
External model files needed for generating initial condition and surface 
fields for the FV3SAR successfully fetched from HPSS!!!

Exiting script:  \"${scrfunc_fn}\"
In directory:    \"${scrfunc_dir}\"
========================================================================"

  elif [ "${ICS_OR_LBCS}" = "LBCS" ]; then

    print_info_msg "
========================================================================
External model files needed for generating lateral boundary conditions
on the halo of the FV3SAR's regional grid successfully fetched from 
HPSS!!!

Exiting script:  \"${scrfunc_fn}\"
In directory:    \"${scrfunc_dir}\"
========================================================================"

  fi

fi
#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script/func-
# tion.
#
#-----------------------------------------------------------------------
#
{ restore_shell_opts; } > /dev/null 2>&1

