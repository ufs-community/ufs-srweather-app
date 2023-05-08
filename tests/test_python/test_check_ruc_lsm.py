""" Test for the define_ruc_lsm script. """

#pylint: disable=invalid-name

import os
import unittest

from python_utils import set_env_var

from check_ruc_lsm import check_ruc_lsm

class Testing(unittest.TestCase):
    """ Define the tests"""

    def test_check_ruc_lsm(self):
        """" Read in a CCPP suite definition file and check that it is
        using RUC LSM as part of the suite. """
        test_dir = os.path.dirname(os.path.abspath(__file__))
        USHdir = os.path.join(test_dir, "..", "..", "ush")
        self.assertTrue(
            check_ruc_lsm(
                ccpp_phys_suite_fp=f"{USHdir}{os.sep}test_data{os.sep}suite_FV3_GSD_SAR.xml"
            )
        )

    def setUp(self):
        set_env_var("DEBUG", True)
