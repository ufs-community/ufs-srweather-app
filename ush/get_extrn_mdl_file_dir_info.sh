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
# Specify the set of valid argument names for this script/function.  Then 
# process the arguments provided to this script/function (which should 
# consist of a set of name-value pairs of the form arg1="value1", etc).
#
#-----------------------------------------------------------------------
#
  local valid_args=( \
    "extrn_mdl_name" \
    "anl_or_fcst" \
    "cdate_FV3LAM" \
    "time_offset_hrs" \
    "varname_extrn_mdl_cdate" \
    "varname_extrn_mdl_lbc_spec_fhrs" \
    "varname_extrn_mdl_fns_on_disk" \
    "varname_extrn_mdl_fns_in_arcv" \
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
    cdate_FV3LAM \
    time_offset_hrs \
    varname_extrn_mdl_cdate \
    varname_extrn_mdl_lbc_spec_fhrs \
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
  and/or lateral boundary conditions for the FV3-LAM will be generated.

  anl_or_fcst:
  Flag that specifies whether the external model files we are interested
  in obtaining are analysis or forecast files.

  cdate_FV3LAM:
  The cycle date and time (hours only) for which we want to obtain file
  and directory information.  This has the form YYYYMMDDHH, where YYYY
  is the four-digit starting year of the cycle, MM is the two-digit
  month, DD is the two-digit day of the month, and HH is the two-digit
  hour of day.

  time_offset_hrs:
  The number of hours by which to shift back in time the start time of
  the external model forecast from the specified cycle start time of the
  FV3-LAM (cdate_FV3LAM).  When getting directory and file information on
  external model analysis files, this is normally set to 0.  When get-
  ting directory and file information on external model forecast files,
  this may be set to a nonzero value to obtain information for an exter-
  nal model run that started time_offset_hrs hours before cdate_FV3LAM
  (instead of exactly at cdate_FV3LAM).  Note that in this case, the
  forecast hours (relative to the external model run's start time) at
  which the lateral boundary conditions will be updated must be shifted
  forward by time_offset_hrs hours relative to those for the FV3-LAM in
  order to make up for the backward-in-time shift in the starting time
  of the external model.

  varname_extrn_mdl_cdate:
  Name of the global variable that will contain the starting date and
  hour of the external model run.

  varname_extrn_mdl_lbc_spec_fhrs:
  Name of the global variable that will contain the forecast hours (re-
  lative to the starting time of the external model run, which is earli-
  er than that of the FV3-LAM by time_offset_hrs hours) at which lateral
  boundary condition (LBC) output files are obtained from the external
  model (and will be used to update the LBCs of the FV3-LAM).

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

fi


#
#-----------------------------------------------------------------------
#
# Declare additional local variables.
#
#-----------------------------------------------------------------------
#
  local yyyy mm dd hh mn yyyymmdd \
        lbc_spec_fhrs i num_fhrs \
        yy ddd fcst_hhh fcst_hh fcst_mn \
        prefix suffix fns fns_on_disk fns_in_arcv \
        sysbasedir sysdir \
        arcv_dir arcv_fmt arcv_fns arcv_fps arcvrel_dir
#
#-----------------------------------------------------------------------
#
# Check input variables for valid values.
#
#-----------------------------------------------------------------------
#
  anl_or_fcst="${anl_or_fcst^^}"
  valid_vals_anl_or_fcst=( "ANL" "FCST" )
  check_var_valid_value "anl_or_fcst" "valid_vals_anl_or_fcst"
#
#-----------------------------------------------------------------------
#
# Extract from cdate_FV3LAM the starting year, month, day, and hour of 
# the FV3-LAM cycle.  Then subtract the temporal offset specified in 
# time_offset_hrs (assumed to be given in units of hours) from cdate_FV3LAM
# to obtain the starting date and time of the external model, express the 
# result in YYYYMMDDHH format, and save it in cdate.  This is the starting 
# time of the external model forecast.
#
#-----------------------------------------------------------------------
#
  yyyy=${cdate_FV3LAM:0:4}
  mm=${cdate_FV3LAM:4:2}
  dd=${cdate_FV3LAM:6:2}
  hh=${cdate_FV3LAM:8:2}
  yyyymmdd=${cdate_FV3LAM:0:8}

  cdate=$( date --utc --date "${yyyymmdd} ${hh} UTC - ${time_offset_hrs} hours" "+%Y%m%d%H" )
#
#-----------------------------------------------------------------------
#
# Extract from cdate the starting year, month, day, and hour of the external 
# model forecast.  Also, set the starting minute to "00" and get the date
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
# Initialize lbc_spec_fhrs to an empty array.  Then, if considering a
# forecast, reset lbc_spec_fhrs to the array of forecast hours at which 
# the lateral boundary conditions (LBCs) are to be updated, starting with 
# the 2nd such time (i.e. the one having array index 1).  We do not include 
# the first hour (hour 0) because at this initial time, the LBCs are 
# obtained from the analysis fields provided by the external model (as 
# opposed to a forecast field).
#
#-----------------------------------------------------------------------
#
  lbc_spec_fhrs=( "" )

  if [ "${anl_or_fcst}" = "FCST" ]; then

    lbc_spec_fhrs=( "${LBC_SPEC_FCST_HRS[@]}" )
#
# Add the temporal offset specified in time_offset_hrs (assumed to be in 
# units of hours) to the the array of LBC update forecast hours to make
# up for shifting the starting hour back in time.  After this addition,
# lbc_spec_fhrs will contain the LBC update forecast hours relative to
# the start time of the external model run.
#
    num_fhrs=${#lbc_spec_fhrs[@]}
    for (( i=0; i<=$((num_fhrs-1)); i++ )); do
      lbc_spec_fhrs[$i]=$(( ${lbc_spec_fhrs[$i]} + time_offset_hrs ))
    done

  fi
#
#-----------------------------------------------------------------------
#
# Set additional parameters needed in forming the names of the external
# model files only under certain circumstances.
#
#-----------------------------------------------------------------------
#
  if [ "${extrn_mdl_name}" = "RAP" ] || \
     [ "${extrn_mdl_name}" = "HRRR" ] || \
     [ "${extrn_mdl_name}" = "NAM" ] || \
     [ "${extrn_mdl_name}" = "FV3GFS" -a "${MACHINE}" = "JET" ]; then
#
# Get the Julian day-of-year of the starting date and time of the exter-
# nal model forecast.
#
    ddd=$( date --utc --date "${yyyy}-${mm}-${dd} ${hh}:${mn} UTC" "+%j" )
#
# Get the last two digits of the year of the starting date and time of 
# the external model forecast.
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
      fns_on_disk=( "${fns[@]/%/$suffix}" )
      fns_in_arcv=( "${fns[@]/%/$suffix}" )
      ;;

    "FV3GFS")

      if [ "${fv3gfs_file_fmt}" = "nemsio" ]; then

        fns=( "atm" "sfc" )
        suffix="anl.nemsio"
        fns=( "${fns[@]/%/$suffix}" )

# Set names of external files if searching on disk.
        if [ "${MACHINE}" = "JET" ]; then
          prefix="${yy}${ddd}${hh}00.gfs.t${hh}z."
        else
          prefix="gfs.t${hh}z."
        fi
        fns_on_disk=( "${fns[@]/#/$prefix}" )

# Set names of external files if searching in an archive file, e.g. from
# HPSS.
        prefix="gfs.t${hh}z."
        fns_in_arcv=( "${fns[@]/#/$prefix}" )

      elif [ "${fv3gfs_file_fmt}" = "grib2" ]; then

# GSK 12/16/2019:
# Turns out that the .f000 file contains certain necessary fields that
# are not in the .anl file, so switch to the former.
#        fns=( "gfs.t${hh}z.pgrb2.0p25.anl" )  # Get only 0.25 degree files for now.
#        fns=( "gfs.t${hh}z.pgrb2.0p25.f000" )  # Get only 0.25 degree files for now.
        fns_on_disk=( "gfs.t${hh}z.pgrb2.0p25.f000" )  # Get only 0.25 degree files for now.
        fns_in_arcv=( "gfs.t${hh}z.pgrb2.0p25.f000" )  # Get only 0.25 degree files for now.
     
      elif [ "${fv3gfs_file_fmt}" = "netcdf" ]; then

        fns=( "atm" "sfc" )
        suffix="anl.nc"
        fns=( "${fns[@]/%/$suffix}" )

# Set names of external files if searching on disk.
        if [ "${MACHINE}" = "JET" ]; then
          prefix="${yy}${ddd}${hh}00.gfs.t${hh}z."
        else
          prefix="gfs.t${hh}z."
        fi
        fns_on_disk=( "${fns[@]/#/$prefix}" )

# Set names of external files if searching in an archive file, e.g. from
# HPSS.
        prefix="gfs.t${hh}z."
        fns_in_arcv=( "${fns[@]/#/$prefix}" )

      fi
      ;;

    "RAP")
#
# Note that this is GSL RAPX data, not operational NCEP RAP data.  An option for the latter
# may be added in the future.
#
      if [ "${MACHINE}" = "JET" ]; then
        fns_on_disk=( "wrfnat_130_${fcst_hh}.grib2" )
      else
        fns_on_disk=( "${yy}${ddd}${hh}${mn}${fcst_hh}${fcst_mn}" )
      fi
      fns_in_arcv=( "${yy}${ddd}${hh}${mn}${fcst_hh}${fcst_mn}" )
      ;;

    "HRRR")
