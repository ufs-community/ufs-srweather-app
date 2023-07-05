""" Tests for set_thompson_mp_fix_files.py """

#pylint: disable=invalid-name
import os
import unittest

from set_thompson_mp_fix_files import set_thompson_mp_fix_files

class Testing(unittest.TestCase):
    """ Define the tests"""
    def test_set_thompson_mp_fix_files(self):
        """ Test that when given a CCPP physics suite that uses Thompson
        mp, the function returns True. """
        test_dir = os.path.dirname(os.path.abspath(__file__))
        USHdir = os.path.join(test_dir, "..", "..", "ush")
        uses_thompson, _, _ = set_thompson_mp_fix_files(
            os.path.join(f"{USHdir}", "test_data", "suite_FV3_GSD_SAR.xml"),
            "Thompson_MP_MONTHLY_CLIMO.nc",
            False,
        )
        self.assertEqual(True, uses_thompson)
