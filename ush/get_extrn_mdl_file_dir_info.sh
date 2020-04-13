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
# This file defines a function that is used to obtain information (e.g.
# output file names, system and mass store file and/or directory names)
# for a specified external model, analysis or forecast, and cycle date.
# See the usage statement below for this function should be called and
# the definitions of the input parameters.
# 
#-----------------------------------------------------------------------
#
function get_extrn_mdl_file_dir_info() {
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
# Specify the set of valid argument names for this script/function.  
# Then process the arguments provided to this script/function (which 
# should consist of a set of name-value pairs of the form arg1="value1",
# etc).
#
#-----------------------------------------------------------------------
#
  local valid_args=( \
    "extrn_mdl_name" "anl_or_fcst" "cdate_FV3SAR" "time_offset_hrs" \
    "varname_extrn_mdl_cdate" \
    "varname_extrn_mdl_lbc_update_fhrs" \
    "varname_extrn_mdl_fns" \
    "varname_extrn_mdl_sysdir" \
    "varname_extrn_mdl_arcv_fmt" \
    "varname_extrn_mdl_arcv_fns" \
    "varname_extrn_mdl_arcv_fps" \
    "varname_extrn_mdl_arcvrel_dir" \
  )
  process_args valid_args "$@"
#
#-----------------------------------------------------------------------
#
# For debugging purposes, print out values of arguments passed to this
# script/function.  Note that these will be printed out only if VERBOSE
# is set to TRUE.
#
#-----------------------------------------------------------------------
#
  print_input_args valid_args
#
#-----------------------------------------------------------------------
#
# Check arguments.
#
#-----------------------------------------------------------------------
#
if [ 0 = 1 ]; then

  if [ "$#" -ne "13" ]; then

    print_err_msg_exit "
Incorrect number of arguments specified:

  Function name:  \"${func_name}\"
  Number of arguments specified:  $#

Usage:

  ${func_name} \
    extrn_mdl_name \
    anl_or_fcst \
    cdate_FV3SAR \
    time_offset_hrs \
    varname_extrn_mdl_cdate \
    varname_extrn_mdl_lbc_update_fhrs \
    varname_extrn_mdl_fns \
    varname_extrn_mdl_sysdir \
    varname_extrn_mdl_arcv_fmt \
    varname_extrn_mdl_arcv_fns \
    varname_extrn_mdl_arcv_fps \
    varname_extrn_mdl_arcvrel_dir

where the arguments are defined as follows:
 
  extrn_mdl_name:
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
 
  varname_extrn_mdl_cdate:
  Name of the global variable that will contain the starting date and 
  hour of the external model run.
 
  varname_extrn_mdl_lbc_update_fhrs:
  Name of the global variable that will contain the forecast hours (re-
  lative to the starting time of the external model run, which is earli-
  er than that of the FV3SAR by time_offset_hrs hours) at which lateral
  boundary condition (LBC) output files are obtained from the external
  model (and will be used to update the LBCs of the FV3SAR).
 
  varname_extrn_mdl_fns:
  Name of the global variable that will contain the names of the exter-
  nal model output files.
 
  varname_extrn_mdl_sysdir:
  Name of the global variable that will contain the system directory in
  which the externaml model output files may be stored.
 
  varname_extrn_mdl_arcv_fmt:
  Name of the global variable that will contain the format of the ar-
  chive file on HPSS in which the externaml model output files may be 
  stored.
 
  varname_extrn_mdl_arcv_fns:
  Name of the global variable that will contain the name of the archive
  file on HPSS in which the externaml model output files may be stored.
 
  varname_extrn_mdl_arcv_fps:
  Name of the global variable that will contain the full path to the ar-
  chive file on HPSS in which the externaml model output files may be 
  stored.
 
  varname_extrn_mdl_arcvrel_dir:
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
  local extrn_mdl_name="${!iarg}"
  iarg=$(( iarg+1 ))
  local anl_or_fcst="${!iarg}"
  iarg=$(( iarg+1 ))
  local cdate_FV3SAR="${!iarg}"
  iarg=$(( iarg+1 ))
  local time_offset_hrs="${!iarg}"

  iarg=$(( iarg+1 ))
  local varname_extrn_mdl_cdate="${!iarg}"
  iarg=$(( iarg+1 ))
  local varname_extrn_mdl_lbc_update_fhrs="${!iarg}"
  iarg=$(( iarg+1 ))
  local varname_extrn_mdl_fns="${!iarg}"
  iarg=$(( iarg+1 ))
  local varname_extrn_mdl_sysdir="${!iarg}"
  iarg=$(( iarg+1 ))
  local varname_extrn_mdl_arcv_fmt="${!iarg}"
  iarg=$(( iarg+1 ))
  local varname_extrn_mdl_arcv_fns="${!iarg}"
  iarg=$(( iarg+1 ))
  local varname_extrn_mdl_arcv_fps="${!iarg}"
  iarg=$(( iarg+1 ))
  local varname_extrn_mdl_arcvrel_dir="${!iarg}"


fi


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
        fns prefix suffix \
        sysbasedir sysdir \
        arcv_dir arcv_fmt arcv_fns arcv_fps arcvrel_dir
#
#-----------------------------------------------------------------------
#
# Check input variables for valid values.
#
#-----------------------------------------------------------------------
#
  valid_vals_anl_or_fcst=( "ANL" "anl" "FCST" "fcst" )
  check_var_valid_value "anl_or_fcst" "valid_vals_anl_or_fcst"
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

  if [ "${anl_or_fcst}" = "FCST" ]; then

    lbc_update_fhrs=( "${LBC_UPDATE_FCST_HRS[@]}" )
#
# Add the temporal offset specified in time_offset_hrs (assumed to be in 
# units of hours) to the the array of LBC update forecast hours to make
# up for shifting the starting hour back in time.  After this addition,
# lbc_update_fhrs will contain the LBC update forecast hours relative to
# the start time of the external model run.
#
    num_fhrs=${#lbc_update_fhrs[@]}
    for (( i=0; i<=$((num_fhrs-1)); i++ )); do
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
  if [ "${extrn_mdl_name}" = "RAPX" ] || \
     [ "${extrn_mdl_name}" = "HRRRX" ] || \
     [ "${extrn_mdl_name}" = "FV3GFS" -a "${MACHINE}" = "JET" ]; then
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
  if [ "${anl_or_fcst}" = "ANL" ]; then
    fv3gfs_file_fmt="${FV3GFS_FILE_FMT_ICS}"
  elif [ "${anl_or_fcst}" = "FCST" ]; then
    fv3gfs_file_fmt="${FV3GFS_FILE_FMT_LBCS}"
  fi

  case "${anl_or_fcst}" in
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

    case "${extrn_mdl_name}" in

    "GSMGFS")
#      fns=( "atm" "sfc" "nst" )
      fns=( "atm" "sfc" )
      prefix="gfs.t${hh}z."
      fns=( "${fns[@]/#/$prefix}" )
      suffix="anl.nemsio"
      fns=( "${fns[@]/%/$suffix}" )
      ;;

    "FV3GFS")
    
      if [ "${fv3gfs_file_fmt}" = "nemsio" ]; then  

