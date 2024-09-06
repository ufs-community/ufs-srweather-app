#!/usr/bin/env python3
# pylint: disable=logging-fstring-interpolation
"""
This script helps users pull data from known data streams, including
URLS and HPSS (only on supported NOAA platforms), or from user-supplied
data locations on disk.

Several supported data streams are included in
parm/data_locations.yml, which provides locations and naming
conventions for files commonly used with the SRW App. Provide the file
to this tool via the --config flag. Users are welcome to provide their
own file with alternative locations and naming conventions.

When using this script to pull from disk, the user is required to
provide the path to the data location, which can include Python
templates. The file names follow those included in the --config file by
default, or can be user-supplied via the --file_name flag. That flag
takes a YAML-formatted string that follows the same conventions outlined
in the parm/data_locations.yml file for naming files.

To see usage for this script:

    python retrieve_data.py -h

Also see the parse_args function below.
"""

import argparse
import datetime as dt
import glob
import logging
import os
import shutil
import subprocess
import sys
import glob
from textwrap import dedent
import time
import urllib.request
from copy import deepcopy

import yaml


def clean_up_output_dir(expected_subdir, local_archive, output_path, source_paths):

    """Remove expected sub-directories and existing_archive files on
    disk once all files have been extracted and put into the specified
    output location."""

    unavailable = {}
    expand_source_paths = []
    logging.debug(f"Cleaning up local paths: {source_paths}")
    for p in source_paths:
        expand_source_paths.extend(glob.glob(p.lstrip("/")))

    # Check to make sure the files exist on disk
    for file_path in expand_source_paths:
        local_file_path = os.path.join(os.getcwd(), file_path.lstrip("/"))
        logging.debug(f"Moving {local_file_path} to {output_path}")
        if not os.path.exists(local_file_path):
            logging.info(f"File does not exist: {local_file_path}")
            unavailable["hpss"] = expand_source_paths
        else:
            file_name = os.path.basename(file_path)
            expected_output_loc = os.path.join(output_path, file_name)
            if not local_file_path == expected_output_loc:
                logging.info(f"Moving {local_file_path} to " f"{expected_output_loc}")
                shutil.move(local_file_path, expected_output_loc)

    # Clean up directories from inside archive, if they exist
    if os.path.exists(expected_subdir) and expected_subdir != "./":
        logging.info(f"Removing {expected_subdir}")
        os.removedirs(expected_subdir)

    # If an archive exists on disk, remove it
    if os.path.exists(local_archive):
        os.remove(local_archive)
    return unavailable


def copy_file(source, destination, copy_cmd):

    """
    Copy a file from a source and place it in the destination location.
    Return a boolean value reflecting the state of the copy.

    Assumes destination exists.
    """

    if not os.path.exists(source):
        logging.info(f"File does not exist on disk \n {source} \n try using: --input_file_path <your_path>")
        return False

    # Using subprocess here because system copy is much faster than
    # python copy options.
    cmd = f"{copy_cmd} {source} {destination}"
    logging.info(f"Running command: \n {cmd}")
    try:
        subprocess.run(
            cmd,
            check=True,
            shell=True,
        )
    except subprocess.CalledProcessError as err:
        logging.info(err)
        return False
    return True

def check_file(url):

    """
    Check that a file exists at the expected URL. Return boolean value
    based on the response.
    """
    status_code = urllib.request.urlopen(url).getcode()
    return status_code == 200

def download_file(url):

    """
    Download a file from a url source, and place it in a target location
    on disk.

    Arguments:
      url          url to file to be downloaded

    Return:
      boolean value reflecting state of download.
    """

    # wget flags:
    # -c continue previous attempt
    # -T timeout seconds
    # -t number of tries
    cmd = f"wget -q -c -T 15 -t 2 {url}"
    logging.debug(f"Running command: \n {cmd}")
    try:
        subprocess.run(
            cmd,
            check=True,
            shell=True,
        )
    except subprocess.CalledProcessError as err:
        logging.info(err)
        return False
    except:
        logging.error("Command failed!")
        raise

    return True


