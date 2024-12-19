#!/usr/bin/env python3

from datetime import datetime, timedelta, date
from pprint import pprint
from textwrap import dedent
from python_utils import print_input_args, print_err_msg_exit
import logging


def set_cycle_dates(start_time_first_cycl, start_time_last_cycl, cycl_intvl,
                    return_type='string'):
    """
    This file defines a function that returns a list containing the starting
    times of all the cycles in the experiment.

    If return_type is set to 'string' (the default value), the returned list
    contains strings in the format 'YYYYMMDDHH'.  If it is set to 'datetime',
    the returned list contains a set of datetime objects.

    Args:
        start_time_first_cycl (datetime.datetime):
            Starting time of first cycle.

        start_time_last_cycl (datetime.datetime):
            Starting time of last cycle.

        cycl_intvl (datetime.timedelta):
            Time interval between cycle start times.

        return_type (str):
            Type of the returned list.  Can be 'string' or 'datetime'.

    Returns:
        all_cdates (list):
            Either a list of strings in the format 'YYYYMMDDHH' or a list of datetime
            objects containing the cycle starting times, where 'YYYY' is the four-
            digit year, 'MM is the two-digit month, 'DD' is the two-digit day-of-
            month, and 'HH' is the two-digit hour-of-day.
    """

    print_input_args(locals())

    valid_values = ['string', 'datetime']
    if return_type not in valid_values:
        msg = dedent(f"""
            Invalid value for optional argument "return_type":
                {return_type = }
            Valid values are:
                {valid_values = }
            """)
        logging.error(msg)
        raise ValueError(msg)

    # iterate over cycles
    all_cdates = []
    cdate = start_time_first_cycl
    while cdate <= start_time_last_cycl:
        all_cdates.append(cdate)
        cdate += cycl_intvl

    if return_type == 'string':
        all_cdates = [datetime.strftime(cdate, "%Y%m%d%H") for cdate in all_cdates]

    return all_cdates


