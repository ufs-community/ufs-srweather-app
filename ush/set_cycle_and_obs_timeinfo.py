#!/usr/bin/env python3

from datetime import datetime, timedelta, date
from pprint import pprint
from python_utils import print_input_args, print_err_msg_exit

def set_cycle_dates(start_time_first_cycl, start_time_last_cycl, cycl_intvl):
    """This file defines a function that, given the start and end dates
    as date time objects, and a cycling frequency, returns an array of
    cycle date-hours whose elements have the form YYYYMMDDHH.  Here,
    YYYY is a four-digit year, MM is a two- digit month, DD is a
    two-digit day of the month, and HH is a two-digit hour of the day.

    Args:
        start_time_first_cycl:
        Starting time of first cycle; a datetime object.

        start_time_last_cycl:
        Starting time of last cycle; a datetime object.

        cycl_intvl:
        Time interval between cycle starting times; a timedelta object.

    Returns:
        A list of strings containing cycle starting times in the format
        'YYYYMMDDHH'
    """

    print_input_args(locals())

    # iterate over cycles
    all_cdates = []
    cdate = start_time_first_cycl
    while cdate <= start_time_last_cycl:
        cyc = datetime.strftime(cdate, "%Y%m%d%H")
        all_cdates.append(cyc)
        cdate += cycl_intvl 
    return all_cdates


