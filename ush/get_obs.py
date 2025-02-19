#!/usr/bin/env python3

import os
import sys
import shutil
import argparse
import logging
from pathlib import Path
import datetime as dt
from textwrap import dedent
from pprint import pprint
from math import ceil, floor
import subprocess
import retrieve_data
from python_utils import (
    load_yaml_config,
)
from mrms_pull_topofhour import mrms_pull_topofhour

def get_obs_arcv_hr(obtype, arcv_intvl_hrs, hod):
    """
    This file defines a function that, for the given observation type, obs
    archive interval, and hour of day, returns the hour (counting from hour
    zero of the day) corresponding to the archive file in which the obs file
    for the given hour of day is included.

    Note that for cumulative fields (like CCPA and NOHRSC, as opposed to
    instantaneous ones like MRMS and NDAS), the archive files corresponding
    to hour 0 of the day represent accumulations over the previous day.  Thus,
    here, we never return an archive hour of 0 for cumulative fields.  Instead,
    if the specified hour-of-day is 0, we consider that to represent the 0th
    hour of the NEXT day (i.e. the 24th hour of the current day) and set the
    archive hour to 24.

    Args:

        obtype (str):
            The observation type.

        arcv_intvl_hrs (int):
            Time interval (in hours) between archive files.  For example, if the obs
            files are bundled into 6-hourly archives, then this will be set to 6.  This
            must be between 1 and 24 and must divide evenly into 24.

        hod (int):
            The hour of the day.  This must be between 0 and 23.  For cumulative fields
            (CCPA and NOHRSC), hour 0 is treated as that of the next day, i.e. as the
            24th hour of the current day.

    Returns:
        arcv_hr (int):
            The hour since the start of day corresponding to the archive file containing
            the obs file for the given hour of day.
    """

    valid_obtypes = ['CCPA', 'NOHRSC', 'MRMS', 'NDAS', 'AERONET', 'AIRNOW']

    if obtype not in valid_obtypes:
        msg = dedent(f"""
            The specified observation type is not supported:
                {obtype = }
            Valid observation types are:
                {valid_obtypes}
        """)
        logging.error(msg)
        raise ValueError(msg)

    # Ensure that the archive interval divides evenly into 24 hours.
    remainder = 24 % arcv_intvl_hrs
    if remainder != 0:
        msg = dedent(f"""
            The archive interval for obs of type {obtype} must divide evenly into 24
            but doesn't:
                {arcv_intvl_hrs = }
                24 % arcv_intvl_hrs = {remainder}
            """)
        logging.error(msg)
        raise ValueError(msg)

    if (hod < 0) or (hod > 23):
        msg = dedent(f"""
            The specified hour-of-day must be between 0 and 23, inclusive, but isn't:
                {hod = }
        """)
        logging.error(msg)
        raise ValueError(msg)

    # Set the archive hour.  This depends on the obs type because each obs
    # type can organize its observation files into archives in a different
    # way, e.g. a cumulative obs type may put the obs files for hours 1
    # through 6 of the day in the archive labeled with hour 6 while an
    # instantaneous obs type may put the obs files for hours 0 through 5 of
    # the day in the archive labeled with hour 6.
    if obtype in ['CCPA']:
        if hod == 0:
            arcv_hr = 24
        else:
            arcv_hr = ceil(hod/arcv_intvl_hrs)*arcv_intvl_hrs
    elif obtype in ['NOHRSC']:
        if hod == 0:
            arcv_hr = 24
        else:
            arcv_hr = floor(hod/arcv_intvl_hrs)*arcv_intvl_hrs
    elif obtype in ['MRMS']:
        arcv_hr = (floor(hod/arcv_intvl_hrs))*arcv_intvl_hrs
    elif obtype in ['NDAS']:
        arcv_hr = (floor(hod/arcv_intvl_hrs) + 1)*arcv_intvl_hrs
    elif obtype in ['AERONET']:
        arcv_hr = (floor(hod/arcv_intvl_hrs))*arcv_intvl_hrs
    elif obtype in ['AIRNOW']:
        arcv_hr = (floor(hod/arcv_intvl_hrs))*arcv_intvl_hrs

    return arcv_hr


