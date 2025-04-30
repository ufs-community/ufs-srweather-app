""" Tests for set_fv3nml_sfc_climo_filenames.py """

#pylint: disable=invalid-name

import os
import shutil
import tempfile
import unittest

from python_utils import (
    define_macos_utilities,
    )
from set_fv3nml_sfc_climo_filenames import set_fv3nml_sfc_climo_filenames

class Testing(unittest.TestCase):
    """ Define the tests """
    def test_set_fv3nml_sfc_climo_filenames(self):
        """ Call the function and don't raise an Exception. """
        set_fv3nml_sfc_climo_filenames(config=self.config, namelist=self.namelist)

    def setUp(self):
        define_macos_utilities()
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

        os.makedirs(FIXlam)
        shutil.copy(
            os.path.join(PARMdir, "input.nml.FV3"),
            os.path.join(EXPTDIR, "input.nml"),
        )
        self.config = {
            "workflow": {
              "CRES": "C3357",
              "FIXlam": FIXlam
              },
            "user": {
              "PARMdir": PARMdir,
              "RUN_ENVIR": "nco"
              }
        }
        self.namelist=os.path.join(EXPTDIR, "input.nml")

    def tearDown(self):
        self.tmp_dir.cleanup()
