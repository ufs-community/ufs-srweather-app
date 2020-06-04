#!/bin/bash

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
. $ushdir/set_FV3nml_sfc_climo_filenames.sh
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
# Set the full path to the experiment's rocoto workflow xml file.  This
# file will be placed at the top level of the experiment directory and
# then used by rocoto to run the workflow.
#
#-----------------------------------------------------------------------
#
WFLOW_XML_FP="$EXPTDIR/${WFLOW_XML_FN}"
#
#-----------------------------------------------------------------------
#
# Create a multiline variable that consists of a yaml-compliant string
# specifying the values that the jinja variables in the template rocoto
# XML should be set to.  These values are set either in the user-specified
# workflow configuration file (EXPT_CONFIG_FN) or in the setup.sh script
# sourced above.  Then call the python script that generates the XML.
#
#-----------------------------------------------------------------------
#
settings="\
#
# Parameters needed by the job scheduler.
#
  'account': $ACCOUNT
  'sched': $SCHED
  'queue_default': ${QUEUE_DEFAULT}
  'queue_default_tag': ${QUEUE_DEFAULT_TAG}
  'queue_hpss': ${QUEUE_HPSS}
  'queue_hpss_tag': ${QUEUE_HPSS_TAG}
  'queue_fcst': ${QUEUE_FCST}
  'queue_fcst_tag': ${QUEUE_FCST_TAG}
#
# Workflow task names.
#
  'make_grid_tn': ${MAKE_GRID_TN}
  'make_orog_tn': ${MAKE_OROG_TN}
  'make_sfc_climo_tn': ${MAKE_SFC_CLIMO_TN}
  'get_extrn_ics_tn': ${GET_EXTRN_ICS_TN}
  'get_extrn_lbcs_tn': ${GET_EXTRN_LBCS_TN}
  'make_ics_tn': ${MAKE_ICS_TN}
  'make_lbcs_tn': ${MAKE_LBCS_TN}
  'run_fcst_tn': ${RUN_FCST_TN}
  'run_post_tn': ${RUN_POST_TN}
#
# Number of nodes to use for each task.
#
  'nnodes_make_grid': ${NNODES_MAKE_GRID}
  'nnodes_make_orog': ${NNODES_MAKE_OROG}
  'nnodes_make_sfc_climo': ${NNODES_MAKE_SFC_CLIMO}
  'nnodes_get_extrn_ics': ${NNODES_GET_EXTRN_ICS}
  'nnodes_get_extrn_lbcs': ${NNODES_GET_EXTRN_LBCS}
  'nnodes_make_ics': ${NNODES_MAKE_ICS}
  'nnodes_make_lbcs': ${NNODES_MAKE_LBCS}
  'nnodes_run_fcst': ${NNODES_RUN_FCST}
  'nnodes_run_post': ${NNODES_RUN_POST}
#
# Number of logical processes per node for each task.  If running without
# threading, this is equal to the number of MPI processes per node.
#
  'ppn_make_grid': ${PPN_MAKE_GRID}
  'ppn_make_orog': ${PPN_MAKE_OROG}
  'ppn_make_sfc_climo': ${PPN_MAKE_SFC_CLIMO}
  'ppn_get_extrn_ics': ${PPN_GET_EXTRN_ICS}
  'ppn_get_extrn_lbcs': ${PPN_GET_EXTRN_LBCS}
  'ppn_make_ics': ${PPN_MAKE_ICS}
  'ppn_make_lbcs': ${PPN_MAKE_LBCS}
  'ppn_run_fcst': ${PPN_RUN_FCST}
  'ppn_run_post': ${PPN_RUN_POST}
#
# Maximum wallclock time for each task.
#
  'wtime_make_grid': ${WTIME_MAKE_GRID}
  'wtime_make_orog': ${WTIME_MAKE_OROG}
  'wtime_make_sfc_climo': ${WTIME_MAKE_SFC_CLIMO}
  'wtime_get_extrn_ics': ${WTIME_GET_EXTRN_ICS}
  'wtime_get_extrn_lbcs': ${WTIME_GET_EXTRN_LBCS}
  'wtime_make_ics': ${WTIME_MAKE_ICS}
  'wtime_make_lbcs': ${WTIME_MAKE_LBCS}
  'wtime_run_fcst': ${WTIME_RUN_FCST}
  'wtime_run_post': ${WTIME_RUN_POST}
