#
#-----------------------------------------------------------------------
#
# Source the variable definitions script.                                                                                                         
#
#-----------------------------------------------------------------------
#
. $SCRIPT_VAR_DEFNS_FP
#
#-----------------------------------------------------------------------
#
# Source function definition files.
#
#-----------------------------------------------------------------------
#
. $USHDIR/source_funcs.sh
#
#-----------------------------------------------------------------------
#
# This file defines a function that is used to obtain information (e.g.
# output file names, system and mass store file and/or directory names)
# for a specified external model, analysis or forecast, and cycle date.
# See the usage statement below for this function should be called and
# the definitions of the input parameters.
# 
#-----------------------------------------------------------------------
#
function get_extrn_mdl_file_dir_info () {
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
# Check arguments.
#
#-----------------------------------------------------------------------
#
  if [ "$#" -ne "13" ]; then
    print_err_msg_exit "\
Function \"${FUNCNAME[0]}\":  Incorrect number of arguments specified.
Usage:

  ${FUNCNAME[0]} \
    extrn_mdl \
    anl_or_fcst \
    cdate_FV3SAR \
    time_offset_hrs \
    output_fn \
    glob_var_name_filenames \
    glob_var_name_filenames \
    glob_var_name_arcv_file_fmt \
    glob_var_name_arcv_filename \
    glob_var_name_arcv_fullpath \
    glob_var_name_arcvrel_dir

where the arguments are defined as follows:
 
  extrn_mdl:
  Name of the external model, i.e. the name of the model providing the
  fields from which files containing initial conditions, surface fields, 
  and/or lateral boundary conditions for the FV3SAR will be generated.
 
  anl_or_fcst:
  Flag that specifies whether the external model files we are interested
  in obtaining are analysis or forecast files.  
 
  cdate_FV3SAR:
  The cycle date and time (hours only) for which we want to obtain file
  and directory information.  This has the form YYYYMMDDHH, where YYYY
  is the four-digit starting year of the cycle, MM is the two-digit 
  month, DD is the two-digit day of the month, and HH is the two-digit
  hour of day.
 
  time_offset_hrs:
  The number of hours by which to shift back in time the start time of
  the external model forecast from the specified cycle start time of the
  FV3SAR (cdate_FV3SAR).  When getting directory and file information on
  external model analysis files, this is normally set to 0.  When get-
  ting directory and file information on external model forecast files,
  this may be set to a nonzero value to obtain information for an exter-
  nal model run that started time_offset_hrs hours before cdate_FV3SAR 
  (instead of exactly at cdate_FV3SAR).  Note that in this case, the 
  forecast hours (relative to the external model run's start time) at
  which the lateral boundary conditions will be updated must be shifted
  forward by time_offset_hrs hours relative to those for the FV3SAR in
  order to make up for the backward-in-time shift in the starting time
  of the external model.
 
  output_fn:
  Name of the file in which output from this function will be stored, 
  including the names of the output variables (specified as inputs to 
  this function; see below) and the values calculated for them.  This
  output file is written in such a way that it can be sourced by the 
  calling script.  We write output to this file and then have the call-
  ing script read it in because there is no straightforward way in bash
  to return values from a function to the calling script.
 
  glob_var_name_cdate:
  Name of the global variable that will contain the starting date and 
  hour of the external model run.
 
  glob_var_name_lbc_update_fhrs:
  Name of the global variable that will contain the forecast hours (re-
  lative to the starting time of the external model run, which is earli-
  er than that of the FV3SAR by time_offset_hrs hours) at which lateral
  boundary condition (LBC) output files are obtained from the external
  model (and will be used to update the LBCs of the FV3SAR).
 
  glob_var_name_filenames:
  Name of the global variable that will contain the names of the exter-
  nal model output files.
 
  glob_var_name_sysdir:
  Name of the global variable that will contain the system directory in
  which the externaml model output files may be stored.
 
  glob_var_name_arcv_file_fmt:
  Name of the global variable that will contain the format of the ar-
  chive file on HPSS in which the externaml model output files may be 
  stored.
 
  glob_var_name_arcv_filename:
  Name of the global variable that will contain the name of the archive
  file on HPSS in which the externaml model output files may be stored.
 
  glob_var_name_arcv_fullpath:
  Name of the global variable that will contain the full path to the ar-
  chive file on HPSS in which the externaml model output files may be 
  stored.
 
  glob_var_name_arcvrel_dir:
  Name of the global variable that will contain the archive-relative di-
  rectory, i.e. the directory \"inside\" the archive file in which the ex-
  ternal model output files may be stored.
 
"

  fi
#
#-----------------------------------------------------------------------
#
# Step through the arguments list and set each to a local variable.
#
#-----------------------------------------------------------------------
#
  local iarg="0"
  iarg=$(( iarg+1 ))
  local extrn_mdl="${!iarg}"
  iarg=$(( iarg+1 ))
  local anl_or_fcst="${!iarg}"
  iarg=$(( iarg+1 ))
  local cdate_FV3SAR="${!iarg}"
  iarg=$(( iarg+1 ))
  local time_offset_hrs="${!iarg}"

  iarg=$(( iarg+1 ))
  local output_fn="${!iarg}"
  iarg=$(( iarg+1 ))
  local glob_var_name_cdate="${!iarg}"
  iarg=$(( iarg+1 ))
  local glob_var_name_lbc_update_fhrs="${!iarg}"
  iarg=$(( iarg+1 ))
  local glob_var_name_filenames="${!iarg}"
  iarg=$(( iarg+1 ))
  local glob_var_name_sysdir="${!iarg}"
  iarg=$(( iarg+1 ))
  local glob_var_name_arcv_file_fmt="${!iarg}"
  iarg=$(( iarg+1 ))
  local glob_var_name_arcv_filename="${!iarg}"
  iarg=$(( iarg+1 ))
  local glob_var_name_arcv_fullpath="${!iarg}"
  iarg=$(( iarg+1 ))
  local glob_var_name_arcvrel_dir="${!iarg}"
#
#-----------------------------------------------------------------------
#
# Declare additional local variables.  Note that all variables in this 
# function should be local.  The variables set by this function are not
# directly passed back to the calling script because that is not easily
# feasable in bash.  Instead, the calling script specifies a file in 
# which to store the output variables and their values.  The name of 
# of this file
#
#-----------------------------------------------------------------------
#
  local yyyy mm dd hh mn yyyymmdd \
        lbc_update_fhrs i num_fhrs \
        yy ddd fcst_hhh fcst_hh fcst_mn \
        filenames prefix suffix \
        sysbasedir sysdir \
        arcv_dir arcv_file_fmt arcv_filename arcv_fullpath arcvrel_dir
#
#-----------------------------------------------------------------------
#
# Check input variables for valid values.
#
#-----------------------------------------------------------------------
#
  valid_vals_anl_or_fcst=( "ANL" "anl" "FCST" "fcst" )
  iselementof "$anl_or_fcst" valid_vals_anl_or_fcst || { \
    valid_vals_anl_or_fcst_str=$(printf "\"%s\" " "${valid_vals_anl_or_fcst[@]}");
    print_err_msg_exit "\
Value specified in anl_or_fcst is not supported:
  anl_or_fcst = \"$anl_or_fcst\"
anl_or_fcst must be set to one of the following:
  $valid_vals_anl_or_fcst_str
"; }
#
# For convenience of checking input values, change contents of anl_or_-
# fcst to uppercase.
#
  anl_or_fcst="${anl_or_fcst^^}"
#
#-----------------------------------------------------------------------
#
# Extract from cdate_FV3SAR the starting year, month, day, and hour of 
# the FV3SAR cycle.  Then subtract the temporal offset specified in 
# time_offset_hrs (assumed to be given in units of hours) from cdate_-
# FV3SAR to obtain the starting date and time of the external model, ex-
# press the result in YYYYMMDDHH format, and save it in cdate.  This is
# the starting time of the external model forecast.
#
#-----------------------------------------------------------------------
#
  yyyy=${cdate_FV3SAR:0:4}
  mm=${cdate_FV3SAR:4:2}
  dd=${cdate_FV3SAR:6:2}
  hh=${cdate_FV3SAR:8:2}
  yyyymmdd=${cdate_FV3SAR:0:8}

  cdate=$( date --utc --date "${yyyymmdd} ${hh} UTC - ${time_offset_hrs} hours" "+%Y%m%d%H" )
#
#-----------------------------------------------------------------------
#
# Extract from cdate the starting year, month, day, and hour of the ex-
# ternal model.  Also, set the starting minute to "00" and get the date
# without the time-of-day.  These are needed below in setting various 
# directory and file names.
#
#-----------------------------------------------------------------------
#
  yyyy=${cdate:0:4}
  mm=${cdate:4:2}
  dd=${cdate:6:2}
  hh=${cdate:8:2}
  mn="00"
  yyyymmdd=${cdate:0:8}
#
#-----------------------------------------------------------------------
#
# Initialize lbc_update_fhrs to an empty array.  Then, if considering a
# forecast, reset lbc_update_fhrs to the array of forecast hours at 
# which the lateral boundary conditions (LBCs) are to be updated, start-
# ing with the 2nd such time (i.e. the one having array index 1).  We do
# not include the first hour (hour zero) because at this initial time, 
# the LBCs are obtained from the analysis fields provided by the exter-
# nal model (as opposed to a forecast field).
#
#-----------------------------------------------------------------------
#
  lbc_update_fhrs=( "" )

  if [ "$ANL_OR_FCST" = "FCST" ]; then

    lbc_update_fhrs=( "${LBC_UPDATE_FCST_HRS[@]}" )
#
# Add the temporal offset specified in time_offset_hrs (assumed to be in 
# units of hours) to the the array of LBC update forecast hours to make
# up for shifting the starting hour back in time.  After this addition,
# lbc_update_fhrs will contain the LBC update forecast hours relative to
# the start time of the external model run.
#
    num_fhrs=${#lbc_update_fhrs[@]}
    for (( i=0; i<=$(( $num_fhrs - 1 )); i++ )); do
      lbc_update_fhrs[$i]=$(( ${lbc_update_fhrs[$i]} + time_offset_hrs ))
    done

  fi
#
#-----------------------------------------------------------------------
#
# Set additional parameters needed in forming the names of RAPX and
# HRRRX output files. 
#
#-----------------------------------------------------------------------
#
  if [ "$extrn_mdl" = "RAPX" ] || \
     [ "$extrn_mdl" = "HRRRX" ]; then
#
# Get the Julian day-of-year of the starting date and time of the exter-
# nal model run.
#
    ddd=$( date --utc --date "${yyyy}-${mm}-${dd} ${hh}:${mn} UTC" "+%j" )
#
# Get the last two digits of the year of the starting date and time of 
# the external model run.
#
    yy=${yyyy:2:4}

  fi
#
#-----------------------------------------------------------------------
#
# Set the external model output file names that must be obtained (from 
# disk if available, otherwise from HPSS).
#
#-----------------------------------------------------------------------
#
  case "$anl_or_fcst" in
#
#-----------------------------------------------------------------------
#
# Consider analysis files (possibly including surface files).
#
#-----------------------------------------------------------------------
#
  "ANL")

    fcst_hh="00"
    fcst_mn="00"

    case "$extrn_mdl" in

    "GFS")
#      filenames=( "atm" "sfc" "nst" )
      filenames=( "atm" "sfc" )
      prefix="gfs.t${hh}z."
      filenames=( "${filenames[@]/#/$prefix}" )
      suffix="anl.nemsio"
      filenames=( "${filenames[@]/%/$suffix}" )
      ;;

    "RAPX")
      filenames=( "${yy}${ddd}${hh}${mn}${fcst_hh}${fcst_mn}" )
      ;;

    "HRRRX")
      filenames=( "${yy}${ddd}${hh}${mn}${fcst_hh}${fcst_mn}" )
      ;;

    *)
      print_err_msg_exit "\
The external model file names have not yet been specified for this com-
bination of external model (extrn_mdl) and analysis or forecast (anl_-
or_fcst):
  extrn_mdl = \"$extrn_mdl\"
  anl_or_fcst = \"$anl_or_fcst\"
