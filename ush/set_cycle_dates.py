#!/usr/bin/env python3

from datetime import datetime, timedelta, date

from python_utils import print_input_args, print_err_msg_exit


def set_cycle_dates(date_start, date_end, incr_cycl_freq):
    """This file defines a function that, given the start and end dates
    as date time objects, and a cycling frequency, returns an array of
    cycle date-hours whose elements have the form YYYYMMDDHH.  Here,
    YYYY is a four-digit year, MM is a two- digit month, DD is a
    two-digit day of the month, and HH is a two-digit hour of the day.

    Args:
        date_start: start date, datetime object
        date_end: end date, datetime object
        incr_cycl_freq: cycle frequency increment in hours, an int
    Returns:
        A list of dates in a format YYYYMMDDHH
    """

    print_input_args(locals())

    freq_delta = timedelta(hours=incr_cycl_freq)

    # iterate over cycles
    all_cdates = []
    cdate = date_start
    while cdate <= date_end:
        cyc = datetime.strftime(cdate, "%Y%m%d%H")
        all_cdates.append(cyc)
        cdate += freq_delta
    return all_cdates