#
# Note that this is GSL HRRRX data, not operational NCEP HRRR data.  An option for the latter
# may be added in the future.
#
      if [ "${MACHINE}" = "JET" ]; then
        fns_on_disk=( "wrfnat_hrconus_${fcst_hh}.grib2" )
      else
        fns_on_disk=( "${yy}${ddd}${hh}${mn}${fcst_hh}${fcst_mn}" )
      fi
      fns_in_arcv=( "${yy}${ddd}${hh}${mn}${fcst_hh}${fcst_mn}" )
      ;;

    "NAM")
      fns=( "" )
      prefix="nam.t${hh}z.bgrdsfi${hh}"
      fns=( "${fns[@]/#/$prefix}" )
      suffix=".tm${hh}"
      fns_on_disk=( "${fns[@]/%/$suffix}" )
      fns_in_arcv=( "${fns[@]/%/$suffix}" )
      ;;

    *)
      print_err_msg_exit "\
The external model file names (either on disk or in archive files) have 
not yet been specified for this combination of external model (extrn_mdl_name) 
and analysis or forecast (anl_or_fcst):
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
      fcst_hhh=( $( printf "%03d " "${lbc_spec_fhrs[@]}" ) )
      prefix="gfs.t${hh}z.atmf"
      fns=( "${fcst_hhh[@]/#/$prefix}" )
      suffix=".nemsio"
      fns_on_disk=( "${fns[@]/%/$suffix}" )
      fns_in_arcv=( "${fns[@]/%/$suffix}" )
      ;;

    "FV3GFS")

      if [ "${fv3gfs_file_fmt}" = "nemsio" ]; then

        fcst_hhh=( $( printf "%03d " "${lbc_spec_fhrs[@]}" ) )
        suffix=".nemsio"
        fns=( "${fcst_hhh[@]/%/$suffix}" )

        if [ "${MACHINE}" = "JET" ]; then
          prefix="${yy}${ddd}${hh}00.gfs.t${hh}z.atmf"
        else
          prefix="gfs.t${hh}z.atmf"
        fi
        fns_on_disk=( "${fns[@]/#/$prefix}" )

        prefix="gfs.t${hh}z.atmf"
        fns_in_arcv=( "${fns[@]/#/$prefix}" )

      elif [ "${fv3gfs_file_fmt}" = "grib2" ]; then

        fcst_hhh=( $( printf "%03d " "${lbc_spec_fhrs[@]}" ) )
        prefix="gfs.t${hh}z.pgrb2.0p25.f"
        fns_on_disk=( "${fcst_hhh[@]/#/$prefix}" )
        fns_in_arcv=( "${fcst_hhh[@]/#/$prefix}" )

      elif [ "${fv3gfs_file_fmt}" = "netcdf" ]; then

        fcst_hhh=( $( printf "%03d " "${lbc_spec_fhrs[@]}" ) )
        suffix=".nc"
        fns=( "${fcst_hhh[@]/%/$suffix}" )

        if [ "${MACHINE}" = "JET" ]; then
          prefix="${yy}${ddd}${hh}00.gfs.t${hh}z.atmf"
        else
          prefix="gfs.t${hh}z.atmf"
        fi
        fns_on_disk=( "${fns[@]/#/$prefix}" )

        prefix="gfs.t${hh}z.atmf"
        fns_in_arcv=( "${fns[@]/#/$prefix}" )

      fi
      ;;

    "RAP")