def arg_list_to_range(args):

    """
    Given an argparse list argument, return the sequence to process.

    The length of the list will determine what sequence items are returned:

      Length = 1:   A single item is to be processed
      Length = 2:   A sequence of start, stop with increment 1
      Length = 3:   A sequence of start, stop, increment
      Length > 3:   List as is

    argparse should provide a list of at least one item (nargs='+').

    Must ensure that the list contains integers.
    """

    args = args if isinstance(args, list) else list(args)
    arg_len = len(args)
    if arg_len in (2, 3):
        args[1] += 1
        return list(range(*args))

    return args


def fill_template(template_str, cycle_date, templates_only=False, **kwargs):

    """Fill in the provided template string with date time information,
    and return the resulting string.

    Arguments:
      template_str    a string containing Python templates
      cycle_date      a datetime object that will be used to fill in
                      date and time information
      templates_only  boolean value. When True, this function will only
                      return the templates available.

    Keyword Args:
      ens_group       a number associated with a bin where ensemble
                      members are stored in archive files
      fcst_hr         an integer forecast hour. string formatting should
                      be included in the template_str
      mem             a single ensemble member. should be a positive integer value

    Return:
      filled template string
    """
 
    # Parse keyword args
    ens_group = kwargs.get("ens_group")
    fcst_hr = kwargs.get("fcst_hr", 0)
    mem = kwargs.get("mem", "")
    # -----

    cycle_hour = cycle_date.strftime("%H")

    # One strategy for binning data files at NCEP is to put them into 6
    # cycle bins. The archive file names include the low and high end of the
    # range. Set the range as would be indicated in the archive file
    # here. Integer division is intentional here.
    low_end = int(cycle_hour) // 6 * 6
    bin6 = f"{low_end:02d}-{low_end+5:02d}"

    # Another strategy is to bundle odd cycle hours with their next
    # lowest even cycle hour. Files are named only with the even hour.
    # Integer division is intentional here.
    hh_even = f"{int(cycle_hour) // 2 * 2:02d}"

    format_values = dict(
        bin6=bin6,
        ens_group=ens_group,
        fcst_hr=fcst_hr,
        dd=cycle_date.strftime("%d"),
        hh=cycle_hour,
        hh_even=hh_even,
        jjj=cycle_date.strftime("%j"),
        mem=mem,
        min=cycle_date.strftime("%M"),
        mm=cycle_date.strftime("%m"),
        yy=cycle_date.strftime("%y"),
        yyyy=cycle_date.strftime("%Y"),
        yyyymm=cycle_date.strftime("%Y%m"),
        yyyymmdd=cycle_date.strftime("%Y%m%d"),
        yyyymmddhh=cycle_date.strftime("%Y%m%d%H"),
    )

    if templates_only:
        return f'{",".join((format_values.keys()))}'
    return template_str.format(**format_values)


def create_target_path(target_path):

    """
    Append target path and create directory for ensemble members
    """
    if not os.path.exists(target_path):
        os.makedirs(target_path)
    return target_path


def find_archive_files(paths, file_names, cycle_date, ens_group):

    """Given an equal-length set of archive paths and archive file
    names, and a cycle date, check HPSS via hsi to make sure at least
    one set exists. Return a dict of the paths of the existing archive, along with
    the item in set of paths that was found."""

    zipped_archive_file_paths = zip(paths, file_names)

    # Narrow down which HPSS files are available for this date
    for list_item, (archive_path, archive_file_names) in enumerate(
        zipped_archive_file_paths
    ):

        existing_archives = {}
        if not isinstance(archive_file_names, list):
            archive_file_names = [archive_file_names]

        for n_fp, archive_file_name in enumerate(archive_file_names):
            # Only test the first item in the list, it will tell us if this
            # set exists at this date.
            file_path = os.path.join(archive_path, archive_file_name)
            file_path = fill_template(file_path, cycle_date, ens_group=ens_group)
            file_path = hsi_single_file(file_path)

            if file_path:
                existing_archives[n_fp] = file_path

        if existing_archives:
            for existing_archive in existing_archives.values():
                logging.info(f"Found HPSS file: {existing_archive}")
            return existing_archives, list_item

    return "", 0


