#!/bin/bash -l

#
#-----------------------------------------------------------------------
#
# This file defines and then calls a function that sets up a forecast
# experiment and creates a workflow (according to the parameters speci-
# fied in the configuration file; see instructions).
#
#-----------------------------------------------------------------------
#
function generate_FV3SAR_wflow() {
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
# Set directories.
#
#-----------------------------------------------------------------------
#
ushdir="${scrfunc_dir}"
#
#-----------------------------------------------------------------------
#
# Source bash utility functions.
#
#-----------------------------------------------------------------------
#
. $ushdir/source_util_funcs.sh
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
# Source the file that defines and then calls the setup function.  The
# setup function in turn first sources the default configuration file 
# (which contains default values for the experiment/workflow parameters)
# and then sources the user-specified configuration file (which contains
# user-specified values for a subset of the experiment/workflow parame-
# ters that override their default values).
#
#-----------------------------------------------------------------------
#
. $ushdir/setup.sh
#
#-----------------------------------------------------------------------
#
# Set the full paths to the template and actual workflow xml files.  The
# actual workflow xml will be placed in the run directory and then used
# by rocoto to run the workflow.
#
#-----------------------------------------------------------------------
#
TEMPLATE_XML_FP="${TEMPLATE_DIR}/${WFLOW_XML_FN}"
WFLOW_XML_FP="$EXPTDIR/${WFLOW_XML_FN}"
#
#-----------------------------------------------------------------------
#
# Copy the xml template file to the run directory.
#
#-----------------------------------------------------------------------
#
cp_vrfy ${TEMPLATE_XML_FP} ${WFLOW_XML_FP}
#
#-----------------------------------------------------------------------
#
# Set local variables that will be used later below to replace place-
# holder values in the workflow xml file.
#
#-----------------------------------------------------------------------
#
PROC_RUN_FCST="${NUM_NODES}:ppn=${NCORES_PER_NODE}"

FHR=( $( seq 0 1 ${FCST_LEN_HRS} ) )
i=0
FHR_STR=$( printf "%02d" "${FHR[i]}" )
numel=${#FHR[@]}
for i in $(seq 1 $(($numel-1)) ); do
  hour=$( printf "%02d" "${FHR[i]}" )
  FHR_STR="${FHR_STR} $hour"
done
FHR="${FHR_STR}"
#
#-----------------------------------------------------------------------
#
# Fill in the xml file with parameter values that are either specified
# in the configuration file/script (config.sh) or set in the setup
# script sourced above.
#
#-----------------------------------------------------------------------
#
CDATE_generic="@Y@m@d@H"
if [ "${RUN_ENVIR}" = "nco" ]; then
  CYCLE_DIR="$STMP/tmpnwprd/${EMC_GRID_NAME}_${CDATE_generic}"
else
  CYCLE_DIR="$EXPTDIR/${CDATE_generic}"
fi
#
# Computational resource parameters.
#
set_file_param "${WFLOW_XML_FP}" "ACCOUNT" "$ACCOUNT"
set_file_param "${WFLOW_XML_FP}" "SCHED" "$SCHED"
set_file_param "${WFLOW_XML_FP}" "QUEUE_DEFAULT" "${QUEUE_DEFAULT}"
set_file_param "${WFLOW_XML_FP}" "QUEUE_HPSS" "${QUEUE_HPSS}"
set_file_param "${WFLOW_XML_FP}" "QUEUE_FCST" "${QUEUE_FCST}"
set_file_param "${WFLOW_XML_FP}" "PROC_RUN_FCST" "${PROC_RUN_FCST}"
#
# Directories.
#
set_file_param "${WFLOW_XML_FP}" "USHDIR" "$USHDIR"
set_file_param "${WFLOW_XML_FP}" "JOBSDIR" "$JOBSDIR"
set_file_param "${WFLOW_XML_FP}" "EXPTDIR" "$EXPTDIR"
set_file_param "${WFLOW_XML_FP}" "LOGDIR" "$LOGDIR"
set_file_param "${WFLOW_XML_FP}" "CYCLE_DIR" "${CYCLE_DIR}"
#
# Files.
#
set_file_param "${WFLOW_XML_FP}" "GLOBAL_VAR_DEFNS_FP" "${GLOBAL_VAR_DEFNS_FP}"
#
# External model information.
#
set_file_param "${WFLOW_XML_FP}" "EXTRN_MDL_NAME_ICS" "${EXTRN_MDL_NAME_ICS}"
set_file_param "${WFLOW_XML_FP}" "EXTRN_MDL_NAME_LBCS" "${EXTRN_MDL_NAME_LBCS}"
set_file_param "${WFLOW_XML_FP}" "EXTRN_MDL_FILES_SYSBASEDIR_ICS" "${EXTRN_MDL_FILES_SYSBASEDIR_ICS}"
set_file_param "${WFLOW_XML_FP}" "EXTRN_MDL_FILES_SYSBASEDIR_LBCS" "${EXTRN_MDL_FILES_SYSBASEDIR_LBCS}"
#
# Cycle-specific information.
#
set_file_param "${WFLOW_XML_FP}" "DATE_FIRST_CYCL" "${DATE_FIRST_CYCL}"
set_file_param "${WFLOW_XML_FP}" "DATE_LAST_CYCL" "${DATE_LAST_CYCL}"
set_file_param "${WFLOW_XML_FP}" "YYYY_FIRST_CYCL" "${YYYY_FIRST_CYCL}"
set_file_param "${WFLOW_XML_FP}" "MM_FIRST_CYCL" "${MM_FIRST_CYCL}"
set_file_param "${WFLOW_XML_FP}" "DD_FIRST_CYCL" "${DD_FIRST_CYCL}"
set_file_param "${WFLOW_XML_FP}" "HH_FIRST_CYCL" "${HH_FIRST_CYCL}"
set_file_param "${WFLOW_XML_FP}" "FHR" "$FHR"
#
# Rocoto workflow task names.
#
set_file_param "${WFLOW_XML_FP}" "MAKE_GRID_TN" "${MAKE_GRID_TN}"
set_file_param "${WFLOW_XML_FP}" "MAKE_OROG_TN" "${MAKE_OROG_TN}"
set_file_param "${WFLOW_XML_FP}" "MAKE_SFC_CLIMO_TN" "${MAKE_SFC_CLIMO_TN}"
set_file_param "${WFLOW_XML_FP}" "GET_EXTRN_ICS_TN" "${GET_EXTRN_ICS_TN}"
set_file_param "${WFLOW_XML_FP}" "GET_EXTRN_LBCS_TN" "${GET_EXTRN_LBCS_TN}"
set_file_param "${WFLOW_XML_FP}" "MAKE_ICS_TN" "${MAKE_ICS_TN}"
set_file_param "${WFLOW_XML_FP}" "MAKE_LBCS_TN" "${MAKE_LBCS_TN}"
set_file_param "${WFLOW_XML_FP}" "RUN_FCST_TN" "${RUN_FCST_TN}"
set_file_param "${WFLOW_XML_FP}" "RUN_POST_TN" "${RUN_POST_TN}"
#
# Flags that determine whether or not certain tasks are launched.
#
set_file_param "${WFLOW_XML_FP}" "RUN_TASK_MAKE_GRID" "${RUN_TASK_MAKE_GRID}"
set_file_param "${WFLOW_XML_FP}" "RUN_TASK_MAKE_OROG" "${RUN_TASK_MAKE_OROG}"
set_file_param "${WFLOW_XML_FP}" "RUN_TASK_MAKE_SFC_CLIMO" "${RUN_TASK_MAKE_SFC_CLIMO}"
#
#-----------------------------------------------------------------------
#
# Extract from CDATE the starting year, month, day, and hour of the
# forecast.  These are needed below for various operations.
#
#-----------------------------------------------------------------------
#
YYYY_FIRST_CYCL=${DATE_FIRST_CYCL:0:4}
MM_FIRST_CYCL=${DATE_FIRST_CYCL:4:2}
DD_FIRST_CYCL=${DATE_FIRST_CYCL:6:2}
HH_FIRST_CYCL=${CYCL_HRS[0]}
#
#-----------------------------------------------------------------------
#
# Replace the dummy line in the XML defining a generic cycle hour with
# one line per cycle hour containing actual values.
#
#-----------------------------------------------------------------------
#
regex_search="(^\s*<cycledef\s+group=\"at_)(CC)(Z\">)(\&DATE_FIRST_CYCL;)(CC00)(\s+)(\&DATE_LAST_CYCL;)(CC00)(.*</cycledef>)(.*)"
i=0
for cycl in "${CYCL_HRS[@]}"; do
  regex_replace="\1${cycl}\3\4${cycl}00 \7${cycl}00\9"
  crnt_line=$( sed -n -r -e "s%${regex_search}%${regex_replace}%p" "${WFLOW_XML_FP}" )
  if [ "$i" -eq "0" ]; then
    all_cycledefs="${crnt_line}"
  else
    all_cycledefs=$( printf "%s\n%s" "${all_cycledefs}" "${crnt_line}" )
  fi
  i=$((i+1))
done
#
# Replace all actual newlines in the variable all_cycledefs with back-
# slash-n's.  This is needed in order for the sed command below to work
# properly (i.e. to avoid it failing with an "unterminated `s' command"
# message).
#
all_cycledefs=${all_cycledefs//$'\n'/\\n}
#
# Replace all ampersands in the variable all_cycledefs with backslash-
# ampersands.  This is needed because the ampersand has a special mean-
# ing when it appears in the replacement string (here named regex_re-
# place) and thus must be escaped.
#
all_cycledefs=${all_cycledefs//&/\\\&}
#
# Perform the subsutitution.
#
sed -i -r -e "s|${regex_search}|${all_cycledefs}|g" "${WFLOW_XML_FP}"


#
#-----------------------------------------------------------------------
#
# For select workflow tasks, create symlinks (in an appropriate subdi-
# rectory under the workflow directory tree) that point to module files
# in the various cloned external repositories.  In principle, this is 
# better than having hard-coded module files for tasks because the sym-
# links will always point to updated module files.  However, it does re-
# quire that these module files in the external repositories be coded
# correctly, e.g. that they really be lua module files and not contain
# any shell commands (like "export SOME_VARIABLE").
#
#-----------------------------------------------------------------------
#
machine=${MACHINE,,}

cd_vrfy "${MODULES_DIR}/tasks/$machine"

#
# The "module" file (really a shell script) for orog in the UFS_UTILS 
# repo uses a shell variable named MOD_PATH, but it is not clear where
# that is defined.  That needs to be fixed.  Until then, we have to use
# a hard-coded module file, which may or may not be compatible with the
# modules used in the UFS_UTILS repo to build the orog code.
#ln_vrfy -fs "${UFS_UTILS_DIR}/modulefiles/fv3gfs/orog.$machine" \
#            "${MAKE_OROG_TN}"
ln_vrfy -fs "${MAKE_OROG_TN}.hardcoded" "${MAKE_OROG_TN}"

ln_vrfy -fs "${UFS_UTILS_DIR}/modulefiles/modulefile.sfc_climo_gen.$machine" \
            "${MAKE_SFC_CLIMO_TN}"

#ln_vrfy -fs "${CHGRES_DIR}/modulefiles/chgres_cube.$machine" \
#            "${MAKE_ICS_TN}"
#ln_vrfy -fs "${MAKE_ICS_TN}.hardcoded" "${MAKE_ICS_TN}"
cp_vrfy "${CHGRES_DIR}/modulefiles/chgres_cube.$machine" \
        "${MAKE_ICS_TN}"
cat "${MAKE_ICS_TN}.local" >> "${MAKE_ICS_TN}"

#ln_vrfy -fs "${CHGRES_DIR}/modulefiles/chgres_cube.$machine" \
#            "${MAKE_LBCS_TN}"
#ln_vrfy -fs "${MAKE_LBCS_TN}.hardcoded" "${MAKE_LBCS_TN}"
cp_vrfy "${CHGRES_DIR}/modulefiles/chgres_cube.$machine" \
        "${MAKE_LBCS_TN}"
cat "${MAKE_LBCS_TN}.local" >> "${MAKE_LBCS_TN}"

ln_vrfy -fs "${UFS_WTHR_MDL_DIR}/NEMS/src/conf/modules.nems" \
            "${RUN_FCST_TN}"

cd_vrfy -
#
#-----------------------------------------------------------------------
#
# Make sure that the correct ozone production/loss fixed file is speci-
# fied in the array FIXgsm_FILENAMES.  There should be two such files
# on disk in the system directory specified in FIXgsm.  They are named
#
#   ozprdlos_2015_new_sbuvO3_tclm15_nuchem.f77
#
# and
#
#   global_o3prdlos.f77
#
# The first should be used with the 2015 ozone parameterization, while
# the second should be used with the more recent ozone parameterization
# (referred to here as the after-2015 parameterization).
#
# Which of these should be used depends on the specified physics suite
# (CCPP_PHYS_SUITE).  The GFS physics suite uses the after-2015 parame-
# terization, while the GSD physics suite uses the 2015 parameteriza-
# tion.  Thus, we must ensure that the ozone production/loss fixed file
# listed in the array FIXgsm_FILENAMES is the correct one for the gi-
# ven physics suite.  We do this below as follows.
#
# First, note that FIXgsm_FILENAMES should contain the name of exactly
# one of the ozone production/loss fixed files listed above.  We verify
# this by trying to obtain the indices of the elements of FIXam_FILES_-
# SYSDIR that contain the two files.  One of these indices should not
# exist while the other one should.  If the 2015 file is the one that is
# found in FIXgsm_FILENAMES, then if we're using GFS physics, we 
# change that element in FIXgsm_FILENAMES to the name of the after-
# 2015 file.  Similarly, if the after-2015 file is the one that is found
# in FIXgsm_FILENAMES, then if we're using GSD physics, we change that
# element in FIXgsm_FILENAMES to the name of the 2015 file.  If 
# neither file or more than one ozone production/loss file is found in
# FIXgsm_FILENAMES, we print out an error message and exit.
#
#-----------------------------------------------------------------------
#
ozphys_2015_fn="ozprdlos_2015_new_sbuvO3_tclm15_nuchem.f77"
indx_ozphys_2015=$( get_elem_inds "FIXgsm_FILENAMES" "${ozphys_2015_fn}" )
read -a indx_ozphys_2015 <<< ${indx_ozphys_2015}
num_files_ozphys_2015=${#indx_ozphys_2015[@]}

ozphys_after2015_fn="global_o3prdlos.f77"
indx_ozphys_after2015=$( get_elem_inds "FIXgsm_FILENAMES" "${ozphys_after2015_fn}" )
read -a indx_ozphys_after2015 <<< ${indx_ozphys_after2015}
num_files_ozphys_after2015=${#indx_ozphys_after2015[@]}

if [ ${num_files_ozphys_2015} -eq 1 ] && \
   [ ${num_files_ozphys_after2015} -eq 0 ]; then

  if [ "${CCPP_PHYS_SUITE}" = "FV3_GFS_2017_gfdlmp" ]; then
    FIXgsm_FILENAMES[${indx_ozphys_2015}]="${ozphys_after2015_fn}"
  fi

elif [ ${num_files_ozphys_2015} -eq 0 ] && \
     [ ${num_files_ozphys_after2015} -eq 1 ]; then

  if [ "${CCPP_PHYS_SUITE}" = "FV3_GSD_v0" ] || \
     [ "${CCPP_PHYS_SUITE}" = "FV3_GSD_SAR" ]; then
    FIXgsm_FILENAMES[${indx_ozphys_after2015}]="${ozphys_2015_fn}"
  fi

else

  FIXgsm_FILENAMES_str=$( printf "\"%s\"\n" "${FIXgsm_FILENAMES[@]}" )
  print_err_msg_exit "\
The array FIXgsm_FILENAMES containing the names of the fixed files in
the system directory (FIXgsm) to copy or link to has been specified in-
correctly because it contains no or more than one occurrence of the 
ozone production/loss file(s) (whose names are specified in the varia-
bles ozphys_2015_fn and ozphys_after2015_fn):
  FIXgsm = \"${FIXgsm}\"
  ozphys_2015_fn = \"${ozphys_2015_fn}\"
  num_files_ozphys_2015_fn = \"${num_files_ozphys_2015_fn}\"
  ozphys_after2015_fn = \"${ozphys_after2015_fn}\"
  num_files_ozphys_after2015_fn = \"${num_files_ozphys_after2015_fn}\"
  FIXgsm_FILENAMES = 
(
${FIXgsm_FILENAMES_str}
)
Please check the contents of the FIXgsm_FILENAMES array and rerun."

fi
#
#-----------------------------------------------------------------------
#
# Copy the workflow (re)launch script to the experiment directory.
#
#-----------------------------------------------------------------------
#
print_info_msg "
Creating symlink in the experiment directory (EXPTDIR) to the workflow
launch script (WFLOW_LAUNCH_SCRIPT_FP):
  EXPTDIR = \"${EXPTDIR}\"
  WFLOW_LAUNCH_SCRIPT_FP = \"${WFLOW_LAUNCH_SCRIPT_FP}\""
ln_vrfy -fs "${WFLOW_LAUNCH_SCRIPT_FP}" "$EXPTDIR"
#
#-----------------------------------------------------------------------
#
# If USE_CRON_TO_RELAUNCH is set to TRUE, add a line to the user's cron
# table to call the (re)launch script every CRON_RELAUNCH_INTVL_MNTS mi-
# nutes.
#
#-----------------------------------------------------------------------
#
if [ "${USE_CRON_TO_RELAUNCH}" = "TRUE" ]; then
#
# Make a backup copy of the user's crontab file and save it in a file.
#
  time_stamp=$( date "+%F_%T" )
  crontab_backup_fp="$EXPTDIR/crontab.bak.${time_stamp}"
  print_info_msg "
Copying contents of user cron table to backup file:
  crontab_backup_fp = \"${crontab_backup_fp}\""
  crontab -l > ${crontab_backup_fp}
#
# Below, we use "grep" to determine whether the crontab line that the 
# variable CRONTAB_LINE contains is already present in the cron table.  
# For that purpose, we need to escape the asterisks in the string in 
# CRONTAB_LINE with backslashes.  Do this next.
#
  crontab_line_esc_astr=$( printf "%s" "${CRONTAB_LINE}" | \
                           sed -r -e "s%[*]%\\\\*%g" )
#
# In the grep command below, the "^" at the beginning of the string be-
# ing passed to grep is a start-of-line anchor while the "$" at the end
# of the string is an end-of-line anchor.  Thus, in order for grep to 
# find a match on any given line of the output of "crontab -l", that 
# line must contain exactly the string in the variable crontab_line_-
# esc_astr without any leading or trailing characters.  This is to eli-
# minate situations in which a line in the output of "crontab -l" con-
# tains the string in crontab_line_esc_astr but is precedeeded, for ex-
# ample, by the comment character "#" (in which case cron ignores that
# line) and/or is followed by further commands that are not part of the 
# string in crontab_line_esc_astr (in which case it does something more
# than the command portion of the string in crontab_line_esc_astr does).
#
  grep_output=$( crontab -l | grep "^${crontab_line_esc_astr}$" )
  exit_status=$?

  if [ "${exit_status}" -eq 0 ]; then

    print_info_msg "
The following line already exists in the cron table and thus will not be
added:
  CRONTAB_LINE = \"${CRONTAB_LINE}\""
  
  else

    print_info_msg "
Adding the following line to the cron table in order to automatically
resubmit FV3SAR workflow:
  CRONTAB_LINE = \"${CRONTAB_LINE}\""

    ( crontab -l; echo "${CRONTAB_LINE}" ) | crontab -

  fi

fi
#
#-----------------------------------------------------------------------
#
#
#
#-----------------------------------------------------------------------
#
## Is this if-statement still necessary?
#if [ "${RUN_ENVIR}" = "nco" ]; then
#
#  glob_pattern="C*_mosaic.nc"
#  cd_vrfy $FIXsar
#  num_files=$( ls -1 ${glob_pattern} 2>/dev/null | wc -l )
#
#  if [ "${num_files}" -ne "1" ]; then
#    print_err_msg_exit "\
#Exactly one file must exist in directory FIXsar matching the globbing
#pattern glob_pattern:
#  FIXsar = \"${FIXsar}\"
#  glob_pattern = \"${glob_pattern}\"
#  num_files = ${num_files}"
#  fi
#
#  fn=$( ls -1 ${glob_pattern} )
#  RES=$( printf "%s" $fn | sed -n -r -e "s/^C([0-9]*)_mosaic.nc/\1/p" )
#  CRES="C$RES"
#echo "RES = $RES"
#
##  RES_equiv=$( ncdump -h "${grid_fn}" | grep -o ":RES_equiv = [0-9]\+" | grep -o "[0-9]")
##  RES_equiv=${RES_equiv//$'\n'/}
##printf "%s\n" "RES_equiv = $RES_equiv"
##  CRES_equiv="C${RES_equiv}"
##printf "%s\n" "CRES_equiv = $CRES_equiv"
##
##  RES="$RES_equiv"
##  CRES="$CRES_equiv"
#
#  set_file_param "${GLOBAL_VAR_DEFNS_FP}" "RES" "${RES}"
#  set_file_param "${GLOBAL_VAR_DEFNS_FP}" "CRES" "${CRES}"
#
#fi
#
#-----------------------------------------------------------------------
#
# Copy fixed files from system directory to the FIXam directory (which 
# is under the experiment directory).  Note that some of these files get
# renamed.
#
#-----------------------------------------------------------------------
#

# In NCO mode, we assume the following copy operation is done beforehand,
# but that can be changed.
if [ "${RUN_ENVIR}" != "nco" ]; then

  print_info_msg "$VERBOSE" "
Copying fixed files from system directory to the experiment directory..."

  check_for_preexist_dir $FIXam "delete"
  mkdir -p $FIXam

  cp_vrfy $FIXgsm/global_hyblev.l65.txt $FIXam
  for (( i=0; i<${NUM_FIXam_FILES}; i++ )); do
    cp_vrfy $FIXgsm/${FIXgsm_FILENAMES[$i]} \
            $FIXam/${FIXam_FILENAMES[$i]}
  done

fi
#
#-----------------------------------------------------------------------
#
# Copy templates of various input files to the experiment directory.
#
#-----------------------------------------------------------------------
#
print_info_msg "$VERBOSE" "
Copying templates of various input files to the experiment directory..."

print_info_msg "$VERBOSE" "
  Copying the template data table file to the experiment directory..."
cp_vrfy "${DATA_TABLE_TMPL_FP}" "${DATA_TABLE_FP}"

print_info_msg "$VERBOSE" "
  Copying the template field table file to the experiment directory..."
cp_vrfy "${FIELD_TABLE_TMPL_FP}" "${FIELD_TABLE_FP}"

print_info_msg "$VERBOSE" "
  Copying the template FV3 namelist file to the experiment directory..."
cp_vrfy "${FV3_NML_TMPL_FP}" "${FV3_NML_FP}"

print_info_msg "$VERBOSE" "
  Copying the template NEMS configuration file to the experiment direct-
  ory..."
cp_vrfy "${NEMS_CONFIG_TMPL_FP}" "${NEMS_CONFIG_FP}"
#
# If using CCPP ... 
#
if [ "${USE_CCPP}" = "TRUE" ]; then
#
# Copy the CCPP physics suite definition file from its location in the 
# clone of the FV3 code repository to the experiment directory (EXPT-
# DIR).
#
  print_info_msg "$VERBOSE" "
Copying the CCPP physics suite definition XML file from its location in
the forecast model directory sturcture to the experiment directory..."
  cp_vrfy "${CCPP_PHYS_SUITE_IN_CCPP_FP}" "${CCPP_PHYS_SUITE_FP}"
#
# If using the GSD_v0 or GSD_SAR physics suite, copy the fixed file con-
# taining cloud condensation nuclei (CCN) data that is needed by the 
# Thompson microphysics parameterization to the experiment directory.
#
  if [ "${CCPP_PHYS_SUITE}" = "FV3_GSD_v0" ] || \
     [ "${CCPP_PHYS_SUITE}" = "FV3_GSD_SAR" ]; then
    print_info_msg "$VERBOSE" "
Copying the fixed file containing cloud condensation nuclei (CCN) data 
(needed by the Thompson microphysics parameterization) to the experiment
directory..."
    cp_vrfy "$FIXgsd/CCN_ACTIVATE.BIN" "$EXPTDIR"
  fi

fi
#
#-----------------------------------------------------------------------
#
# Set parameters in the FV3SAR namelist file.
#
#-----------------------------------------------------------------------
#
print_info_msg "$VERBOSE" "
Setting parameters in FV3 namelist file (FV3_NML_FP):
  FV3_NML_FP = \"${FV3_NML_FP}\""
#
# Set npx and npy, which are just NX plus 1 and NY plus 1, respectively.  
# These need to be set in the FV3SAR Fortran namelist file.  They repre-
# sent the number of cell vertices in the x and y directions on the re-
# gional grid.
#
npx=$((NX+1))
npy=$((NY+1))
#
# Set parameters.
#
set_file_param "${FV3_NML_FP}" "blocksize" "$BLOCKSIZE"
set_file_param "${FV3_NML_FP}" "ccpp_suite" "\'${CCPP_PHYS_SUITE}\'"
set_file_param "${FV3_NML_FP}" "layout" "${LAYOUT_X},${LAYOUT_Y}"
set_file_param "${FV3_NML_FP}" "npx" "$npx"
set_file_param "${FV3_NML_FP}" "npy" "$npy"

set_file_param "${FV3_NML_FP}" "target_lon" "${LON_CTR}"
set_file_param "${FV3_NML_FP}" "target_lat" "${LAT_CTR}"
# Question:
# For a JPgrid type grid, what should stretch_fac be set to?  This de-
# pends on how the FV3 code uses the stretch_fac parameter in the name-
# list file.  Recall that for a JPgrid, it gets set in the function 
# set_gridparams_JPgrid(.sh) to something like 0.9999, but is it ok to
# set it to that here in the FV3 namelist file?
set_file_param "${FV3_NML_FP}" "stretch_fac" "${STRETCH_FAC}"
set_file_param "${FV3_NML_FP}" "bc_update_interval" "${LBC_UPDATE_INTVL_HRS}"
#
# For the GSD_v0 and the GSD_SAR physics suites, set the parameter lsoil
# according to the external models used to obtain ICs and LBCs.
#
if [ "${CCPP_PHYS_SUITE}" = "FV3_GSD_v0" ] || \
   [ "${CCPP_PHYS_SUITE}" = "FV3_GSD_SAR" ]; then

  if [ "${EXTRN_MDL_NAME_ICS}" = "GSMGFS" -o \
       "${EXTRN_MDL_NAME_ICS}" = "FV3GFS" ] && \
     [ "${EXTRN_MDL_NAME_LBCS}" = "GSMGFS" -o \
       "${EXTRN_MDL_NAME_LBCS}" = "FV3GFS" ]; then
    set_file_param "${FV3_NML_FP}" "lsoil" "4"
  elif [ "${EXTRN_MDL_NAME_ICS}" = "RAPX" -o \
         "${EXTRN_MDL_NAME_ICS}" = "HRRRX" ] && \
       [ "${EXTRN_MDL_NAME_LBCS}" = "RAPX" -o \
         "${EXTRN_MDL_NAME_LBCS}" = "HRRRX" ]; then
    set_file_param "${FV3_NML_FP}" "lsoil" "9"
  else
    print_err_msg_exit "\
The value to set the variable lsoil to in the FV3 namelist file (FV3_-
NML_FP) has not been specified for the following combination of physics
suite and external models for ICs and LBCs:
  CCPP_PHYS_SUITE = \"${CCPP_PHYS_SUITE}\"
  EXTRN_MDL_NAME_ICS = \"${EXTRN_MDL_NAME_ICS}\"
  EXTRN_MDL_NAME_LBCS = \"${EXTRN_MDL_NAME_LBCS}\"
Please change one or more of these parameters or provide a value for 
lsoil (and change workflow generation script(s) accordingly) and rerun."
  fi

fi
#
#-----------------------------------------------------------------------
#
# To have a record of how this experiment/workflow was generated, copy
# the experiment/workflow configuration file to the experiment directo-
# ry.
#
#-----------------------------------------------------------------------
#
cp_vrfy $USHDIR/${EXPT_CONFIG_FN} $EXPTDIR
#
#-----------------------------------------------------------------------
#
# For convenience, print out the commands that need to be issued on the 
# command line in order to launch the workflow and to check its status.  
# Also, print out the command that should be placed in the user's cron-
# tab in order for the workflow to be continually resubmitted.
#
#-----------------------------------------------------------------------
#
wflow_db_fn="${WFLOW_XML_FN%.xml}.db"
rocotorun_cmd="rocotorun -w ${WFLOW_XML_FN} -d ${wflow_db_fn} -v 10"
rocotostat_cmd="rocotostat -w ${WFLOW_XML_FN} -d ${wflow_db_fn} -v 10"

print_info_msg "
========================================================================
========================================================================

Workflow generation completed.

========================================================================
========================================================================

The experiment directory is:

  > EXPTDIR=\"$EXPTDIR\"

To launch the workflow, first ensure that you have a compatible version
of rocoto loaded.  For example, to load version 1.3.1 of rocoto, use

  > module load rocoto/1.3.1

(This version has been tested on hera; later versions may also work but
have not been tested.)  To launch the workflow, change location to the 
experiment directory (EXPTDIR) and issue the rocotrun command, as fol-
lows:

  > cd $EXPTDIR
  > ${rocotorun_cmd}

To check on the status of the workflow, issue the rocotostat command 
(also from the experiment directory):

  > ${rocotostat_cmd}

Note that:

1) The rocotorun command must be issued after the completion of each 
   task in the workflow in order for the workflow to submit the next 
   task(s) to the queue.

2) In order for the output of the rocotostat command to be up-to-date,
   the rocotorun command must be issued immediately before the rocoto-
   stat command.

For automatic resubmission of the workflow (say every 3 minutes), the 
following line can be added to the user's crontab (use \"crontab -e\" to
edit the cron table): 

*/3 * * * * cd $EXPTDIR && ${rocotorun_cmd}

Done.
"
#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script/func-
# tion.
#
#-----------------------------------------------------------------------
#
{ restore_shell_opts; } > /dev/null 2>&1

}




#
#-----------------------------------------------------------------------
#
# Start of the script that will call the experiment/workflow generation 
# function defined above.
#
#-----------------------------------------------------------------------
#
set -u
#set -x
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
# Set directories.
#
#-----------------------------------------------------------------------
#
ushdir="${scrfunc_dir}"
#
# Set the name of and full path to the temporary file in which we will 
# save some experiment/workflow variables.  The need for this temporary
# file is explained below.
#
tmp_fn="tmp"
tmp_fp="$ushdir/${tmp_fn}"
rm -f "${tmp_fp}"
#
# Set the name of and full path to the log file in which the output from
# the experiment/workflow generation function will be saved.
#
log_fn="log.generate_FV3SAR_wflow"
log_fp="$ushdir/${log_fn}"
rm -f "${log_fp}"
#
# Call the generate_FV3SAR_wflow function defined above to generate the
# experiment/workflow.  Note that we pipe the output of the function 
# (and possibly other commands) to the "tee" command in order to be able
# to both save it to a file and print it out to the screen (stdout).  
# The piping causes the call to the function (and the other commands 
# grouped with it using the curly braces, { ... }) to be executed in a 
# subshell.  As a result, the experiment/workflow variables that the 
# function sets are not available outside of the grouping, i.e. they are
# not available at and after the call to "tee".  Since some of these va-
# riables are needed after the call to "tee" below, we save them in a 
# temporary file and read them in outside the subshell later below.
#
{ 
generate_FV3SAR_wflow 2>&1  # If this exits with an error, the whole {...} group quits, so things don't work...
retval=$?
echo "$EXPTDIR" >> "${tmp_fp}"
echo "$retval" >> "${tmp_fp}"
} | tee "${log_fp}"
#
# Read in experiment/workflow variables needed later below from the tem-
# porary file created in the subshell above containing the call to the 
# generate_FV3SAR_wflow function.  These variables are not directly 
# available here because the call to generate_FV3SAR_wflow above takes
# place in a subshell (due to the fact that we are then piping its out-
# put to the "tee" command).  Then remove the temporary file.
#
exptdir=$( sed "1q;d" "${tmp_fp}" )
retval=$( sed "2q;d" "${tmp_fp}" )
rm "${tmp_fp}"
#
# If the call to the generate_FV3SAR_wflow function above was success-
# ful, move the log file in which the "tee" command saved the output of
# the function to the experiment directory.
#
if [ $retval -eq 0 ]; then
  mv "${log_fp}" "$exptdir"
#
# If the call to the generate_FV3SAR_wflow function above was not suc-
# cessful, print out an error message and exit with a nonzero return 
# code.
# 
else
  printf "
Experiment/workflow generation failed.  Check the log file from the ex-
periment/workflow generation script in the file specified by log_fp:
  log_fp = \"${log_fp}\"
Stopping.
"
  exit 1
fi