#
# Flags that specify whether to run the preprocessing tasks.
#
  'run_task_make_grid': ${RUN_TASK_MAKE_GRID}
  'run_task_make_orog': ${RUN_TASK_MAKE_OROG}
  'run_task_make_sfc_climo': ${RUN_TASK_MAKE_SFC_CLIMO}
#
# Number of physical cores per node for the current machine.
#
  'ncores_per_node': ${NCORES_PER_NODE}
#
# Directories and files.
#
  'jobsdir': $JOBSDIR
  'logdir': $LOGDIR
  'cycle_basedir': ${CYCLE_BASEDIR}
  'global_var_defns_fp': ${GLOBAL_VAR_DEFNS_FP}
  'load_modules_run_task_fp': ${LOAD_MODULES_RUN_TASK_FP}
#
# External model information for generating ICs and LBCs.
#
  'extrn_mdl_name_ics': ${EXTRN_MDL_NAME_ICS}
  'extrn_mdl_name_lbcs': ${EXTRN_MDL_NAME_LBCS}
#
# Parameters that determine the set of cycles to run.
#
  'date_first_cycl': !datetime ${DATE_FIRST_CYCL}${CYCL_HRS[0]}
  'date_last_cycl': !datetime ${DATE_LAST_CYCL}${CYCL_HRS[0]}
  'cycl_freq': !!str 24:00:00
#
# Forecast length (same for all cycles).
#
  'fcst_len_hrs': ${FCST_LEN_HRS}"
#
# For debugging purposes, print out what "settings" has been set to.
#
print_info_msg $VERBOSE "
The variable \"settings\" specifying values of the rococo XML variables
has been set as follows:

settings =
$settings"
#
# Set the full path to the template rocoto XML file.  Then call a python
# script to generate the experiment's actual XML file from this template
# file.
#
template_xml_fp="${TEMPLATE_DIR}/${WFLOW_XML_FN}"
$USHDIR/create_xml.py -q \
                      -t ${template_xml_fp} \
                      -u "$settings" \
                      -o ${WFLOW_XML_FP} || \
  print_err_msg_exit "\
Call to python script create_xml.py to create a rocoto workflow XML file
from a template file failed.  Parameters passed to this script are:
  Full path to template rocoto XML file:
    template_xml_fp = \"${template_xml_fp}\"
  Full path to output rocoto XML file:
    WFLOW_XML_FP = \"${WFLOW_XML_FP}\"
  Namelist settings specified on command line:
    settings =
$settings"
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
#
# Only some platforms build EMC_post using modules.
#
case $MACHINE in

  "CHEYENNE")
    print_info_msg "No post modulefile needed for $MACHINE"
    ;;

  *)
    ln_vrfy -fs "${EMC_POST_DIR}/modulefiles/post/v8.0.0-$machine" \
                "${RUN_POST_TN}"
    ;;

esac

cd_vrfy -
#
#-----------------------------------------------------------------------
#
# Create a symlink in the experiment directory that points to the workflow
# (re)launch script.
#
#-----------------------------------------------------------------------
#
print_info_msg "
Creating symlink in the experiment directory (EXPTDIR) that points to the
workflow launch script (WFLOW_LAUNCH_SCRIPT_FP):
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
# Copy fixed files from system directory to the FIXam directory (which
# is under the experiment directory).  Note that some of these files get
# renamed during the copy process.
#
#-----------------------------------------------------------------------
#

# In NCO mode, we assume the following copy operation is done beforehand,
# but that can be changed.
if [ "${RUN_ENVIR}" != "nco" ]; then

  print_info_msg "$VERBOSE" "