"
      ;;

    esac
    ;;
#
#-----------------------------------------------------------------------
#
# Consider forecast files.
#
#-----------------------------------------------------------------------
#
  "FCST")

    fcst_mn="00"

    case "$extrn_mdl" in

    "GFS")
      fcst_hhh=( $( printf "%03d " "${lbc_update_fhrs[@]}" ) )
      prefix="gfs.t${hh}z.atmf"
      filenames=( "${fcst_hhh[@]/#/$prefix}" )
      suffix=".nemsio"
      filenames=( "${filenames[@]/%/$suffix}" )
      ;;

    "RAPX")
      fcst_hh=( $( printf "%02d " "${lbc_update_fhrs[@]}" ) )
      prefix="${yy}${ddd}${hh}${mn}"
      filenames=( "${fcst_hh[@]/#/$prefix}" )
      suffix="${fcst_mn}"
      filenames=( "${filenames[@]/%/$suffix}" )
      ;;

    "HRRRX")
      fcst_hh=( $( printf "%02d " "${lbc_update_fhrs[@]}" ) )
      prefix="${yy}${ddd}${hh}${mn}"
      filenames=( "${fcst_hh[@]/#/$prefix}" )
      suffix="${fcst_mn}"
      filenames=( "${filenames[@]/%/$suffix}" )
      ;;

    *)
      print_err_msg_exit "\
The external model file names have not yet been specified for this com-
bination of external model (extrn_mdl) and analysis or forecast (anl_-
or_fcst):
  extrn_mdl = \"$extrn_mdl\"
  anl_or_fcst = \"$anl_or_fcst\"