def check_temporal_consistency_cumul_fields(
    vx_config, cycle_start_times, fcst_len, fcst_output_intvl):
    """
    This function reads in a subset of the parameters in the verification
    configuration dictionary and ensures that certain temporal constraints on
    these parameters are satisfied.  It then returns an updated version of
    the verification configuration dictionary that satisfies these constraints.

    The constraints are on the accumulation intervals associated with the
    cumulative field groups (and the corresponding observation types) that
    are to be verified.  The constraints on each such accumulation interval
    are as follows:

    1) The accumulation interval is less than or equal to the forecast length.
       This ensures that the forecast(s) can accumulate the field(s) in the
       field group over that interval.

    2) The obs availability interval evenly divides the accumulation interval.
       This ensures that the obs can be added together to obtain accumulated
       values of the obs field, e.g. the 6-hourly NOHRSC obs can be added to
       obtain 24-hour observed snowfall accumulations.  Note that this also
       ensures that the accumulation interval is greater than or equal to the
       obs availability interval.

    3) The forecast output interval evenly divides the accumulation interval.
       This ensures that the forecast output can be added together to obtain
       accumulated values of the fields in the field group.  For example, if
       the forecast output interval is 3 hours, the resulting 3-hourly APCP
       outputs from the forecast can be added to obtain 6-hourly forecast APCP.
       Note that this also ensures that the accumulation interval is greater
       than or equal to the forecast output interval.

    4) The hour-of-day at which the accumulated forecast values will be
       available are a subset of the ones at which the accumulated obs
       values are available.  This ensures that the accumulated fields
       from the obs and forecast are valid at the same times and thus can
       be compared in the verification.

    If for a given field-accumulation combination any of these constraints
    is violated, that accumulation is removed from the list of accumulations
    to verify for that field.

    Args:
        vx_config (dict):
            The verification configuration dictionary.

        cycle_start_times (list):
            List containing the starting times of the cycles in the experiment; each
            list element is a datetime object.

        fcst_len (datetime.timedelta):
            The length of each forecast; a timedelta object.

        fcst_output_intvl (datetime.timedelta):
            Time interval between forecast output times; a timedelta object.

    Returns:
        vx_config (dict):
            An updated version of the verification configuration dictionary.

        fcst_obs_matched_times_all_cycles_cumul (dict):
            Dictionary containing the times (in YYYYMMDDHH string format) at
            which various field/accumlation combinations are output and at
            which the corresponding obs type is also available.
    """

    # Set dictionary containing all field groups that consist of cumulative
    # fields (i.e. whether or not those field groups are to be verified).  
    # The keys are the observation types and the field groups.
    obtype_to_fg_dict_cumul = {"CCPA": "APCP", "NOHRSC": "ASNOW"}

    # Convert from datetime.timedelta objects to integers.
    one_hour = timedelta(hours=1)
    fcst_len_hrs = int(fcst_len/one_hour)
    fcst_output_intvl_hrs = int(fcst_output_intvl/one_hour)

    # Initialize one of the variables that will be returned to an empty
    # dictionary.
    fcst_obs_matched_times_all_cycles_cumul = dict()

    for obtype, fg in obtype_to_fg_dict_cumul.items():

        # If the current cumulative field is not in the list of fields to be
        # verified, just skip to the next field.
        if fg not in vx_config["VX_FIELD_GROUPS"]:
            continue

        # Initialize a sub-dictionary in one of the dictionaries to be returned.
        fcst_obs_matched_times_all_cycles_cumul.update({fg: {}})

        #
        # Get the availability interval of the current observation type from the
        # verification configuration dictionary and use it to calculate the hours-
        # of-day at which the obs will be available.
        #
        # Get the obs availability interval.
        config_var_name = "".join([obtype, "_OBS_AVAIL_INTVL_HRS"])
        obs_avail_intvl_hrs = vx_config[config_var_name]
        # Ensure that the obs availability interval evenly divides into 24.
        remainder = 24 % obs_avail_intvl_hrs
        if remainder != 0:
            msg = dedent(f"""
                The obs availability interval for obs of type {obtype} must divide evenly
                into 24 but doesn't:
                    {obs_avail_intvl_hrs = }
                    24 % obs_avail_intvl_hrs = {remainder}"
                """)
            logging.error(msg)
            raise ValueError(msg)
        # Assume that the obs are available at hour 0 of the day regardless
        # of obs type.
        obs_avail_hr_start = 0
        obs_avail_hr_end = obs_avail_hr_start + 24
        # Construct list of obs availability hours-of-day.
        obs_avail_hrs_of_day = list(range(obs_avail_hr_start, obs_avail_hr_end, obs_avail_intvl_hrs))
        obs_avail_hrs_of_day_str = ['%02d' % int(hr) for hr in obs_avail_hrs_of_day]
        #
        # Get the array of accumulation intervals for the current cumulative field.
        # Then loop over them to ensure that the constraints listed above are
        # satisfied.  If for a given accumulation one or more of the constraints
        # is not satisfied, remove that accumulation from the list of accumulations
        # for the current field.
        #
        accum_intvls_array_name = "".join(["VX_", fg, "_ACCUMS_HRS"])
        accum_intvls_hrs = vx_config[accum_intvls_array_name]
        #
        # Loop through the accumulation intervals and check the temporal constraints
        # listed above.
        #
        for accum_hrs in accum_intvls_hrs.copy():

            accum_hh = f"{accum_hrs:02d}"
            # Initialize a sub-sub-dictionary in one of the dictionaries to be returned.
            fcst_obs_matched_times_all_cycles_cumul[fg][accum_hh] = []
            #
            # Make sure that the accumulation interval is less than or equal to the
            # forecast length.
            #
            if accum_hrs > fcst_len_hrs:
                msg = dedent(f"""
                    The accumulation interval (accum_hrs) for the current cumulative field
                    group (fg) and corresponding observation type (obtype) is greater than
                    the forecast length (fcst_len_hrs):
                        {fg = }
                        {obtype = }
                        {accum_hrs = }
                        {fcst_len_hrs = }
                    Thus, the forecast(s) cannot accumulate the field(s) in this field group
                    over this interval.  Will remove this accumulation interval from the list
                    of accumulation intervals to verify for this field group/obtype.
                    """)
                logging.info(msg)
                accum_intvls_hrs.remove(accum_hrs)
            #
            # Make sure that accumulation interval is evenly divisible by the observation
            # availability interval.
            #
            if accum_hrs in accum_intvls_hrs:
                rem_obs = accum_hrs % obs_avail_intvl_hrs
                if rem_obs != 0:
                    msg = dedent(f"""
                        The accumulation interval (accum_hrs) for the current cumulative field
                        group (fg) and corresponding observation type (obtype) is not evenly
                        divisible by the observation type's availability interval (obs_avail_intvl_hrs):
                            {fg = }
                            {obtype = }
                            {accum_hrs = }
                            {obs_avail_intvl_hrs = }
                            accum_hrs % obs_avail_intvl_hrs = {rem_obs}
                        Thus, this observation type cannot be accumulated over this interval.
                        Will remove this accumulation interval from the list of accumulation
                        intervals to verify for this field group/obtype.
                        """)
                    logging.info(msg)
                    accum_intvls_hrs.remove(accum_hrs)
            #
            # Make sure that accumulation interval is evenly divisible by the forecast
            # output interval.
            #
            if accum_hrs in accum_intvls_hrs:
                rem_fcst = accum_hrs % fcst_output_intvl_hrs
                if rem_fcst != 0:
                    msg = dedent(f"""
                        The accumulation interval (accum_hrs) for the current cumulative field
                        group (fg) and corresponding observation type (obtype) is not evenly
                        divisible by the forecast output interval (fcst_output_intvl):
                            {fg = }
                            {obtype = }
                            {accum_hrs = }
                            {fcst_output_intvl_hrs = }
                            accum_hrs % fcst_output_intvl_hrs = {rem_fcst}
                        Thus, the forecast(s) cannot accumulate the field(s) in this field group
                        over this interval.  Will remove this accumulation interval from the list
                        of accumulation intervals to verify for this field group/obtype.
                        """)
                    logging.info(msg)
                    accum_intvls_hrs.remove(accum_hrs)
            #
            # Make sure that the hours-of-day at which the current cumulative field
            # will be output are a subset of the hours-of-day at which the corresponding
            # obs type is available.
            #
            if accum_hrs in accum_intvls_hrs:

                # Initialize sets that will contain the forecast output times of the
                # current cumulative field over all cycles.
                fcst_output_times_all_cycles = set()

                # Calculate the forecast output times of the current cumulative field
                # for the current cycle and include them in the the set of such times
                # over all cycles.
                accum = timedelta(hours=accum_hrs)
                num_fcst_output_times_per_cycle = int(fcst_len/accum)
                for i, start_time_crnt_cycle in enumerate(cycle_start_times):
                    fcst_output_times_crnt_cycle \
                    = [start_time_crnt_cycle + (i+1)*accum
                       for i in range(0, num_fcst_output_times_per_cycle)]
                    fcst_output_times_all_cycles \
                    = fcst_output_times_all_cycles | set(fcst_output_times_crnt_cycle)

                # Get all the hours-of-day at which the current cumulative field will be
                # output by the forecast.
                fcst_output_times_all_cycles = sorted(fcst_output_times_all_cycles)
                fcst_output_times_all_cycles_str \
                = [datetime.strftime(dt_object, "%Y%m%d%H")
                   for dt_object in fcst_output_times_all_cycles]
                fcst_output_hrs_of_day_str = [yyyymmddhh[8:10] for yyyymmddhh in fcst_output_times_all_cycles_str]
                fcst_output_hrs_of_day_str.sort()

                # Check that all the forecast output hours-of-day are a subset of the obs
                # availability hours-of-day.  If not, remove the current accumulation
                # interval from the list of intervals to verify.
                if not set(fcst_output_hrs_of_day_str) <= set(obs_avail_hrs_of_day_str):
                    msg = dedent(f"""
                        The accumulation interval (accum_hrs) for the current cumulative field
                        group (fg) is such that the forecast will output the field(s) in the 
                        field group at at least one hour-of-day at which the corresponding
                        observation type is not available:
                            {fg = }
                            {obtype = }
                            {accum_hrs = }
                        The forecast output hours-of-day for this field group/accumulation interval
                        combination are:
                            {fcst_output_hrs_of_day_str = }
                        The hours-of-day at which the obs are available are:
                            {obs_avail_hrs_of_day_str = }
                        Thus, at least some of the forecast output cannot be verified.  Will remove
                        this accumulation interval from the list of accumulation intervals to verify
                        for this field group/obtype.
                        """)
                    logging.info(msg)
                    accum_intvls_hrs.remove(accum_hrs)
                else:
                    fcst_obs_matched_times_all_cycles_cumul[fg][accum_hh] = fcst_output_times_all_cycles_str
        #
        # Update the value in the experiment configuration dictionary of the list
        # of accumulation intervals to verify for this cumulative field (since
        # some accumulation intervals may have been removed after the checks above).
        #
        vx_config[accum_intvls_array_name] = accum_intvls_hrs
        #
        # If the updated list of accumulations for the current cumulative field
        # is empty, remove the field from the list of fields to verify in the
        # verification configuration dictionary.
        #
        if not accum_intvls_hrs:
            vx_config["VX_FIELD_GROUPS"].remove(fg)
            msg = dedent(f"""
                The list of accumulation intervals (accum_intvls_hrs) for the current
                cumulative field group to verify (fg) is empty:
                    {fg = }
                    {accum_intvls_hrs = }
                Removing this field from the list of fields to verify.  The updated list
                is:
                    {vx_config["VX_FIELD_GROUPS"]}
                """)
            logging.info(msg)

    return vx_config, fcst_obs_matched_times_all_cycles_cumul