#
# Note that this is GSL RAPX data, not operational NCEP RAP data.  An option for the latter
# may be added in the future.
#
      fcst_hh=( $( printf "%02d " "${lbc_spec_fhrs[@]}" ) )

      if [ "${MACHINE}" = "JET" ]; then 
        prefix="wrfnat_130_"
        suffix=".grib2"
      else
        prefix="${yy}${ddd}${hh}${mn}"
        suffix="${fcst_mn}"
      fi
      fns_on_disk=( "${fcst_hh[@]/#/$prefix}" )
      fns_on_disk=( "${fns_on_disk[@]/%/$suffix}" )

      prefix="${yy}${ddd}${hh}${mn}"
      fns_in_arcv=( "${fcst_hh[@]/#/$prefix}" )
      suffix="${fcst_mn}"
      fns_in_arcv=( "${fns_in_arcv[@]/%/$suffix}" )
      ;;

    "HRRR")
#
# Note that this is GSL HRRRX data, not operational NCEP HRRR data.  An option for the latter
# may be added in the future.
#
      fcst_hh=( $( printf "%02d " "${lbc_spec_fhrs[@]}" ) )

      if [ "${MACHINE}" = "JET" ]; then
        prefix="wrfnat_hrconus_"
        suffix=".grib2"
      else
        prefix="${yy}${ddd}${hh}${mn}"
        suffix="${fcst_mn}"
      fi
      fns_on_disk=( "${fcst_hh[@]/#/$prefix}" )
      fns_on_disk=( "${fns_on_disk[@]/%/$suffix}" )

      prefix="${yy}${ddd}${hh}${mn}"
      fns_in_arcv=( "${fcst_hh[@]/#/$prefix}" )
      suffix="${fcst_mn}"
      fns_in_arcv=( "${fns_in_arcv[@]/%/$suffix}" )
      ;;

    "NAM")
      fcst_hhh=( $( printf "%03d " "${lbc_spec_fhrs[@]}" ) )
      prefix="nam.t${hh}z.bgrdsf"
      fns=( "${fcst_hhh[@]/#/$prefix}" )
      suffix=""
      fns_on_disk=( "${fns[@]/%/$suffix}" )
      fns_in_arcv=( "${fns[@]/%/$suffix}" )
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
# Set the system directory (i.e. a directory on disk) in which the external
# model output files for the specified cycle date (cdate) may be located.
# Note that this will be used by the calling script only if the output
# files for the specified cdate actually exist at this location.  Otherwise,
# the files will be searched for on the mass store (HPSS).
#
#-----------------------------------------------------------------------
#
  if [ "${anl_or_fcst}" = "ANL" ]; then
    sysbasedir="${EXTRN_MDL_SYSBASEDIR_ICS}"
  elif [ "${anl_or_fcst}" = "FCST" ]; then
    sysbasedir="${EXTRN_MDL_SYSBASEDIR_LBCS}"
  fi

  case "${extrn_mdl_name}" in