"
      ;;

    esac
    ;;

  esac
#
#-----------------------------------------------------------------------
#
# Set the system directory (i.e. a directory on disk) in which the ex-
# ternal model output files for the specified cycle date (cdate) may be
# located.  Note that this will be used by the calling script only if 
# the output files for the specified cdate actually exist at this loca-
# tion.  Otherwise, the files will be searched for on the mass store
# (HPSS).
#
#-----------------------------------------------------------------------
#
  if [ "$anl_or_fcst" = "ANL" ]; then
    sysbasedir="$EXTRN_MDL_FILES_SYSBASEDIR_ICSSURF"
  elif [ "$anl_or_fcst" = "FCST" ]; then
    sysbasedir="$EXTRN_MDL_FILES_SYSBASEDIR_LBCS"
  fi

  case "$extrn_mdl" in

  "GFS")
    case "$MACHINE" in
    "WCOSS_C")
      sysdir="$sysbasedir/gfs.${yyyymmdd}"
      ;;
    "THEIA")
      sysdir="$sysbasedir/gfs.${yyyymmdd}/${hh}"
      ;;
    "JET")
      sysdir="$sysbasedir/${yyyymmdd}"
      ;;
    "ODIN")
      sysdir="$sysbasedir/${yyyymmdd}"
      ;;
    *)
      print_err_msg_exit "\
The system directory in which to look for external model output files 
has not been specified for this external model and machine combination:
  extrn_mdl = \"$extrn_mdl\"
  MACHINE = \"$MACHINE\"