#        fns=( "atm" "sfc" "nst" )
        fns=( "atm" "sfc" )
        if [ "${MACHINE}" = "JET" ]; then
          prefix="${yy}${ddd}${hh}00.gfs.t${hh}z."
        else
          prefix="gfs.t${hh}z."
        fi
        fns=( "${fns[@]/#/$prefix}" )
        suffix="anl.nemsio"
        fns=( "${fns[@]/%/$suffix}" )

      elif [ "${fv3gfs_file_fmt}" = "grib2" ]; then

# GSK 12/16/2019:
# Turns out that the .f000 file contains certain necessary fields that
# are not in the .anl file, so switch to the former.
#        fns=( "gfs.t${hh}z.pgrb2.0p25.anl" )  # Get only 0.25 degree files for now.
        fns=( "gfs.t${hh}z.pgrb2.0p25.f000" )  # Get only 0.25 degree files for now.

      fi
      ;;
  
    "RAPX")
      if [ "${MACHINE}" = "JET" ]; then
        fns=( "wrfnat_130_${fcst_hh}.grib2" )
      else
        fns=( "${yy}${ddd}${hh}${mn}${fcst_hh}${fcst_mn}" )
      fi
      ;;

    "HRRRX")
      if [ "${MACHINE}" = "JET" ]; then
        fns=( "wrfnat_hrconus_${fcst_hh}.grib2" )
      else
        fns=( "${yy}${ddd}${hh}${mn}${fcst_hh}${fcst_mn}" )
      fi
      ;;

    *)
      print_err_msg_exit "\
The external model file names have not yet been specified for this com-
bination of external model (extrn_mdl_name) and analysis or forecast 
(anl_or_fcst):
  extrn_mdl_name = \"${extrn_mdl_name}\"
  anl_or_fcst = \"${anl_or_fcst}\""
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

    case "${extrn_mdl_name}" in

    "GSMGFS")
      fcst_hhh=( $( printf "%03d " "${lbc_update_fhrs[@]}" ) )
      prefix="gfs.t${hh}z.atmf"
      fns=( "${fcst_hhh[@]/#/$prefix}" )
      suffix=".nemsio"
      fns=( "${fns[@]/%/$suffix}" )
      ;;

    "FV3GFS")
      if [ "${fv3gfs_file_fmt}" = "nemsio" ]; then
        fcst_hhh=( $( printf "%03d " "${lbc_update_fhrs[@]}" ) )
        if [ "${MACHINE}" = "JET" ]; then
          prefix="${yy}${ddd}${hh}00.gfs.t${hh}z.atmf"
        else
          prefix="gfs.t${hh}z.atmf"
        fi
        fns=( "${fcst_hhh[@]/#/$prefix}" )
        suffix=".nemsio"
        fns=( "${fns[@]/%/$suffix}" )
      elif [ "${fv3gfs_file_fmt}" = "grib2" ]; then
        fcst_hhh=( $( printf "%03d " "${lbc_update_fhrs[@]}" ) )
        prefix="gfs.t${hh}z.pgrb2.0p25.f"
        fns=( "${fcst_hhh[@]/#/$prefix}" )
      fi
      ;;

    "RAPX")
      fcst_hh=( $( printf "%02d " "${lbc_update_fhrs[@]}" ) )
      if [ "${MACHINE}" = "JET" ]; then 
        prefix="wrfnat_130_"
      else
        prefix="${yy}${ddd}${hh}${mn}"
      fi
      fns=( "${fcst_hh[@]/#/$prefix}" )
      if [ "${MACHINE}" = "JET" ]; then
        suffix=".grib2"
      else
        suffix="${fcst_mn}"
      fi
      fns=( "${fns[@]/%/$suffix}" )
      ;;

    "HRRRX")
      fcst_hh=( $( printf "%02d " "${lbc_update_fhrs[@]}" ) )
      if [ "${MACHINE}" = "JET" ]; then
        prefix="wrfnat_hrconus_"
      else
        prefix="${yy}${ddd}${hh}${mn}"
      fi
      fns=( "${fcst_hh[@]/#/$prefix}" )
      if [ "${MACHINE}" = "JET" ]; then
        suffix=".grib2"
      else
        suffix="${fcst_mn}"
      fi
      fns=( "${fns[@]/%/$suffix}" )
      ;;

    *)
      print_err_msg_exit "\
The external model file names have not yet been specified for this com-
bination of external model (extrn_mdl_name) and analysis or forecast 
(anl_or_fcst):
  extrn_mdl_name = \"${extrn_mdl_name}\"
  anl_or_fcst = \"${anl_or_fcst}\""
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
  if [ "${anl_or_fcst}" = "ANL" ]; then
    sysbasedir="${EXTRN_MDL_FILES_SYSBASEDIR_ICS}"
  elif [ "${anl_or_fcst}" = "FCST" ]; then
    sysbasedir="${EXTRN_MDL_FILES_SYSBASEDIR_LBCS}"
  fi

  case "${extrn_mdl_name}" in