def get_file_templates(cla, known_data_info, data_store, use_cla_tmpl=False):

    """Returns the file templates requested by user input, either from
    the command line, or from the known data information dict.

    Arguments:

       cla              command line arguments Namespace object
       known_data_info  dict from data_locations yaml file
       data_store       string corresponding to a key in the
                        known_data_info dict
       use_cla_tmpl     boolean on whether to check cla for templates

    Returns:
       file_templates   a list of file templates
    """

    file_templates = known_data_info.get(data_store, {}).get("file_names")
    file_templates = deepcopy(file_templates)

    # Remove sfc files from fcst in file_names of external models for LBCs
    # sfc files needed in fcst when time_offset is not zero.
    if cla.ics_or_lbcs == "LBCS" and isinstance(file_templates, dict):
        for format in ['netcdf', 'nemsio']:
            for i, tmpl in enumerate(file_templates.get(format, {}).get('fcst', [])):
                if "sfc" in tmpl:
                    del file_templates[format]['fcst'][i]

    if use_cla_tmpl:
        file_templates = cla.file_templates if cla.file_templates else file_templates
# nperlin 05/31/2024 diagnostics
    msg = "Diagnostic prints in retrieve_data.py"
    print(msg)
    msg = f"cla is is {cla}!"
    print(msg)
    msg = f"cla.data_type is {cla.data_type}!"
    print(msg)
    msg = f"cla.file_fmt is {cla.file_fmt}!"
    print(msg)
    msg = f"cla.file_set is {cla.file_set}!"
    print(msg)
    msg = f"use_cla_tmpl is {use_cla_tmpl}!"
    print(msg)
    msg = f"cla.cycle_date is {cla.cycle_date}!"
    print(msg)

    if isinstance(file_templates, dict):
        if cla.file_fmt is not None:
            file_templates = file_templates[cla.file_fmt]
        file_templates = file_templates[cla.file_set]
    if not file_templates:
        msg = "No file naming convention found. They must be provided \
                either on the command line or on in a config file."
        raise argparse.ArgumentTypeError(msg)
    return file_templates


def get_requested_files(cla, file_templates, input_locs, method="disk", **kwargs):

    # pylint: disable=too-many-locals

    """This function copies files from disk locations
    or downloads files from a url, depending on the option specified for
    user.

    This function expects that the output directory exists and is
    writeable.

    Arguments:

    cla            Namespace object containing command line arguments
    file_templates a list of file templates
    input_locs      A string containing a single data location, either a url
                   or disk path, or a list of paths/urls.
    method         Choice of disk or download to indicate protocol for
                   retrieval

    Keyword args:
    members        a list integers corresponding to the ensemble members
    check_all      boolean flag that indicates all urls should be
                   checked for all files

    Returns:
    unavailable  a list of locations/files that were unretrievable
    """

    members = kwargs.get("members", "")
    members = cla.members if isinstance(cla.members, list) else [members]

    check_all = kwargs.get("check_all", False)

    logging.info(f"Getting files named like {file_templates}")

    # Make sure we're dealing with lists for input locations and file
    # templates. Makes it easier to loop and zip.
    file_templates = (
        file_templates if isinstance(file_templates, list) else [file_templates]
    )

    input_locs = input_locs if isinstance(input_locs, list) else [input_locs]

    orig_path = os.getcwd()
    unavailable = []

    locs_files = pair_locs_with_files(input_locs, file_templates, check_all)
    for mem in members:
        target_path = fill_template(cla.output_path, cla.cycle_date, mem=mem)
        target_path = create_target_path(target_path)

        logging.info(f"Retrieved files will be placed here: \n {target_path}")
        os.chdir(target_path)

        for fcst_hr in cla.fcst_hrs:
            logging.debug(f"Looking for fhr = {fcst_hr}")
            for loc, templates in locs_files:

                templates = templates if isinstance(templates, list) else [templates]

                logging.debug(f"Looking for files like {templates}")
                logging.debug(f"They should be here: {loc}")

                template_loc = loc
                for tmpl_num, template in enumerate(templates):
                    if isinstance(loc, list) and len(loc) == len(templates):
                        template_loc = loc[tmpl_num]
                    input_loc = os.path.join(template_loc, template)
                    input_loc = fill_template(
                        input_loc,
                        cla.cycle_date,
                        fcst_hr=fcst_hr,
                        mem=mem,
                    )
                    logging.info(f"Getting file: {input_loc}")
                    logging.debug(f"Target path: {target_path}")
                    if method == "disk":
                        if cla.symlink:
                            retrieved = copy_file(input_loc, target_path, "ln -sf")
                        else:
                            retrieved = copy_file(input_loc, target_path, "cp")

                    elif method == "download":

                        if cla.check_file:
                            retrieved = check_file(input_loc)

                        else:
                            retrieved = download_file(input_loc)
                        # Wait a bit before trying the next download.
                        # Seems to reduce the occurrence of timeouts
                        # when downloading from AWS
                        time.sleep(5)

                    logging.debug(f"Retrieved status: {retrieved}")
                    if not retrieved:
                        unavailable.append(input_loc)

                if not unavailable:
                    # Start on the next fcst hour if all files were
                    # found from a loc/template combo
                    break
                else:
                    logging.debug(f"Some files were not retrieved: {unavailable}")
                    logging.debug("Will check other locations for missing files")

    os.chdir(orig_path)
    return unavailable