"
      ;;
    esac
    ;;

  "RAPX")
    case "$MACHINE" in
    "WCOSS_C")
      sysdir="$sysbasedir"
      ;;
    "THEIA")
      sysdir="$sysbasedir"
      ;;
    "JET")
      sysdir="$sysbasedir"
      ;;
    "ODIN")
      sysdir="$sysbasedir"
      ;;
    *)
      print_err_msg_exit "\
The system directory in which to look for external model output files 
has not been specified for this external model and machine combination:
  extrn_mdl = \"$extrn_mdl\"
  MACHINE = \"$MACHINE\"
"
      ;;
    esac
    ;;

  "HRRRX")
    case "$MACHINE" in
    "WCOSS_C")
      sysdir="$sysbasedir"
      ;;
    "THEIA")
      sysdir="$sysbasedir"
      ;;
    "JET")
      sysdir="$sysbasedir"
      ;;
    "ODIN")
      sysdir="$sysbasedir"
      ;;
    *)
      print_err_msg_exit "\
The system directory in which to look for external model output files 
has not been specified for this external model and machine combination:
  extrn_mdl = \"$extrn_mdl\"
  MACHINE = \"$MACHINE\"
"
      ;;
    esac
    ;;

  *)
    print_err_msg_exit "\
The system directory in which to look for external model output files 
has not been specified for this external model:
  extrn_mdl = \"$extrn_mdl\"