def set_fcst_output_times_and_obs_days_all_cycles(
    cycle_start_times, fcst_len, fcst_output_intvl):
    """
    This function returns forecast output times and observation days (i.e.
    days on which obs are needed because there is forecast output on those
    days) for both instantaneous (e.g. REFC, RETOP, T2m) and cumulative (e.g.
    APCP) fields that need to be verified.  Note that for cumulative fields,
    the only accumulation interval considered is the forecast output interval.
    Accumulation intervals larger than this are considered elsewhere (and
    accumulation interval smaller than this are obviously not allowed).

    Args:
        cycle_start_times (list):
            List containing the starting times of the cycles in the experiment; each
            list element is a datetime object.

        fcst_len (datetime.timedelta):
            The length of each forecast.

        fcst_output_intvl (datetime.timedelta):
            Time interval between forecast output times.

    Returns:
        fcst_output_times_all_cycles (dict):
            Dictionary containing a list of forecast output times over all cycles for
            instantaneous fields and a second analogous list for cumulative fields.
            Each element of these lists is a string of the form 'YYYYMMDDHH'.

        obs_days_all_cycles (dict):
            Dictionary containing a list of observation days (i.e. days on which
            observations are needed to perform verification) over all cycles for
            instantaneous fields and a second analogous list for cumulative fields.
            Each element of these lists is a string of the form 'YYYYMMDD'.
    """

    # Get the number of forecast output times per cycle/forecast.
    num_fcst_output_times_per_cycle = int(fcst_len/fcst_output_intvl + 1)

    # Initialize dictionaries that will contain the various forecast output
    # time and obs day information.  Note that we initialize the contents of
    # these dictionaries as sets because that better suites the data manipulation
    # we will need to do, but these sets will later be converted to lists.
    fcst_output_times_all_cycles = dict()
    fcst_output_times_all_cycles['inst'] = set()
    fcst_output_times_all_cycles['cumul'] = set()
    obs_days_all_cycles = dict()
    obs_days_all_cycles['inst'] = set()
    obs_days_all_cycles['cumul'] = set()

    for i, start_time_crnt_cycle in enumerate(cycle_start_times):
        # Create a list of forecast output times of instantaneous fields for the
        # current cycle.
        fcst_output_times_crnt_cycle_inst \
        = [start_time_crnt_cycle + i*fcst_output_intvl
           for i in range(0,num_fcst_output_times_per_cycle)]
        # Include the output times of instantaneous fields for the current cycle
        # in the set of all such output times over all cycles.
        fcst_output_times_all_cycles['inst'] \
        = fcst_output_times_all_cycles['inst'] | set(fcst_output_times_crnt_cycle_inst)

        # Create a list of instantaneous field obs days (i.e. days on which
        # observations of instantaneous fields are needed for verification) for
        # the current cycle.  We do this by dropping the hour-of-day from each
        # element of the list of forecast output times and keeping only unique
        # elements.
        tmp = [datetime_obj.date() for datetime_obj in fcst_output_times_crnt_cycle_inst]
        obs_days_crnt_cycl_inst = sorted(set(tmp))
        # Include the obs days for instantaneous fields for the current cycle
        # in the set of all such obs days over all cycles.
        obs_days_all_cycles['inst'] = obs_days_all_cycles['inst'] | set(obs_days_crnt_cycl_inst)

        # Create a list of forecast output times of cumulative fields for the
        # current cycle.  This is simply the list of forecast output times for
        # instantaneous fields but with the first time dropped (because nothing
        # has yet accumulated at the starting time of the cycle).
        fcst_output_times_crnt_cycle_cumul = fcst_output_times_crnt_cycle_inst
        fcst_output_times_crnt_cycle_cumul.pop(0)
        # Include the obs days for cumulative fields for the current cycle in the
        # set of all such obs days over all cycles.
        fcst_output_times_all_cycles['cumul'] \
        = fcst_output_times_all_cycles['cumul'] | set(fcst_output_times_crnt_cycle_cumul)

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
        tmp = fcst_output_times_crnt_cycle_cumul
        last_output_time_cumul = fcst_output_times_crnt_cycle_cumul[-1]
        if last_output_time_cumul.hour == 0:
            tmp.pop()
        tmp = [datetime_obj.date() for datetime_obj in tmp]
        obs_days_crnt_cycl_cumul = sorted(set(tmp))
        # Include the obs days for cumulative fields for the current cycle in the
        # set of all such obs days over all cycles.
        obs_days_all_cycles['cumul'] = obs_days_all_cycles['cumul'] | set(obs_days_crnt_cycl_cumul)

    # Convert the set of output times of instantaneous fields over all cycles
    # to a sorted list of strings of the form 'YYYYMMDDHH'.
    fcst_output_times_all_cycles['inst'] = sorted(fcst_output_times_all_cycles['inst'])
    fcst_output_times_all_cycles['inst'] \
    = [datetime.strftime(fcst_output_times_all_cycles['inst'][i], "%Y%m%d%H")
       for i in range(len(fcst_output_times_all_cycles['inst']))]

    # Convert the set of obs days for instantaneous fields over all cycles
    # to a sorted list of strings of the form 'YYYYMMDD'.
    obs_days_all_cycles['inst'] = sorted(obs_days_all_cycles['inst'])
    obs_days_all_cycles['inst'] \
    = [datetime.strftime(obs_days_all_cycles['inst'][i], "%Y%m%d")
       for i in range(len(obs_days_all_cycles['inst']))]

    # Convert the set of output times of cumulative fields over all cycles to
    # a sorted list of strings of the form 'YYYYMMDDHH'.
    fcst_output_times_all_cycles['cumul'] = sorted(fcst_output_times_all_cycles['cumul'])
    fcst_output_times_all_cycles['cumul'] \
    = [datetime.strftime(fcst_output_times_all_cycles['cumul'][i], "%Y%m%d%H")
       for i in range(len(fcst_output_times_all_cycles['cumul']))]

    # Convert the set of obs days for cumulative fields over all cycles to a
    # sorted list of strings of the form 'YYYYMMDD'.
    obs_days_all_cycles['cumul'] = sorted(obs_days_all_cycles['cumul'])
    obs_days_all_cycles['cumul'] \
    = [datetime.strftime(obs_days_all_cycles['cumul'][i], "%Y%m%d")
       for i in range(len(obs_days_all_cycles['cumul']))]

    return fcst_output_times_all_cycles, obs_days_all_cycles


