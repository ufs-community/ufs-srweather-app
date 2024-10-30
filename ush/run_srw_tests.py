#!/usr/bin/env python3

import os
import subprocess
import time
import argparse

class SRWTest:

  """Python class to handle the launching of a set of SRW tests.
  The expectation is to have a "clean" experiment directory with only new experiments
  that are ready to run (e.g., no ``_old*`` experiments left around from previous tests).
  This script takes only one parameter (``-e`` or ``--exptdir``) which points to the 
  ``expt_basedir`` specified when the ``run_WE2E_tests.py`` script is run to set up the tests.
  The script will work sequentially through each of the test directories and 
  launch the workflow for each with a call to ``launch_FV3LAM_wflow.sh``.
  After the initial launch, the ``checkTests`` method is called to monitor the
  status of each test and to call the ``launch_FV3LAM_wflow.sh`` script repeatedly 
  in each uncompleted workflow until all workflows are done."""

  def __init__(self, exptdir):
    self.exptdir=exptdir
    # Get a list of test directories 
    cmdstring="find {} -maxdepth 1 -type d | tail -n+2".format(self.exptdir)
    status= subprocess.check_output(cmdstring,shell=True).strip().decode('utf-8')
    # Turn the stdout from the shell command into a list
    self.testDirectories = status.split("\n")
    self.launchcmd = "./launch_FV3LAM_wflow.sh >& /dev/null"
    # Loop through each of the test directories and launch the initial jobs in the workflow
    for testD in self.testDirectories:
      print("starting {} workflow".format(testD))
      os.chdir(testD)
      os.system(self.launchcmd)
      os.chdir(self.exptdir)
    # Now start monitoring the workflows
    self.checkTests()

  def checkTests(self):
    """Check status of workflows/experiments; remove any that have failed or completed, 
    and continue running the launch command for those that aren't complete.
    
    Returns:
      None
    """
    while(len(self.testDirectories) > 0):
      cmdstring="grep -L 'wflow_status =' */log.launch_FV3LAM_wflow | xargs dirname"
      try:
        status= subprocess.check_output(cmdstring,shell=True).strip().decode('utf-8')
      except:
        print("Tests have all completed")
        return
      self.testDirectories = status.split("\n")
      # continue looping through directories
      for testD in self.testDirectories:
        os.chdir(testD)
        os.system(self.launchcmd)
        os.chdir(self.exptdir)
        print("calling launch_FV3LAM_wflow.sh from {}".format(testD))
        time.sleep(5.0)
      time.sleep(30.0)

if __name__ == "__main__":
  parser = argparse.ArgumentParser(description='Run through a set of SRW WE2E tests until they are complete')
  parser.add_argument('-e','--exptdir', help='directory where experiments have been staged', required=False,default=os.getcwd())
  args = vars(parser.parse_args())

  test = SRWTest(args['exptdir'])

