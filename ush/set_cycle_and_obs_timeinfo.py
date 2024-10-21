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

    If return_type is set to "string" (the default value), the returned list
    contains strings in the format 'YYYYMMDDHH'.  If it is set to "datetime",
    the returned list contains a set of datetime objects.

    Args:
        start_time_first_cycl:
        Starting time of first cycle; a datetime object.

        start_time_last_cycl:
        Starting time of last cycle; a datetime object.

        cycl_intvl:
        Time interval between cycle starting times; a timedelta object.

        return_type:
        String that specifies the type of the returned list.

    Returns:
        all_cdates:
        Either a list of strings in the format 'YYYYMMDDHH' or a list of datetime
        objects containing the cycle starting times, where 'YYYY' is the four-
        digit year, 'MM is the two-digit month, 'DD'' is the two-digit day-of-
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

    if return_type == "string":
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
    cumulative forecast fields (and corresponding observation type pairs) that
    are to be verified.  The constraints on each such accumulation interval
    are as follows:

    1) The accumulation interval is less than or equal to the forecast length
       (since otherwise, the forecast field cannot be accumulated over that
       interval).

    2) The obs availability interval evenly divides the accumulation interval.
       This ensures that the obs can be added together to obtain accumulated
       values of the obs field, e.g. the 6-hourly NOHRSC obs can be added to
       obtain 24-hour observed snowfall accumulations.  Note that this also
       ensures that the accumulation interval is greater than or equal to the
       obs availability interval.

    3) The forecast output interval evenly divides the accumulation interval.
       This ensures that the forecast output can be added together to obtain
       accumulated values of the forecast field, e.g. if the forecast output
       interval is 3 hours, the resulting 3-hourly APCP outputs from the forecast
       can be added to obtain 6-hourly forecast APCP.  Note that this also ensures
       that the accumulation interval is greater than or equal to the forecast
       output interval.

    4) The hour-of-day at which the accumulated forecast values will be
       available are a subset of the ones at which the accumulated obs
       values are available.  This ensures that the accumulated fields
       from the obs and forecast are valid at the same times and thus can
       be compared in the verification.

    If for a given field-accumulation combination any of these constraints
    is violated, that accumulation is removed from the list of accumulations
    to verify for that field.

    Args:
        vx_config:
        The verification configuration dictionary.

        cycle_start_times:
        List containing the starting times of the cycles in the experiment;
        each list element is a datetime object.

        fcst_len:
        The length of each forecast; a timedelta object.

        fcst_output_intvl:
        Time interval between forecast output times; a timedelta object.

    Returns:
        vx_config:
        An updated version of the verification configuration dictionary.

        fcst_obs_matched_times_all_cycles_cumul:
        Dictionary containing the times (in YYYYMMDDHH string format) at
        which various field/accumlation combinations are output and at
        which the corresponding obs type is also available.
    """
    # Set dictionary containing all cumulative fields (i.e. whether or not
    # they are to be verified).  The keys are the observation types and the
    # values are the field names in the forecasts.
    vx_cumul_fields_all = {"CCPA": "APCP", "NOHRSC": "ASNOW"}

    # Convert from datetime.timedelta objects to integers.
    one_hour = timedelta(hours=1)
    fcst_len_hrs = int(fcst_len/one_hour)
    fcst_output_intvl_hrs = int(fcst_output_intvl/one_hour)

    # Initialize one of the variables that will be returned to an empty
    # dictionary.
    fcst_obs_matched_times_all_cycles_cumul = dict()

    for obtype, field_fcst in vx_cumul_fields_all.items():

        # If the current cumulative field is not in the list of fields to be
        # verified, just skip to the next field.
        if field_fcst not in vx_config["VX_FIELDS"]:
            continue

        # Initialize a sub-dictionary in one of the dictionaries to be returned.
        fcst_obs_matched_times_all_cycles_cumul.update({field_fcst: {}})

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
        accum_intvls_array_name = "".join(["VX_", field_fcst, "_ACCUMS_HRS"])
        accum_intvls_hrs = vx_config[accum_intvls_array_name]
        #
        # Loop through the accumulation intervals and check the temporal constraints
        # listed above.
        #
        for accum_hrs in accum_intvls_hrs.copy():

            accum_hh = f"{accum_hrs:02d}"
            # Initialize a sub-sub-dictionary in one of the dictionaries to be returned.
            fcst_obs_matched_times_all_cycles_cumul[field_fcst][accum_hh] = []
            #
            # Make sure that the accumulation interval is less than or equal to the
            # forecast length.
            #
            if accum_hrs > fcst_len_hrs:
                msg = dedent(f"""
                    The accumulation interval (accum_hrs) for the current cumulative forecast
                    field (field_fcst) and corresponding observation type (obtype) is greater
                    than the forecast length (fcst_len_hrs):
                        {field_fcst = }
                        {obtype = }
                        {accum_hrs = }
                        {fcst_len_hrs = }
                    Thus, this forecast field cannot be accumulated over this interval.  Will
                    remove this accumulation interval from the list of accumulation intervals
                    to verify for this field/obtype.
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
                        The accumulation interval (accum_hrs) for the current cumulative forecast
                        field (field_fcst) and corresponding observation type (obtype) is not
                        evenly divisible by the observation type's availability interval
                        (obs_avail_intvl_hrs):
                            {field_fcst = }
                            {obtype = }
                            {accum_hrs = }
                            {obs_avail_intvl_hrs = }
                            accum_hrs % obs_avail_intvl_hrs = {rem_obs}
                        Thus, this observation type cannot be accumulated over this interval.
                        Will remove this accumulation interval from the list of accumulation
                        intervals to verify for this field/obtype.
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
                        The accumulation interval (accum_hrs) for the current cumulative forecast
                        field (field_fcst) and corresponding observation type (obtype) is not
                        evenly divisible by the forecast output interval (fcst_output_intvl):
                            {field_fcst = }
                            {obtype = }
                            {accum_hrs = }
                            {fcst_output_intvl_hrs = }
                            accum_hrs % fcst_output_intvl_hrs = {rem_fcst}
                        Thus, this forecast field cannot be accumulated over this interval.  Will
                        remove this accumulation interval from the list of accumulation intervals
                        to verify for this field/obtype.
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
                        The accumulation interval (accum_hrs) for the current cumulative forecast
                        field (field_fcst) is such that the forecast will output the field on at
                        least one of hour-of-day on which the corresponding observation type is
                        not available:
                            {field_fcst = }
                            {obtype = }
                            {accum_hrs = }
                        The forecast output hours-of-day for this field/accumulation interval
                        combination are:
                            {fcst_output_hrs_of_day_str = }
                        The hours-of-day at which the obs are available are:
                            {obs_avail_hrs_of_day_str = }
                        Thus, at least some of the forecast output cannot be verified.  Will remove
                        this accumulation interval from the list of accumulation intervals to
                        verify for this field/obtype.
                        """)
                    logging.info(msg)
                    accum_intvls_hrs.remove(accum_hrs)
                else:
                    fcst_obs_matched_times_all_cycles_cumul[field_fcst][accum_hh] = fcst_output_times_all_cycles_str
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
            vx_config["VX_FIELDS"].remove(field_fcst)
            msg = dedent(f"""
                The list of accumulation intervals (accum_intvls_hrs) for the current
                cumulative field to verify (field_fcst) is empty:
                    {field_fcst = }
                    {accum_intvls_hrs = }
                Removing this field from the list of fields to verify.  The updated list
                is:
                    {vx_config["VX_FIELDS"]}
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
        cycle_start_times:
        List containing the starting times of the cycles in the experiment;
        each list element is a datetime object.

        fcst_len:
        The length of each forecast; a timedelta object.

        fcst_output_intvl:
        Time interval between forecast output times; a timedelta object.

    Returns:
        fcst_output_times_all_cycles:
        Dictionary containing a list of forecast output times over all cycles for
        instantaneous fields and a second analogous list for cumulative fields.
        Each element of these lists is a string of the form 'YYYYMMDDHH'.

        obs_days_all_cycles:
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
        obs_days_all_cycles:
        A list of strings of the form 'YYYYMMDD', with each string representing
        a day on which observations are needed.  Note that the list must be
        sorted, i.e. the days must be increasing in time, but there may be
        gaps between days.

    Returns:
        cycledefs_all_obs_days:
        A list of strings, with each string being a ROCOTO-style cycledef of
        the form

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
        vx_config:
        The verification configuration dictionary.

        cycle_start_times:
        List containing the starting times of the cycles in the experiment;
        each list element is a datetime object.

        fcst_len:
        The length of each forecast; a timedelta object.

        fcst_output_times_all_cycles:
        Dictionary containing a list of forecast output times over all cycles for
        instantaneous fields and a second analogous list for cumulative fields.
        Each element of these lists is a string of the form 'YYYYMMDDHH'.

        obs_days_all_cycles:
        Dictionary containing a list of observation days (i.e. days on which
        observations are needed to perform verification) over all cycles for
        instantaneous fields and a second analogous list for cumulative fields.
        Each element of these lists is a string of the form 'YYYYMMDD'.

    Returns:
        obs_retrieve_times_by_day:
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

    # Get list of forecast fields to be verified.
    vx_fields = vx_config['VX_FIELDS']

    # Define dictionary containing information about all fields that may
    # possibly be verified.  This information includes their temporal
    # characteristics (cumulative vs. instantaneous) and the mapping between
    # the observation type and the forecast field.
    vx_field_info = {'cumul': [{'obtype': 'CCPA',   'fcst_fields': ['APCP']},
                               {'obtype': 'NOHRSC', 'fcst_fields': ['ASNOW']}],
                     'inst':  [{'obtype': 'MRMS',   'fcst_fields': ['REFC', 'RETOP']},
                               {'obtype': 'NDAS',   'fcst_fields': ['ADPSFC', 'ADPUPA']}]
                    }

    # Keep only those items in the dictionary vx_field_info defined above
    # that have forecast fields that appear in the list of forecast fields to
    # be verified.
    for obs_time_type, obtypes_to_fcst_fields_dict_list in vx_field_info.copy().items():
        for obtypes_to_fcst_fields_dict in obtypes_to_fcst_fields_dict_list.copy():
            obtype = obtypes_to_fcst_fields_dict['obtype']
            fcst_fields = obtypes_to_fcst_fields_dict['fcst_fields']
            fcst_fields = [field for field in fcst_fields if field in vx_fields]
            obtypes_to_fcst_fields_dict['fcst_fields'] = fcst_fields
            if not fcst_fields: obtypes_to_fcst_fields_dict_list.remove(obtypes_to_fcst_fields_dict)
        if not obtypes_to_fcst_fields_dict_list: vx_field_info.pop(obs_time_type)

    # Create dictionary containing the temporal characteristics as keys and
    # a string list of obs types to verify as the values.
    obs_time_type_to_obtypes_dict = dict()
    for obs_time_type, obtypes_to_fcst_fields_dict_list in vx_field_info.items():
        obtype_list = [the_dict['obtype'] for the_dict in obtypes_to_fcst_fields_dict_list]
        obs_time_type_to_obtypes_dict[obs_time_type] = obtype_list

    # Initialize the return variable.
    obs_retrieve_times_by_day = dict()

    # Define timedelta object representing a single day.
    one_day = timedelta(days=1)

    # Loop over all obs types to be verified (by looping over the temporal
    # type and the specific obs under that type).  For each obs type, loop
    # over each obs day and find the times within that that at which the obs
    # need to be retrieved.
    for obs_time_type, obtypes in obs_time_type_to_obtypes_dict.items():

        fcst_output_times_all_cycles_crnt_ttype = fcst_output_times_all_cycles[obs_time_type]
        obs_days_all_cycles_crnt_ttype = obs_days_all_cycles[obs_time_type]

        for obtype in obtypes:

            obs_retrieve_times_by_day[obtype] = dict()

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
                        {obs_avail_intvl_hrs = }
                        24 % obs_avail_intvl_hrs = {remainder}"
                    """)
                raise ValueError(msg)
            obs_avail_intvl = timedelta(hours=obs_avail_intvl_hrs)
            num_obs_avail_times_per_day = int(24/obs_avail_intvl_hrs)

            # Loop over all obs days over all cycles (for the current obs type).  For
            # each such day, get the list forecast output times and the list of obs
            # availability times.  Finally, set the times (on that day) that obs need
            # to be retrieved to the intersection of these two lists.
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

                obs_retrieve_times_crnt_day = list(set(fcst_output_times_crnt_day) & set(obs_avail_times_crnt_day))
                obs_retrieve_times_crnt_day.sort()

                obs_day_str = datetime.strftime(obs_day, "%Y%m%d")
                obs_retrieve_times_by_day[obtype][obs_day_str] = obs_retrieve_times_crnt_day

    return obs_retrieve_times_by_day