def set_fcst_output_times_and_obs_days_all_cycles(
    start_time_first_cycl, start_time_last_cycl, cycl_intvl, fcst_len, fcst_output_intvl):
    """Given the starting time of the first cycle of an SRW App experiment, the
    starting time of the last cycle, the interval between cycle start times,
    the forecast length, and the forecast output interval, this function
    returns two pairs of lists: the first of each pair is a list of strings
    of forecast output times over all cycles (each element of the form
    'YYYYMMDDHH'), and the second is a list of days over all cycles on which
    observations are needed to perform verification (each element of the form
    'YYYYMMDD').  The first pair of lists is for instantaneous output fields
    (e.g. REFC, RETOP, T2m), and the second pair is for cumulative ones (e.g.
    APCP or accumulated precipitation).  The accumulation period for the latter
    is the forecast output interval.

    Args:
        start_time_first_cycl:
        Starting time of first cycle; a datetime object.

        start_time_last_cycl:
        Starting time of last cycle; a datetime object.

        cycl_intvl:
        Time interval between cycle starting times; a timedelta object.

        fcst_len:
        The length of each forecast; a timedelta object.

        fcst_output_intvl:
        Time interval between forecast output times; a timedelta object.

    Returns:
        output_times_all_cycles_inst:
        List of forecast output times over all cycles of instantaneous fields.
        Each element is a string of the form 'YYYYMMDDHH'.

        obs_days_all_cycles_inst:
        List of observation days (i.e. days on which observations are needed to
        perform verification) over all cycles of instantaneous fields.  Each
        element is a string of the form 'YYYYMMDD'.

        output_times_all_cycles_cumul:
        List of forecast output times over all cycles of cumulative fields.  Each
        element is a string of the form 'YYYYMMDDHH'.

        obs_days_all_cycles_cumul:
        List of observation days (i.e. days on which observations are needed to
        perform verification) over all cycles of cumulative fields.  Each element
        is a string of the form 'YYYYMMDD'.

    """

    # Get the list containing the starting times of the cycles.  Each element
    # of the list is a string of the form 'YYYYMMDDHH'.
    cycle_start_times_str \
    = set_cycle_dates(start_time_first_cycl, start_time_last_cycl, cycl_intvl)

    # Convert cycle_start_times_str to a list of datetime objects.
    cycle_start_times = [datetime.strptime(yyyymmddhh, "%Y%m%d%H") for yyyymmddhh in cycle_start_times_str]

    # Get the number of forecast output times per cycle/forecast.
    num_output_times_per_cycle = int(fcst_len/fcst_output_intvl + 1)

    # Initialize sets that will contain the various forecast output and obs
    # day information.
    output_times_all_cycles_inst = set()
    obs_days_all_cycles_inst = set()
    output_times_all_cycles_cumul = set()
    obs_days_all_cycles_cumul = set()

    for i, start_time_crnt_cycle in enumerate(cycle_start_times):
        # Create a list of forecast output times of instantaneous fields for the
        # current cycle.
        output_times_crnt_cycle_inst \
        = [start_time_crnt_cycle + i*fcst_output_intvl
           for i in range(0,num_output_times_per_cycle)]
        # Include the output times of instantaneous fields for the current cycle 
        # in the set of all such output times over all cycles.
        output_times_all_cycles_inst \
        = output_times_all_cycles_inst | set(output_times_crnt_cycle_inst)

        # Create a list of instantaneous field obs days (i.e. days on which
        # observations of instantaneous fields are needed for verification) for
        # the current cycle.  We do this by dropping the hour-of-day from each
        # element of the list of forecast output times and keeping only unique
        # elements.
        tmp = [datetime_obj.date() for datetime_obj in output_times_crnt_cycle_inst]
        obs_days_crnt_cycl_inst = sorted(set(tmp))
        # Include the obs days for instantaneous fields for the current cycle 
        # in the set of all such obs days over all cycles.
        obs_days_all_cycles_inst = obs_days_all_cycles_inst | set(obs_days_crnt_cycl_inst)

        # Create a list of forecast output times of cumulative fields for the
        # current cycle.  This is simply the list of forecast output times for
        # instantaneous fields but with the first time dropped (because nothing
        # has yet accumulated at the starting time of the cycle).
        output_times_crnt_cycle_cumul = output_times_crnt_cycle_inst
        output_times_crnt_cycle_cumul.pop(0)
        # Include the obs days for cumulative fields for the current cycle in the
        # set of all such obs days over all cycles.
        output_times_all_cycles_cumul \
        = output_times_all_cycles_cumul | set(output_times_crnt_cycle_cumul)

        # Create a list of cumulative field obs days (i.e. days on which
        # observations of cumulative fields are needed for verification) for
        # the current cycle.  We do this by dropping the hour-of-day from each
        # element of the list of forecast output times and keeping only unique
        # elements.  Note, however, that before dropping the hour-of-day from
        # the list of forecast output times, we remove the last forecast output
        # time if it happens to be the 0th hour of a day.  This is because in
        # the scripts/tasks that get observations of cumulative fields, the
        # zeroth hour of a day is considered part of the previous day (because
        # it represents accumulation that occurred on the previous day).
        tmp = output_times_crnt_cycle_cumul
        last_output_time_cumul = output_times_crnt_cycle_cumul[-1]
        if last_output_time_cumul.hour == 0:
            tmp.pop()
        tmp = [datetime_obj.date() for datetime_obj in tmp]
        obs_days_crnt_cycl_cumul = sorted(set(tmp))
        # Include the obs days for cumulative fields for the current cycle in the
        # set of all such obs days over all cycles.
        obs_days_all_cycles_cumul = obs_days_all_cycles_cumul | set(obs_days_crnt_cycl_cumul)

    # Convert the set of output times of instantaneous fields over all cycles
    # to a sorted list of strings of the form 'YYYYMMDDHH'.
    output_times_all_cycles_inst = sorted(output_times_all_cycles_inst)
    output_times_all_cycles_inst = [datetime.strftime(output_times_all_cycles_inst[i], "%Y%m%d%H")
                                    for i in range(len(output_times_all_cycles_inst))]

    # Convert the set of obs days for instantaneous fields over all cycles
    # to a sorted list of strings of the form 'YYYYMMDD'.
    obs_days_all_cycles_inst = sorted(obs_days_all_cycles_inst)
    obs_days_all_cycles_inst = [datetime.strftime(obs_days_all_cycles_inst[i], "%Y%m%d")
                                for i in range(len(obs_days_all_cycles_inst))]

    # Convert the set of output times of cumulative fields over all cycles to
    # a sorted list of strings of the form 'YYYYMMDDHH'.
    output_times_all_cycles_cumul = sorted(output_times_all_cycles_cumul)
    output_times_all_cycles_cumul = [datetime.strftime(output_times_all_cycles_cumul[i], "%Y%m%d%H")
                                     for i in range(len(output_times_all_cycles_cumul))]

    # Convert the set of obs days for cumulative fields over all cycles to a
    # sorted list of strings of the form 'YYYYMMDD'.
    obs_days_all_cycles_cumul = sorted(obs_days_all_cycles_cumul)
    obs_days_all_cycles_cumul = [datetime.strftime(obs_days_all_cycles_cumul[i], "%Y%m%d")
                                 for i in range(len(obs_days_all_cycles_cumul))]

    return output_times_all_cycles_inst, obs_days_all_cycles_inst, \
           output_times_all_cycles_cumul, obs_days_all_cycles_cumul


