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

    global EXTRN_MDL_LBCS_OFFSET_HRS

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
    env_vars = ["EXTRN_MDL_LBCS_OFFSET_HRS"]
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
        EXTRN_MDL_LBCS_OFFSET_HRS = get_env_var("EXTRN_MDL_LBCS_OFFSET_HRS")
        self.assertEqual(EXTRN_MDL_LBCS_OFFSET_HRS,3)

    def setUp(self):
        set_env_var("EXTRN_MDL_NAME_LBCS","RAP")
        set_env_var("EXTRN_MDL_LBCS_OFFSET_HRS",None)