#
# It is not clear which, if any, systems the (old) spectral GFS model is 
# available on, so set sysdir for this external model to a null string.
#
  "GSMGFS")
    case "$MACHINE" in
    "WCOSS_CRAY")
      sysdir=""
      ;;
    "WCOSS_DELL_P3")
      sysdir=""
      ;;
    "HERA")
      sysdir=""
      ;;
    "ORION")
      sysdir="$sysbasedir"
      ;;
    "JET")
      sysdir=""
      ;;
    "ODIN")
      sysdir="$sysbasedir"
      ;;
    "CHEYENNE")
      sysdir=""
      ;;
    "STAMPEDE")
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


  "FV3GFS")
    case "$MACHINE" in
    "WCOSS_CRAY")
      sysdir="$sysbasedir/gfs.${yyyymmdd}/${hh}/atmos"
      ;;
    "WCOSS_DELL_P3")
      sysdir="$sysbasedir/gfs.${yyyymmdd}/${hh}/atmos"
      ;;
    "HERA")
      sysdir="$sysbasedir/gfs.${yyyymmdd}/${hh}/atmos"
      ;;
    "ORION")
      sysdir="$sysbasedir"
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
    "STAMPEDE")
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


  "RAP")
    case "$MACHINE" in
    "WCOSS_CRAY")
      sysdir="$sysbasedir"
      ;;
    "WCOSS_DELL_P3")
      sysdir="$sysbasedir"
      ;;
    "HERA")
      sysdir="$sysbasedir"
      ;;
    "ORION")
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


  "HRRR")
    case "$MACHINE" in
    "WCOSS_CRAY")
      sysdir="$sysbasedir"
      ;;
    "WCOSS_DELL_P3")
      sysdir="$sysbasedir"
      ;;
    "HERA")
      sysdir="$sysbasedir"
      ;;
    "ORION")
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

  "NAM")
    case "$MACHINE" in
    "WCOSS_CRAY")
      sysdir="$sysbasedir"
      ;;
    "WCOSS_DELL_P3")
      sysdir="$sysbasedir"
      ;;
    "HERA")
      sysdir="$sysbasedir"
      ;;
    "ORION")
      sysdir="$sysbasedir"
      ;;
    "JET")
      sysdir="$sysbasedir"
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
# Set parameters associated with the mass store (HPSS) for the specified 
# cycle date (cdate).  These consist of:
#
# 1) The type of the archive file (e.g. tar, zip, etc).
# 2) The name of the archive file.
# 3) The full path in HPSS to the archive file.
# 4) The relative directory in the archive file in which the model output 
#    files are located.
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
    arcv_fps="${arcv_dir}/${arcv_fns}"
    ;;

  "FV3GFS")

    if [ "${cdate_FV3LAM}" -lt "2019061200" ]; then
      arcv_dir="/NCEPDEV/emc-global/5year/emc.glopara/WCOSS_C/Q2FY19/prfv3rt3/${cdate_FV3LAM}"
      arcv_fns=""
    elif [ "${cdate_FV3LAM}" -ge "2019061200" ] && \
         [ "${cdate_FV3LAM}" -lt "2020022600" ]; then
      arcv_dir="/NCEPPROD/hpssprod/runhistory/rh${yyyy}/${yyyy}${mm}/${yyyymmdd}"
      arcv_fns="gpfs_dell1_nco_ops_com_gfs_prod_gfs.${yyyymmdd}_${hh}."
    elif [ "${cdate_FV3LAM}" -ge "2020022600" ]; then
      arcv_dir="/NCEPPROD/hpssprod/runhistory/rh${yyyy}/${yyyy}${mm}/${yyyymmdd}"
      arcv_fns="com_gfs_prod_gfs.${yyyymmdd}_${hh}."
    fi

    if [ "${fv3gfs_file_fmt}" = "nemsio" ]; then

      if [ "${anl_or_fcst}" = "ANL" ]; then
        arcv_fns="${arcv_fns}gfs_nemsioa"
      elif [ "${anl_or_fcst}" = "FCST" ]; then
        last_fhr_in_nemsioa="39"
        first_lbc_fhr="${lbc_spec_fhrs[0]}"
        last_lbc_fhr="${lbc_spec_fhrs[-1]}"
        if [ "${last_lbc_fhr}" -le "${last_fhr_in_nemsioa}" ]; then
          arcv_fns="${arcv_fns}gfs_nemsioa"
        elif [ "${first_lbc_fhr}" -gt "${last_fhr_in_nemsioa}" ]; then
          arcv_fns="${arcv_fns}gfs_nemsiob"
        else
          arcv_fns=( "${arcv_fns}gfs_nemsioa" "${arcv_fns}gfs_nemsiob" )
        fi
      fi

    elif [ "${fv3gfs_file_fmt}" = "grib2" ]; then

      arcv_fns="${arcv_fns}gfs_pgrb2"

    elif [ "${fv3gfs_file_fmt}" = "netcdf" ]; then

      if [ "${anl_or_fcst}" = "ANL" ]; then
        arcv_fns="${arcv_fns}gfs_nca"
      elif [ "${anl_or_fcst}" = "FCST" ]; then
        last_fhr_in_netcdfa="39"
        first_lbc_fhr="${lbc_spec_fhrs[0]}"
        last_lbc_fhr="${lbc_spec_fhrs[-1]}"
        if [ "${last_lbc_fhr}" -le "${last_fhr_in_netcdfa}" ]; then
          arcv_fns="${arcv_fns}gfs_nca"
        elif [ "${first_lbc_fhr}" -gt "${last_fhr_in_netcdfa}" ]; then
          arcv_fns="${arcv_fns}gfs_ncb"
        else
          arcv_fns=( "${arcv_fns}gfs_nca" "${arcv_fns}gfs_ncb" )
        fi
      fi

    fi

    arcv_fmt="tar"
    
    slash_atmos_or_null=""
    if [ "${cdate_FV3LAM}" -ge "2021032100" ]; then
      slash_atmos_or_null="/atmos"
    fi
    arcvrel_dir="./gfs.${yyyymmdd}/${hh}${slash_atmos_or_null}"
     
    is_array arcv_fns
    if [ "$?" = "0" ]; then
      suffix=".${arcv_fmt}"
      arcv_fns=( "${arcv_fns[@]/%/$suffix}" )
      prefix="${arcv_dir}/"
      arcv_fps=( "${arcv_fns[@]/#/$prefix}" )
    else
      arcv_fns="${arcv_fns}.${arcv_fmt}"
      arcv_fps="${arcv_dir}/${arcv_fns}"
    fi
    ;;


  "RAP")
