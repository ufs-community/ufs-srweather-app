""" Tests for set_FV3nml_sfc_climo_filenames.py """

#pylint: disable=invalid-name

import os
import unittest

from python_utils import set_env_var, mkdir_vrfy, cp_vrfy, define_macos_utilities
from set_FV3nml_sfc_climo_filenames import set_FV3nml_sfc_climo_filenames

class Testing(unittest.TestCase):
    """ Define the tests """
    def test_set_FV3nml_sfc_climo_filenames(self): #pylint: disable=no-self-use
        """ Call the function and don't raise an Exception. """
        set_FV3nml_sfc_climo_filenames()

    def setUp(self):
        define_macos_utilities()
        set_env_var("DEBUG", True)
        set_env_var("VERBOSE", True)
        test_dir = os.path.dirname(os.path.abspath(__file__))
        USHdir = os.path.join(test_dir, "..", "..", "ush")
        PARMdir = os.path.join(USHdir, "..", "parm")
        EXPTDIR = os.path.join(USHdir, "test_data", "expt")
        FIXlam = os.path.join(EXPTDIR, "fix_lam")
        mkdir_vrfy("-p", FIXlam)
        mkdir_vrfy("-p", EXPTDIR)
        cp_vrfy(
            os.path.join(PARMdir, "input.nml.FV3"),
            os.path.join(EXPTDIR, "input.nml"),
        )
        set_env_var("PARMdir", PARMdir)
        set_env_var("EXPTDIR", EXPTDIR)
        set_env_var("FIXlam", FIXlam)
        set_env_var("DO_ENSEMBLE", False)
        set_env_var("CRES", "C3357")
        set_env_var("RUN_ENVIR", "nco")
        set_env_var("FV3_NML_FP", os.path.join(EXPTDIR, "input.nml"))