def hsi_single_file(file_path, mode="ls"):

    """Call hsi as a subprocess for Python and return information about
    whether the file_path was found.

    Arguments:
        file_path    path on HPSS
        mode         the hsi command to run. ls is default. may also
                     pass "get" to retrieve the file path

    """
    cmd = f"hsi {mode} {file_path}"

    logging.info(f"Running command \n {cmd}")
    try:
        subprocess.run(
            cmd,
            check=True,
            shell=True,
        )
    except subprocess.CalledProcessError:
        logging.warning(f"{file_path} is not available!")
        return ""

    return file_path


def hpss_requested_files(cla, file_names, store_specs, members=-1, ens_group=-1):

    # pylint: disable=too-many-locals

    """This function interacts with the "hpss" protocol in a provided
    data store specs file to download a set of files requested by the
    user. Depending on the type of archive file (zip or tar), it will
    either pull the entire file and unzip it, or attempt to pull
    individual files from a tar file.

    It cleans up local disk after files are deemed available to remove
    any empty subdirectories that may still be present.

    This function exepcts that the output directory exists and is
    writable.
    """
    members = [-1] if members == -1 else members

    archive_paths = store_specs["archive_path"]
    archive_paths = (
        archive_paths if isinstance(archive_paths, list) else [archive_paths]
    )

    # Could be a list of lists
    archive_file_names = store_specs.get("archive_file_names", {})
    if cla.file_fmt is not None:
        archive_file_names = archive_file_names[cla.file_fmt]

    if isinstance(archive_file_names, dict):
        archive_file_names = archive_file_names[cla.file_set]

    unavailable = {}
    existing_archives = {}

    logging.debug(
        f"Will try to look for: " f" {list(zip(archive_paths, archive_file_names))}"
    )

    existing_archives, which_archive = find_archive_files(
        archive_paths,
        archive_file_names,
        cla.cycle_date,
        ens_group=ens_group,
    )

    logging.debug(f"Found existing archives: {existing_archives}")

    if not existing_archives:
        logging.warning("No archive files were found!")
        unavailable["archive"] = list(zip(archive_paths, archive_file_names))
        return unavailable

    logging.info(f"Files in archive are named: {file_names}")

    archive_internal_dirs = store_specs.get("archive_internal_dir", [""])
    if isinstance(archive_internal_dirs, dict):
        archive_internal_dirs = archive_internal_dirs.get(cla.file_set, [""])

    # which_archive matters for choosing the correct file names within,
    # but we can safely just try all options for the
    # archive_internal_dir
    logging.debug(f"Checking archive number {which_archive} in list.")

    for archive_internal_dir_tmpl in archive_internal_dirs:
        for mem in members:
            archive_internal_dir = fill_template(
                archive_internal_dir_tmpl,
                cla.cycle_date,
                mem=mem,
            )

            output_path = fill_template(cla.output_path, cla.cycle_date, mem=mem)
            logging.info(f"Will place files in {os.path.abspath(output_path)}")
            logging.debug(f"CWD: {os.getcwd()}")

            if mem != -1:
                archive_internal_dir = fill_template(
                    archive_internal_dir_tmpl,
                    cla.cycle_date,
                    mem=mem,
                )
                output_path = create_target_path(output_path)
                logging.info(f"Will place files in {os.path.abspath(output_path)}")

            source_paths = []
            for fcst_hr in cla.fcst_hrs:
                for file_name in file_names:
                    source_paths.append(
                        fill_template(
                            os.path.join(archive_internal_dir, file_name),
                            cla.cycle_date,
                            fcst_hr=fcst_hr,
                            mem=mem,
                            ens_group=ens_group,
                        )
                    )

            expected = set(source_paths)
            unavailable = {}
            for existing_archive in existing_archives.values():
                if store_specs.get("archive_format", "tar") == "zip":

                    # Get the entire file from HPSS
                    existing_archive = hsi_single_file(existing_archive, mode="get")

                    # Grab only the necessary files from the archive
                    cmd = f'unzip -o {os.path.basename(existing_archive)} {" ".join(source_paths)}'

                else:
                    cmd = f'htar -xvf {existing_archive} {" ".join(source_paths)}'

                logging.info(f"Running command \n {cmd}")

                try:
                    r = subprocess.run(
                        cmd,
                        check=False,
                        shell=True,
                    )
                except:
                    if r.returncode == 11:
                        # Continue if files missing from archive; we will check later if this is
                        # an acceptable condition
                        logging.warning("One or more files not found in zip archive")
                        pass
                    else:
                        raise Exception("Error running archive extraction command")

                # Check that files exist and Remove any data transfer artifacts.
                # Returns {'hpss': []}, turn that into a new dict of
                # sets.
                unavailable[existing_archive] = set(
                    clean_up_output_dir(
                        expected_subdir=archive_internal_dir,
                        local_archive=os.path.basename(existing_archive),
                        output_path=output_path,
                        source_paths=source_paths,
                    ).get("hpss", [])
                )

            # Once we go through all the archives, the union of all
            # "unavailable" files should equal the "expected" list of
            # files since clean_up_output_dir only reports on those that
            # are missing from one of the files attempted. If any
            # additional files are reported as unavailable, then
            # something has gone wrong.
            unavailable = set.union(*unavailable.values())

    # Break loop if unexpected files were found or if files were found
    # A successful file found does not equal the expected file list and 
    # returns an empty set function.
    if not expected == unavailable:
        return unavailable - expected
    
    # If this loop has completed successfully without returning early, then all files have been found
    return {}


