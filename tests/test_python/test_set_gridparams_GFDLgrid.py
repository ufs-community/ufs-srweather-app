""" Defines the tests for set_gridparams_GFDLgrid """

#pylint: disable=invalid-name

import unittest

from set_gridparams_GFDLgrid import set_gridparams_GFDLgrid

class Testing(unittest.TestCase):
    """ Define the tests """

    def test_set_gridparams_GFDLgrid(self):

        """ Test that grid parameters are set as expected, and that a
        list is returned with expected values. Some work here is needed
        to understand why we have a list with these magic numbers."""
        grid_params = set_gridparams_GFDLgrid(
            lon_of_t6_ctr=-97.5,
            lat_of_t6_ctr=38.5,
            res_of_t6g=96,
            stretch_factor=1.4,
            refine_ratio_t6g_to_t7g=3,
            istart_of_t7_on_t6g=13,
            iend_of_t7_on_t6g=84,
            jstart_of_t7_on_t6g=17,
            jend_of_t7_on_t6g=80,
            run_envir="community",
            verbose=True,
            nh4=4,
        )

        self.assertEqual(
            list(grid_params.values()),
            [-97.5, 38.5, 216, 192, 6, 1.4, 21, 172, 29, 164],
        )