#
# It is not clear which, if any, systems the (old) spectral GFS model is 
# available on, so set sysdir for this external model to a null string.
#
  "GSMGFS")
    case "$MACHINE" in
    "WCOSS_C")
      sysdir=""
      ;;
    "THEIA")
      sysdir=""
      ;;
    "HERA")
      sysdir=""
      ;;
    "JET")
      sysdir=""
      ;;
    "ODIN")
      sysdir=""
      ;;
    "CHEYENNE")
      sysdir=""
      ;;
    *)
      print_err_msg_exit "\
The system directory in which to look for external model output files 
has not been specified for this external model and machine combination:
  extrn_mdl_name = \"${extrn_mdl_name}\"
  MACHINE = \"$MACHINE\""
      ;;
    esac
    ;;


  "FV3GFS")
    case "$MACHINE" in
    "WCOSS_C")
      sysdir="$sysbasedir/gfs.${yyyymmdd}"
      ;;
    "THEIA")
      sysdir="$sysbasedir/gfs.${yyyymmdd}/${hh}"
      ;;
    "HERA")
      sysdir="$sysbasedir/gfs.${yyyymmdd}/${hh}"
      ;;
    "JET")
      sysdir="$sysbasedir"
      ;;
    "ODIN")
      sysdir="$sysbasedir/${yyyymmdd}"
      ;;
    "CHEYENNE")
      sysdir="$sysbasedir/gfs.${yyyymmdd}/${hh}"
      ;;
    *)
      print_err_msg_exit "\
The system directory in which to look for external model output files 
has not been specified for this external model and machine combination:
  extrn_mdl_name = \"${extrn_mdl_name}\"
  MACHINE = \"$MACHINE\""
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
    "HERA")
      sysdir="$sysbasedir"
      ;;
    "JET")
      sysdir="$sysbasedir/${yyyymmdd}${hh}/postprd"
      ;;
    "ODIN")
      sysdir="$sysbasedir"
      ;;
    "CHEYENNE")
      sysdir="$sysbasedir"
      ;;
    *)
      print_err_msg_exit "\
The system directory in which to look for external model output files 
has not been specified for this external model and machine combination:
  extrn_mdl_name = \"${extrn_mdl_name}\"
  MACHINE = \"$MACHINE\""
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
    "HERA")
      sysdir="$sysbasedir"
      ;;
    "JET")
      sysdir="$sysbasedir/${yyyymmdd}${hh}/postprd"
      ;;
    "ODIN")
      sysdir="$sysbasedir"
      ;;
    "CHEYENNE")
      sysdir="$sysbasedir"
      ;;
    *)
      print_err_msg_exit "\
The system directory in which to look for external model output files 
has not been specified for this external model and machine combination:
  extrn_mdl_name = \"${extrn_mdl_name}\"
  MACHINE = \"$MACHINE\""
      ;;
    esac
    ;;


  *)
    print_err_msg_exit "\
The system directory in which to look for external model output files 
has not been specified for this external model:
  extrn_mdl_name = \"${extrn_mdl_name}\""

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
  case "${extrn_mdl_name}" in

  "GSMGFS")
    arcv_dir="/NCEPPROD/hpssprod/runhistory/rh${yyyy}/${yyyy}${mm}/${yyyymmdd}"
    arcv_fmt="tar"
    arcv_fns="gpfs_hps_nco_ops_com_gfs_prod_gfs.${cdate}."
    if [ "${anl_or_fcst}" = "ANL" ]; then
      arcv_fns="${arcv_fns}anl"
      arcvrel_dir="."
    elif [ "${anl_or_fcst}" = "FCST" ]; then
      arcv_fns="${arcv_fns}sigma"
      arcvrel_dir="/gpfs/hps/nco/ops/com/gfs/prod/gfs.${yyyymmdd}"
    fi
    arcv_fns="${arcv_fns}.${arcv_fmt}"
    arcv_fps="$arcv_dir/$arcv_fns"
    ;;

  "FV3GFS")
    if [ "${fv3gfs_file_fmt}" = "nemsio" ]; then
 
      if [ "${cdate_FV3SAR}" -le "2019061206" ]; then
        arcv_dir="/NCEPDEV/emc-global/5year/emc.glopara/WCOSS_C/Q2FY19/prfv3rt3/${cdate_FV3SAR}"
        arcv_fns=""
      else
        arcv_dir="/NCEPPROD/hpssprod/runhistory/rh${yyyy}/${yyyy}${mm}/${yyyymmdd}"
        arcv_fns="gpfs_dell1_nco_ops_com_gfs_prod_gfs.${yyyymmdd}_${hh}."
      fi
      arcv_fmt="tar"
      if [ "${anl_or_fcst}" = "ANL" ]; then
        arcv_fns="${arcv_fns}gfs_nemsioa"
        arcvrel_dir="./gfs.${yyyymmdd}/${hh}"
      elif [ "${anl_or_fcst}" = "FCST" ]; then
        last_fhr_in_nemsioa="39"
        first_lbc_fhr="${lbc_update_fhrs[0]}"
        last_lbc_fhr="${lbc_update_fhrs[-1]}"
        if [ "${last_lbc_fhr}" -le "${last_fhr_in_nemsioa}" ]; then
          arcv_fns="${arcv_fns}gfs_nemsioa"
        elif [ "${first_lbc_fhr}" -gt "${last_fhr_in_nemsioa}" ]; then
          arcv_fns="${arcv_fns}gfs_nemsiob"
        else
          arcv_fns=( "${arcv_fns}gfs_nemsioa" "${arcv_fns}gfs_nemsiob" )
        fi
        arcvrel_dir="./gfs.${yyyymmdd}/${hh}"
      fi

    elif [ "${fv3gfs_file_fmt}" = "grib2" ]; then

      arcv_dir="/NCEPPROD/hpssprod/runhistory/rh${yyyy}/${yyyy}${mm}/${yyyymmdd}"
      arcv_fns="gpfs_dell1_nco_ops_com_gfs_prod_gfs.${yyyymmdd}_${hh}.gfs_pgrb2"
      arcv_fmt="tar"
      arcvrel_dir="./gfs.${yyyymmdd}/${hh}"
  
    fi

    is_array arcv_fns
    if [ "$?" = "0" ]; then
      suffix=".${arcv_fmt}"
      arcv_fns=( "${arcv_fns[@]/%/$suffix}" )
      prefix="$arcv_dir/"
      arcv_fps=( "${arcv_fns[@]/#/$prefix}" )
    else
      arcv_fns="${arcv_fns}.${arcv_fmt}"
      arcv_fps="$arcv_dir/$arcv_fns"
    fi
    ;;

  "RAPX")
