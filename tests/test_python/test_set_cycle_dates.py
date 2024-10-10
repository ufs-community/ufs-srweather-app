""" Test set_cycle_dates.py """

from datetime import datetime, timedelta
import unittest

from set_cycle_and_obs_timeinfo import set_cycle_dates

class Testing(unittest.TestCase):
    """ Define the tests"""

    def test_set_cycle_dates_string(self):

        """ Test that the proper list of dates are produced given the
        input data and return_type left to its default value (so the 
        output should be a list of strings)"""
        cdates = set_cycle_dates(
            start_time_first_cycl=datetime(2022, 1, 1, 6),
            start_time_last_cycl=datetime(2022, 1, 2, 12),
            cycl_intvl=timedelta(hours=6),
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

    def test_set_cycle_dates_datetime(self):

        """ Test that the proper list of dates are produced given the
        input data and return_type left set to "datetime" (so the output
        should be a list of datetime objects)"""
        cdates = set_cycle_dates(
            start_time_first_cycl=datetime(2022, 1, 1, 6),
            start_time_last_cycl=datetime(2022, 1, 2, 12),
            cycl_intvl=timedelta(hours=6),
            return_type="datetime",
        )
        self.assertEqual(
            cdates,
            [
                datetime(2022, 1, 1, 6),
                datetime(2022, 1, 1, 12),
                datetime(2022, 1, 1, 18),
                datetime(2022, 1, 2, 0),
                datetime(2022, 1, 2, 6),
                datetime(2022, 1, 2, 12),
            ],
        )