Copying fixed files from system directory (FIXgsm) to a subdirectory
(FIXam) in the experiment directory:
  FIXgsm = \"$FIXgsm\"
  FIXam = \"$FIXam\""

  check_for_preexist_dir_file "$FIXam" "delete"
  mkdir_vrfy -p "$FIXam"
  mkdir_vrfy -p "$FIXam/fix_co2_proj"

  num_files=${#FIXgsm_FILES_TO_COPY_TO_FIXam[@]}
  for (( i=0; i<${num_files}; i++ )); do
    fn="${FIXgsm_FILES_TO_COPY_TO_FIXam[$i]}"
    cp_vrfy "$FIXgsm/$fn" "$FIXam/$fn"
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
     [ "${CCPP_PHYS_SUITE}" = "FV3_GSD_SAR_v1" ] || \
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
# This if-statement is a temporary fix that makes corrections to the suite
# definition file for the "FV3_GFS_2017_gfdlmp_regional" physics suite
# that EMC uses. 
#
# IMPORTANT:
# This if-statement must be removed once these corrections are made to
# the suite definition file in the dtc/develop branch of the NCAR fork
# of the fv3atm repository.
#
#-----------------------------------------------------------------------
#
if [ "${USE_CCPP}" = "TRUE" ] && \
   [ "${CCPP_PHYS_SUITE}" = "FV3_GFS_2017_gfdlmp_regional" ]; then
  mv_vrfy "${CCPP_PHYS_SUITE_FP}.tmp" "${CCPP_PHYS_SUITE_FP}"
fi





#
#-----------------------------------------------------------------------
#
# Copy the forecast model executable from its location in the directory
# in which the forecast model repository was cloned (UFS_WTHR_MDL_DIR)
# to the executables directory (EXECDIR).
#
# Note that if there is already an experiment that is running the forecast
# task (so that the forecast model executable in EXECDIR is in use) and
# the user tries to generate another experiment, the generation of this
# second experiment will fail because the operating system won't allow
# the existing executable in EXECDIR to be overwritten (because it is
# "busy", i.e. in use by the first experiment).  For this reason, below,
# we try to prevent this situation by comparing the ages of the source
# and target executables and attempting the copy only if the source one
# is newer (or if the target doesn't exist).  This will very likely prevent
# the situation described above, but it doesn't guarantee that it will
# never happen (it will still happen if an experiment is running a forecast
# while the user rebuilts the forecast model and attempts to generate a
# new experiment.  For this reason, this copy operation should really be
# performed duirng the build step, not here.
#
# Question:
# Why doesn't the build script(s) perform this action?  It should...
#
#-----------------------------------------------------------------------
#
if [ "${USE_CCPP}" = "TRUE" ]; then
  exec_fn="fv3.exe"
else
  exec_fn="fv3_32bit.exe"
fi

exec_fp="${UFS_WTHR_MDL_DIR}/tests/${exec_fn}"
if [ ! -f "${exec_fp}" ]; then
  print_err_msg_exit "\
The executable (exec_fp) for running the forecast model does not exist:
  exec_fp = \"${exec_fp}\"
Please ensure that you've built this executable."
fi
#
# Make a copy of the executable in the executables directory only if a
# copy doens't already exist or if a copy does exist but is older than
# the original.
#
if [ ! -e "${FV3_EXEC_FP}" ] || \
   [ "${exec_fp}" -nt "${FV3_EXEC_FP}" ]; then
  print_info_msg "$VERBOSE" "
Copying the FV3SAR executable (exec_fp) to the executables directory
(EXECDIR):
  exec_fp = \"${exec_fp}\"
  EXECDIR = \"$EXECDIR\""
  cp_vrfy "${exec_fp}" "${FV3_EXEC_FP}"
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
# These need to be set in the FV3SAR Fortran namelist file.  They represent
# the number of cell vertices in the x and y directions on the regional
# grid.
#
npx=$((NX+1))
npy=$((NY+1))
#
# For the FV3_GSD_v0 and the FV3_GSD_SAR physics suites, set the parameter
# lsoil according to the external models used to obtain ICs and LBCs.
#
if [ "${CCPP_PHYS_SUITE}" = "FV3_GSD_v0" ] || \
   [ "${CCPP_PHYS_SUITE}" = "FV3_GSD_SAR" ]; then

  if [ "${EXTRN_MDL_NAME_ICS}" = "GSMGFS" -o \
       "${EXTRN_MDL_NAME_ICS}" = "FV3GFS" ] && \
     [ "${EXTRN_MDL_NAME_LBCS}" = "GSMGFS" -o \
       "${EXTRN_MDL_NAME_LBCS}" = "FV3GFS" ]; then
    lsoil=4
  elif [ "${EXTRN_MDL_NAME_ICS}" = "RAPX" -o \
         "${EXTRN_MDL_NAME_ICS}" = "HRRRX" ] && \
       [ "${EXTRN_MDL_NAME_LBCS}" = "RAPX" -o \
         "${EXTRN_MDL_NAME_LBCS}" = "HRRRX" ]; then
    lsoil=9
  else
    print_err_msg_exit "\
The value to set the variable lsoil to in the FV3 namelist file (FV3_NML_FP)
has not been specified for the following combination of physics suite and
external models for ICs and LBCs:
  CCPP_PHYS_SUITE = \"${CCPP_PHYS_SUITE}\"
  EXTRN_MDL_NAME_ICS = \"${EXTRN_MDL_NAME_ICS}\"
  EXTRN_MDL_NAME_LBCS = \"${EXTRN_MDL_NAME_LBCS}\"
Please change one or more of these parameters or provide a value for lsoil
(and change workflow generation script(s) accordingly) and rerun."
  fi

fi
#
# Create a multiline variable that consists of a yaml-compliant string
# specifying the values that the namelist variables that are physics-
# suite-independent need to be set to.  Below, this variable will be
# passed to a python script that will in turn set the values of these
# variables in the namelist file.
#
settings="\
'atmos_model_nml': {
    'blocksize': $BLOCKSIZE,
    'ccpp_suite': ${CCPP_PHYS_SUITE},
  }
