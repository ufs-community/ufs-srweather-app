""" Test for the set_gridparams_ESGgrid.py script. """

#pylint: disable=invalid-name

import unittest

from python_utils import set_env_var
from set_gridparams_ESGgrid import set_gridparams_ESGgrid

class Testing(unittest.TestCase):
    """ Define the tests """

    def test_set_gridparams_ESGgrid(self):
        """ Test that when provided inputs, the expected output is
        provided in a list. Some work is needed here to remove magic
        from the numbers. """

        grid_parms = set_gridparams_ESGgrid(
            lon_ctr=-97.5,
            lat_ctr=38.5,
            nx=1748,
            ny=1038,
            pazi=0.0,
            halo_width=6,
            delx=3000.0,
            dely=3000.0,
            constants={
                "RADIUS_EARTH": 6371200.0,
                "DEGS_PER_RADIAN": 57.29577951308232087679,
            },
        )

        self.assertEqual(
            list(grid_parms.values()),
            [
                -97.5,
                38.5,
                1748,
                1038,
                0.0,
                6,
                0.999,
                0.013489400626196555,
                0.013489400626196555,
                -1760,
                -1050,
            ],
        )

    def setUp(self):
        set_env_var("DEBUG", False)
        set_env_var("VERBOSE", False)