def get_obs(config, obtype, yyyymmdd_task):
    """
    This script checks for the existence of obs files of the specified type
    at the locations specified by variables in the SRW App's configuration
    file.  If one or more of these files do not exist, it retrieves them from
    a data store (using the ``retrieve_data.py`` script and as specified by the
    configuration file ``parm/data_locations.yml`` for that script) and places
    them in the locations specified by the App's configuration variables,
    renaming them if necessary.

    Args:
        config (dict):
            The final configuration dictionary (obtained from ``var_defns.yaml``).

        obtype (str):
            The observation type.

        yyyymmdd_task (datetime.datetime):
            The date for which obs may be needed.

    Returns:
        True (bool):
            If all goes well.


    Detailed Description:

    In this script, the main (outer) loop to obtain obs files is over a
    sequence of archive hours, where each archive hour in the sequence
    represents one archive (tar) file in the data store, and archive hours
    are with respect to hour 0 of the day.  The number of archive hours in
    this sequence depends on how the obs files are arranged into archives
    for the given obs type.  For example, if the obs files for a given day
    are arranged into four archives, then the archive interval is 6 hours,
    and in order to get all the obs files for that day, the loop must
    iterate over a sequence of 4 hours, either [0, 6, 12, 18] or [6, 12,
    18, 24] (which of these it will be depends on how the obs files are
    arranged into the archives).

    Below, we give a description of archive layout for each obs type and
    give the archive hours to loop over for the case in which we need to
    obtain all available obs for the current day.


    CCPA (Climatology-Calibrated Precipitation Analysis) precipitation accumulation obs
    -----------------------------------------------------------------------------------
    For CCPA, the archive interval is 6 hours, i.e. the obs files are bundled
    into 6-hourly archives.  The archives are organized such that each one
    contains 6 files, so that the obs availability interval is

    .. math::

       \\begin{align*}
             \\qquad \\text{obs_avail_intvl_hrs}
         & = (\\text{24 hrs})/[(\\text{4 archives}) \\times (\\text{6 files/archive})] \\hspace{50in} \\\\
         & = \\text{1 hr/file}
       \\end{align*}

    i.e. there is one obs file for each hour of the day containing the
    accumulation over that one hour.  The archive corresponding to hour 0
    of the current day contains 6 files representing accumulations during
    the 6 hours of the previous day.  The archive corresponding to hour 6
    of the current day contains 6 files for the accumulations during the
    first 6 hours of the current day, and the archives corresponding to
    hours 12 and 18 of the current day each contain 6 files for accumulations
    during hours 6-12 and 12-18, respectively, of the current day.  Thus,
    to obtain all the one-hour accumulations for the current day, we must
    extract all the obs files from the three archives corresponding to hours
    6, 12, and 18 of the current day and from the archive corresponding to
    hour 0 of the next day.  This corresponds to an archive hour sequence
    of [6, 12, 18, 24].  Thus, in the simplest case in which the observation
    retrieval times include all hours of the current task's day at which
    obs files are available and none of the obs files for this day already
    exist on disk, this sequence will be [6, 12, 18, 24].  In other cases,
    the sequence we loop over will be a subset of [6, 12, 18, 24].

    Note that CCPA files for 1-hour accumulation have incorrect metadata in
    the files under the "00" directory (i.e. for hours-of-day 19 to 00 of
    the next day) from 20180718 to 20210504.  This script corrects these
    errors if getting CCPA obs at these times.


    NOHRSC (National Operational Hydrologic Remote Sensing Center) snow accumulation observations
    ---------------------------------------------------------------------------------------------
    For NOHRSC, the archive interval is 24 hours, i.e. the obs files are
    bundled into 24-hourly archives.  The archives are organized such that
    each one contains 4 files, so that the obs availability interval is

    .. math::

       \\begin{align*}
             \\qquad \\text{obs_avail_intvl_hrs}
         & = (\\text{24 hrs})/[(\\text{1 archive}) \\times (\\text{4 files/archive})] \\hspace{50in} \\\\
         & = \\text{6 hr/file}
       \\end{align*}

    i.e. there is one obs file for each 6-hour interval of the day containing
    the accumulation over those 6 hours.  The 4 obs files within each archive
    correspond to hours 0, 6, 12, and 18 of the current day.  The obs file
    for hour 0 contains accumulations during the last 6 hours of the previous
    day, while those for hours 6, 12, and 18 contain accumulations for the
    first, second, and third 6-hour chunks of the current day.  Thus, to
    obtain all the 6-hour accumulations for the current day, we must extract
    from the archive for the current day the obs files for hours 6, 12, and
    18 and from the archive for the next day the obs file for hour 0.  This
    corresponds to an archive hour sequence of [0, 24].  Thus, in the simplest
    case in which the observation retrieval times include all hours of the
    current task's day at which obs files are available and none of the obs
    files for this day already exist on disk, this sequence will be [0, 24].
    In other cases, the sequence we loop over will be a subset of [0, 24].


    MRMS (Multi-Radar Multi-Sensor) radar observations
    --------------------------------------------------
    For MRMS, the archive interval is 24 hours, i.e. the obs files are
    bundled into 24-hourly archives.  The archives are organized such that
    each contains gzipped grib2 files for that day that are usually only a
    few minutes apart.  However, since the forecasts cannot (yet) perform
    sub-hourly output, we filter this data in time by using only those obs
    files that are closest to each hour of the day for which obs are needed.
    This effectively sets the obs availability interval for MRMS to one
    hour, i.e.

    .. math::

       \\begin{align*}
             \\qquad \\text{obs_avail_intvl_hrs}
         & = \\text{1 hr/file} \\hspace{50in} \\\\
       \\end{align*}

    i.e. there is one obs file for each hour of the day containing values
    at that hour (but only after filtering in time; also see notes for
    ``MRMS_OBS_AVAIL_INTVL_HRS`` in ``config_defaults.yaml``).  Thus, to
    obtain the obs at all hours of the day, we only need to extract files
    from one archive.  Thus, in the simplest case in which the observation
    retrieval times include all hours of the current task's day at which obs
    files are available and none of the obs files for this day already exist
    on disk, the sequence of archive hours over which we loop will be just
    [0].  Note that:

    * For cases in which MRMS data are not needed for all hours of the day,
      we still need to retrieve and extract from this single daily archive.
      Thus, the archive hour sequence over which we loop over will always
      be just [0] for MRMS obs.

    * Because MRMS obs are split into two sets of archives -- one for
      composite reflectivity (REFC) and another for echo top (RETOP) --
      on any given day (and with an archive hour of 0) we actually retrive
      and extract two different archive files (one per field).


    NDAS (NAM Data Assimilation System) conventional observations
    -------------------------------------------------------------
    For NDAS, the archive interval is 6 hours, i.e. the obs files are
    bundled into 6-hourly archives.  The archives are organized such that
    each one contains 7 files (not say 6).  The archive associated with
    time yyyymmddhh_arcv contains the hourly files at

      | yyyymmddhh_arcv - 6 hours
      | yyyymmddhh_arcv - 5 hours
      | ...
      | yyyymmddhh_arcv - 2 hours
      | yyyymmddhh_arcv - 1 hours
      | yyyymmddhh_arcv - 0 hours

    These are known as the tm06, tm05, ..., tm02, tm01, and tm00 files,
    respectively.  Thus, the tm06 file from the current archive, say the
    one associated with time yyyymmddhh_arcv, has the same valid time as
    the tm00 file from the previous archive, i.e. the one associated with
    time (yyyymmddhh_arcv - 6 hours).  It turns out that the tm06 file from
    the current archive contains more/better observations than the tm00
    file from the previous archive.  Thus, for a given archive time
    yyyymmddhh_arcv, we use 6 of the 7 files at tm06, ..., tm01 but not
    the one at tm00, effectively resulting in 6 files per archive for NDAS
    obs.  The obs availability interval is then

    .. math::

       \\begin{align*}
             \\qquad \\text{obs_avail_intvl_hrs}
         & = (\\text{24 hrs})/[(\\text{4 archives}) \\times (\\text{6 files/archive})] \\hspace{50in} \\\\
         & = \\text{1 hr/file}
       \\end{align*}

    i.e. there is one obs file for each hour of the day containing values
    at that hour.  The archive corresponding to hour 0 of the current day
    contains 6 files valid at hours 18 through 23 of the previous day.  The
    archive corresponding to hour 6 of the current day contains 6 files
    valid at hours 0 through 5 of the current day, and the archives
    corresponding to hours 12 and 18 of the current day each contain 6
    files valid at hours 6 through 11 and 12 through 17 of the current day.
    Thus, to obtain all the hourly values for the current day (from hour
    0 to hour 23), we must extract the 6 obs files (excluding the tm00
    ones) from the three archives corresponding to hours 6, 12, and 18 of
    the current day and the archive corresponding to hour 0 of the next
    day.  This corresponds to an archive hour sequence set below of [6, 12,
    18, 24].  Thus, in the simplest case in which the observation retrieval
    times include all hours of the current task's day at which obs files
    are available and none of the obs files for this day already exist on
    disk, this sequence will be [6, 12, 18, 24].  In other cases, the
    sequence we loop over will be a subset of [6, 12, 18, 24].

    AERONET Aerosol Optical Depth (AOD) observations:
    -------------------------------------------------
    For AERONET, the archive interval is 24 hours. There is one archive per day
    containing a single text file that contains all of the day's observations.

    AIRNOW Air Quality Particulate Matter (PM25, PM10) observations:
    ----------------------------------------------------------------
    For AIRNOW, the HPSS archive interval is 24 hours. There is one archive per day
    containing one text file per hour that contains all the observation for that
    hour.
    When retrieved from AWS, the interval is 1 hour.
    """

    # Convert obtype to upper case to simplify code below.
    obtype = obtype.upper()

    # For convenience, get the verification portion of the configuration
    # dictionary.
    vx_config = cfg['verification']

    # Get the time interval (in hours) at which the obs are available.
    obs_avail_intvl_hrs = vx_config[f'{obtype}_OBS_AVAIL_INTVL_HRS']

    # The obs availability interval must divide evenly into 24 hours.  Otherwise,
    # different days would have obs available at different hours-of-day.  Make
    # sure this is the case.
    remainder = 24 % obs_avail_intvl_hrs
    if remainder != 0:
        msg = dedent(f"""
            The obs availability interval for obs of type {obtype} must divide evenly
            into 24 but doesn't:
                {obs_avail_intvl_hrs = }
                24 % obs_avail_intvl_hrs = {remainder}
            """)
        logging.error(msg)
        raise ValueError(msg)

    # For convenience, convert the obs availability interval to a datetime
    # object.
    obs_avail_intvl = dt.timedelta(hours=obs_avail_intvl_hrs)

    # Get the base directory for the observations.
    obs_dir = vx_config[f'{obtype}_OBS_DIR']

    # Get from the verification configuration dictionary the list of METplus
    # file name template(s) corresponding to the obs type.
    obs_fn_templates = vx_config[f'OBS_{obtype}_FN_TEMPLATES']

    # Note that the list obs_fn_templates consists of pairs of elements such
    # that the first element of the pair represents the verification field
    # group(s) for which an obs file name template will be needed and the
    # second element is the template itself.  For convenience, convert this
    # information to a dictionary in which the field groups are the keys and
    # the templates are the values.
    #
    # Note:
    # Once the ex-scripts for the vx tasks are converted from bash to python,
    # the lists in the SRW App's configuration file containing the METplus
    # obs file name template(s) (from which the variable obs_fn_templates
    # was obtained above) can be converted to python dictionaries.  Then the
    # list-to-dictionary conversion step here will no longer be needed.
    obs_fn_templates_by_fg = dict()
    for i in range(0, len(obs_fn_templates), 2):
        obs_fn_templates_by_fg[obs_fn_templates[i]] = obs_fn_templates[i+1]

    # For convenience, get the list of verification field groups for which
    # the various obs file templates will be used.
    field_groups_in_obs = obs_fn_templates_by_fg.keys()
    #
    #-----------------------------------------------------------------------
    #
    # Set variables that are only needed for some obs types.
    #
    #-----------------------------------------------------------------------
    #

    # For cumulative obs, set the accumulation period to use when getting obs
    # files.  This is simply a properly formatted version of the obs availability
    # interval.
    accum_obs_formatted = None
    if obtype == 'CCPA':
        accum_obs_formatted = f'{obs_avail_intvl_hrs:02d}'
    elif obtype == 'NOHRSC':
        accum_obs_formatted = f'{obs_avail_intvl_hrs:d}'

    # For MRMS obs, set field-dependent parameters needed in forming grib2
    # file names.
    mrms_fields_in_obs_filenames = []
    mrms_levels_in_obs_filenames = []
    if obtype == 'MRMS':
        for fg in field_groups_in_obs:
            if fg == 'REFC':
                mrms_fields_in_obs_filenames.append('MergedReflectivityQCComposite')
                mrms_levels_in_obs_filenames.append('00.50')
            elif fg == 'RETOP':
                mrms_fields_in_obs_filenames.append('EchoTop')
                mrms_levels_in_obs_filenames.append('18_00.50')
            else:
                msg = dedent(f"""
                    Field and level names have not been specified for this {obtype} field
                    group:
                        {obtype = }
                        {fg = }
                    """)
                logging.error(msg)
                raise ValueError(msg)

    # CCPA files for 1-hour accumulation have incorrect metadata in the files
    # under the "00" directory from 20180718 to 20210504.  Set these starting
    # and ending dates as datetime objects for later use.
    ccpa_bad_metadata_start = dt.datetime.strptime('20180718', '%Y%m%d')
    ccpa_bad_metadata_end = dt.datetime.strptime('20210504', '%Y%m%d')

    #
    #-----------------------------------------------------------------------
    #
    # Form a string list of all the times in the current day (each in the
    # format "YYYYMMDDHH") at which to retrieve obs.
    #
    #-----------------------------------------------------------------------
    #
    yyyymmdd_task_str = dt.datetime.strftime(yyyymmdd_task, '%Y%m%d')
    obs_retrieve_times_crnt_day_str = vx_config[f'OBS_RETRIEVE_TIMES_{obtype}_{yyyymmdd_task_str}']
    obs_retrieve_times_crnt_day \
    = [dt.datetime.strptime(yyyymmddhh_str, '%Y%m%d%H') for yyyymmddhh_str in obs_retrieve_times_crnt_day_str]
    #
    #-----------------------------------------------------------------------
    #
    # Obs files will be obtained by extracting them from the relevant n-hourly
    # archives, where n is the archive interval in hours (denoted below by the
    # variable arcv_intvl_hrs).  Thus, we must first obtain the sequence of
    # hours (since hour 0 of the task day) corresponding to the archive files
    # from which we must extract obs files.  We refer to this as the sequence
    # of archive hours.
    #
    # To generate this sequence, we first set the archive interval and then
    # set the starting and ending archive hour values.
    #
    #
    #-----------------------------------------------------------------------
    #
    if obtype == 'CCPA':
        arcv_intvl_hrs = 6
    elif obtype == 'NOHRSC':
        arcv_intvl_hrs = 24
    elif obtype == 'MRMS':
        arcv_intvl_hrs = 24
    elif obtype == 'NDAS':
        arcv_intvl_hrs = 6
    elif obtype == 'AERONET':
        arcv_intvl_hrs = 24
    elif obtype == 'AIRNOW':
        if vx_config[f'OBS_DATA_STORE_AIRNOW'] == 'hpss':
            arcv_intvl_hrs = 24
        else:
            arcv_intvl_hrs = 1

    arcv_intvl = dt.timedelta(hours=arcv_intvl_hrs)

    # Number of obs files within each archive.
    num_obs_files_per_arcv = int(arcv_intvl/obs_avail_intvl)

    # Initial guess for starting archive hour.  This is set to the archive
    # hour containing obs at the first obs retrieval time of the day.
    arcv_hr_start = get_obs_arcv_hr(obtype, arcv_intvl_hrs, obs_retrieve_times_crnt_day[0].hour)

    # Ending archive hour.  This is set to the archive hour containing obs at
    # the last obs retrieval time of the day.
    arcv_hr_end = get_obs_arcv_hr(obtype, arcv_intvl_hrs, obs_retrieve_times_crnt_day[-1].hour)

    # Set other variables needed below when evaluating the METplus template for
    # the full path to the processed observation files.
    ushdir = config['user']['USHdir']

    # Create dictionary containing the paths to all the processed obs files
    # that should exist once this script successfully completes.  In this
    # dictionary, the keys are the field groups, and the values are lists of
    # paths.  Here, by "paths to processed files" we mean the paths after any
    # renaming and rearrangement of files that this script may do to the "raw"
    # files, i.e. the files as they are named and arranged within the archive
    # (tar) files on HPSS.
    all_fp_proc_dict = {}
    for fg, fn_proc_tmpl in obs_fn_templates_by_fg.items():
        fp_proc_tmpl = os.path.join(obs_dir, fn_proc_tmpl)
        all_fp_proc_dict[fg] = []
        for yyyymmddhh in obs_retrieve_times_crnt_day:
            # Set the lead time, a timedelta object from the beginning of the
            # day at which the file is valid.
            leadtime = yyyymmddhh - yyyymmdd_task
            # Call METplus subroutine to evaluate the template for the full path to
            # the file containing METplus timestrings at the current time.
            fn = sts.do_string_sub(tmpl=fp_proc_tmpl,init=yyyymmdd_task,valid=yyyymmddhh,
                                   lead=leadtime.total_seconds())
            all_fp_proc_dict[fg].append(fn)

    # Check whether any obs files already exist on disk in their processed
    # (i.e. final) locations.  If so, adjust the starting archive hour.  In
    # the process, keep a count of the number of obs files that already exist
    # on disk.
    num_existing_files = 0
    do_break = False
    for fg in field_groups_in_obs:
        for yyyymmddhh, fp_proc in zip(obs_retrieve_times_crnt_day, all_fp_proc_dict[fg]):
            # Check whether the processed file already exists.
            if os.path.isfile(fp_proc):
                num_existing_files += 1
                msg = dedent(f"""
                    File already exists on disk:
                        {fp_proc = }
                    """)
                logging.debug(msg)
            else:
                arcv_hr_start = get_obs_arcv_hr(obtype, arcv_intvl_hrs, yyyymmddhh.hour)
                msg = dedent(f"""
                    File does not exist on disk:
                        {fp_proc = }
                    Setting the hour (since hour 0 of the current task day) of the first
                    archive to retrieve to:
                        {arcv_hr_start = }
                    """)
                logging.info(msg)
                do_break = True
                break
        if do_break: break

    # If the number of obs files that already exist on disk is equal to the
    # number of obs files needed, then there is no need to retrieve any files.
    # The number of obs files needed (i.e. that need to be staged) is equal
    # to the number of times in the current day that obs are needed times the
    # number of sets of files that the current obs type contains.
    num_files_needed = len(obs_retrieve_times_crnt_day)*len(obs_fn_templates_by_fg)
    if num_existing_files == num_files_needed:

        msg = dedent(f"""
            All obs files needed for the current day (yyyymmdd_task) already exist
            on disk:
                {yyyymmdd_task = }
            Thus, there is no need to retrieve any files.
            """)
        logging.info(msg)
        return True

    # If the number of obs files that already exist on disk is not equal to
    # the number of obs files needed, then we will need to retrieve files.
    # In this case, set the sequence of hours corresponding to the archives
    # from which files will be retrieved.
    arcv_hrs = [hr for hr in range(arcv_hr_start, arcv_hr_end+arcv_intvl_hrs, arcv_intvl_hrs)]
    msg = dedent(f"""
        At least some obs files needed for the current day (yyyymmdd_task)
        do not exist on disk:
            {yyyymmdd_task = }
        The number of obs files needed for the current day is:
            {num_files_needed = }
        The number of obs files that already exist on disk is:
            {num_existing_files = }
        Will retrieve remaining files by looping over archives corresponding to
        the following hours (since hour 0 of the current day):
            {arcv_hrs = }
        """)
    logging.info(msg)
    #
    #-----------------------------------------------------------------------
    #
    # At this point, at least some obs files for the current day need to be
    # retrieved.  Thus, loop over the relevant archives that contain obs for
    # the day given by yyyymmdd_task and retrieve files as needed.
    #
    # Note that the NOHRSC data on HPSS are archived by day, with the archive
    # for a given day containing 6-hour as well as 24-hour grib2 files.  As
    # described above, the four 6-hour files are for accumulated snowfall at
    # hour 0 of the current day (which represents accumulation over the last
    # 6 hours of the previous day) as well as hours 6, 12, and 18, while the
    # two 24-hour files are at hour 0 (which represents accumulation over all
    # 24 hours of the previous day) and 12 (which represents accumulation over
    # the last 12 hours of the previous day plus the first 12 hours of the
    # current day).  Here, we will only obtain the 6-hour files.  In other
    # workflow tasks, the values in these 6-hour files will be added as
    # necessary to obtain accumulations over longer periods (e.g. 24 hours).
    # Since the four 6-hour files are in one archive and are relatively small
    # (on the order of kilobytes), we get them all with a single call to the
    # retrieve_data.py script.
    #
    #-----------------------------------------------------------------------
    #

    # Whether to remove raw observations after processed directories have
    # been created from them.
    remove_raw_obs = vx_config[f'REMOVE_RAW_OBS_DIRS']

    # Base directory that will contain the archive subdirectories in which
    # the files extracted from each archive (tar) file will be placed.  We
    # refer to this as the "raw" base directory because it contains files
    # as they are found in the archives before any processing by this script.
    basedir_raw = os.path.join(obs_dir, 'raw_' + yyyymmdd_task_str)

    for arcv_hr in arcv_hrs:

        msg = dedent(f"""
            Processing archive hour {arcv_hr} ...
            """)
        logging.info(msg)

        # Calculate the time information for the current archive.
        yyyymmddhh_arcv = yyyymmdd_task + dt.timedelta(hours=arcv_hr)
        yyyymmddhh_arcv_str = dt.datetime.strftime(yyyymmddhh_arcv, '%Y%m%d%H')
        yyyymmdd_arcv_str = dt.datetime.strftime(yyyymmddhh_arcv, '%Y%m%d')

        # Set the subdirectory under the raw base directory that will contain the
        # files retrieved from the current archive.  We refer to this as the "raw"
        # archive sudirectory because it will contain the files as they are in
        # the archive before any processing by this script.  Later below, this
        # will be combined with the raw base directory (whose name depends on the
        # year, month, and day of the current obs day) to obtain the full path to
        # the raw archive directory (arcv_dir_raw).
        #
        # Notes on each obs type:
        #
        # CCPA:
        # The raw subdirectory name must include the year, month, day, and hour
        # in order to avoid get_obs tasks for different days clobbering each
        # others' obs files.
        #
        # NOHRSC:
        # The hour-of-day of the archive is irrelevant because there is only one
        # archive per day, so we don't include it in the raw archive subdirectory's
        # name.  However, we still need a subdirectory that contains the year,
        # month, and day information of the archive because in the simplest case
        # of having to get the NOHRSC obs for all hours of the current obs day,
        # we need to extract obs files from two archives -- one for the current
        # day (which includes the files for accumulations over hours 0-6, 6-12,
        # and 12-18 of the current day) and another for the next day (which
        # includes the file for accumulations over hours 18-24 of the current
        # day).  To distinguish between the raw obs files from these two archives,
        # we create an archive-time dependent raw subdirectory for each possible
        # archive.
        #
        # MRMS:
        # There is only one archive per day, and it contains all the raw obs
        # files needed to generate processed obs files for the current day.
        # Since we will only ever need this one archive for a given day,
        # for simplicity we simply do not create a raw archive subdirectory.
        #
        # NDAS:
        # Same as for CCPA.
        #
        # AERONET, AIRNOW:
        # Same as for MRMS
        #

        if obtype in ['CCPA', 'NDAS']:
            arcv_subdir_raw = yyyymmddhh_arcv_str
        elif obtype == 'NOHRSC':
            arcv_subdir_raw = yyyymmdd_arcv_str
        elif obtype in ['MRMS', 'AERONET', 'AIRNOW']:
            arcv_subdir_raw = ''

        # Combine the raw archive base directory with the raw archive subdirectory
        # name to obtain the full path to the raw archive directory.
        arcv_dir_raw = os.path.join(basedir_raw, arcv_subdir_raw)

        # Check whether any of the obs retrieval times for the day associated with
        # this task fall in the time interval spanned by the current archive.  If
        # so, set the flag (do_retrieve) to retrieve the files in the current
        # archive.
        if obtype == 'CCPA':
            arcv_contents_start = yyyymmddhh_arcv - (num_obs_files_per_arcv - 1)*obs_avail_intvl
            arcv_contents_end = yyyymmddhh_arcv
        elif obtype == 'NOHRSC':
            arcv_contents_start = yyyymmddhh_arcv
            arcv_contents_end = yyyymmddhh_arcv + (num_obs_files_per_arcv - 1)*obs_avail_intvl
        elif obtype == 'MRMS':
            arcv_contents_start = yyyymmddhh_arcv
            arcv_contents_end = yyyymmddhh_arcv + (num_obs_files_per_arcv - 1)*obs_avail_intvl
        elif obtype == 'NDAS':
            arcv_contents_start = yyyymmddhh_arcv - num_obs_files_per_arcv*obs_avail_intvl
            arcv_contents_end = yyyymmddhh_arcv - obs_avail_intvl
        elif obtype in ['AERONET', 'AIRNOW']:
            arcv_contents_start = yyyymmddhh_arcv
            arcv_contents_end = yyyymmddhh_arcv + (num_obs_files_per_arcv - 1)*obs_avail_intvl

        do_retrieve = False
        for obs_retrieve_time in obs_retrieve_times_crnt_day:
            if (obs_retrieve_time >= arcv_contents_start) and \
               (obs_retrieve_time <= arcv_contents_end):
                do_retrieve = True
                break

        if not do_retrieve:
            msg = dedent(f"""
                None of the current day's observation retrieval times (possibly including
                hour 0 of the next day if considering a cumulative obs type) fall in the
                range spanned by the current {arcv_intvl_hrs}-hourly archive file.  The
                bounds of the data in the current archive are:
                    {arcv_contents_start = }
                    {arcv_contents_end = }
                The times at which obs need to be retrieved are:
                    {obs_retrieve_times_crnt_day = }
                """)
            logging.info(msg)

        else:

            # Make sure the raw archive directory exists because it is used below as
            # the output directory of the retrieve_data.py script (so if this directory
            # doesn't already exist, that script will fail).  Creating this directory
            # also ensures that the raw base directory (basedir_raw) exists before we
            # change location to it below.
            Path(arcv_dir_raw).mkdir(parents=True, exist_ok=True)

            # The retrieve_data.py script first extracts the contents of the archive
            # file into the directory it was called from and then moves them to the
            # specified output location (via the --output_path option).  Note that
            # the relative paths of obs files within archives associted with different
            # days may be the same.  Thus, if files with the same archive-relative
            # paths are being simultaneously extracted from multiple archive files
            # (by multiple get_obs tasks), they will likely clobber each other if the
            # extracton is being carried out into the same location on disk.  To avoid
            # this, we first change location to the raw base directory (whose name is
            # obs-day dependent) and then call the retrieve_data.py script.
            os.chdir(basedir_raw)

            # Pull obs from HPSS or AWS based on OBS_DATA_STORE* setting.

            #
            # Note that for the specific case of NDAS obs, this will get all 7 obs
            # files in the current archive, although we will make use of only 6 of
            # these (we will not use the tm00 file).

            parmdir = config['user']['PARMdir']
            args = ['--debug', \
                    '--file_set', 'obs', \
                    '--config', os.path.join(parmdir, 'data_locations.yml'), \
                    '--cycle_date', yyyymmddhh_arcv_str, \
                    '--data_stores', vx_config[f'OBS_DATA_STORE_{obtype}'], \
                    '--data_type', obtype + '_obs', \
                    '--output_path', arcv_dir_raw, \
                    '--summary_file', 'retrieve_data.log']
            retrieve_data.main(args)

            # Get the list of times corresponding to the obs files in the current
            # archive.  This is a list of datetime objects.
            if obtype == 'CCPA':
                obs_times_in_arcv = [yyyymmddhh_arcv - i*obs_avail_intvl for i in range(0,num_obs_files_per_arcv)]
            elif obtype == 'NOHRSC':
                obs_times_in_arcv = [yyyymmddhh_arcv + i*obs_avail_intvl for i in range(0,num_obs_files_per_arcv)]
            elif obtype == 'MRMS':
                obs_times_in_arcv = [yyyymmddhh_arcv + i*obs_avail_intvl for i in range(0,num_obs_files_per_arcv)]
            elif obtype == 'NDAS':
                obs_times_in_arcv = [yyyymmddhh_arcv - (i+1)*obs_avail_intvl for i in range(0,num_obs_files_per_arcv)]
            elif obtype in ['AERONET', 'AIRNOW']:
                obs_times_in_arcv = [yyyymmddhh_arcv + i*obs_avail_intvl for i in range(0,num_obs_files_per_arcv)]
            obs_times_in_arcv.sort()

            # Loop over the raw obs files extracted from the current archive and
            # generate from them the processed obs files.
            #
            # Notes on each obs type:
            #
            # CCPA:
            # For most dates, generating the processed obs files consists of simply
            # copying or moving the files from the raw archive directory to the processed
            # directory, possibly renaming them in the process.  However, for dates
            # between 20180718 and 20210504 and hours-of-day 19 through the end of the
            # day (i.e. hour 0 of the next day), it involves using wgrib2 to correct an
            # error in the metadata of the raw file and writing the corrected data
            # to a new grib2 file in the processed location.
            #
            # NOHRSC, AERONET, AIRNOW:
            # Generating the processed obs files consists of simply copying or moving
            # the files from the raw archive directory to the processed directory,
            # possibly renaming them in the process.
            #
            # MRMS:
            # The MRMS obs are in fact available every few minutes, but the smallest
            # value we allow the obs availability interval to be set to is 1 hour
            # because the forecasts cannot (yet) perform sub-hourly output (also see
            # notes for MRMS_OBS_AVAIL_INTVL_HRS in config_defaults.yaml).  For this
            # reason, MRMS obs require an extra processing step on the raw files (before
            # creating the processed files).  In this step, at each obs retrieval time
            # we first generate an intermediate grib2 file from the set of all raw (and
            # gzipped) grib2 files for the current day (the latter usually being only a
            # few minutes apart) the file that is nearest in time to the obs retrieval
            # time.  After selecting this gzipped grib2 file, we unzip it and place it
            # in a temporary subdirectory under the raw base directory.  Only after this
            # step do we then generate the processed file by moving this intermediate
            # file to the processed directory, possibly renaming it in the process.
            #
            # NDAS:
            # Generating the processed obs files consists of simply copying or moving
            # the files from the raw archive directory to the processed directory,
            # possibly renaming them in the process.  Note that for a given NDAS archive,
            # the tm06 file in a contains more/better observations than the tm00 file
            # in the previous archive (their valid times being equivalent), so we always
            # use the tm06 files.
            for yyyymmddhh in obs_times_in_arcv:

                # Create the processed obs file from the raw one (by moving, copying, or
                # otherwise) only if the time of the current file in the current archive
                # also exists in the list of obs retrieval times for the current day.  We
                # need to check this because it is possible that some of the obs retrieval
                # times come before the range of times spanned by the current archive while
                # the others come after, but none fall within that range.  This can happen
                # because the set of archive hours over which we are looping were constructed
                # above without considering whether there are obs retrieve time gaps that
                # make it unnecessary to retrieve some of the archives between the first
                # and last ones that must be retrieved.
                if yyyymmddhh in obs_retrieve_times_crnt_day:

                    for i, fg in enumerate(field_groups_in_obs):

                        # For MRMS obs, first select from the set of raw files for the current day
                        # those that are nearest in time to the current hour.  Unzip these in a
                        # temporary subdirectory under the raw base directory.
                        #
                        # Note that the function we call to do this (mrms_pull_topofhour) assumes
                        # a certain file naming convention.  That convention must match the names
                        # of the files that the retrieve_data.py script called above ends up
                        # retrieving.  The list of possible templates for these names is given
                        # in parm/data_locations.yml, but which of those is actually used is not
                        # known until retrieve_data.py completes.  Thus, that information needs
                        # to be passed back by retrieve_data.py and then passed to mrms_pull_topofhour.
                        # For now, we hard-code the file name here.
                        if obtype == 'MRMS':
                            yyyymmddhh_str = dt.datetime.strftime(yyyymmddhh, '%Y%m%d%H')
                            mrms_pull_topofhour(valid_time=yyyymmddhh_str,
                                                source=basedir_raw,
                                                outdir=os.path.join(basedir_raw, 'topofhour'),
                                                product=mrms_fields_in_obs_filenames[i],
                                                add_vdate_subdir=False)

                        # The raw file name needs to be the same as what the retrieve_data.py
                        # script called above ends up retrieving.  The list of possible templates
                        # for this name is given in parm/data_locations.yml, but which of those
                        # is actually used is not known until retrieve_data.py completes.  Thus,
                        # that information needs to be passed back by the script and used here.
                        # For now, we hard-code the file name here.
                        yyyymmddhh_str = dt.datetime.strftime(yyyymmddhh, '%Y%m%d%H')
                        hr = yyyymmddhh.hour
                        if obtype == 'CCPA':
                            fn_raw = 'ccpa.t' + f'{hr:02d}' + 'z.' + accum_obs_formatted + 'h.hrap.conus.gb2'
                        elif obtype == 'NOHRSC':
                            fn_raw = 'sfav2_CONUS_' + accum_obs_formatted + 'h_' + yyyymmddhh_str + '_grid184.grb2'
                        elif obtype == 'MRMS':
                            fn_raw = f'{mrms_fields_in_obs_filenames[i]}_{mrms_levels_in_obs_filenames[i]}' \
                                   + f'_{yyyymmdd_task_str}-{hr:02d}0000.grib2'
                            fn_raw = os.path.join('topofhour', fn_raw)
                        elif obtype == 'NDAS':
                            time_ago = yyyymmddhh_arcv - yyyymmddhh
                            hrs_ago = int(time_ago.seconds/3600)
                            hh_arcv_str = dt.datetime.strftime(yyyymmddhh_arcv, '%H')
                            fn_raw = f'nam.t{hh_arcv_str}z.prepbufr.tm{hrs_ago:02d}.nr'
                        elif obtype == 'AERONET':
                            fn_raw = f'{yyyymmdd_task_str}.lev15'
                            # Special logic for AERONET pulled from http: internet archives result
                            # in weird filenames, rename them to the standard name before continuing
                            badfile = os.path.join(arcv_dir_raw, f'print_web_data_v3?year={yyyymmddhh_str[:4]}')
                            if os.path.isfile(badfile):
                                shutil.move(badfile, os.path.join(arcv_dir_raw, fn_raw))
                        elif obtype == 'AIRNOW':
                            if vx_config['AIRNOW_INPUT_FORMAT'] == 'airnowhourlyaqobs':
                                fn_raw = f'HourlyAQObs_{yyyymmddhh_str}.dat'
                            elif vx_config['AIRNOW_INPUT_FORMAT'] == 'airnowhourly':
                                fn_raw = f'HourlyData_{yyyymmddhh_str}.dat'
                        fp_raw = os.path.join(arcv_dir_raw, fn_raw)

                        # Special logic for AERONET pulled from http: internet archives result
                        # in weird filenames, rename them to the standard name before continuing

                        # Get the full path to the final processed obs file (fp_proc) we want to
                        # create.
                        indx = obs_retrieve_times_crnt_day.index(yyyymmddhh)
                        fp_proc = all_fp_proc_dict[fg][indx]

                        # Make sure the directory in which the processed file will be created exists.
                        dir_proc = os.path.dirname(fp_proc)
                        Path(dir_proc).mkdir(parents=True, exist_ok=True)

                        msg = dedent(f"""
                            Creating the processed obs file
                                {fp_proc}
                            from the raw file
                                {fp_raw}
                            ...
                            """)
                        logging.debug(msg)

                        yyyymmdd = yyyymmddhh.replace(hour=0, minute=0, second=0)
                        # CCPA files for 1-hour accumulation have incorrect metadata in the files
                        # under the "00" directory from 20180718 to 20210504.  After the data is
                        # pulled, reorganize into correct yyyymmdd structure.
                        if (obtype == 'CCPA') and \
                           ((yyyymmdd >= ccpa_bad_metadata_start) and (yyyymmdd <= ccpa_bad_metadata_end)) and \
                           (((hr >= 19) and (hr <= 23)) or (hr == 0)):
                            cmd = ' '.join(['wgrib2', fp_raw, '-set_date -24hr -grib', fp_proc, '-s'])
                            result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
                        elif remove_raw_obs:
                            shutil.move(fp_raw, fp_proc)
                        else:
                            shutil.copy(fp_raw, fp_proc)
    #
    #-----------------------------------------------------------------------
    #
    # Clean up raw obs directories.
    #
    #-----------------------------------------------------------------------
    #
    if remove_raw_obs:
        logging.info("Removing raw obs directories ...")
        shutil.rmtree(basedir_raw)

    return True