'fv_core_nml': {
    'target_lon': ${LON_CTR},
    'target_lat': ${LAT_CTR},
#
# Question:
# For a JPgrid type grid, what should stretch_fac be set to?  This depends
# on how the FV3 code uses the stretch_fac parameter in the namelist file.
# Recall that for a JPgrid, it gets set in the function set_gridparams_JPgrid(.sh)
# to something like 0.9999, but is it ok to set it to that here in the
# FV3 namelist file?
#
    'stretch_fac': ${STRETCH_FAC},
    'npx': $npx,
    'npy': $npy,
    'layout': [${LAYOUT_X}, ${LAYOUT_Y}],
    'bc_update_interval': ${LBC_SPEC_INTVL_HRS},
  }
'gfs_physics_nml': {
    'lsoil': ${lsoil:-null},
  }"
#
# Add to "settings" the values of those namelist variables that specify
# the paths to fixed files in the FIXam directory.  As above, these namelist
# variables are physcs-suite-independent.
#
# Note that the array FV3_NML_VARNAME_TO_FIXam_FILES_MAPPING contains
# the mapping between the namelist variables and the names of the files
# in the FIXam directory.  Here, we loop through this array and process
# each element to construct each line of "settings".
#
settings="$settings
'namsfc': {"

regex_search="^[ ]*([^| ]+)[ ]*[|][ ]*([^| ]+)[ ]*$"
num_nml_vars=${#FV3_NML_VARNAME_TO_FIXam_FILES_MAPPING[@]}
for (( i=0; i<${num_nml_vars}; i++ )); do

  mapping="${FV3_NML_VARNAME_TO_FIXam_FILES_MAPPING[$i]}"
  nml_var_name=$( printf "%s\n" "$mapping" | \
                  sed -n -r -e "s/${regex_search}/\1/p" )
  FIXam_fn=$( printf "%s\n" "$mapping" |
              sed -n -r -e "s/${regex_search}/\2/p" )

  fp="\"\""
  if [ ! -z "${FIXam_fn}" ]; then
    fp="$FIXam/${FIXam_fn}"
#
# If not in NCO mode, for portability and brevity, change fp so that it
# is a relative path (relative to any cycle directory immediately under
# the experiment directory).
#
    if [ "${RUN_ENVIR}" != "nco" ]; then
      fp=$( realpath --canonicalize-missing \
                     --relative-to="$EXPTDIR/any_cycle_dir" "$fp" )
    fi
  fi
#
# Add a line to the variable "settings" that specifies (in a yaml-compliant
# format) the name of the current namelist variable and the value it should
# be set to.
#
  settings="$settings
    '${nml_var_name}': $fp,"

done
#
# Add to "settings" several namelist variable name-and-value pairs that
# are constant.  These should probably be added to the base namelist file
# (FV3_NML_BASE_FP) and this step removed.
#
settings="$settings
#    'FNZORC': \"igbp\",
#    'FNTSFA': \"\",
#    'FNACNA': \"\",
#    'FNSNOA': \"\",
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
# Call the set_namelist.py script to create a new FV3 namelist file (full
# path specified by FV3_NML_FP) using the file FV3_NML_BASE_FP as the base
# (i.e. starting) namelist file, with physics-suite-dependent modifications
# to the base file specified in the yaml configuration file FV3_NML_YAML_CONFIG_FP
# (for the physics suite specified by CCPP_PHYS_SUITE), and with additional
# physics-suite-independent modificaitons specified in the variable
# "settings" set above.
#
#-----------------------------------------------------------------------
#
$USHDIR/set_namelist.py -q \
                        -n ${FV3_NML_BASE_FP} \
                        -c ${FV3_NML_YAML_CONFIG_FP} ${CCPP_PHYS_SUITE} \
                        -u "$settings" \
                        -o ${FV3_NML_FP} || \
  print_err_msg_exit "\
Call to python script set_namelist.py to generate an FV3 namelist file
failed.  Parameters passed to this script are:
  Full path to base namelist file:
    FV3_NML_BASE_FP = \"${FV3_NML_BASE_FP}\"
  Full path to yaml configuration file for various physics suites:
    FV3_NML_YAML_CONFIG_FP = \"${FV3_NML_YAML_CONFIG_FP}\"
  Physics suite to extract from yaml configuration file:
    CCPP_PHYS_SUITE = \"${CCPP_PHYS_SUITE}\"
  Full path to output namelist file:
    FV3_NML_FP = \"${FV3_NML_FP}\"
  Namelist settings specified on command line:
    settings =
$settings"
#
# If not running the MAKE_GRID_TN task (which implies the workflow will
# use pregenerated grid files), set the namelist variables specifying
# the paths to surface climatology files.  These files are located in
# (or have symlinks that point to them) in the FIXsar directory.
#
# Note that if running the MAKE_GRID_TN task, this action usually cannot
# be performed here but must be performed in that task because the names
# of the surface climatology files depend on the CRES parameter (which is
# the C-resolution of the grid), and this parameter is in most workflow
# configurations is not known until the grid is created.
#
if [ "${RUN_TASK_MAKE_GRID}" = "FALSE" ]; then
  set_FV3nml_sfc_climo_filenames
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

"
case $MACHINE in

"CHEYENNE")
  print_info_msg "\
To launch the workflow, first ensure that you have a compatible version
of rocoto in your \$PATH. On Cheyenne, version 1.3.1 has been pre-built;
you can load it in your \$PATH with one of the following commands, depending
on your default shell:

bash:
  > export PATH=\${PATH}:/glade/p/ral/jntp/tools/rocoto/rocoto-1.3.1/bin/

tcsh:
  > setenv PATH \${PATH}:/glade/p/ral/jntp/tools/rocoto/rocoto-1.3.1/bin/
"
  ;;

*)
  print_info_msg "\
To launch the workflow, first ensure that you have a compatible version
of rocoto loaded.  For example, to load version 1.3.1 of rocoto, use

  > module load rocoto/1.3.1

(This version has been tested on hera; later versions may also work but
have not been tested.)
"
  ;;

esac
print_info_msg "
To launch the workflow, change location to the experiment directory
(EXPTDIR) and issue the rocotrun command, as follows:

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

*/3 * * * * cd $EXPTDIR && ./launch_FV3SAR_wflow.sh

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