def load_str(arg):

    """Load a dict string safely using YAML. Return the resulting dict."""
    return yaml.load(arg, Loader=yaml.SafeLoader)


def config_exists(arg):

    """
    Check to ensure that the provided config file exists. If it does,
    load it with YAML's safe loader and return the resulting dict.
    """

    # Check for existence of file
    if not os.path.exists(arg):
        msg = f"{arg} does not exist!"
        raise argparse.ArgumentTypeError(msg)

    with open(arg, "r") as config_path:
        cfg = yaml.load(config_path, Loader=yaml.SafeLoader)
    return cfg


def pair_locs_with_files(input_locs, file_templates, check_all):

    """
    Given a list of input locations and files, return an iterable that
    contains the multiple locations and file templates for files that
    should be searched in those locations.

    check_all indicates that all locations should be paired with all
    avaiable file templates.

    The different possibilities:
    1. Get one or more files from a single path/url
    2. Get multiple files from multiple corresponding
       paths/urls
    3. Check all paths for all file templates until files are
       found

    The default will be to handle #1 and #2. #3 will be
    indicated by a flag in the yaml: "check_all: True"

    """

    if not check_all:

        # Make sure the length of both input_locs and
        # file_templates is consistent

        # Case 2 above
        if len(file_templates) == len(input_locs):
            locs_files = list(zip(input_locs, file_templates))

        # Case 1 above
        elif len(file_templates) > len(input_locs) and len(input_locs) == 1:

            locs_files = list(zip(input_locs, [file_templates]))
        else:
            msg = "Please check your input locations and templates."
            raise KeyError(msg)
    else:
        # Case 3 above
        locs_files = [(loc, file_templates) for loc in input_locs]

    return locs_files


