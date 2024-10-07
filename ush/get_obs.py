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
from python_utils import (
    load_yaml_config,
)


def get_obs_arcv_hr(obtype, arcv_intvl_hrs, hod):
    """
    This file defines a function that, for the given observation type, obs
    archive interval, and hour of day, returns the hour (counting from hour
    zero of the day) corresponding to the archive file in which the obs file
    for the given hour of day is included.

    Note that for cumulative fields (like CCPA and NOHRSC, as opposed to
    instantaneous ones like MRMS and NDAS), the archive files corresponding
    to hour 0 of the day represent accumulations over the previous day.  Thus,
    here, we never return an achive hour of 0 for cumulative fields.  Instead,
    if the specified hour-of-day is 0, we consider that to represent the 0th
    hour of the NEXT day (i.e. the 24th hour of the current day) and set the
    archive hour to 24.

    Args:
        obtype:
        The observation type.  A string.

        arcv_intvl_hrs:
        Time interval (in hours) between archive files.  An integer.  For example,
        if the obs files are bundled into 6-hourly archives, then this will be
        set to 6.  This must be between 1 and 24 and must divide evenly into 24.

        hod:
        The hour of the day.  An integer.  This must be between 0 and 23.  For
        cumulative fields (CCPA and NOHRSC), hour 0 is treated as that of the 
        next day, i.e. as the 24th hour of the current day.

    Returns:
        arcv_hr:
        The hour since the start of day corresponding to the archive file containing
        the obs file for the given hour of day.  An integer.
    """

    valid_obtypes = ['CCPA', 'NOHRSC', 'MRMS', 'NDAS']
    obtype_upper = obtype.upper()
    if obtype_upper not in valid_obtypes:
        msg = dedent(f"""
            The specified observation type (after converting to upper case) is not
            supported:
                obtype_upper = {obtype_upper}
            Valid observation types are:
                {valid_obtypes}
        """)
        logging.error(msg)
        raise Exception(msg)

    # Ensure that the archive inerval divides evenly into 24 hours.
    remainder = 24 % arcv_intvl_hrs
    if remainder != 0:
        msg = dedent(f"""
            The archive interval for obs of type {obtype} must divide evenly into 24
            but doesn't:
                arcv_intvl_hrs = {arcv_intvl_hrs}
                24 % arcv_intvl_hrs = {remainder}
            """)
        logging.error(msg)
        raise Exception(msg)

    if (hod < 0) or (hod > 23):
        msg = dedent(f"""
            The specified hour-of-day must be between 0 and 23, inclusive, but isn't:
                hod = {hod}
        """)
        logging.error(msg)
        raise Exception(msg)

    # Set the archive hour.  This depends on the obs type because each obs
    # type can organize its observation files into archives in a different
    # way, e.g. a cumulative obs type may put the obs files for hours 1
    # through 6 of the day in the archive labeled with hour 6 while an
    # instantaneous obs type may put the obs files for hours 0 through 5 of
    # the day in the archive labeled with hour 6.
    if obtype_upper in ['CCPA']:
        if hod == 0:
            arcv_hr = 24
        else:
            arcv_hr = ceil(hod/arcv_intvl_hrs)*arcv_intvl_hrs
    elif obtype_upper in ['NOHRSC']:
        if hod == 0:
            arcv_hr = 24
        else:
            arcv_hr = floor(hod/arcv_intvl_hrs)*arcv_intvl_hrs
    elif obtype_upper in ['MRMS']:
        arcv_hr = (floor(hod/arcv_intvl_hrs))*arcv_intvl_hrs
    elif obtype_upper in ['NDAS']:
        arcv_hr = (floor(hod/arcv_intvl_hrs) + 1)*arcv_intvl_hrs

    return arcv_hr


