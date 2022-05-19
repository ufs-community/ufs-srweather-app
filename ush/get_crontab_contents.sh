#
#-----------------------------------------------------------------------
#
# This file defines a function that returns the contents of the user's 
# cron table as well as the command to use to manipulate the cron table
# (i.e. the "crontab" command, but on some platforms the version or 
# location of this may change depending on other circumstances, e.g. on
# Cheyenne, this depends on whether a script that wants to call "crontab"
# is itself being called from a cron job).  Arguments are as follows:
#
# called_from_cron:
# Boolean flag that specifies whether this function (and the scripts or
# functions that are calling it) are called as part of a cron job.  Must
# be set to "TRUE" or "FALSE".
#
# outvarname_crontab_cmd:
# Name of the output variable that will contain the command to issue for
# the system "crontab" command.
#
# outvarname_crontab_contents:
# Name of the output variable that will contain the contents of the 
# user's cron table.
# 
#-----------------------------------------------------------------------
#
function get_crontab_contents() { 

  { save_shell_opts; set -u +x; } > /dev/null 2>&1

  local valid_args=( \
    "called_from_cron" \
    "outvarname_crontab_cmd" \
    "outvarname_crontab_contents" \
    )
  process_args valid_args "$@"
  print_input_args "valid_args"

  local __crontab_cmd__ \
        __crontab_contents__
  #
  # Make sure called_from_cron is set to a valid value.
  #
  source $USHDIR/constants.sh
  check_var_valid_value "called_from_cron" "valid_vals_BOOLEAN"
  called_from_cron=$( boolify ${called_from_cron} )

  if [ "$MACHINE" = "WCOSS_DELL_P3" ]; then
    __crontab_cmd__=""
    __crontab_contents__=$( cat "/u/$USER/cron/mycrontab" )
  else
    __crontab_cmd__="crontab"
    #
    # On Cheyenne, simply typing "crontab" will launch the crontab command 
    # at "/glade/u/apps/ch/opt/usr/bin/crontab".  This is a containerized 
    # version of crontab that will work if called from scripts that are 
    # themselves being called as cron jobs.  In that case, we must instead 
    # call the system version of crontab at /usr/bin/crontab.
    #
    if [ "$MACHINE" = "CHEYENNE" ]; then
      if [ -n "${called_from_cron}" ] && [ "${called_from_cron}" = "TRUE" ]; then
        __crontab_cmd__="/usr/bin/crontab"
      fi
    fi
    __crontab_contents__=$( ${__crontab_cmd__} -l )
  fi
  #
  # Set output variables.
  #
  printf -v ${outvarname_crontab_cmd} "%s" "${__crontab_cmd__}"
  printf -v ${outvarname_crontab_contents} "%s" "${__crontab_contents__}"

  { restore_shell_opts; } > /dev/null 2>&1

}
