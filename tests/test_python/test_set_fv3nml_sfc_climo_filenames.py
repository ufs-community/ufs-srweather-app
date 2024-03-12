""" Tests for set_fv3nml_sfc_climo_filenames.py """

#pylint: disable=invalid-name

import os
import tempfile
import unittest

from python_utils import (
    cp_vrfy,
    define_macos_utilities,
    mkdir_vrfy,
    set_env_var,
    )
from set_fv3nml_sfc_climo_filenames import set_fv3nml_sfc_climo_filenames

class Testing(unittest.TestCase):
    """ Define the tests """
    def test_set_fv3nml_sfc_climo_filenames(self):
        """ Call the function and don't raise an Exception. """
        set_fv3nml_sfc_climo_filenames(config=self.config)

    def setUp(self):
        define_macos_utilities()
        set_env_var("DEBUG", True)
        set_env_var("VERBOSE", True)
        test_dir = os.path.dirname(os.path.abspath(__file__))
        USHdir = os.path.join(test_dir, "..", "..", "ush")
        PARMdir = os.path.join(USHdir, "..", "parm")

        # Create a temporary experiment directory structure
        # pylint: disable=consider-using-with
        self.tmp_dir = tempfile.TemporaryDirectory(
            dir=os.path.dirname(__file__),
            prefix="expt",
            )
        EXPTDIR = self.tmp_dir.name
        FIXlam = os.path.join(EXPTDIR, "fix_lam")

        mkdir_vrfy("-p", FIXlam)
        cp_vrfy(
            os.path.join(PARMdir, "input.nml.FV3"),
            os.path.join(EXPTDIR, "input.nml"),
        )
        self.config = {
            "CRES": "C3357",
            "DO_ENSEMBLE": False,
            "EXPTDIR": EXPTDIR,
            "FIXlam": FIXlam,
            "FV3_NML_FP": os.path.join(EXPTDIR, "input.nml"),
            "PARMdir": PARMdir,
            "RUN_ENVIR": "nco",
        }

    def tearDown(self):
        self.tmp_dir.cleanup()