"

  esac
#
#-----------------------------------------------------------------------
#
# Set parameters related to the mass store (HPSS) for the specified cy-
# cle date (cdate).  These consist of:
#
# 1) The type of the archive file (e.g. tar, zip, etc).
# 2) The name of the archive file.
# 3) The full path in HPSS to the archive file.
# 4) The relative directory in the archive file in which the module out-
#    put files are located.
#
# Note that these will be used by the calling script only if the archive
# file for the specified cdate actually exists on HPSS.
#
#-----------------------------------------------------------------------
#
  case "$extrn_mdl" in

  "GFS")
    arcv_dir="/NCEPPROD/hpssprod/runhistory/rh${yyyy}/${yyyy}${mm}/${yyyymmdd}"
    arcv_file_fmt="tar"
    arcv_filename="gpfs_hps_nco_ops_com_gfs_prod_gfs.${cdate}."
    if [ "$anl_or_fcst" = "ANL" ]; then
      arcv_filename="${arcv_filename}anl"
      arcvrel_dir="."
    elif [ "$anl_or_fcst" = "FCST" ]; then
      arcv_filename="${arcv_filename}sigma"
      arcvrel_dir="/gpfs/hps/nco/ops/com/gfs/prod/gfs.${yyyymmdd}"
    fi
    arcv_filename="${arcv_filename}.${arcv_file_fmt}"
    arcv_fullpath="$arcv_dir/$arcv_filename"
    ;;

  "RAPX")
    arcv_dir="/BMC/fdr/Permanent/${yyyy}/${mm}/${dd}/data/fsl/rap/full/wrfnat"
    arcv_file_fmt="zip"
    arcv_filename="${yyyy}${mm}${dd}${hh}00.${arcv_file_fmt}"
    arcv_fullpath="$arcv_dir/$arcv_filename"
    arcvrel_dir=""
    ;;

  "HRRRX")
    arcv_dir="/BMC/fdr/Permanent/${yyyy}/${mm}/${dd}/data/fsl/hrrr/conus/wrfnat"
    arcv_file_fmt="zip"
    arcv_filename="${yyyy}${mm}${dd}${hh}00.${arcv_file_fmt}"
    arcv_fullpath="$arcv_dir/$arcv_filename"
    arcvrel_dir=""
    ;;

  *)
    print_err_msg_exit "\
Archive file information has not been specified for this external model:
  extrn_mdl = \"$extrn_mdl\"
"
    ;;

  esac
#
#-----------------------------------------------------------------------
#
# Write results to the specified output file in a form that can be 
# sourced by the calling script.
#
#-----------------------------------------------------------------------
#
echo "HELLO1111"
pwd
ls -alF
echo "HELLO2222"
  { cat << EOM > $output_fn
$glob_var_name_cdate="$cdate"
$glob_var_name_lbc_update_fhrs=( $( printf "\"%s\" " "${lbc_update_fhrs[@]}" ))
$glob_var_name_filenames=( $( printf "\"%s\" " "${filenames[@]}" ))
$glob_var_name_sysdir="$sysdir"
$glob_var_name_arcv_file_fmt="$arcv_file_fmt"
$glob_var_name_arcv_filename="$arcv_filename"
$glob_var_name_arcv_fullpath="$arcv_fullpath"
$glob_var_name_arcvrel_dir="$arcvrel_dir"
EOM
 } || print_err_msg_exit "\
Heredoc (cat) command to store output variable values to file returned 
with a nonzero status.
"
echo "HELLO3333"
pwd
ls -alF
echo "HELLO4444"
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
