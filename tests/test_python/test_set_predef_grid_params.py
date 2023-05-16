""" Defines tests for setting the predefined grid parameters. """

import os
import unittest

from set_predef_grid_params import set_predef_grid_params

class Testing(unittest.TestCase):

    "Define the tests"

    def test_set_predef_grid_params(self):
        """ Check that the method called updates or sets specific entries
        in the parameter dict."""
        test_dir = os.path.dirname(os.path.abspath(__file__))
        ushdir = os.path.join(test_dir, "..", "..", "ush")
        fcst_config = {
            "PREDEF_GRID_NAME": "RRFS_CONUS_3km",
            "QUILTING": False,
            "DT_ATMOS": 36,
            "LAYOUT_X": 18,
            "LAYOUT_Y": 36,
            "BLOCKSIZE": 28,
        }
        params_dict = set_predef_grid_params(
            ushdir,
            fcst_config["PREDEF_GRID_NAME"],
            fcst_config["QUILTING"],
        )
        self.assertEqual(params_dict["GRID_GEN_METHOD"], "ESGgrid")
        self.assertEqual(params_dict["ESGgrid_LON_CTR"], -97.5)
        fcst_config = {
            "PREDEF_GRID_NAME": "RRFS_CONUS_3km",
            "QUILTING": True,
            "DT_ATMOS": 36,
            "LAYOUT_X": 18,
            "LAYOUT_Y": 36,
            "BLOCKSIZE": 28,
        }
        params_dict = set_predef_grid_params(
            ushdir,
            fcst_config["PREDEF_GRID_NAME"],
            fcst_config["QUILTING"],
        )
        self.assertEqual(params_dict["WRTCMP_nx"], 1799)
