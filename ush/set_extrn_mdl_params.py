#!/usr/bin/env python3

import unittest

from python_utils import import_vars, export_vars, set_env_var, get_env_var

def set_extrn_mdl_params():
    """ Sets parameters associated with the external model used for initial 
    conditions (ICs) and lateral boundary conditions (LBCs).
    Args:
        None
    Returns:
        None
    """

    #import all env variables
    import_vars()

    global EXTRN_MDL_SYSBASEDIR_ICS, EXTRN_MDL_SYSBASEDIR_LBCS,  EXTRN_MDL_LBCS_OFFSET_HRS

    #
    #-----------------------------------------------------------------------
    #
    # Use known locations or COMIN as default, depending on RUN_ENVIR
    #
    #-----------------------------------------------------------------------
    #
    if RUN_ENVIR == "nco":
      EXTRN_MDL_SYSBASEDIR_ICS=EXTRN_MDL_SYSBASEDIR_ICS or COMIN
      EXTRN_MDL_SYSBASEDIR_LBCS=EXTRN_MDL_SYSBASEDIR_LBCS or COMIN
    else:
      ics_dir=EXTRN_MDL_NAME_ICS
      lbcs_dir=EXTRN_MDL_NAME_LBCS
      EXTRN_MDL_SYSBASEDIR_ICS=EXTRN_MDL_SYSBASEDIR_ICS or ics_dir
      EXTRN_MDL_SYSBASEDIR_LBCS=EXTRN_MDL_SYSBASEDIR_LBCS or lbcs_dir
    
    #
    #-----------------------------------------------------------------------
    #
    # Set EXTRN_MDL_LBCS_OFFSET_HRS, which is the number of hours to shift 
    # the starting time of the external model that provides lateral boundary 
    # conditions.
    #
    #-----------------------------------------------------------------------
    #
    if EXTRN_MDL_NAME_LBCS == "RAP":
        EXTRN_MDL_LBCS_OFFSET_HRS=EXTRN_MDL_LBCS_OFFSET_HRS or "3"
    else:
        EXTRN_MDL_LBCS_OFFSET_HRS=EXTRN_MDL_LBCS_OFFSET_HRS or "0"

    # export values we set above
    env_vars = ["EXTRN_MDL_SYSBASEDIR_ICS", "EXTRN_MDL_SYSBASEDIR_LBCS", "EXTRN_MDL_LBCS_OFFSET_HRS"]
    export_vars(env_vars=env_vars)
#
#-----------------------------------------------------------------------
#
# Call the function defined above.
#
#-----------------------------------------------------------------------
#
if __name__ == "__main__":
    set_extrn_mdl_params()
   
class Testing(unittest.TestCase):
    def test_extrn_mdl_params(self):
        set_extrn_mdl_params()
        EXTRN_MDL_SYSBASEDIR_ICS = get_env_var("EXTRN_MDL_SYSBASEDIR_ICS")
        COMINgfs = get_env_var("COMINgfs")
        self.assertEqual(EXTRN_MDL_SYSBASEDIR_ICS,COMINgfs)

    def setUp(self):
        set_env_var("MACHINE","HERA")
        set_env_var("RUN_ENVIR","nco")
        set_env_var("EXTRN_MDL_NAME_ICS","FV3GFS")
        set_env_var("EXTRN_MDL_NAME_LBCS","FV3GFS")
        set_env_var("EXTRN_MDL_SYSBASEDIR_ICS",None)
        set_env_var("EXTRN_MDL_SYSBASEDIR_LBCS",None)
        set_env_var("EXTRN_MDL_LBCS_OFFSET_HRS",None)
        set_env_var("COMINgfs","/base/path/of/directory/containing/gfs/input/files")