def set_rocoto_cycledefs_for_obs_days(obs_days_all_cycles):
    """
    Given a list of days on which observations are needed (because there is
    forecast output on those days), this function generates a list of ROCOTO-
    style cycledef strings that together span the days (over all cycles of an
    SRW App experiment) on which obs are needed.  The input list of days must
    be increasing in time, but the days do not have to be consecutive, i.e.
    there may be gaps between days that are greater than one day.

    Each cycledef string in the output list represents a set of consecutive
    days in the input string (when used inside a <cycledef> tag in a ROCOTO
    XML).  Thus, when the cycledef strings in the output string are all
    assigned to the same cycledef group in a ROCOTO XML, that group will
    represent all the days on which observations are needed.  This allows
    the ROCOTO workflow to define a single set of non-consecutive days on
    which obs are needed and define tasks (e.g. get_obs) only for those
    days, thereby avoiding the redundant creation of these tasks for any
    in-between days on which obs are not needed.

    Args:
        obs_days_all_cycles (list):
            A list of strings of the form 'YYYYMMDD', with each string representing
            a day on which observations are needed.  Note that the list must be sorted,
            i.e. the days must be increasing in time, but there may be gaps between
            days.

    Returns:
        cycledefs_all_obs_days (list):
            A list of strings, with each string being a ROCOTO-style cycledef of the
            form
            
                '{yyyymmdd_start}0000 {yyyymmdd_end}0000 24:00:00'
            
            where {yyyymmdd_start} is the starting day of the first cycle in the
            cycledef and {yyyymmdd_end} is the starting day of the last cycle (note
            that the minutes and hours in these cycledef stirngs are always set to
            '00').  For example, an element of the output list may be:
            
                '202404290000 202405010000 24:00:00'
    """

    # To enable arithmetic with dates, convert input sting list of observation
    # days (i.e. days on which observations are needed) over all cycles to a
    # list of datetime objects.
    tmp = [datetime.strptime(yyyymmdd, "%Y%m%d") for yyyymmdd in obs_days_all_cycles]

    # Initialize the variable that in the loop below contains the date of
    # the previous day.  This is just the first element of the list of
    # datetime objects constructed above.  Then use it to initialize the
    # list (consec_obs_days_lists) that will contain lists of consecutive
    # observation days.  Thus, after its construction is complete, each
    # element of consec_obs_days_lists will itself be a list containing
    # datetime objects that represent consecutive days (i.e. are guaranteed
    # to be 24 hours apart).
    day_prev = tmp[0]
    consec_obs_days_lists = list()
    consec_obs_days_lists.append([day_prev])

    # Remove the first element of the list of obs days since it has already
    # been used initiliaze consec_obs_days_lists.
    tmp.pop(0)

    # Loop over the remaining list of obs days and construct the list of
    # lists of consecutive obs days.
    one_day = timedelta(days=1)
    for day_crnt in tmp:
        # If the current obs day comes 24 hours after the previous obs day, i.e.
        # if it is the next day of the previous obs day, append it to the last
        # existing list in consec_obs_days_lists.
        if day_crnt == day_prev + one_day:
            consec_obs_days_lists[-1].append(day_crnt)
        # If the current obs day is NOT the next day of the previous obs day,
        # append a new element to consec_obs_days_lists and initialize it as a
        # list containing a single element -- the current obs day.
        else:
            consec_obs_days_lists.append([day_crnt])
        # Update the value of the previous day in preparation for the next
        # iteration of the loop.
        day_prev = day_crnt

    # Use the list of lists of consecutive obs days to construct a list of
    # ROCOTO-style cycledef strings that each represent a set of consecutive
    # obs days when included in a <cycledef> tag in a ROCOTO XML.  Each
    # string in this new list corresponds to a series of consecutive days on
    # which observations are needed (where by "consecutive" we mean no days
    # are skipped), and there is at least a one-day gap between each such
    # series.  These cycledefs together represent all the days (i.e. over all
    # cycles of the experiment) on which observations are needed.
    cycledefs_all_obs_days = list()
    for consec_obs_days_list in consec_obs_days_lists:
        cycledef_start = consec_obs_days_list[0].strftime('%Y%m%d%H%M')
        cycledef_end = consec_obs_days_list[-1].strftime('%Y%m%d%H%M')
        cycledefs_all_obs_days.append(' '.join([cycledef_start, cycledef_end, '24:00:00']))

    return cycledefs_all_obs_days