def path_exists(arg):

    """Check whether the supplied path exists and is writeable"""

    if not os.path.exists(arg):
        msg = f"{arg} does not exist!"
        raise argparse.ArgumentTypeError(msg)

    if not os.access(arg, os.X_OK | os.W_OK):
        logging.error(f"{arg} is not writeable!")
        raise argparse.ArgumentTypeError(msg)

    return arg


def setup_logging(debug=False):

    """Calls initialization functions for logging package, and sets the
    user-defined level for logging in the script."""

    level = logging.INFO
    if debug:
        level = logging.DEBUG

    logging.basicConfig(format="%(levelname)s: %(message)s \n ", level=level)
    if debug:
        logging.info("Logging level set to DEBUG")


def write_summary_file(cla, data_store, file_templates):

    """Given the command line arguments and the data store from which
    the data was retrieved, write a bash summary file that is needed by
    the workflow elements downstream."""

    members =  cla.members if isinstance(cla.members, list) else [-1]
    for mem in members:
        files = []
        for tmpl in file_templates:
            tmpl = tmpl if isinstance(tmpl, list) else [tmpl]
            for t in tmpl:
                files.extend(
                    [fill_template(t, cla.cycle_date, fcst_hr=fh, mem=mem) for fh in cla.fcst_hrs]
                )
        output_path = fill_template(cla.output_path, cla.cycle_date, mem=mem)
        summary_fp = os.path.join(output_path, cla.summary_file)
        logging.info(f"Writing a summary file to {summary_fp}")
        file_contents = dedent(
            f"""
            DATA_SRC={data_store}
            EXTRN_MDL_CDATE={cla.cycle_date.strftime('%Y%m%d%H')}
            EXTRN_MDL_STAGING_DIR={output_path}
            EXTRN_MDL_FNS=( {' '.join(files)} )
            EXTRN_MDL_FHRS=( {' '.join([str(i) for i in cla.fcst_hrs])} )
            """
        )
        logging.info(f"Contents: {file_contents}")
        with open(summary_fp, "w") as summary:
            summary.write(file_contents)


def to_datetime(arg):
    """Return a datetime object give a string like YYYYMMDDHH or
    YYYYMMDDHHmm."""
    if len(arg) == 10:
        fmt_str = "%Y%m%d%H"
    elif len(arg) == 12:
        fmt_str = "%Y%m%d%H%M"
    else:
        msg = f"""The length of the input argument is {len(arg)} and is
        not a supported input format."""
        raise argparse.ArgumentTypeError(msg)
    return dt.datetime.strptime(arg, fmt_str)


def to_lower(arg):
    """Return a string provided by arg into all lower case."""
    return arg.lower()


