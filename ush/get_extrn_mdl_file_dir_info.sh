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

usage () {

echo "
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

  varname_extrn_mdl_fns_on_disk:
  Name of the global variable that will contain the expected names of 
  the external model output files on disk.

  varname_extrn_mdl_fns_in_arcv:
  Name of the global variable that will contain the expected names of 
  the external model output files on NOAA HPSS.

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
}

function quit_unless_user_spec_data() {
  if [ "${USE_USER_STAGED_EXTRN_FILES}" != "TRUE" ]; then
    print_err_msg_exit "\
The system directory in which to look for external model output files
has not been specified for this external model and machine combination:
  extrn_mdl_name = \"${extrn_mdl_name}\"
  MACHINE = \"$MACHINE\""
  fi
}

function get_extrn_mdl_file_dir_info() {

  { save_shell_opts; set -u +x; } > /dev/null 2>&1

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

  if [ "$#" -ne "13" ]; then
    print_err_msg_exit $(usage)
  fi

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
  # Declare additional local variables.
  #
  #-----------------------------------------------------------------------
  #
  local yyyy yy mm dd hh mn yyyymmdd ddd \
        lbc_spec_fhrs i num_fhrs \
        fcst_hhh fcst_hh fcst_mn \
        prefix suffix fns fns_on_disk fns_in_arcv \
        sysbasedir sysdir \
        arcv_dir arcv_fmt arcv_fns arcv_fps arcvrel_dir

  anl_or_fcst=$(echo_uppercase $anl_or_fcst)
  valid_vals_anl_or_fcst=( "ANL" "FCST" )
  check_var_valid_value "anl_or_fcst" "valid_vals_anl_or_fcst"
  #
  #-----------------------------------------------------------------------
  #
  # Set cdate to the start time for the external model being used.
  #
  #-----------------------------------------------------------------------
  #
  hh=${cdate_FV3LAM:8:2}
  yyyymmdd=${cdate_FV3LAM:0:8}

  # Adjust time for offset
  cdate=$( $DATE_UTIL --utc --date "${yyyymmdd} ${hh} UTC - ${time_offset_hrs} hours" "+%Y%m%d%H" )

  yyyy=${cdate:0:4}
  yy=${yyyy:2:4}
  mm=${cdate:4:2}
  dd=${cdate:6:2}
  hh=${cdate:8:2}
  mn="00"
  yyyymmdd=${cdate:0:8}
  # Julian day -- not 3 digit day of month
  ddd=$( $DATE_UTIL --utc --date "${yyyy}-${mm}-${dd} ${hh}:${mn} UTC" "+%j" )
  #
  #-----------------------------------------------------------------------
  #
  # Initialize lbc_spec_fhrs array. Skip the initial time, since it is
  # handled separately.
  #
  #-----------------------------------------------------------------------
  #
  lbc_spec_fhrs=( "" )

  if [ "${anl_or_fcst}" = "FCST" ]; then

    lbc_spec_fhrs=( "${LBC_SPEC_FCST_HRS[@]}" )

    num_fhrs=${#lbc_spec_fhrs[@]}
    for (( i=0; i<=$((num_fhrs-1)); i++ )); do
      # Add in offset to account for shift in initial time
      lbc_spec_fhrs[$i]=$(( ${lbc_spec_fhrs[$i]} + time_offset_hrs ))
    done

  fi
  #
  #-----------------------------------------------------------------------
  #
  # The model may be started with a variety of file types from FV3GFS.
  # Set that file type now
  #
  #-----------------------------------------------------------------------
  #

  if [ "${anl_or_fcst}" = "ANL" ]; then
    fv3gfs_file_fmt="${FV3GFS_FILE_FMT_ICS}"
  elif [ "${anl_or_fcst}" = "FCST" ]; then
    fv3gfs_file_fmt="${FV3GFS_FILE_FMT_LBCS}"
  fi

  #
  #-----------------------------------------------------------------------
  #
  # Generate an array of file names expected from the external model
  # Assume that filenames in archive and on disk are the same, unless
  # otherwise specified (primarily on Jet).
  #
  #-----------------------------------------------------------------------
  #
  declare -a fns_on_disk
  declare -a fns_in_arcv
  case "${anl_or_fcst}" in

    "ANL")

      fcst_hh="00"
      fcst_mn="00"

      case "${extrn_mdl_name}" in

      "GSMGFS")
        fns_in_arcv=("gfs.t${hh}z.atmanl.nemsio" "gfs.t${hh}z.sfcanl.nemsio")
        ;;

      "FV3GFS")
        case "${fv3gfs_file_fmt}" in
          "nemsio")
            fns_in_arcv=("gfs.t${hh}z.atmanl.nemsio" "gfs.t${hh}z.sfcanl.nemsio")

            # File names are prefixed with a date time on Jet
            if [ "${MACHINE}" = "JET" ]; then
              prefix="${yy}${ddd}${hh}00"
              fns_on_disk=( ${fns_in_arcv[@]/#/$prefix})
            fi
            ;;
          "grib2")
            fns_in_arcv=( "gfs.t${hh}z.pgrb2.0p25.f000" )
            ;;
          "netcdf")
            fns_in_arcv=("gfs.t${hh}z.atmanl.nc" "gfs.t${hh}z.sfcanl.nc")
            # File names are prefixed with a date time on Jet
            if [ "${MACHINE}" = "JET" ]; then
              prefix="${yy}${ddd}${hh}00"
              fns_on_disk=( ${fns_in_arcv[@]/#/$prefix})
            fi
            ;;
        esac
        ;;

      "RAP")
        ;& # Fall through. RAP and HRRR follow same naming rules

      "HRRR")
        fns_in_arcv=( "${yy}${ddd}${hh}${mn}${fcst_hh}${fcst_mn}" )
        if [ "${MACHINE}" = "JET" ]; then 
          fns_on_disk=( "${yy}${ddd}${hh}${mn}${fcst_mn}${fcst_hh}${fcst_mn}" )
        fi
        ;;

      "NAM")
        fns=( "" )
        fns_in_arcv=( "nam.t${hh}z.bgrdsf${fcst_hh}.tm00" )
        ;;

      *)
        if [ "${USE_USER_STAGED_EXTRN_FILES}" != "TRUE" ]; then
          print_err_msg_exit "\
The external model file names (either on disk or in archive files) have 
not yet been specified for this combination of external model (extrn_mdl_name) 
and analysis or forecast (anl_or_fcst):
  extrn_mdl_name = \"${extrn_mdl_name}\"
  anl_or_fcst = \"${anl_or_fcst}\""
      fi
      ;;

    esac # End external model case for ANL files
    ;;

    "FCST")
      fcst_mn="00"
      fcst_hhh=( $( printf "%03d " "${lbc_spec_fhrs[@]}" ) )
      fcst_hh=( $( printf "%02d " "${lbc_spec_fhrs[@]}" ) )

      case "${extrn_mdl_name}" in

      "GSMGFS")
        fn_tmpl="gfs.t${hh}z.atmfFHR3.nemsio"
        ;;

      "FV3GFS")

        if [ "${fv3gfs_file_fmt}" = "nemsio" ]; then
          fn_tmpl="gfs.t${hh}z.atmfFHR3.nemsio"
          if [ "${MACHINE}" = "JET" ]; then
            disk_tmpl="${yy}${ddd}${hh}00.gfs.t${hh}z.atmfFHR3.nemsio"
            for fhr in ${fcst_hhh[@]} ; do
              fns_on_disk+=(${disk_tmpl/FHR3/$fhr})
            done
          fi
        elif [ "${fv3gfs_file_fmt}" = "grib2" ]; then
          fn_tmpl="gfs.t${hh}z.pgrb2.0p25.fFHR3"
        elif [ "${fv3gfs_file_fmt}" = "netcdf" ]; then
          fn_tmpl="gfs.t${hh}z.atmfFHR3.nc"
          if [ "${MACHINE}" = "JET" ]; then
            disk_tmpl="${yy}${ddd}${hh}00.gfs.t${hh}z.atmfFHR3.nc"
            for fhr in ${fcst_hhh[@]} ; do
              fns_on_disk+=(${disk_tmpl/FHR3/$fhr})
            done
          fi
        fi
        ;;

      "RAP")
        ;&  # Fall through since RAP and HRRR are named the same

      "HRRR")
        fn_tmpl="${yy}${ddd}${hh}00FHR200"
        if [ "${MACHINE}" = "JET" ]; then 
          disk_tmpl="${yy}${ddd}${hh}0000FHR2"
          for fhr in ${fcst_hhh[@]} ; do
            fns_on_disk+=(${disk_tmpl/FHR3/$fhr})
          done
        fi
        ;;

      "NAM")
        fn_tmpl="nam.t${hh}z.bgrdsfFHR3"
        ;;

      *)
        if [ "${USE_USER_STAGED_EXTRN_FILES}" != "TRUE" ]; then
          print_err_msg_exit "\
The external model file names have not yet been specified for this com-
bination of external model (extrn_mdl_name) and analysis or forecast
(anl_or_fcst):
  extrn_mdl_name = \"${extrn_mdl_name}\"
  anl_or_fcst = \"${anl_or_fcst}\""
        fi
        ;;

    esac # End external model case for FCST files
    ;;
  esac # End ANL FCST case

  #
  # Expand the archive file names for all forecast hours
  #
  if [ ${anl_or_fcst} = FCST ] ; then
    if [[ $fn_tmpl =~ FHR3 ]] ; then
      fhrs=( $( printf "%03d " "${lbc_spec_fhrs[@]}" ) )
      tmpl=FHR3
    elif [[ ${fn_tmpl} =~ FHR2 ]] ; then
      fhrs=( $( printf "%02d " "${lbc_spec_fhrs[@]}" ) )
      tmpl=FHR2
    else
      print_err_msg_exit "\
        Forecast file name templates are expected to contain a template
      string, either FHR2 or FHR3"
    fi
    for fhr in ${fhrs[@]}; do
      fns_in_arcv+=(${fn_tmpl/$tmpl/$fhr})
    done
  fi

  # Make sure all filenames variables are set.
  if [ -z $fns_in_arcv ] ; then
    print_err_msg_exit "\
      The script has not set \$fns_in_arcv properly"
  fi

  if [ -z ${fns_on_disk:-} ] ; then
    fns_on_disk=(${fns_in_arcv[@]})
  fi
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
    sysbasedir=${EXTRN_MDL_SYSBASEDIR_ICS}
  elif [ "${anl_or_fcst}" = "FCST" ]; then
    sysbasedir=${EXTRN_MDL_SYSBASEDIR_LBCS}
  fi

  sysdir=$sysbasedir
  # Use the basedir unless otherwise specified for special platform
  # cases below.
  if [ -n "${sysbasedir}" ] ; then
    case "${extrn_mdl_name}" in

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
        "ODIN")
          sysdir="$sysbasedir/${yyyymmdd}"
          ;;
        "CHEYENNE")
          sysdir="$sysbasedir/gfs.${yyyymmdd}/${hh}"
          ;;
        esac
        ;;

      "RAP")
        case "$MACHINE" in
        "JET")
          sysdir="$sysbasedir/${yyyymmdd}${hh}/postprd"
          ;;
        esac
        ;;

      "HRRR")
        case "$MACHINE" in
        "JET")
          sysdir="$sysbasedir/${yyyymmdd}${hh}/postprd"
          ;;
        esac
        ;;

    esac
  fi
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
    # Note that this is GSL RAPX data, not operational NCEP RAP data.
    # An option for the latter may be added in the future.
    #
    # The zip archive files for RAPX are named such that the forecast
    # files for odd-numbered starting hours (e.g. 01, 03, ..., 23) are
    # stored together with the forecast files for the corresponding
    # preceding even numbered starting hours (e.g. 00, 02, ..., 22,
    # respectively), in an archive file whose name contains only the
    # even-numbered hour. Thus, in forming the name of the archive
    # file, if the starting hour (hh) is odd, we reduce it by one to get
    # the corresponding even-numbered hour and use that to form the
    # archive file name.
    #
    # Convert hh to a decimal (i.e. base-10) number to ovoid octal
    # interpretation in bash.

    hh_orig=$hh
    hh=$((10#$hh))
    if [ $(($hh%2)) = 1 ]; then
      hh=$((hh-1))
    fi
    # Archive files use 2-digit forecast hour
    hh=$( printf "%02d\n" $hh )

    arcv_dir="/BMC/fdr/Permanent/${yyyy}/${mm}/${dd}/data/fsl/rap/full/wrfnat"
    arcv_fmt="zip"
    arcv_fns="${yyyy}${mm}${dd}${hh}00.${arcv_fmt}"
    arcv_fps="${arcv_dir}/${arcv_fns}"
    arcvrel_dir=""

    # Reset hh to its original value
    hh=${hh_orig}
    ;;

  "HRRR")
    #
    # Note that this is GSL HRRRX data, not operational NCEP HRRR data.
    # An option for the latter may be added in the future.
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
  # arrays, recast them as arrays because that is what is expected in
  # the code below.
  #
  is_array arcv_fns || arcv_fns=( "${arcv_fns}" )
  is_array arcv_fps || arcv_fps=( "${arcv_fps}" )
  #
  #-----------------------------------------------------------------------
  #
  # Use the eval function to set the output variables. Note that each
  # of these is set only if the corresponding input variable specifying
  # the name to use for the output variable is not empty.
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