def get_obs_retrieve_times_by_day(
    vx_config, cycle_start_times, fcst_len,
    fcst_output_times_all_cycles, obs_days_all_cycles):
    """
    This function generates dictionary of dictionaries that, for each
    combination of obs type needed and each obs day, contains a string list
    of the times at which that type of observation is needed on that day.
    The elements of each list are formatted as 'YYYYMMDDHH'.

    Args:
        vx_config (dict):
            The verification configuration dictionary.

        cycle_start_times (list):
            List containing the starting times of the cycles in the experiment; each
            list element is a datetime object.

        fcst_len (datetime.timedelta):
            The length of each forecast.

        fcst_output_times_all_cycles (dict):
            Dictionary containing a list of forecast output times over all cycles for
            instantaneous fields and a second analogous list for cumulative fields.
            Each element of these lists is a string of the form 'YYYYMMDDHH'.

        obs_days_all_cycles (dict):
            Dictionary containing a list of observation days (i.e. days on which
            observations are needed to perform verification) over all cycles for
            instantaneous fields and a second analogous list for cumulative fields.
            Each element of these lists is a string of the form 'YYYYMMDD'.

    Returns:
        obs_retrieve_times_by_day (dict):
            Dictionary of dictionaries containing times at which each type of obs is
            needed on each obs day.
    """

    # Convert string contents of input dictionaries to datetime objects.
    for time_type in ['cumul', 'inst']:
        fcst_output_times_all_cycles[time_type] \
        = [datetime.strptime(fcst_output_times_all_cycles[time_type][i], "%Y%m%d%H")
                             for i in range(len(fcst_output_times_all_cycles[time_type]))]
        obs_days_all_cycles[time_type] \
        = [datetime.strptime(obs_days_all_cycles[time_type][i], "%Y%m%d")
                             for i in range(len(obs_days_all_cycles[time_type]))]

    # Get list of field groups to be verified.
    vx_field_groups = vx_config['VX_FIELD_GROUPS']

    # Define a list of dictionaries containing information about all the obs
    # types that can possibly be used for verification in the SRW App.  Each
    # dictionary in the list contains the name of the obs type, the temporal
    # nature of that obs type (i.e. whether the obs type contains cumulative
    # or instantaneous fields), and a list of the field groups that the obs
    # type may be used to verify.
    all_obs_info \
    = [{'obtype': 'CCPA',   'time_type': 'cumul', 'field_groups': ['APCP']},
       {'obtype': 'NOHRSC', 'time_type': 'cumul', 'field_groups': ['ASNOW']},
       {'obtype': 'MRMS',   'time_type': 'inst',  'field_groups': ['REFC', 'RETOP']},
       {'obtype': 'NDAS',   'time_type': 'inst',  'field_groups': ['SFC', 'UPA']},
       {'obtype': 'AERONET',   'time_type': 'inst',  'field_groups': ['AOD']},
       {'obtype': 'AIRNOW',   'time_type': 'inst',  'field_groups': ['PM25', 'PM10']}
      ]

    # Create new list that has the same form as the list of dictionaries
    # defined above but contains only those obs types that have at least one
    # field group that appears in the list of field groups to verify.  Note
    # that for those obs types that are retained in the list, the field groups
    # that will not be verified are discarded.
    obs_info = []
    for obs_dict in all_obs_info.copy():
        obtype = obs_dict['obtype']
        field_groups = obs_dict['field_groups']
        field_groups = [field for field in field_groups if field in vx_field_groups]
        obs_dict = obs_dict.copy()
        obs_dict['field_groups'] = field_groups
        if field_groups: obs_info.append(obs_dict)

    # For convenience, define timedelta object representing a single day.
    one_day = timedelta(days=1)

    # Generate a dictionary (of dictionaries) that, for each obs type to be
    # used in the vx and for each day for which there is forecast output,
    # will contain the times at which verification will be performed, i.e.
    # the times at which the forecast output will be compared to observations.
    # We refer to these times as the vx comparison times.
    vx_compare_times_by_day = dict()
    for obs_dict in obs_info:
        obtype = obs_dict['obtype']
        obs_time_type = obs_dict['time_type']

        fcst_output_times_all_cycles_crnt_ttype = fcst_output_times_all_cycles[obs_time_type]
        obs_days_all_cycles_crnt_ttype = obs_days_all_cycles[obs_time_type]

        vx_compare_times_by_day[obtype] = dict()

        # Get the availability interval for the current observation type from the
        # verification configuration dictionary.  Then make sure it divides evenly
        # into 24.
        config_var_name = "".join([obtype, "_OBS_AVAIL_INTVL_HRS"])
        obs_avail_intvl_hrs = vx_config[config_var_name]
        remainder = 24 % obs_avail_intvl_hrs
        if remainder != 0:
            msg = dedent(f"""
                The obs availability interval for obs of type {obtype} must divide evenly
                into 24 but doesn't:
                  obs_avail_intvl_hrs = {obs_avail_intvl_hrs}
                  24 % obs_avail_intvl_hrs = {remainder}"
                """)
            logging.error(msg)
            raise Exception(msg)
        obs_avail_intvl = timedelta(hours=obs_avail_intvl_hrs)
        num_obs_avail_times_per_day = int(24/obs_avail_intvl_hrs)

        # Loop over all obs days over all cycles (for the current obs type).  For
        # each such day, get the list forecast output times and the list of obs
        # availability times.  Finally, set the times (on that day) that verification
        # will be performed to the intersection of these two lists.
        for obs_day in obs_days_all_cycles_crnt_ttype:

            next_day = obs_day + one_day
            if obs_time_type == "cumul":
                fcst_output_times_crnt_day \
                = [time for time in fcst_output_times_all_cycles_crnt_ttype if obs_day < time <= next_day]
            elif obs_time_type == "inst":
                fcst_output_times_crnt_day \
                = [time for time in fcst_output_times_all_cycles_crnt_ttype if obs_day <= time < next_day]
            fcst_output_times_crnt_day = [datetime.strftime(time, "%Y%m%d%H") for time in fcst_output_times_crnt_day]

            if obs_time_type == "cumul":
                obs_avail_times_crnt_day \
                = [obs_day + (i+1)*obs_avail_intvl for i in range(0,num_obs_avail_times_per_day)]
            elif obs_time_type == "inst":
                obs_avail_times_crnt_day \
                = [obs_day + i*obs_avail_intvl for i in range(0,num_obs_avail_times_per_day)]
            obs_avail_times_crnt_day = [datetime.strftime(time, "%Y%m%d%H") for time in obs_avail_times_crnt_day]

            vx_compare_times_crnt_day = list(set(fcst_output_times_crnt_day) & set(obs_avail_times_crnt_day))
            vx_compare_times_crnt_day.sort()

            obs_day_str = datetime.strftime(obs_day, "%Y%m%d")
            vx_compare_times_by_day[obtype][obs_day_str] = vx_compare_times_crnt_day

    # For each obs type to be used in the vx and for each day for which there
    # is forecast output, calculate the times at which obs need to be retrieved.
    # For instantaneous fields, the obs retrieval times are the same as the
    # times at which vx will be performed.  For cumulative fields, each field
    # value needs to be constructed by adding values from previous times.  For
    # example, if we're verifying 6-hourly precipitation and the obs availability
    # interval for precip obs (CCPA) is 1 hour, then the 6-hourly values must
    # be built by adding the 1-hour values.  Thus, this requires obs at every
    # hour, not just every 6 hours.
    #
    # First, initialze the dictionary (of dictionaries) that will contain the
    # obs retreival times (for all obs types and each day for which there is
    # forecast output), and set the values for instantaneous obs to the vx
    # comparison times calculated above.
    obs_retrieve_times_by_day = dict()
    for obs_dict in obs_info:
        obtype = obs_dict['obtype']
        obs_time_type = obs_dict['time_type']
        if obs_time_type == 'inst':
            obs_retrieve_times_by_day[obtype] = vx_compare_times_by_day[obtype]

    # Next, calculate the obs retrieval times for cumulative fields.  We want
    # these times grouped into days because the get_obs workflow tasks that
    # will use this information are day-based (i.e. each task will get obs
    # for a single day).  However, it is easier to first calculate these
    # times as a single group over all cycles.  We do this next.
    obs_retrieve_times_all_cycles = dict()
    for obs_dict in obs_info:

        obtype = obs_dict['obtype']
        obs_time_type = obs_dict['time_type']
        field_groups = obs_dict['field_groups']

        # Consider only cumulative fields.
        if obs_time_type != 'cumul':
            continue

        # Initialize the set that will contain the obs retrieval times over all
        # cycles.
        obs_retrieve_times_all_cycles[obtype] = set()

        # Get the availability interval for the current observation type from the
        # verification configuration dictionary.
        config_var_name = "".join([obtype, "_OBS_AVAIL_INTVL_HRS"])
        obs_avail_intvl_hrs = vx_config[config_var_name]
        obs_avail_intvl = timedelta(hours=obs_avail_intvl_hrs)

        # Consider all field groups to be verified for the current obs type.
        for fg in field_groups:

            # Get the list of accumulation intervals for the current cumulative obs
            # type and field group combination.
            accum_intvls_array_name = "".join(["VX_", fg, "_ACCUMS_HRS"])
            accum_intvls_hrs = vx_config[accum_intvls_array_name]

            for cycle_start_time in cycle_start_times:

                # Loop through the accumulation intervals for this obs type and field
                # group combination.
                for accum_intvl_hrs in accum_intvls_hrs:
                    accum_intvl = timedelta(hours=accum_intvl_hrs)
                    # Get the number of accumulation intervals that fits in the duration of
                    # the forecast.  Note that the accumulation interval doesn't necessarily
                    # have to evenly divide the forecast duration; we simply drop any fractional
                    # accumulation intervals by rounding down to the nearest integer.
                    num_accum_intvls_in_fcst = int(fcst_len/accum_intvl)
                    # Calulate the times at which the current cumulative obs field will be
                    # compared to the forecast field(s) in the corresponding cumulative field
                    # group (for the current accumulation interval).
                    vx_compare_times_crnt_cycl = [cycle_start_time + (i+1)*accum_intvl
                                                  for i in range(0,num_accum_intvls_in_fcst)]
                    # For each such comparison time, get the times at which obs are needed
                    # to form that accumulation.  For example, if the current accumulation
                    # interval is 6 hours and the obs are available every hour, then the
                    # times at which obs are needed will be the comparison time as well as
                    # the five hours preceeding it.  Then put all such times over all vx
                    # comparison times within all cycles into a single array of times (which
                    # is stored in the dictionary obs_retrieve_times_all_cycles).
                    for vx_compare_time in vx_compare_times_crnt_cycl:
                        remainder = accum_intvl_hrs % obs_avail_intvl_hrs
                        if remainder != 0:
                            msg = dedent(f"""
                                The obs availability interval for obs of type {obtype} must divide evenly
                                into the current accumulation interval (accum_intvl) but doesn't:
                                  accum_intvl_hrs = {accum_intvl_hrs}
                                  obs_avail_intvl_hrs = {obs_avail_intvl_hrs}
                                  accum_intvl_hrs % obs_avail_intvl_hrs = {remainder}"
                                """)
                            logging.error(msg)
                            raise Exception(msg)
                        num_obs_avail_times_in_accum_intvl = int(accum_intvl/obs_avail_intvl)
                        obs_retrieve_times_crnt_accum_intvl \
                        = [vx_compare_time - i*obs_avail_intvl \
                           for i in range(0,num_obs_avail_times_in_accum_intvl)]
                        obs_retrieve_times_all_cycles[obtype] \
                        = obs_retrieve_times_all_cycles[obtype] | set(obs_retrieve_times_crnt_accum_intvl)

            # Convert the final set of obs retrieval times for the current obs type
            # to a sorted list.  Note that the sorted() function will convert a set
            # to a sorted list (a set itself cannot be sorted).
            obs_retrieve_times_all_cycles[obtype] = sorted(obs_retrieve_times_all_cycles[obtype])

    # Now that the obs retrival times for cumulative fields have been obtained
    # but grouped by cycle start date, regroup them by day and save results
    # in obs_retrieve_times_by_day.
    for obs_dict in obs_info:
        obtype = obs_dict['obtype']
        obs_time_type = obs_dict['time_type']

        # Consider only cumulative obs/fields.
        if obs_time_type != 'cumul':
            continue

        # Initialize variables before looping over obs days.
        obs_retrieve_times_by_day[obtype] = dict()
        obs_days_all_cycles_crnt_ttype = obs_days_all_cycles[obs_time_type]
        obs_retrieve_times_all_cycles_crnt_obtype = obs_retrieve_times_all_cycles[obtype]

        for obs_day in obs_days_all_cycles_crnt_ttype:
            next_day = obs_day + one_day
            obs_retrieve_times_crnt_day \
            = [time for time in obs_retrieve_times_all_cycles_crnt_obtype if obs_day < time <= next_day]
            obs_retrieve_times_crnt_day = [datetime.strftime(time, "%Y%m%d%H") for time in obs_retrieve_times_crnt_day]
            obs_day_str = datetime.strftime(obs_day, "%Y%m%d")
            obs_retrieve_times_by_day[obtype][obs_day_str] = obs_retrieve_times_crnt_day

    return obs_retrieve_times_by_day