#
# The zip archive files for RAPX are named such that the forecast files
# for odd-numbered starting hours (e.g. 01, 03, ..., 23) are stored to-
# gether with the forecast files for the corresponding preceding even-
# numbered starting hours (e.g. 00, 02, ..., 22, respectively), in an 
# archive file whose name contains only the even-numbered hour.  Thus, 
# in forming the name of the archive file, if the starting hour (hh) is
# odd, we reduce it by one to get the corresponding even-numbered hour 
# and use that to form the archive file name.
#
    hh_orig=$hh
# Convert hh to a decimal (i.e. base-10) number.  We need this because 
# if it starts with a 0 (e.g. 00, 01, ..., 09), bash will treat it as an
# octal number, and 08 and 09 are illegal ocatal numbers for which the
# arithmetic operations below will fail.
    hh=$((10#$hh))
    if [ $(($hh%2)) = 1 ]; then
      hh=$((hh-1))
    fi
# Now that the arithmetic is done, recast hh as a two-digit string be-
# cause that is needed in constructing the names below.
    hh=$( printf "%02d\n" $hh )

    arcv_dir="/BMC/fdr/Permanent/${yyyy}/${mm}/${dd}/data/fsl/rap/full/wrfnat"
    arcv_fmt="zip"
    arcv_fns="${yyyy}${mm}${dd}${hh}00.${arcv_fmt}"
    arcv_fps="$arcv_dir/$arcv_fns"
    arcvrel_dir=""
#
# Reset hh to its original value in case it is used again later below.
#
    hh=${hh_orig}
    ;;

  "HRRRX")
    arcv_dir="/BMC/fdr/Permanent/${yyyy}/${mm}/${dd}/data/fsl/hrrr/conus/wrfnat"
    arcv_fmt="zip"
    arcv_fns="${yyyy}${mm}${dd}${hh}00.${arcv_fmt}"
    arcv_fps="$arcv_dir/$arcv_fns"
    arcvrel_dir=""
    ;;

  *)
    print_err_msg_exit "\
Archive file information has not been specified for this external model:
  extrn_mdl_name = \"${extrn_mdl_name}\""
    ;;

  esac
