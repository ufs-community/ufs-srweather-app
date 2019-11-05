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
# Source function definition files.
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
# Load modules.
#
#-----------------------------------------------------------------------
#
module purge
# These need to be made machine-dependent.  The following work only on
# Hera.
module load intel/19.0.4.243
module load netcdf/4.7.0
#
#-----------------------------------------------------------------------
#
# Source the setup script.  Note that this in turn sources the configu-
# ration file/script (config.sh) in the current directory.  It also cre-
# ates the run and work directories, the INPUT and RESTART subdirecto-
# ries under the run directory, and a variable definitions file/script
# in the run directory.  The latter gets sources by each of the scripts
# that run the various workflow tasks.
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
PROC_RUN_FV3="${NUM_NODES}:ppn=${ncores_per_node}"

FHR=( $( seq 0 1 ${FCST_LEN_HRS} ) )
i=0
FHR_STR=$( printf "%02d" "${FHR[i]}" )
numel=${#FHR[@]}
for i in $(seq 1 $(($numel-1)) ); do
  hour=$( printf "%02d" "${FHR[i]}" )
  FHR_STR="$FHR_STR $hour"
done
FHR="$FHR_STR"
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
  CYCLE_DIR="$STMP/tmpnwprd/${PREDEF_GRID_NAME}_${CDATE_generic}"
else
  CYCLE_DIR="$EXPTDIR/${CDATE_generic}"
fi

set_file_param "${WFLOW_XML_FP}" "GLOBAL_VAR_DEFNS_FP" "${GLOBAL_VAR_DEFNS_FP}"
set_file_param "${WFLOW_XML_FP}" "CYCLE_DIR" "${CYCLE_DIR}"
set_file_param "${WFLOW_XML_FP}" "ACCOUNT" "$ACCOUNT"
set_file_param "${WFLOW_XML_FP}" "SCHED" "$SCHED"
set_file_param "${WFLOW_XML_FP}" "QUEUE_DEFAULT" "$QUEUE_DEFAULT"
set_file_param "${WFLOW_XML_FP}" "QUEUE_HPSS" "$QUEUE_HPSS"
set_file_param "${WFLOW_XML_FP}" "QUEUE_FCST" "$QUEUE_FCST"
set_file_param "${WFLOW_XML_FP}" "USHDIR" "$USHDIR"
set_file_param "${WFLOW_XML_FP}" "JOBSDIR" "$JOBSDIR"
set_file_param "${WFLOW_XML_FP}" "EXPTDIR" "$EXPTDIR"
set_file_param "${WFLOW_XML_FP}" "LOGDIR" "$LOGDIR"
set_file_param "${WFLOW_XML_FP}" "EXTRN_MDL_NAME_ICS" "$EXTRN_MDL_NAME_ICS"
set_file_param "${WFLOW_XML_FP}" "EXTRN_MDL_NAME_LBCS" "$EXTRN_MDL_NAME_LBCS"
set_file_param "${WFLOW_XML_FP}" "EXTRN_MDL_FILES_SYSBASEDIR_ICS" "$EXTRN_MDL_FILES_SYSBASEDIR_ICS"
set_file_param "${WFLOW_XML_FP}" "EXTRN_MDL_FILES_SYSBASEDIR_LBCS" "$EXTRN_MDL_FILES_SYSBASEDIR_LBCS"
set_file_param "${WFLOW_XML_FP}" "PROC_RUN_FV3" "$PROC_RUN_FV3"
set_file_param "${WFLOW_XML_FP}" "DATE_FIRST_CYCL" "$DATE_FIRST_CYCL"
set_file_param "${WFLOW_XML_FP}" "DATE_LAST_CYCL" "$DATE_LAST_CYCL"
set_file_param "${WFLOW_XML_FP}" "YYYY_FIRST_CYCL" "$YYYY_FIRST_CYCL"
set_file_param "${WFLOW_XML_FP}" "MM_FIRST_CYCL" "$MM_FIRST_CYCL"
set_file_param "${WFLOW_XML_FP}" "DD_FIRST_CYCL" "$DD_FIRST_CYCL"
set_file_param "${WFLOW_XML_FP}" "HH_FIRST_CYCL" "$HH_FIRST_CYCL"
set_file_param "${WFLOW_XML_FP}" "FHR" "$FHR"
set_file_param "${WFLOW_XML_FP}" "RUN_TASK_MAKE_GRID" "$RUN_TASK_MAKE_GRID"
set_file_param "${WFLOW_XML_FP}" "RUN_TASK_MAKE_OROG" "$RUN_TASK_MAKE_OROG"
set_file_param "${WFLOW_XML_FP}" "RUN_TASK_MAKE_SFC_CLIMO" "$RUN_TASK_MAKE_SFC_CLIMO"
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
# Save the current shell options, turn off the xtrace option, load the
# rocoto module, then restore the original shell options.
#
#-----------------------------------------------------------------------
#
{ save_shell_opts; set +x; } > /dev/null 2>&1
module load rocoto/1.3.1
{ restore_shell_opts; } > /dev/null 2>&1
#
#-----------------------------------------------------------------------
#
# For convenience, print out the commands that needs to be issued on the 
# command line in order to launch the workflow and to check its status.  
# Also, print out the command that should be placed in the user's cron-
# tab in order for the workflow to be continually resubmitted.
#
#-----------------------------------------------------------------------
#
WFLOW_DB_FN="${WFLOW_XML_FN%.xml}.db"
load_rocoto_cmd="module load rocoto/1.3.1"
rocotorun_cmd="rocotorun -w ${WFLOW_XML_FN} -d ${WFLOW_DB_FN} -v 10"
rocotostat_cmd="rocotostat -w ${WFLOW_XML_FN} -d ${WFLOW_DB_FN} -v 10"

print_info_msg "
========================================================================
========================================================================

Workflow generation completed.

========================================================================
========================================================================

The experiment directory is:

  > EXPTDIR=\"$EXPTDIR\"

To launch the workflow, first ensure that you have a compatible version
of rocoto loaded.  For example, on theia, the following version has been
tested and works:

  > ${load_rocoto_cmd}

(Later versions may also work but have not been tested.)  To launch the 
workflow, change location to the experiment directory (EXPTDIR) and is-
sue the rocotrun command, as follows:

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

*/3 * * * * cd $EXPTDIR && $rocotorun_cmd

Done.
"







#
#-----------------------------------------------------------------------
#
#
#
#-----------------------------------------------------------------------
#
if [ "${RUN_ENVIR}" = "nco" ]; then

  glob_pattern="C*_mosaic.nc"
  cd_vrfy $FIXsar
  num_files=$( ls -1 ${glob_pattern} 2>/dev/null | wc -l )

  if [ "${num_files}" -ne "1" ]; then
    print_err_msg_exit "\
Exactly one file must exist in directory FIXsar matching the globbing
pattern glob_pattern:
  FIXsar = \"${FIXsar}\"
  glob_pattern = \"${glob_pattern}\"
  num_files = \"${num_files}\""
  fi

  fn=$( ls -1 ${glob_pattern} )
  RES=$( printf "%s" $fn | sed -n -r -e "s/^C([0-9]*)_mosaic.nc/\1/p" )
  CRES="C$RES"
echo "RES = $RES"

#  RES_equiv=$( ncdump -h "${grid_fn}" | grep -o ":RES_equiv = [0-9]\+" | grep -o "[0-9]")
#  RES_equiv=${RES_equiv//$'\n'/}
#printf "%s\n" "RES_equiv = $RES_equiv"
#  CRES_equiv="C${RES_equiv}"
#printf "%s\n" "CRES_equiv = $CRES_equiv"
#
#  RES="$RES_equiv"
#  CRES="$CRES_equiv"

  set_file_param "${GLOBAL_VAR_DEFNS_FP}" "RES" "${RES}"
  set_file_param "${GLOBAL_VAR_DEFNS_FP}" "CRES" "${CRES}"

else
#
#-----------------------------------------------------------------------
#
# If the grid file generation task in the workflow is going to be 
# skipped (because pregenerated files are available), create links in 
# the FIXsar directory to the pregenerated grid files.
#
#-----------------------------------------------------------------------
#
  if [ "${RUN_TASK_MAKE_GRID}" = "FALSE" ]; then
    $USHDIR/link_fix.sh \
      verbose="FALSE" \
      global_var_defns_fp="${GLOBAL_VAR_DEFNS_FP}" \
      file_group="grid" || \
    print_err_msg_exit "\
Call to script to create links to grid files failed."
  fi
#
#-----------------------------------------------------------------------
#
# If the orography file generation task in the workflow is going to be 
# skipped (because pregenerated files are available), create links in 
# the FIXsar directory to the pregenerated orography files.
#
#-----------------------------------------------------------------------
#
  if [ "${RUN_TASK_MAKE_OROG}" = "FALSE" ]; then
    $USHDIR/link_fix.sh \
      verbose="FALSE" \
      global_var_defns_fp="${GLOBAL_VAR_DEFNS_FP}" \
      file_group="orog" || \
    print_err_msg_exit "\
Call to script to create links to orography files failed."
  fi
#
#-----------------------------------------------------------------------
#
# If the surface climatology file generation task in the workflow is 
# going to be skipped (because pregenerated files are available), create
# links in the FIXsar directory to the pregenerated surface climatology
# files.
#
#-----------------------------------------------------------------------
#
  if [ "${RUN_TASK_MAKE_SFC_CLIMO}" = "FALSE" ]; then
    $USHDIR/link_fix.sh \
      verbose="FALSE" \
      global_var_defns_fp="${GLOBAL_VAR_DEFNS_FP}" \
      file_group="sfc_climo" || \
    print_err_msg_exit "\
Call to script to create links to surface climatology files failed."
  fi

fi



#
#-----------------------------------------------------------------------
#
# Copy fixed files from system directory to the FIXam directory (which 
# is under the experiment directory).  Note that some of these files get
# renamed.
#
#-----------------------------------------------------------------------
#

# For nco, we assume the following copy operation is done beforehand, but
# that can be changed.
if [ "${RUN_ENVIR}" != "nco" ]; then

  print_info_msg "$VERBOSE" "
Copying fixed files from system directory to the experiment directory..."

  check_for_preexist_dir $FIXam "delete"
  mkdir -p $FIXam

  cp_vrfy $FIXgsm/global_hyblev.l65.txt $FIXam
  for (( i=0; i<${NUM_FIXam_FILES}; i++ )); do
    cp_vrfy $FIXgsm/${FIXam_FILES_SYSDIR[$i]} \
            $FIXam/${FIXam_FILES_EXPTDIR[$i]}
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
#
#-----------------------------------------------------------------------
#
# If using CCPP...
#
# If USE_CCPP is set to "TRUE", copy the appropriate modulefile, the 
# CCPP physics suite definition file (an XML file), and possibly other 
# suite-dependent files to the experiment directory.
#
# The modulefile modules.nems in the directory
#
#   $NEMSfv3gfs_DIR/NEMS/src/conf
#
# is generated during the FV3 build process and this is configured pro-
# perly for the machine, shell environment, etc.  Thus, we can just copy
# it to the experiment directory without worrying about what machine 
# we're on, but this still needs to be confirmed.
#
# Note that a modulefile is a file whose first line is the "magic coo-
# kie" '#%Module'.  It is interpreted by the "module load ..." command.  
# It sets environment variables (including prepending/appending to 
# paths) and loads modules.
#
# QUESTION:
# Why don't we do this for the non-CCPP version of FV3?
#
# ANSWER:
# Because for that case, we load different versions of intel and impi 
# (compare modules.nems to the modules loaded for the case of USE_CCPP
# set to "FALSE" in run_FV3SAR.sh).  Maybe these can be combined at some 
# point.  Note that a modules.nems file is generated in the same rela-
# tive location in the non-CCPP-enabled version of NEMSfv3gfs, so maybe
# that can be used and the run_FV3SAR.sh script modified to accomodate
# such a change.  That way the below can be performed for both the CCPP-
# enabled and non-CCPP-enabled versions of NEMSfv3gfs.
#
#-----------------------------------------------------------------------
#
if [ "${USE_CCPP}" = "TRUE" ]; then
#
# Copy the shell script that initializes the Lmod (Lua-based module) 
# system/software for handling modules.  This script:
#
# 1) Detects the shell in which it is being invoked (i.e. the shell of
#    the "parent" script in which it is being sourced).
# 2) Detects the machine it is running on and and calls the appropriate 
#    (shell- and machine-dependent) initalization script to initialize 
#    Lmod.
# 3) Purges all modules.
# 4) Uses the "module use ..." command to prepend or append paths to 
#    Lmod's search path (MODULEPATH).
#
  print_info_msg "$VERBOSE" "
Copying the shell script that initializes the Lmod (Lua-based module) 
system/software for handling modules..."
#
# The following might have to be made shell-dependent, e.g. if using csh 
# or tcsh, copy over the file module-setup.csh.inc??.
#
# It may be convenient to also copy over this script when running the 
# non-CCPP version of the FV3SAR and try to simplify the run script 
# (run_FV3SAR.sh) so that it doesn't depend on whether USE_CCPP is set 
# to "TRUE" or "FALSE".  We can do that, but currently the non-CCPP and 
# CCPP-enabled versions of the FV3SAR code use different versions of
# intel and impi, so module-setup.sh must account for this.
#
  cp_vrfy ${NEMSfv3gfs_DIR}/NEMS/src/conf/module-setup.sh.inc \
          $EXPTDIR/module-setup.sh
#
# Append the command that adds the path to the CCPP libraries (via the
# shell variable LD_LIBRARY_PATH) to the Lmod initialization script in 
# the experiment directory.  This is needed if running the dynamic build
# of the CCPP-enabled version of the FV3SAR.
#
  { cat << EOM >> $EXPTDIR/module-setup.sh
#
# Add path to libccpp.so and libccpphys.so to LD_LIBRARY_PATH"
#
export LD_LIBRARY_PATH="${NEMSfv3gfs_DIR}/ccpp/lib\${LD_LIBRARY_PATH:+:\$LD_LIBRARY_PATH}"
EOM
} || print_err_msg_exit "\
Heredoc (cat) command to append command to add path to CCPP libraries to
the Lmod initialization script in the experiment directory returned with
a nonzero status."

  print_info_msg "$VERBOSE" "
Copying the modulefile required for running the CCPP-enabled version of
the FV3SAR under NEMS to the experiment directory..." 
  cp_vrfy ${NEMSfv3gfs_DIR}/NEMS/src/conf/modules.nems $EXPTDIR/modules.fv3

#
#-----------------------------------------------------------------------
#
# If using CCPP with the GFS physics suite...
#
#-----------------------------------------------------------------------
#
  if [ "${CCPP_PHYS_SUITE}" = "GFS" ]; then

    if [ "${EXTRN_MDL_NAME_ICS}" = "GSMGFS" -o \
         "${EXTRN_MDL_NAME_ICS}" = "FV3GFS" ] && \
       [ "${EXTRN_MDL_NAME_LBCS}" = "GSMGFS" -o \
         "${EXTRN_MDL_NAME_LBCS}" = "FV3GFS" ]; then

      print_info_msg "$VERBOSE" "
Copying the FV3 namelist file for the GFS physics suite to the experi-
ment directory..."
      cp_vrfy ${TEMPLATE_DIR}/${FV3_NML_CCPP_GFSPHYS_GFSEXTRN_FN} \
              $EXPTDIR/${FV3_NML_FN}

    else

      print_err_msg_exit "\
A template FV3 namelist file is not available for the following combina-
tion of physics suite and external models for ICs and LBCs:
  CCPP_PHYS_SUITE = \"${CCPP_PHYS_SUITE}\"
  EXTRN_MDL_NAME_ICS = \"${EXTRN_MDL_NAME_ICS}\"
  EXTRN_MDL_NAME_LBCS = \"${EXTRN_MDL_NAME_LBCS}\"
Please change one or more of these parameters or provide a template
namelist file for this combination (and change workflow generation 
script(s) accordingly) and rerun."

    fi

    print_info_msg "$VERBOSE" "
Copying the field table file for the GFS physics suite to the experiment
directory..."
    cp_vrfy ${TEMPLATE_DIR}/${FIELD_TABLE_FN} \
            $EXPTDIR

    print_info_msg "$VERBOSE" "
Copying the CCPP XML file for the GFS physics suite to the experiment 
directory..."
    cp_vrfy ${NEMSfv3gfs_DIR}/ccpp/suites/suite_FV3_GFS_2017_gfdlmp.xml \
            $EXPTDIR/suite_FV3_GFS_2017_gfdlmp.xml
#
#-----------------------------------------------------------------------
#
# If using CCPP with the GSD physics suite...
#
#-----------------------------------------------------------------------
#
  elif [ "${CCPP_PHYS_SUITE}" = "GSD" ]; then

    print_info_msg "$VERBOSE" "
Copying the FV3 namelist file for the GSD physics suite to the experi-
ment directory..."
    cp_vrfy ${TEMPLATE_DIR}/${FV3_NML_CCPP_GSDPHYS_FN} \
            $EXPTDIR/${FV3_NML_FN}

    print_info_msg "$VERBOSE" "
Copying the field table file for the GSD physics suite to the experiment
directory..."
    cp_vrfy ${TEMPLATE_DIR}/${FIELD_TABLE_CCPP_GSD_FN} \
            $EXPTDIR/${FIELD_TABLE_FN}

    print_info_msg "$VERBOSE" "
Copying the CCPP XML file for the GSD physics suite to the experiment 
directory..."
    cp_vrfy ${NEMSfv3gfs_DIR}/ccpp/suites/suite_FV3_GSD_v0.xml \
            $EXPTDIR/suite_FV3_GSD_v0.xml

    print_info_msg "$VERBOSE" "
Copying the CCN fixed file needed by Thompson microphysics (part of the
GSD suite) to the experiment directory..."
    cp_vrfy $FIXgsd/CCN_ACTIVATE.BIN $EXPTDIR

  fi
#
#-----------------------------------------------------------------------
#
# If not using CCPP...
#
#-----------------------------------------------------------------------
#
elif [ "${USE_CCPP}" = "FALSE" ]; then

  cp_vrfy ${TEMPLATE_DIR}/${FV3_NML_FN} $EXPTDIR
  cp_vrfy ${TEMPLATE_DIR}/${FIELD_TABLE_FN} $EXPTDIR

fi

cp_vrfy ${TEMPLATE_DIR}/${DATA_TABLE_FN} $EXPTDIR
cp_vrfy ${TEMPLATE_DIR}/${NEMS_CONFIG_FN} $EXPTDIR
#
#-----------------------------------------------------------------------
#
# Set the full path to the FV3SAR namelist file.  Then set parameters in
# that file.
#
#-----------------------------------------------------------------------
#
FV3_NML_FP="$EXPTDIR/${FV3_NML_FN}"

print_info_msg "$VERBOSE" "
Setting parameters in FV3 namelist file (FV3_NML_FP):
  FV3_NML_FP = \"${FV3_NML_FP}\""
#
# Set npx_T7 and npy_T7, which are just nx_T7 plus 1 and ny_T7 plus 1,
# respectively.  These need to be set in the FV3SAR Fortran namelist
# file.  They represent the number of cell vertices in the x and y di-
# rections on the regional grid (tile 7).
#
npx_T7=$(($nx_T7+1))
npy_T7=$(($ny_T7+1))
#
# Set parameters.
#
set_file_param "${FV3_NML_FP}" "blocksize" "$blocksize"
set_file_param "${FV3_NML_FP}" "layout" "${layout_x},${layout_y}"
set_file_param "${FV3_NML_FP}" "npx" "${npx_T7}"
set_file_param "${FV3_NML_FP}" "npy" "${npy_T7}"

if [ "${GRID_GEN_METHOD}" = "GFDLgrid" ]; then
# Question:
# For a regional grid (i.e. one that only has a tile 7) should the co-
# ordinates that target_lon and target_lat get set to be those of the 
# center of tile 6 (of the parent grid) or those of tile 7?  These two
# are not necessarily the same [although assuming there is only one re-
# gional domain within tile 6, i.e. assuming there is no tile 8, 9, etc,
# there is no reason not to center tile 7 with respect to tile 6].
  set_file_param "${FV3_NML_FP}" "target_lon" "${lon_ctr_T6}"
  set_file_param "${FV3_NML_FP}" "target_lat" "${lat_ctr_T6}"
elif [ "${GRID_GEN_METHOD}" = "JPgrid" ]; then
  set_file_param "${FV3_NML_FP}" "target_lon" "${lon_rgnl_ctr}"
  set_file_param "${FV3_NML_FP}" "target_lat" "${lat_rgnl_ctr}"
fi
set_file_param "${FV3_NML_FP}" "stretch_fac" "${stretch_fac}"
set_file_param "${FV3_NML_FP}" "bc_update_interval" "${LBC_UPDATE_INTVL_HRS}"
#
# For GSD physics, set the parameter lsoil according to the external mo-
# dels specified for ICs and LBCs.
#
if [ "${CCPP_PHYS_SUITE}" = "GSD" ]; then

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
# Call the function defined above.
#
#-----------------------------------------------------------------------
#
generate_FV3SAR_wflow


