""" Test set_cycle_dates.py """

from datetime import datetime
import unittest

from set_cycle_dates import set_cycle_dates

class Testing(unittest.TestCase):
    """ Define the tests"""
    def test_set_cycle_dates(self):

        """ Test that the proper list of dates are produced given the
        intput data"""
        cdates = set_cycle_dates(
            date_start=datetime(2022, 1, 1, 6),
            date_end=datetime(2022, 1, 2, 12),
            incr_cycl_freq=6,
        )
        self.assertEqual(
            cdates,
            [
                "2022010106",
                "2022010112",
                "2022010118",
                "2022010200",
                "2022010206",
                "2022010212",
            ],
        )
