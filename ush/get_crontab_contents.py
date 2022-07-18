#!/usr/bin/env python3

import os
import sys
import unittest
import argparse
from datetime import datetime

from python_utils import import_vars, set_env_var, print_input_args, \
                         run_command, define_macos_utilities, print_info_msg

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

    #import selected env vars
    IMPORTS = ["MACHINE", "USER"]
    import_vars(env_vars=IMPORTS)
  
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
  
    return __crontab_cmd__, __crontab_contents__

def add_crontab_line():
    """ Add crontab line to cron table """

    #import selected env vars
    IMPORTS = ["MACHINE", "USER", "CRONTAB_LINE", "VERBOSE", "EXPTDIR"]
    import_vars(env_vars=IMPORTS)

    #
    # Make a backup copy of the user's crontab file and save it in a file.
    #
    time_stamp = datetime.now().strftime("%F_%T")
    crontab_backup_fp=os.path.join(EXPTDIR,f"crontab.bak.{time_stamp}")
    print_info_msg(f'''
      Copying contents of user cron table to backup file:
        crontab_backup_fp = \"{crontab_backup_fp}\"''',verbose=VERBOSE)

    global called_from_cron
    try: called_from_cron
    except: called_from_cron = False

    # Get crontab contents
    crontab_cmd,crontab_contents = get_crontab_contents(called_from_cron=called_from_cron)

    # Create backup
    run_command(f'''printf "%s" '{crontab_contents}' > "{crontab_backup_fp}"''')
    
    # Add crontab line
    if CRONTAB_LINE in crontab_contents:
    
      print_info_msg(f'''
          The following line already exists in the cron table and thus will not be
          added:
            CRONTAB_LINE = \"{CRONTAB_LINE}\"''')
    
    else:
    
      print_info_msg(f'''
          Adding the following line to the user's cron table in order to automatically
          resubmit SRW workflow:
            CRONTAB_LINE = \"{CRONTAB_LINE}\"''',verbose=VERBOSE)

      #add new line to crontab contents if it doesn't have one
      NEWLINE_CHAR=""
      if crontab_contents and crontab_contents[-1] != "\n": 
        NEWLINE_CHAR="\n"
    
      #add the crontab line
      if MACHINE == "WCOSS_DELL_P3":
        run_command(f'''printf "%b%s\n" '{NEWLINE_CHAR}' '{CRONTAB_LINE}' >> "/u/{USER}/cron/mycrontab"''')
      else:
        run_command(f'''printf "%s%b%s\n" '{crontab_contents}' '{NEWLINE_CHAR}' '{CRONTAB_LINE}' | {crontab_cmd}''')

def delete_crontab_line(called_from_cron):
    """ Delete crontab line after job is complete i.e. either SUCCESS/FAILURE
    but not IN PROGRESS status"""

    print_input_args(locals())
  
    #import selected env vars
    IMPORTS = ["MACHINE", "USER", "CRONTAB_LINE"]
    import_vars(env_vars=IMPORTS)

    #
    # Get the full contents of the user's cron table.  
    #
    (crontab_cmd,crontab_contents) = get_crontab_contents(called_from_cron)
    #
    # Remove the line in the contents of the cron table corresponding to the 
    # current forecast experiment (if that line is part of the contents).
    # Then record the results back into the user's cron table.
    #
    if (CRONTAB_LINE + '\n') in crontab_contents:
        crontab_contents = crontab_contents.replace(CRONTAB_LINE+'\n','')
    else:
        crontab_contents = crontab_contents.replace(CRONTAB_LINE,'')

    if MACHINE == "WCOSS_DELL_P3":
        run_command(f'''echo '{crontab_contents}' > "/u/{USER}/cron/mycrontab"''')
    else:
        run_command(f'''echo '{crontab_contents}' | {crontab_cmd}''')

def parse_args(argv):
    """ Parse command line arguments for deleting crontab line.
    This is needed because it is called from shell script
    """
    parser = argparse.ArgumentParser(
        description='Crontab job manupilation program.'
    )

    parser.add_argument('-d', '--delete',
                        dest='delete',
                        action='store_true',
                        help='Delete crontab line.')

    parser.add_argument('-c', '--called-from-cron',
                        dest='called_from_cron',
                        action='store_true',
                        help='Called from cron.')

    return parser.parse_args(argv)

if __name__ == '__main__':
    args = parse_args(sys.argv[1:])
    if args.delete:
        delete_crontab_line(args.called_from_cron)	
    
class Testing(unittest.TestCase):
    def test_get_crontab_contents(self):
        crontab_cmd,crontab_contents = get_crontab_contents(called_from_cron=True)
        self.assertEqual(crontab_cmd, "crontab")
    def setUp(self):
        define_macos_utilities();
        set_env_var('DEBUG',False)
        set_env_var('MACHINE', 'HERA')
