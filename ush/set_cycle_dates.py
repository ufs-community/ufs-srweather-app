#!/usr/bin/env python3

import unittest
from datetime import datetime,timedelta,date

from python_utils import print_input_args, print_err_msg_exit

def set_cycle_dates(date_start, date_end, cycle_hrs, incr_cycl_freq):
    """ This file defines a function that, given the starting date (date_start, 
    in the form YYYYMMDD), the ending date (date_end, in the form YYYYMMDD), 
    and an array containing the cycle hours for each day (whose elements 
    have the form HH), returns an array of cycle date-hours whose elements
    have the form YYYYMMDD.  Here, YYYY is a four-digit year, MM is a two-
    digit month, DD is a two-digit day of the month, and HH is a two-digit
    hour of the day.

    Args:
        date_start: start date
        date_end: end date
        cycle_hrs: [ HH0, HH1, ...]
        incr_cycl_freq: cycle frequency increment in hours
    Returns:
        A list of dates in a format YYYYMMDDHH
    """

    print_input_args(locals())

    #calculate date increment
    if incr_cycl_freq <= 24:
        incr_days = 1
    else:
        incr_days = incr_cycl_freq // 24
        if incr_cycl_freq % 24 != 0:
            print_err_msg_exit(f'''
                INCR_CYCL_FREQ is not divided by 24:
                  INCR_CYCL_FREQ = \"{incr_cycl_freq}\"''')

    #iterate over days and cycles
    all_cdates = []
    d = date_start
    while d <= date_end:
        for c in cycle_hrs:
            dc = d + timedelta(hours=c)
            v = datetime.strftime(dc,'%Y%m%d%H')
            all_cdates.append(v)
        d += timedelta(days=incr_days)

    return all_cdates
   
class Testing(unittest.TestCase):
    def test_set_cycle_dates(self):
        cdates = set_cycle_dates(date_start=datetime(2022,1,1), date_end=datetime(2022,1,4),
                        cycle_hrs=[6,12], incr_cycl_freq=48) 
        self.assertEqual(cdates, ['2022010106', '2022010112','2022010306', '2022010312'])