def main(argv):
    # pylint: disable=too-many-branches, too-many-statements
    """
    Uses known location information to try the known locations and file
    paths in priority order.
    """

    cla = parse_args(argv)

    setup_logging(cla.debug)
    print("Running script retrieve_data.py with args:", f"\n{('-' * 80)}\n{('-' * 80)}")
    for name, val in cla.__dict__.items():
        if name not in ["config"]:
            print(f"{name:>15s}: {val}")
    print(f"{('-' * 80)}\n{('-' * 80)}")

    if "disk" in cla.data_stores:
        # Make sure a path was provided.
        if not cla.input_file_path:
            raise argparse.ArgumentTypeError(
                (
                    "You must provide an input_file_path when choosing "
                    " disk as a data store!"
                )
            )

    if "hpss" in cla.data_stores:
        # Make sure hpss module is loaded
        try:
            subprocess.run(
                "which hsi",
                check=True,
                shell=True,
            )
        except subprocess.CalledProcessError:
            logging.error(
                "You requested the hpss data store, but "
                "the HPSS module isn't loaded. This data store "
                "is only available on NOAA compute platforms."
            )
            sys.exit(1)

    known_data_info = cla.config.get(cla.data_type, {})
    if not known_data_info:
        msg = f"No data stores have been defined for {cla.data_type}!"
        if cla.input_file_path is None:
            cla.data_stores = ["disk"]
            raise KeyError(msg)
        logging.info(msg)
        logging.info(f"Checking provided disk location {cla.input_file_path}")

    unavailable = {}
    for data_store in cla.data_stores:
        logging.info(f"Checking {data_store} for {cla.data_type}")
        store_specs = known_data_info.get(data_store, {})

        if data_store == "disk":
            file_templates = get_file_templates(
                cla,
                known_data_info,
                data_store="hpss",
                use_cla_tmpl=True,
            )

            logging.debug(f"User supplied file names are: {file_templates}")
            unavailable = get_requested_files(
                cla,
                check_all=known_data_info.get("check_all", False),
                file_templates=file_templates,
                input_locs=cla.input_file_path,
                method="disk",
            )

        elif not store_specs:
            msg = f"No information is available for {data_store}."
            raise KeyError(msg)

        else:

            file_templates = get_file_templates(
                cla,
                known_data_info,
                data_store=data_store,
            )

            if store_specs.get("protocol") == "download":
                unavailable = get_requested_files(
                    cla,
                    check_all=known_data_info.get("check_all", False),
                    file_templates=file_templates,
                    input_locs=store_specs["url"],
                    method="download",
                    members=cla.members,
                )

            if store_specs.get("protocol") == "htar":
                ens_groups = get_ens_groups(cla.members)
                for ens_group, members in ens_groups.items():
                    unavailable = hpss_requested_files(
                        cla,
                        file_templates,
                        store_specs,
                        members=members,
                        ens_group=ens_group,
                    )

        if not unavailable:
            # All files are found. Stop looking!
            # Write a variable definitions file for the data, if requested
            if cla.summary_file and not cla.check_file:
                write_summary_file(cla, data_store, file_templates)
            break

        logging.debug(f"Some unavailable files: {unavailable}")
        logging.warning(f"Requested files are unavailable from {data_store}")

    if unavailable:
        logging.error("Could not find any of the requested files.")
        sys.exit(1)


def get_ens_groups(members):

    """Given a list of ensemble members, return a dict with keys for
    the ensemble group, and values are lists of ensemble members
    requested in that group."""

    if members is None:
        return {-1: [-1]}

    ens_groups = {}
    for mem in members:
        ens_group = (mem - 1) // 10 + 1
        if ens_groups.get(ens_group) is None:
            ens_groups[ens_group] = [mem]
        else:
            ens_groups[ens_group].append(mem)
    return ens_groups