def set_cycledefs_for_obs_days(obs_days_all_cycles):
    """Given a list of days on which obs are needed, this function generates a
    list of ROCOTO-style cycledef strings that together span the days (over
    all cycles of an SRW App experiment) on which obs are needed.  The input
    list of days must be increasing in time, but the days do not have to be
    consecutive, i.e. there may be gaps between days that are greater than
    one day.
    
    Each cycledef string in the output list represents a set of consecutive
    days in the input string (when used inside a <cycledef> tag in a ROCOTO
    XML).  Thus, when the cycledef strings in the output string are all 
    assigned to the same cycledef group in a ROCOTO XML, that group will
    represent all the days on which observations are needed.

    Args:
        obs_days_all_cycles:
        A list of strings of the form 'YYYYMMDD', with each string representing
        a day on which observations are needed.  Note that the list must be 
        sorted, i.e. the days must be increasing in time, but there may be
        gaps between days.

    Returns:
        cycledef_all_obs_days:
        A list of strings, with each string being a ROCOTO-style cycledef of
        the form

          '{yyyymmdd_start}0000 {yyyymmdd_end}0000 24:00:00'

        where {yyyymmdd_start} is the starting day of the first cycle in the
        cycledef, and {yyyymmdd_end} is the starting day of the last cycle (note
        that the minutes and hours in these cycledef stirngs are always set to 
        '00').  Thus, one of the elements of the output list may be as follows:

          '202404290000 202405010000 24:00:00'
    """

    # To enable arithmetic with dates, convert input sting list of observation
    # days (i.e. days on which observations are needed) over all cycles to a
    # list of datetime objects.
    tmp = [datetime.strptime(yyyymmdd, "%Y%m%d") for yyyymmdd in obs_days_all_cycles]

    # Initialize the variable that in the loop below contains the date of 
    # the previous day.  This is just the first element of the list of
    # datetime objects constructed above.  Then use it to initialize the
    # list (contin_obs_day_lists) that will contain lists of consecutive
    # observation days.  Thus, after its construction is complete, each
    # element of contin_obs_day_lists will itself be a list containing
    # datetime objects that are 24 hours apart.
    day_prev = tmp[0]
    contin_obs_day_lists = list()
    contin_obs_day_lists.append([day_prev])

    # Remove the first element of the list of obs days since it has already
    # been used initiliaze contin_obs_day_lists.
    tmp.pop(0)

    # Loop over the remaining list of obs days and construct the list of
    # lists of consecutive obs days.
    one_day = timedelta(days=1)
    for day_crnt in tmp:
        # If the current obs day comes 24 hours after the previous obs day, i.e.
        # if it is the next day of the previous obs day, append it to the last
        # existing list in contin_obs_day_lists.
        if day_crnt == day_prev + one_day:
            contin_obs_day_lists[-1].append(day_crnt)
        # If the current obs day is NOT the next day of the previous obs day,
        # append a new element to contin_obs_day_lists and initialize it as a
        # list containing a single element -- the current obs day.
        else:
            contin_obs_day_lists.append([day_crnt])
        # Update the value of the previous day in preparation for the next
        # iteration of the loop.
        day_prev = day_crnt

    # Use the list of lists of consecutive obs days to construct a list of
    # ROCOTO-style cycledef strings that each represent a set of consecutive
    # obs days when included in a <cycledef> tag in a ROCOTO XML.  Each
    # string in this new list corresponds to a series of consecutive days on
    # which observations are needed (where by "consecutive" we mean no days
    # are skipped), and there is at least a one day gap between each such
    # series.  These cycledefs together represent all the days (i.e. over all
    # cycles of the experiment) on which observations are needed.
    cycledef_all_obs_days = list()
    for contin_obs_day_list in contin_obs_day_lists:
        cycledef_start = contin_obs_day_list[0].strftime('%Y%m%d%H%M')
        cycledef_end = contin_obs_day_list[-1].strftime('%Y%m%d%H%M')
        cycledef_all_obs_days.append(' '.join([cycledef_start, cycledef_end, '24:00:00']))

    return cycledef_all_obs_days