#
# Note that this is GSL RAPX data, not operational NCEP RAP data.  An option for the latter
# may be added in the future.
#
# The zip archive files for RAPX are named such that the forecast files
# for odd-numbered starting hours (e.g. 01, 03, ..., 23) are stored 
# together with the forecast files for the corresponding preceding even-
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
# Now that the arithmetic is done, recast hh as a two-digit string because
# that is needed in constructing the names below.
    hh=$( printf "%02d\n" $hh )

    arcv_dir="/BMC/fdr/Permanent/${yyyy}/${mm}/${dd}/data/fsl/rap/full/wrfnat"
    arcv_fmt="zip"
    arcv_fns="${yyyy}${mm}${dd}${hh}00.${arcv_fmt}"
    arcv_fps="${arcv_dir}/${arcv_fns}"
    arcvrel_dir=""
#
# Reset hh to its original value in case it is used again later below.
#
    hh=${hh_orig}
    ;;

  "HRRR")
#
# Note that this is GSL HRRRX data, not operational NCEP HRRR data.  An option for the latter
# may be added in the future.
#
    arcv_dir="/BMC/fdr/Permanent/${yyyy}/${mm}/${dd}/data/fsl/hrrr/conus/wrfnat"
    arcv_fmt="zip"
    arcv_fns="${yyyy}${mm}${dd}${hh}00.${arcv_fmt}"
    arcv_fps="${arcv_dir}/${arcv_fns}"
    arcvrel_dir=""
    ;;

  "NAM")
    arcv_dir="/NCEPPROD/hpssprod/runhistory/rh${yyyy}/${yyyy}${mm}/${yyyymmdd}"
    arcv_fmt="tar"
    arcv_fns="com_nam_prod_nam.${yyyy}${mm}${dd}${hh}.bgrid.${arcv_fmt}"
    arcv_fps="${arcv_dir}/${arcv_fns}"
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
# Use the eval function to set the output variables.  Note that each of 
# these is set only if the corresponding input variable specifying the
# name to use for the output variable is not empty.
#
#-----------------------------------------------------------------------
#
  if [ ! -z "${varname_extrn_mdl_cdate}" ]; then
    eval ${varname_extrn_mdl_cdate}="${cdate}"
  fi

  if [ ! -z "${varname_extrn_mdl_lbc_spec_fhrs}" ]; then
    lbc_spec_fhrs_str="( "$( printf "\"%s\" " "${lbc_spec_fhrs[@]}" )")"
    eval ${varname_extrn_mdl_lbc_spec_fhrs}=${lbc_spec_fhrs_str}
  fi

  if [ ! -z "${varname_extrn_mdl_fns_on_disk}" ]; then
    fns_on_disk_str="( "$( printf "\"%s\" " "${fns_on_disk[@]}" )")"
    eval ${varname_extrn_mdl_fns_on_disk}=${fns_on_disk_str}
  fi

  if [ ! -z "${varname_extrn_mdl_fns_in_arcv}" ]; then
    fns_in_arcv_str="( "$( printf "\"%s\" " "${fns_in_arcv[@]}" )")"
    eval ${varname_extrn_mdl_fns_in_arcv}=${fns_in_arcv_str}
  fi

  if [ ! -z "${varname_extrn_mdl_sysdir}" ]; then
    eval ${varname_extrn_mdl_sysdir}="${sysdir}"
  fi

  if [ ! -z "${varname_extrn_mdl_arcv_fmt}" ]; then
    eval ${varname_extrn_mdl_arcv_fmt}="${arcv_fmt}"
  fi

  if [ ! -z "${varname_extrn_mdl_arcv_fns}" ]; then
    arcv_fns_str="( "$( printf "\"%s\" " "${arcv_fns[@]}" )")"
    eval ${varname_extrn_mdl_arcv_fns}=${arcv_fns_str}
  fi

  if [ ! -z "${varname_extrn_mdl_arcv_fps}" ]; then
    arcv_fps_str="( "$( printf "\"%s\" " "${arcv_fps[@]}" )")"
    eval ${varname_extrn_mdl_arcv_fps}=${arcv_fps_str}
  fi

  if [ ! -z "${varname_extrn_mdl_arcvrel_dir}" ]; then
    eval ${varname_extrn_mdl_arcvrel_dir}="${arcvrel_dir}"
  fi
#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script/function.
#
#-----------------------------------------------------------------------
#
  { restore_shell_opts; } > /dev/null 2>&1
}