def parse_args(argv):

    """
    Function maintains the arguments accepted by this script. Please see
    Python's argparse documenation for more information about settings of each
    argument.
    """

    description = (
        "Allowable Python templates for paths, urls, and file names are "
        " defined in the fill_template function and include:\n"
        f'{"-"*120}\n'
        f'{fill_template("null", dt.datetime.now(), templates_only=True)}'
    )
    parser = argparse.ArgumentParser(
        description=description,
    )

    # Required
    parser.add_argument(
        "--file_set",
        choices=("anl", "fcst", "obs", "fix"),
        help="Flag for whether analysis, forecast, \
        fix, or observation files should be gathered",
        required=True,
    )
    parser.add_argument(
        "--config",
        help="Full path to a configuration file containing paths and \
        naming conventions for known data streams. The default included \
        in this repository is in parm/data_locations.yml",
        required=False,
        type=config_exists,
        
    )
    parser.add_argument(
        "--cycle_date",
        help="Cycle date of the data to be retrieved in YYYYMMDDHH \
        or YYYYMMDDHHmm format.",
        required=False, # relaxed this arg option, and set a benign value when not used
        default="1999123100",
        type=to_datetime,
    )
    parser.add_argument(
        "--data_stores",
        help="List of priority data_stores. Tries first list item \
        first. Choices: hpss, nomads, aws, disk, remote.",
        nargs="*",
        required=True,
        type=to_lower,
    )
    parser.add_argument(
        "--data_type",
        help="External model label. This input is case-sensitive",
        required=True,
    )
    parser.add_argument(
        "--fcst_hrs",
        help="A list describing forecast hours.  If one argument, \
        one fhr will be processed.  If 2 or 3 arguments, a sequence \
        of forecast hours [start, stop, [increment]] will be \
        processed.  If more than 3 arguments, the list is processed \
        as-is. default=[0]",
        nargs="+",
        required=False,
        default=[0],
        type=int,
    )
    parser.add_argument(
        "--output_path",
        help="Path to a location on disk. Path is expected to exist.",
        required=True,                    
        type=os.path.abspath,
    )
    parser.add_argument(
        "--ics_or_lbcs",
        choices=("ICS", "LBCS"),
        help="Flag for whether ICS or LBCS.",
        required=False
    )

    # Optional
    parser.add_argument(
        "--version",     # for file patterns that dont conform to cycle_date [TBD]
        help="Version number of package to download, e.g. x.yy.zz",
    )
    parser.add_argument(
        "--symlink",
        action="store_true",
        help="Symlink data files when source is disk",
    )
    parser.add_argument(
        "--debug",
        action="store_true",
        help="Print debug messages",
    )
    parser.add_argument(
        "--file_templates",
        help="One or more file template strings defining the naming \
        convention to be used for the files retrieved from disk. If \
        not provided, the default names from hpss are used.",
        nargs="*",
    )
    parser.add_argument(
        "--file_fmt",
        choices=("grib2", "nemsio", "netcdf", "prepbufr", "tcvitals"),
        help="External model file format",
    )
    parser.add_argument(
        "--input_file_path",
        help="A path to data stored on disk. The path may contain \
        Python templates. File names may be supplied using the \
        --file_templates flag, or the default naming convention will be \
        taken from the --config file.",
    )
    parser.add_argument(
        "--members",
        help="A list describing ensemble members.  If one argument, \
        one member will be processed.  If 2 or 3 arguments, a sequence \
        of members [start, stop, [increment]] will be \
        processed.  If more than 3 arguments, the list is processed \
        as-is.",
        nargs="*",
        type=int,
    )
    parser.add_argument(
        "--summary_file",
        help="Name of the summary file to be written to the output \
        directory",
    )
    parser.add_argument(
        "--check_file",
        action="store_true",
        help="Use this flag to check the existence of requested files, \
         but don't try to download them. Works with download protocol \
         only",
    )

    # Make modifications/checks for given values

    args = parser.parse_args(argv)

    # convert range arguments if necessary 
    args.fcst_hrs = arg_list_to_range(args.fcst_hrs)
    if args.members:
        args.members = arg_list_to_range(args.members)

    # Check required arguments for various conditions
    if not args.ics_or_lbcs and args.file_set in ["anl", "fcst"]:
        raise argparse.ArgumentTypeError(f"--ics_or_lbcs is a required " \
              f"argument when --file_set = {args.file_set}")

    # Check valid arguments for various conditions
    valid_data_stores = ["hpss", "nomads", "aws", "disk", "remote"]
    for store in args.data_stores:
        if store not in valid_data_stores:
            raise argparse.ArgumentTypeError(f"Invalid value '{store}' provided " \
                  f"for --data_stores; valid values are {valid_data_stores}")

    return args


if __name__ == "__main__":
    main(sys.argv[1:])
