#!/usr/bin/env python3

import os
import unittest
from datetime import datetime

from python_utils import import_vars, set_env_var, print_input_args, \
                         run_command, define_macos_utilities, check_var_valid_value
from constants import valid_vals_BOOLEAN

def get_crontab_contents(called_from_cron):
    """
    #-----------------------------------------------------------------------
    #
    # This function returns the contents of the user's 
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
    """
  
    print_input_args(locals())
  
    #import all env vars
    IMPORTS = ["MACHINE", "USER"]
    import_vars(env_vars=IMPORTS)

    #
    # Make sure called_from_cron is set to a valid value.
    #
    check_var_valid_value(called_from_cron, valid_vals_BOOLEAN)
  
    if MACHINE == "WCOSS_DELL_P3":
      __crontab_cmd__=""
      (_,__crontab_contents__,_)=run_command(f'''cat "/u/{USER}/cron/mycrontab"''')
    else:
      __crontab_cmd__="crontab"
      #
      # On Cheyenne, simply typing "crontab" will launch the crontab command 
      # at "/glade/u/apps/ch/opt/usr/bin/crontab".  This is a containerized 
      # version of crontab that will work if called from scripts that are 
      # themselves being called as cron jobs.  In that case, we must instead 
      # call the system version of crontab at /usr/bin/crontab.
      #
      if MACHINE == "CHEYENNE":
        if called_from_cron:
          __crontab_cmd__="/usr/bin/crontab"
      (_,__crontab_contents__,_)=run_command(f'''{__crontab_cmd__} -l''')
    #
    # On Cheyenne, the output of the "crontab -l" command contains a 3-line
    # header (comments) at the top that is not actually part of the user's
    # cron table.  This needs to be removed to avoid adding an unnecessary
    # copy of this header to the user's cron table.
    #
    if MACHINE == "CHEYENNE":
      (_,__crontab_contents__,_)=run_command(f'''printf "%s" "{__crontab_contents__}" | tail -n +4 ''')
  
    return __crontab_cmd__, __crontab_contents__

class Testing(unittest.TestCase):
    def test_get_crontab_contents(self):
        crontab_cmd,crontab_contents = get_crontab_contents(called_from_cron=True)
        self.assertEqual(crontab_cmd, "crontab")
    def setUp(self):
        define_macos_utilities();
        set_env_var('DEBUG',False)
        set_env_var('MACHINE', 'HERA')