#
# Depending on the experiment configuration, the above code may set 
# arcv_fns and arcv_fps to either scalars or arrays.  If they are not 
# arrays, recast them as arrays because that is what is expected in the
# code below.
#
  is_array arcv_fns || arcv_fns=( "${arcv_fns}" )
  is_array arcv_fps || arcv_fps=( "${arcv_fps}" )
#
#-----------------------------------------------------------------------
#
# Use the eval function to set values of output variables.
#
#-----------------------------------------------------------------------
#
  lbc_update_fhrs_str="( "$( printf "\"%s\" " "${lbc_update_fhrs[@]}" )")"
  fns_str="( "$( printf "\"%s\" " "${fns[@]}" )")"
  arcv_fns_str="( "$( printf "\"%s\" " "${arcv_fns[@]}" )")"
  arcv_fps_str="( "$( printf "\"%s\" " "${arcv_fps[@]}" )")"

  eval ${varname_extrn_mdl_cdate}="${cdate}"
  eval ${varname_extrn_mdl_lbc_update_fhrs}=${lbc_update_fhrs_str}
  eval ${varname_extrn_mdl_fns}=${fns_str}
  eval ${varname_extrn_mdl_sysdir}="${sysdir}"
  eval ${varname_extrn_mdl_arcv_fmt}="${arcv_fmt}"
  eval ${varname_extrn_mdl_arcv_fns}=${arcv_fns_str}
  eval ${varname_extrn_mdl_arcv_fps}=${arcv_fps_str}
  eval ${varname_extrn_mdl_arcvrel_dir}="${arcvrel_dir}"
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