def parse_args(argv):
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(
        description="Get observations."
    )

    parser.add_argument(
        "--obtype",
        type=str,
        required=True,
        choices=['CCPA', 'NOHRSC', 'MRMS', 'NDAS', 'AERONET', 'AIRNOW'],
        help="Cumulative observation type.",
    )

    parser.add_argument(
        "--obs_day",
        type=lambda d: dt.datetime.strptime(d, '%Y%m%d'),
        required=True,
        help="Date of observation day, in the form 'YYYMMDD'.",
    )

    parser.add_argument(
        "--var_defns_path",
        type=str,
        required=True,
        help="Path to variable definitions file.",
    )

    choices_log_level = [pair for lvl in list(logging._nameToLevel.keys())
                              for pair in (str.lower(lvl), str.upper(lvl))]
    parser.add_argument(
        "--log_level",
        type=str,
        required=False,
        default='info',
        choices=choices_log_level,
        help=dedent(f"""
            Logging level to use with the 'logging' module.
            """))

    parser.add_argument(
        "--log_fp",
        type=str,
        required=False,
        default='',
        help=dedent(f"""
            Name of or path (absolute or relative) to log file.  If not specified,
            the output goes to screen.
            """))

    return parser.parse_args(argv)


if __name__ == "__main__":
    args = parse_args(sys.argv[1:])

    # We import METPLUS after parse_args so that we can still call the script with -h
    try:
        sys.path.append(os.environ['METPLUS_ROOT'])
    except:
        print("\nERROR ERROR ERROR\n")
        print("Environment variable METPLUS_ROOT must be set to use this script\n")
        raise
    from metplus.util import string_template_substitution as sts

    # Set up logging.
    # If the name/path of a log file has been specified in the command line
    # arguments, place the logging output in it (existing log files of the
    # same name are overwritten).  Otherwise, direct the output to the screen.
    log_level = str.upper(args.log_level)
    msg_format = "[%(levelname)s:%(name)s:  %(filename)s, line %(lineno)s: %(funcName)s()] %(message)s"
    if args.log_fp:
        logging.basicConfig(level=log_level, format=msg_format, filename=args.log_fp, filemode='w')
    else:
        logging.basicConfig(level=log_level, format=msg_format)

    cfg = load_yaml_config(args.var_defns_path)
    get_obs(cfg, args.obtype, args.obs_day)