def get_obs(config, obtype, yyyymmdd_task):
    """
This script performs several important tasks for preparing data for
verification tasks. Depending on the value of the environment variable
OBTYPE=(CCPA|MRMS|NDAS|NOHRSC), the script will prepare that particular data
set.

If data is not available on disk (in the location specified by
CCPA_OBS_DIR, MRMS_OBS_DIR, NDAS_OBS_DIR, or NOHRSC_OBS_DIR respectively),
the script attempts to retrieve the data from HPSS using the retrieve_data.py
script. Depending on the data set, there are a few strange quirks and/or
bugs in the way data is organized; see in-line comments for details.


CCPA (Climatology-Calibrated Precipitation Analysis) precipitation accumulation obs
----------
If data is available on disk, it must be in the following
directory structure and file name conventions expected by verification
tasks:

{CCPA_OBS_DIR}/{YYYYMMDD}/ccpa.t{HH}z.01h.hrap.conus.gb2

If data is retrieved from HPSS, it will be automatically staged by this
script.

Notes about the data and how it's used for verification:

1. Accumulation is currently hardcoded to 01h. The verification will
use MET/pcp-combine to sum 01h files into desired accumulations.

2. There is a problem with the valid time in the metadata for files
valid from 19 - 00 UTC (or files under the '00' directory). This is
accounted for in this script for data retrieved from HPSS, but if you
have manually staged data on disk you should be sure this is accounted
for. See in-line comments below for details.


MRMS (Multi-Radar Multi-Sensor) radar observations
----------
If data is available on disk, it must be in the following
directory structure and file name conventions expected by verification
tasks:

{MRMS_OBS_DIR}/{YYYYMMDD}/[PREFIX]{YYYYMMDD}-{HH}0000.grib2,

Where [PREFIX] is MergedReflectivityQCComposite_00.50_ for reflectivity
data and EchoTop_18_00.50_ for echo top data. If data is not available
at the top of the hour, you should rename the file closest in time to
your hour(s) of interest to the above naming format. A script
"ush/mrms_pull_topofhour.py" is provided for this purpose.

If data is retrieved from HPSS, it will automatically staged by this
this script.


NDAS (NAM Data Assimilation System) conventional observations
----------
If data is available on disk, it must be in the following
directory structure and file name conventions expected by verification
tasks:

{NDAS_OBS_DIR}/{YYYYMMDD}/prepbufr.ndas.{YYYYMMDDHH}

Note that data retrieved from HPSS and other sources may be in a
different format: nam.t{hh}z.prepbufr.tm{prevhour}.nr, where hh is
either 00, 06, 12, or 18, and prevhour is the number of hours prior to
hh (00 through 05). If using custom staged data, you will have to
rename the files accordingly.

If data is retrieved from HPSS, it will be automatically staged by this
this script.


NOHRSC  snow accumulation observations
----------
If data is available on disk, it must be in the following
directory structure and file name conventions expected by verification
tasks:

{NOHRSC_OBS_DIR}/{YYYYMMDD}/sfav2_CONUS_{AA}h_{YYYYMMDD}{HH}_grid184.grb2

where AA is the 2-digit accumulation duration in hours: 06 or 24

METplus is configured to verify snowfall using 06- and 24-h accumulated
snowfall from 6- and 12-hourly NOHRSC files, respectively.

If data is retrieved from HPSS, it will automatically staged by this
this script.
    """

    # Convert obtype to upper case to simplify code below.
    obtype = obtype.upper()

    # For convenience, get the verification portion of the configuration
    # dictionary.
    vx_config = cfg['verification']

    # Get the time interval (in hours) at which the obs are available.
    key = obtype + '_OBS_AVAIL_INTVL_HRS'
    obs_avail_intvl_hrs = vx_config[key]

    # The obs availability inerval must divide evenly into 24 hours.  Otherwise,
    # different days would have obs available at different hours-of-day.  Make
    # sure this is the case.
    remainder = 24 % obs_avail_intvl_hrs
    if remainder != 0:
        msg = dedent(f"""
            The obs availability interval for obs of type {obtype} must divide evenly
            into 24 but doesn't:
                obs_avail_intvl_hrs = {obs_avail_intvl_hrs}
                24 % obs_avail_intvl_hrs = {remainder}
            """)
        logging.error(msg)
        raise Exception(msg)

    # For convenience, convert the obs availability interval to a datetime
    # object.
    obs_avail_intvl = dt.timedelta(hours=obs_avail_intvl_hrs)

    # Get the base directory for the observations.
    key = obtype + '_OBS_DIR'
    obs_dir = vx_config[key]

    # For each observation type, set the group of fields contained in those
    # observation files that we need for verification.  Each group of fields
    # is one that is verified together in the workflow.  We assume there is
    # a separate set of obs files for each such field group in the observations,
    # and in the code below we loop over these sets of files as necessary.  
    # There are several scenarios to consider:
    #
    # * An obs type consists of only one set of files containing only one
    #   field.
    #   This is the case for CCPA and NOHRSC obs.  CCPA obs consist only one
    #   set of files that contain APCP data, and NOHRSC obs consist of only
    #   one set of files that contain ASNOW data.
    #
    # * An obs type consists of more than one set of files, with each file 
    #   containing a different field.
    #   This is the case for MRMS obs.  These consist of two sets of files.
    #   The first set contains REFC data, and the second contains RETOP data.
    #
    # * An obs type consists of only one set of files, but each file contains
    #   multiple groups of fields needed for verification.
    #   This is the case for NDAS obs.  These consist of a single set of files,
    #   but each file contains both the ADPSFC fields (like 2-m temperature) 
    #   and ADPUPA fields (like 500-mb temperature) that are verified separately
    #   in the workflow tasks and thus are considered separate field groups.
    #
    # Other obs type and field group scenarios are also possible, but we do
    # not describe them since they are not applicable to any of the obs types
    # considered here. 
    if obtype == 'CCPA':
        field_groups_in_obs = ['APCP']
    elif obtype == 'NOHRSC':
        field_groups_in_obs = ['ASNOW']
    elif obtype == 'MRMS':
        field_groups_in_obs = ['REFC', 'RETOP']
    elif obtype == 'NDAS':
        field_groups_in_obs = ['ADPSFCandADPUPA']
    num_field_groups = len(field_groups_in_obs)

    # For each field group in the observations, get the METplus file name
    # template for the observation files.  Then combine these with the base
    # directory to get the METplus template for the full path on disk to
    # the processed obs files.  If obs files do not already exist at these
    # locations, they will be retrieved from HPSS and placed at these locations.
    fp_proc_templates = []
    for fg in field_groups_in_obs:
        key = 'OBS_' + obtype + '_' + fg + '_FN_TEMPLATE'
        fn_proc_template = vx_config[key]
        fp_proc_templates.append(os.path.join(obs_dir, fn_proc_template))
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
    fields_in_filenames = []
    levels_in_filenames = []
    if obtype == 'MRMS':
        for fg in field_groups_in_obs:
            if fg == 'REFC':
                fields_in_filenames.append('MergedReflectivityQCComposite')
                levels_in_filenames.append('00.50')
            elif fg == 'RETOP':
                fields_in_filenames.append('EchoTop')
                levels_in_filenames.append('18_00.50')
            else:
                msg = dedent(f"""
                    Invalid field specified for obs type:
                        obtype = {obtype}
                        field = {field}
                    """)
                logging.error(msg)
                raise Exception(msg)

    # CCPA files for 1-hour accumulation have incorrect metadata in the files
    # under the "00" directory from 20180718 to 20210504.  Set these starting
    # and ending dates as datetime objects for later use.
    yyyymmdd_bad_metadata_start_str = None
    yyyymmdd_bad_metadata_end_str = None
    yyyymmdd_bad_metadata_start = None
    yyyymmdd_bad_metadata_end = None
    if obtype == 'CCPA':
        yyyymmdd_bad_metadata_start_str = '20180718'
        yyyymmdd_bad_metadata_end_str = '20210504'
        yyyymmdd_bad_metadata_start = dt.datetime.strptime(yyyymmdd_bad_metadata_start_str, '%Y%m%d')
        yyyymmdd_bad_metadata_end = dt.datetime.strptime(yyyymmdd_bad_metadata_end_str, '%Y%m%d')
    #
    #-----------------------------------------------------------------------
    #
    # Get the list of all the times in the current day at which to retrieve
    # obs.  This is an array with elements having format "YYYYMMDDHH".
    #
    #-----------------------------------------------------------------------
    #
    yyyymmdd_task_str = dt.datetime.strftime(yyyymmdd_task, '%Y%m%d')
    key = 'OBS_RETRIEVE_TIMES_' + obtype + '_' + yyyymmdd_task_str
    obs_retrieve_times_crnt_day_str = vx_config[key]
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
    # For CCPA, the archive interval is 6 hours, i.e. the obs files are
    # bundled into 6-hourly archives.  This implies 4 archives per day.  The
    # archives are organized such that each one contains 6 files, so that the
    # obs availability interval is
    #
    #   obs_avail_intvl_hrs = (24 hrs)/[(4 archives)*(6 files/archive)]
    #                       = 1 hr/file
    #
    # i.e. there is one obs file for each hour of the day containing the
    # accumulation over that one hour.  The archive corresponding to hour 0
    # of the current day contains 6 files representing accumulations during
    # the 6 hours of the previous day.  The archive corresponding to hour 6
    # of the current day corresponds to accumulations during the first 6
    # hours of the current day, and the archives corresponding to hours 12
    # and 18 of the current day correspond to accumulations during the 2nd
    # and 3rd 6-hourly intervals of the current day.  Thus, to obtain all the
    # one-hour accumulations for the current day, we must extract all the obs
    # files from the archives corresponding to hours 6, 12, and 18 of the
    # current day and hour 0 of the next day.  This corresponds to an archive
    # hour sequence set below of [6, 12, 18, 24].  Thus, in the simplest case
    # in which the observation retrieval times include all hours of the
    # current task's day at which obs files are available and none of the obs
    # files for this day already exist on disk, this sequence will be [6, 12,
    # 18, 24].  In other cases, the sequence we loop over will be a subset of
    # [6, 12, 18, 24].
    #
    # For NOHRSC, the archive interval is 24 hours, i.e. the obs files are
    # bundled into 24-hourly archives.  This implies just 1 archive per day.
    # The archives are organized such that each one contains 4 files, so that
    # the obs availability interval is 
    #
    #   obs_avail_intvl_hrs = (24 hrs)/[(1 archive)*(4 files/archive)]
    #                       = 6 hr/file
    #
    # i.e. there is one obs file for each 6-hour interval of the day containing
    # the accumulation over those 6 hours.  The 4 obs files within each archive
    # correspond to hours 0, 6, 12, and 18 of the current day.  The obs file
    # for hour 0 contains accumulations during the last 6 hours of the previous
    # day, while those for hours 6, 12, and 18 contain accumulations for the
    # first, second, and third 6-hour chunks of the current day.  Thus, to
    # obtain all the 6-hour accumulations for the current day, we must extract
    # from the archive for the current day the obs files for hours 6, 12, and
    # 18 and from the archive for the next day the obs file for hour 0.  This 
    # corresponds to an archive hour sequence set below of [0, 24].  Thus, in
    # the simplest case in which the observation retrieval times include all
    # hours of the current task's day at which obs files are available and
    # none of the obs files for this day already exist on disk, this sequence
    # will be [0, 24].  In other cases, the sequence we loop over will be a
    # subset of [0, 24].
    #
    # For NDAS, the archive interval is 6 hours, i.e. the obs files are
    # bundled into 6-hourly archives.  This implies 4 archives per day.  The
    # archives are organized such that each one contains 7 files (not say 6).
    # The archive associated with time yyyymmddhh_arcv contains the hourly
    # files at 
    #
    #   yyyymmddhh_arcv - 6 hours
    #   yyyymmddhh_arcv - 5 hours
    #   ...
    #   yyyymmddhh_arcv - 2 hours
    #   yyyymmddhh_arcv - 1 hours
    #   yyyymmddhh_arcv - 0 hours
    #
    # These are known as the tm06, tm05, ..., tm02, tm01, and tm00 files, 
    # respectively.  Thus, the tm06 file from the current archive, say the
    # one associated with time yyyymmddhh_arcv, has the same valid time as
    # the tm00 file from the previous archive, i.e. the one associated with
    # time (yyyymmddhh_arcv - 6 hours).  It turns out the tm06 file from the
    # current archive contains more/better observations than the tm00 file
    # from the previous archive.  Thus, for a given archive time yyyymmddhh_arcv,
    # we use 6 of the 7 files at tm06, ..., tm01 but not the one at tm00, 
    # effectively resulting in an 6 files per archive for NDAS obs.  The obs
    # availability interval is then
    #
    #   obs_avail_intvl_hrs = (24 hrs)/[(4 archives)*(6 files/archive)]
    #                       = 1 hr/file
    #
    # i.e. there is one obs file for each hour of the day containing values
    # at that hour.  The archive corresponding to hour 0 of the current day
    # contains 6 files valid at hours 18 through 23 of the previous day.  The
    # archive corresponding to hour 6 of the current day contains 6 files
    # valid at hours 0 through 5 of the current day, and the archives
    # corresponding to hours 12 and 18 of the current day each contain 6
    # files valid at hours 6 through 11 and 12 through 17 of the current day.
    # Thus, to obtain all the hourly values for the current day (from hour
    # 0 to hour 23), we must extract the 6 obs files (excluding the tm00
    # ones) from the archives corresponding to hours 6, 12, and 18 of the
    # current day and the archive corresponding to hour 0 of the next day.
    # This corresponds to an archive hour sequence set below of [6, 12, 18,
    # 24].  Thus, in the simplest case in which the observation retrieval
    # times include all hours of the current task's day at which obs files
    # are available and none of the obs files for this day already exist on
    # disk, this sequence will be [6, 12, 18, 24].  In other cases, the
    # sequence we loop over will be a subset of [6, 12, 18, 24].
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
    arcv_intvl = dt.timedelta(hours=arcv_intvl_hrs)

    # Number of obs files within each archive.
    num_obs_files_per_arcv = int(arcv_intvl/obs_avail_intvl)

    # Initial guess for starting archive hour.  This is set to the archive
    # hour containing obs at the first obs retrieval time of the day.
    hod_first = obs_retrieve_times_crnt_day[0].hour
    arcv_hr_start = get_obs_arcv_hr(obtype, arcv_intvl_hrs, hod_first)

    # Ending archive hour.  This is set to the archive hour containing obs at
    # the last obs retrieval time of the day.
    hod_last = obs_retrieve_times_crnt_day[-1].hour
    arcv_hr_end = get_obs_arcv_hr(obtype, arcv_intvl_hrs, hod_last)

    # Set other variables needed below when evaluating the METplus template for
    # the full path to the processed observation files.
    one_hour = dt.timedelta(hours=1)
    ushdir = config['user']['USHdir']

    # Create dictionary containing the paths to all the processed obs files
    # that should exist once this script successfully completes.  In this
    # dictionary, the keys are the field groups, and the values are lists of
    # paths.  Here, by "paths to processed files" we mean the paths after any
    # renaming and rearrangement of files that this script may do to the "raw"
    # files, i.e. the files as they are named and arranged within the archive
    # (tar) files on HPSS.
    all_fp_proc_dict = {}
    for fg, fp_proc_templ in zip(field_groups_in_obs, fp_proc_templates):
        all_fp_proc_dict[fg] = []
        for yyyymmddhh in obs_retrieve_times_crnt_day:
            # Set the lead hour, i.e. the number of hours from the beginning of the
            # day at which the file is valid.
            lhr = int((yyyymmddhh - yyyymmdd_task)/one_hour)
            # Call a bash script to evaluate the template for the full path to the
            # file containing METplus timestrings at the current time.  This should
            # be upgraded to a python script at some point.
            cmd = '; '.join(['export USHdir=' + ushdir,
                             'export yyyymmdd_task=' + yyyymmdd_task_str,
                             'export lhr=' + str(lhr),
                             'export METplus_timestr_tmpl=' + fp_proc_templ,
                              os.path.join(ushdir, 'run_eval_METplus_timestr_tmpl.sh')])
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
            fp_proc = result.stdout.strip()
            all_fp_proc_dict[fg].append(fp_proc)

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
                        fp_proc = {fp_proc}
                    """)
                logging.info(msg)
            else:
                hod = yyyymmddhh.hour
                arcv_hr_start = get_obs_arcv_hr(obtype, arcv_intvl_hrs, hod)
                msg = dedent(f"""
                    File does not exist on disk:
                        fp_proc = {fp_proc}
                    Setting the hour (since hour 0 of the current task day) of the first
                    archive to retrieve to:
                        arcv_hr_start = {arcv_hr_start}
                    """)
                logging.info(msg)
                do_break = True
                break
        if do_break: break

    # If the number of obs files that already exist on disk is equal to the
    # number of obs files needed, then there is no need to retrieve any files.
    num_obs_retrieve_times_crnt_day = len(obs_retrieve_times_crnt_day)
    num_files_needed = num_obs_retrieve_times_crnt_day*num_field_groups
    if num_existing_files == num_files_needed:

        msg = dedent(f"""
            All obs files needed for the current day (yyyymmdd_task) already exist
            on disk:
                yyyymmdd_task = {yyyymmdd_task}
            Thus, there is no need to retrieve any files.
            """)
        logging.info(msg)
        return True

    # If the number of obs files that already exist on disk is not equal to
    # the number of obs files needed, then we will need to retrieve files.
    # In this case, set the sequence of hours corresponding to the archives
    # from which files will be retrieved.
    else:

        arcv_hrs = [hr for hr in range(arcv_hr_start, arcv_hr_end+arcv_intvl_hrs, arcv_intvl_hrs)]
        msg = dedent(f"""
            At least some obs files needed needed for the current day (yyyymmdd_task)
            do not exist on disk:
                yyyymmdd_task = {yyyymmdd_task}
            The number of obs files needed for the current day is:
                num_files_needed = {num_files_needed}
            The number of obs files that already exist on disk is:
                num_existing_files = {num_existing_files}
            Will retrieve remaining files by looping over archives corresponding to
            the following hours (since hour 0 of the current day):
                arcv_hrs = {arcv_hrs}
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

    # Whether to move the files or copy them from their raw to their processed
    # locations.
    mv_or_cp = 'cp'
    # Whether to remove raw observations after processed directories have
    # been created from them.
    key = 'REMOVE_RAW_OBS_' + obtype
    remove_raw_obs = vx_config[key]
    # If the raw directories and files are to be removed at the end of this
    # script, no need to copy the files since the raw directories are going
    # to be removed anyway.
    if remove_raw_obs:
        mv_or_cp = 'mv'

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

        # Directory that will contain the files retrieved from the current archive
        # file.  We refer to this as the "raw" archive directory because it will
        # contain the files as they are in the archive before any processing by
        # this script.
        if obtype == 'CCPA':
            arcv_dir_raw = os.path.join(basedir_raw, yyyymmddhh_arcv_str)
        # For NOHRSC, the hour-of-day for the archive is irrelevant since there
        # is only one archive per day, so don't include it in the raw archive 
        # directory's name.
        elif obtype == 'NOHRSC':
            arcv_dir_raw = os.path.join(basedir_raw, yyyymmdd_arcv_str)
        # Since for MRMS data there is only one archive per day, that directory
        # is redundant, so for simplicity we set arcv_dir_raw to just basedir_raw.
        elif obtype == 'MRMS':
            arcv_dir_raw = basedir_raw
        elif obtype == 'NDAS':
            arcv_dir_raw = os.path.join(basedir_raw, yyyymmddhh_arcv_str)

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
                    arcv_contents_start = {arcv_contents_start}
                    arcv_contents_end = {arcv_contents_end}
                The times at which obs need to be retrieved are:
                    obs_retrieve_times_crnt_day = {obs_retrieve_times_crnt_day}
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

            # Pull obs from HPSS.  This will get all the obs files in the current
            # archive and place them in the raw archive directory.
            #
            # Note that for the specific case of NDAS obs, this will get all 7 obs
            # files in the current archive, although we will make use of only 6 of
            # these (we will not use the tm00 file).
            parmdir = config['user']['PARMdir']
            cmd = ' '.join(['python3', \
                            '-u', os.path.join(ushdir, 'retrieve_data.py'), \
                            '--debug', \
                            '--file_set', 'obs', \
                            '--config', os.path.join(parmdir, 'data_locations.yml'), \
                            '--cycle_date', yyyymmddhh_arcv_str, \
                            '--data_stores', 'hpss', \
                            '--data_type', obtype + '_obs', \
                            '--output_path', arcv_dir_raw, \
                            '--summary_file', 'retrieve_data.log'])
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
            rc = result.returncode

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
            obs_times_in_arcv.sort()

            # Loop over the raw obs files extracted from the current archive and
            # generate from them the processed obs files.
            #
            # For CCPA obs, for most dates this consists of simply copying or moving
            # the files from the raw archive directory to the processed directory,
            # possibly renaming them in the process.  However, for dates between
            # 20180718 and 20210504 and hours-of-day 19 through the end of the day
            # (i.e. hour 0 of the next day), it involves using wgrib2 to correct an
            # error in the metadata of the raw file and writing the corrected data
            # to a new grib2 file in the processed location.
            #
            # For NOHRSC obs, this consists of simply copying or moving the files from
            # the raw archive directory to the processed directory, possibly renaming
            # them in the process.
            #
            # For NDAS obs, this consists of simply copying or moving the files from
            # the raw archive directory to the processed directory, possibly renaming
            # them in the process.  Note that the tm06 file in a given archive contain
            # more/better observations than the tm00 file in the next archive (their
            # valid times are equivalent), so we use the tm06 files.
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
                        # Note that the script we call to do this (mrms_pull_topofhour.py) assumes
                        # a certain file naming convention.  That convention must match the names
                        # of the files that the retrieve_data.py script called above ends up
                        # retrieving.  The list of possibile templates for these names is given
                        # in parm/data_locations.yml, but which of those is actually used is not
                        # known until retrieve_data.py completes.  Thus, that information needs
                        # to be passed back by retrieve_data.py and then passed to mrms_pull_topofhour.py.
                        # For now, we hard-code the file name here.
                        if obtype == 'MRMS':
                            yyyymmddhh_str = dt.datetime.strftime(yyyymmddhh, '%Y%m%d%H')
                            cmd = ' '.join(['python3', \
                                            '-u', os.path.join(ushdir, 'mrms_pull_topofhour.py'), \
                                            '--valid_time', yyyymmddhh_str, \
                                            '--source', basedir_raw, \
                                            '--outdir', os.path.join(basedir_raw, 'topofhour'), \
                                            '--product', fields_in_filenames[i], \
                                            '--no-add_vdate_subdir'])
                            result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
                            rc = result.returncode

                        # The raw file name needs to be the same as what the retrieve_data.py
                        # script called above ends up retrieving.  The list of possibile templates
                        # for this name is given in parm/data_locations.yml, but which of those
                        # is actually used is not known until retrieve_data.py completes.  Thus,
                        # that information needs to be passed back by the script and used here.
                        # For now, we hard-code the file name here.
                        if obtype == 'CCPA':
                            hr = yyyymmddhh.hour
                            fn_raw = 'ccpa.t' + f'{hr:02d}' + 'z.' + accum_obs_formatted + 'h.hrap.conus.gb2'
                        elif obtype == 'NOHRSC':
                            yyyymmddhh_str = dt.datetime.strftime(yyyymmddhh, '%Y%m%d%H')
                            fn_raw = 'sfav2_CONUS_' + accum_obs_formatted + 'h_' + yyyymmddhh_str + '_grid184.grb2'
                        elif obtype == 'MRMS':
                            hr = yyyymmddhh.hour
                            fn_raw = fields_in_filenames[i] + '_' + levels_in_filenames[i] \
                                   + '_' + yyyymmdd_task_str + '-' + f'{hr:02d}' + '0000.grib2'
                            fn_raw = os.path.join('topofhour', fn_raw)
                        elif obtype == 'NDAS':
                            time_ago = yyyymmddhh_arcv - yyyymmddhh
                            hrs_ago = int(time_ago.seconds/3600)
                            hh_arcv_str = dt.datetime.strftime(yyyymmddhh_arcv, '%H')
                            fn_raw = 'nam.t' + hh_arcv_str + 'z.prepbufr.tm' + f'{hrs_ago:02d}' + '.nr'
                        fp_raw = os.path.join(arcv_dir_raw, fn_raw)

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
                        logging.info(msg)

                        yyyymmdd = yyyymmddhh.replace(hour=0, minute=0, second=0)
                        # CCPA files for 1-hour accumulation have incorrect metadata in the files
                        # under the "00" directory from 20180718 to 20210504.  After the data is
                        # pulled, reorganize into correct yyyymmdd structure.
                        if (obtype == 'CCPA') and \
                           ((yyyymmdd >= yyyymmdd_bad_metadata_start) and (yyyymmdd <= yyyymmdd_bad_metadata_end)) and \
                           (((hr >= 19) and (hr <= 23)) or (hr == 0)):
                            cmd = ' '.join(['wgrib2', fp_raw, '-set_date -24hr -grib', fp_proc, '-s'])
                            result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
                        elif mv_or_cp == 'mv':
                            shutil.move(fp_raw, fp_proc)
                        elif mv_or_cp == 'cp':
                            shutil.copy(fp_raw, fp_proc)
    #
    #-----------------------------------------------------------------------
    #
    # Clean up raw obs directories.
    #
    #-----------------------------------------------------------------------
    #
    if remove_raw_obs:
        msg = dedent(f"""
            Removing raw obs directories ..."
            """)
        logging.info(msg)
        shutil.rmtree(basedir_raw)

    return True



def parse_args(argv):
    """Parse command line arguments"""
    parser = argparse.ArgumentParser(
        description="Get observations."
    )

    parser.add_argument(
        "--obtype",
        dest="obtype",
        type=str,
        required=True,
        choices=['CCPA', 'NOHRSC', 'MRMS', 'NDAS'],
        help="Cumulative observation type.",
    )

    parser.add_argument(
        "--obs_day",
        dest="obs_day",
        type=lambda d: dt.datetime.strptime(d, '%Y%m%d'),
        required=True,
        help="Date of observation day, in the form 'YYYMMDD'.",
    )

    parser.add_argument(
        "--var_defns_path",
        dest="var_defns_path",
        type=str,
        required=True,
        help="Path to variable definitions file.",
    )

    choices_log_level = [pair for lvl in list(logging._nameToLevel.keys())
                              for pair in (str.lower(lvl), str.upper(lvl))]
    parser.add_argument(
        "--log_level",
        dest="log_level",
        type=str,
        required=False,
        default='info',
        choices=choices_log_level,
        help=dedent(f"""
            Logging level to use with the 'logging' module.
            """))

    parser.add_argument(
        "--log_fp",
        dest="log_fp",
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


