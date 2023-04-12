""" Test for link_fix.py"""

#pylint: disable=invalid-name
import os
import unittest

from python_utils import mkdir_vrfy, define_macos_utilities

from link_fix import link_fix

class Testing(unittest.TestCase):
    """ Define the tests. """
    def test_link_fix(self):

        """ Test that link_fix returns the expected value for the given
        input configuration """
        res = link_fix(
            verbose=True,
            file_group="grid",
            source_dir=self.task_dir,
            target_dir=self.FIXlam,
            ccpp_phys_suite=self.cfg["CCPP_PHYS_SUITE"],
            constants=self.cfg["constants"],
            dot_or_uscore=self.cfg["DOT_OR_USCORE"],
            nhw=self.cfg["NHW"],
            run_task=False,
            sfc_climo_fields=["foo", "bar"],
        )
        self.assertTrue(res == "3357")

    def setUp(self):
        define_macos_utilities()
        test_dir = os.path.dirname(os.path.abspath(__file__))
        test_data_dir = os.path.join(os.path.dirname(test_dir), "test_data")
        self.FIXlam = os.path.join(test_data_dir, "expt", "fix_lam")
        self.task_dir = os.path.join(test_data_dir, "RRFS_CONUS_3km")
        mkdir_vrfy("-p", self.FIXlam)

        self.cfg = {
            "DOT_OR_USCORE": "_",
            "NHW": 6,
            "CCPP_PHYS_SUITE": "FV3_GSD_SAR",
            "constants": {
                "NH0": 0,
                "NH4": 4,
                "NH3": 3,
                "TILE_RGNL": 7,
            },
        }
