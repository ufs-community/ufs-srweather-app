# pylint: disable=logging-fstring-interpolation
'''
This script helps users pull data from known data streams, including
URLS and HPSS (only on supported NOAA platforms), or from user-supplied
data locations on disk.

Several supported data streams are included in
ush/templates/data_locations.yml, which provides locations and naming
conventions for files commonly used with the SRW App. Provide the file
to this tool via the --config flag. Users are welcome to provide their
own file with alternative locations and naming conventions.

When using this script to pull from disk, the user is required to
provide the path to the data location, which can include Python
templates. The file names follow those included in the --config file by
default, or can be user-supplied via the --file_name flag. That flag
takes a YAML-formatted string that follows the same conventions outlined
in the ush/templates/data_locations.yml file for naming files.

To see usage for this script:

    python retrieve_data.py -h

Also see the parse_args function below.
'''

import argparse
import datetime as dt
import logging
import os
import shutil
import subprocess
import sys

import yaml

def clean_up_output_dir(expected_subdir, local_archive, output_path, source_paths):

    ''' Remove expected sub-directories and existing_archive files on
    disk once all files have been extracted and put into the specified
    output location. '''

    unavailable = {}
    # Check to make sure the files exist on disk
    for file_path in source_paths:
        local_file_path = os.path.join(output_path,file_path)
        if not os.path.exists(local_file_path):
            logging.info(f'File does not exist: {local_file_path}')
            unavailable['hpss'] = source_paths
        else:
            file_name = os.path.basename(file_path)
            expected_output_loc = os.path.join(output_path, file_name)
            if not local_file_path == expected_output_loc:
                logging.info(f'Moving {local_file_path} to ' \
                             f'{expected_output_loc}')
                shutil.move(local_file_path, expected_output_loc)

    # Clean up directories from inside archive, if they exist
    if os.path.exists(expected_subdir) and expected_subdir != './':
        logging.info(f'Removing {expected_subdir}')
        os.removedirs(expected_subdir)

    # If an archive exists on disk, remove it
    if os.path.exists(local_archive):
        os.remove(local_archive)

    return unavailable

def copy_file(source, destination):

    '''
    Copy a file from a source and place it in the destination location.
    Return a boolean value reflecting the state of the copy.

    Assumes destination exists.
    '''

    if not os.path.exists(source):
        logging.info(f'File does not exist on disk \n {source}')
        return False

    # Using subprocess here because system copy is much faster than
    # python copy options.
    cmd = f'cp {source} {destination}'
    logging.info(f'Running command: \n {cmd}')
    try:
        subprocess.run(cmd,
            check=True,
            shell=True,
            )
    except subprocess.CalledProcessError as err:
        logging.info(err)
        return False
    return True

def download_file(url):

    '''
    Download a file from a url source, and place it in a target location
    on disk.

    Arguments:
      url          url to file to be downloaded

    Return:
      boolean value reflecting state of download.
    '''

    # wget flags:
    # -c continue previous attempt
    # -T timeout seconds
    # -t number of tries
    cmd = f'wget -c -T 30 -t 3 {url}'
    logging.info(f'Running command: \n {cmd}')
    try:
        subprocess.run(cmd,
            check=True,
            shell=True,
            )
    except subprocess.CalledProcessError as err:
        logging.info(err)
        return False
    except:
        logging.error('Command failed!')
        raise

    return True

def download_requested_files(cla, data_store, store_specs):

    ''' This function interacts with the "download" protocol in a
    provided data store specs file to download a set of files requested
    by the user. It calls download_file for each individual file that
    should be downloaded. '''

    base_urls = store_specs['url']
    base_urls = base_urls if isinstance(base_urls, list) else [base_urls]

    file_names = store_specs.get('file_names', {})
    if cla.file_type is not None:
        file_names = file_names[cla.file_type]
    file_names = file_names[cla.anl_or_fcst]
    target_path = fill_template(cla.output_path,
                                cla.cycle_date)

    logging.info(f'Downloaded files will be placed here: \n {target_path}')
    orig_path = os.getcwd()
    os.chdir(target_path)
    unavailable = {}
    for base_url in base_urls:
        for fcst_hr in cla.fcst_hrs:
            for file_name in file_names:
                url = os.path.join(base_url, file_name)
                url = fill_template(url, cla.cycle_date, fcst_hr)
                downloaded = download_file(url)
                if not downloaded:

                    if unavailable.get(data_store) is None:
                        unavailable[data_store] = []
                    unavailable[data_store].append(target_path)
                    os.chdir(orig_path)
                    # Returning here assumes that if the first file
                    # isn't found, none of the others will be. Don't
                    # waste time timing out on every requested file.
                    return unavailable
    os.chdir(orig_path)
    return unavailable

def fhr_list(args):

    '''
    Given an argparse list argument, return the sequence of forecast hours to
    process.

    The length of the list will determine what forecast hours are returned:

      Length = 1:   A single fhr is to be processed
      Length = 2:   A sequence of start, stop with increment 1
      Length = 3:   A sequence of start, stop, increment
      Length > 3:   List as is

    argparse should provide a list of at least one item (nargs='+').

    Must ensure that the list contains integers.
    '''

    args = args if isinstance(args, list) else [args]
    arg_len = len(args)
    if arg_len in (2, 3):
        args[1] += 1
        return list(range(*args))

    return args

def fill_template(template_str, cycle_date, fcst_hr=0,
        templates_only=False):

    ''' Fill in the provided template string with date time information,
    and return the resulting string.

    Arguments:
      template_str    a string containing Python templates
      cycle_date      a datetime object that will be used to fill in
                      date and time information
      fcst_hr         an integer forecast hour. string formatting should
                      be included in the template_str
      templates_only  boolean value. When True, this function will only
                      return the templates available.

    Rerturn:
      filled template string
    '''

    cycle_hour = cycle_date.strftime('%H')
    # One strategy for binning data files at NCEP is to put them into 6
    # cycle bins. The archive file names include the low and high end of the
    # range. Set the range as would be indicated in the archive file
    # here. Integer division is intentional here.
    low_end = int(cycle_hour) // 6 * 6
    bin6 = f'{low_end:02d}-{low_end+5:02d}'

    # Another strategy is to bundle odd cycle hours with their next
    # lowest even cycle hour. Files are named only with the even hour.
    # Integer division is intentional here.
    hh_even = f'{int(cycle_hour) // 2 * 2:02d}'

    format_values = dict(
        bin6=bin6,
        fcst_hr=fcst_hr,
        dd=cycle_date.strftime('%d'),
        hh=cycle_hour,
        hh_even=hh_even,
        jjj=cycle_date.strftime('%j'),
        mm=cycle_date.strftime('%m'),
        yy=cycle_date.strftime('%y'),
        yyyy=cycle_date.strftime('%Y'),
        yyyymm=cycle_date.strftime('%Y%m'),
        yyyymmdd=cycle_date.strftime('%Y%m%d'),
        yyyymmddhh=cycle_date.strftime('%Y%m%d%H'),
        )
    if templates_only:
        return f'{",".join((format_values.keys()))}'
    return template_str.format(**format_values)

def find_archive_files(paths, file_names, cycle_date):

    ''' Given an equal-length set of archive paths and archive file
    names, and a cycle date, check HPSS via hsi to make sure at least
    one set exists. Return the path of the existing archive, along with
    the item in set of paths that was found.'''

    zipped_archive_file_paths = zip(paths, file_names)

    # Narrow down which HPSS files are available for this date
    for list_item, (archive_path, archive_file_names) in \
        enumerate(zipped_archive_file_paths):

        if not isinstance(archive_file_names, list):
            archive_file_names = [archive_file_names]

        # Only test the first item in the list, it will tell us if this
        # set exists at this date.
        file_path = os.path.join(archive_path, archive_file_names[0])
        file_path = fill_template(file_path, cycle_date)

        existing_archive = hsi_single_file(file_path)

        if existing_archive:
            logging.info(f'Found HPSS file: {file_path}')
            return existing_archive, list_item

    return '', 0

def get_requested_files(cla, file_names, input_loc, method='disk'):

    ''' This function copies files from disk locations
    or downloads files from a url, depending on the option specified for
    user.

    This function expects that the output directory exists and is
    writeable.

    Arguments:

    cla        Namespace object containing command line arguments
    file_names Dict of file names by file type and kind
    input_loc  A string containing a single data location, either a url
               or disk path.
    method     Choice of disk or download to indicate protocol for
               retrieval

    Returns
    unavailable  a dict whose keys are "method" and whose values are a
                 list of files unretrievable
    '''

    unavailable = {}

    if cla.file_type is not None:
        file_names = file_names[cla.file_type]
    file_names = file_names[cla.anl_or_fcst]

    file_names = file_names if isinstance(file_names, list) else \
            [file_names]
    target_path = fill_template(cla.output_path,
                                cla.cycle_date)

    logging.info(f'Retrieved files will be placed here: \n {target_path}')
    orig_path = os.getcwd()
    os.chdir(target_path)
    unavailable = {}
    for fcst_hr in cla.fcst_hrs:
        for file_name in file_names:
            loc = os.path.join(input_loc, file_name)
            loc = fill_template(loc, cla.cycle_date, fcst_hr)

            if method == 'disk':
                retrieved = copy_file(loc, target_path)

            if method == 'download':
                retrieved = download_file(loc)

            if not retrieved:

                if unavailable.get(method) is None:
                    unavailable[method] = []
                unavailable[method].append(target_path)
                os.chdir(orig_path)
                # Returning here assumes that if the first file
                # isn't found, none of the others will be. Don't
                # waste time timing out on every requested file.
                return unavailable
    os.chdir(orig_path)
    return unavailable

def hsi_single_file(file_path, mode='ls'):

    ''' Call hsi as a subprocess for Python and return information about
    whether the file_path was found.

    Arguments:
        file_path    path on HPSS
        mode         the hsi command to run. ls is default. may also
                     pass "get" to retrieve the file path

    '''
    cmd = f'hsi {mode} {file_path}'

    logging.info(f'Running command \n {cmd}')
    try:
        subprocess.run(cmd,
                       check=True,
                       shell=True,
                       )
    except subprocess.CalledProcessError:
        logging.warning(f'{file_path} is not available!')
        return ''

    return file_path

def hpss_requested_files(cla, store_specs):

    ''' This function interacts with the "hpss" protocol in a
    provided data store specs file to download a set of files requested
    by the user. Depending on the type of archive file (zip or tar), it
    will either pull the entire file and unzip it, or attempt to pull
    individual files from a tar file.

    It cleans up local disk after files are deemed available to remove
    any empty subdirectories that may still be present.

    This function exepcts that the output directory exists and is
    writable.
    '''

    archive_paths = store_specs['archive_path']
    archive_paths = archive_paths if isinstance(archive_paths, list) \
        else [archive_paths]

    # Could be a list of lists
    archive_file_names = store_specs.get('archive_file_names', {})
    if cla.file_type is not None:
        archive_file_names = archive_file_names[cla.file_type]

    if isinstance(archive_file_names, dict):
        archive_file_names = archive_file_names[cla.anl_or_fcst]

    unavailable = {}
    existing_archive = None

    logging.debug(f'Will try to look for: '\
            f' {list(zip(archive_paths, archive_file_names))}')

    existing_archive, which_archive = find_archive_files(archive_paths,
                                                         archive_file_names,
                                                         cla.cycle_date,
                                                         )

    if not existing_archive:
        logging.warning('No archive files were found!')
        unavailable['archive'] = list(zip(archive_paths, archive_file_names))
        return unavailable

    # Use the found archive file path to get the necessary files
    file_names = store_specs.get('file_names', {})
    if cla.file_type is not None:
        file_names = file_names[cla.file_type]
    file_names = file_names[cla.anl_or_fcst]

    logging.debug(f'Grabbing archive number {which_archive} in list.')
    archive_internal_dir = store_specs.get('archive_internal_dir', [''])[which_archive]
    archive_internal_dir = fill_template(archive_internal_dir,
                                         cla.cycle_date)

    output_path = fill_template(cla.output_path, cla.cycle_date)
    logging.info(f'Will place files in {os.path.abspath(output_path)}')
    orig_path = os.getcwd()
    os.chdir(output_path)
    logging.debug(f'CWD: {os.getcwd()}')

    source_paths = []
    for fcst_hr in cla.fcst_hrs:
        for file_name in file_names:
            source_paths.append(fill_template(
                os.path.join(archive_internal_dir, file_name),
                cla.cycle_date,
                fcst_hr,
                ))

    if store_specs.get('archive_format', 'tar') == 'zip':
        # Get the entire file from HPSS
        existing_archive = hsi_single_file(existing_archive, mode='get')

        # Grab only the necessary files from the archive
        cmd = f'unzip -o {os.path.basename(existing_archive)} {" ".join(source_paths)}'

    else:
        cmd = f'htar -xvf {existing_archive} {" ".join(source_paths)}'

    logging.info(f'Running command \n {cmd}')
    subprocess.run(cmd,
                   check=True,
                   shell=True,
                   )

    # Check that files exist and Remove any data transfer artifacts.
    unavailable = clean_up_output_dir(
        expected_subdir=archive_internal_dir,
        local_archive=os.path.basename(existing_archive),
        output_path=output_path,
        source_paths=source_paths,
        )

    os.chdir(orig_path)

    return unavailable

def load_str(arg):

    ''' Load a dict string safely using YAML. Return the resulting dict.  '''
    return yaml.load(arg, Loader=yaml.SafeLoader)

def config_exists(arg):

    '''
    Check to ensure that the provided config file exists. If it does, load it
    with YAML's safe loader and return the resulting dict.
    '''

    # Check for existence of file
    if not os.path.exists(arg):
        msg = f'{arg} does not exist!'
        raise argparse.ArgumentTypeError(msg)

    with open(arg, 'r') as config_path:
        cfg = yaml.load(config_path, Loader=yaml.SafeLoader)
    return cfg

def path_exists(arg):

    ''' Check whether the supplied path exists and is writeable '''

    if not os.path.exists(arg):
        msg = f'{arg} does not exist!'
        raise argparse.ArgumentTypeError(msg)

    if not os.access(arg, os.X_OK|os.W_OK):
        logging.error(f'{arg} is not writeable!')
        raise argparse.ArgumentTypeError(msg)

    return arg

def setup_logging(debug=False):

    ''' Calls initialization functions for logging package, and sets the
    user-defined level for logging in the script.'''

    level = logging.WARNING
    if debug:
        level = logging.DEBUG

    logging.basicConfig(format='%(levelname)s: %(message)s \n ', level=level)
    if debug:
        logging.info('Logging level set to DEBUG')



def to_datetime(arg):
    ''' Return a datetime object give a string like YYYYMMDDHH.
    '''

    return dt.datetime.strptime(arg, '%Y%m%d%H')

def to_lower(arg):
    ''' Return a string provided by arg into all lower case. '''
    return arg.lower()

def main(cla):
    '''
    Uses known location information to try the known locations and file
    paths in priority order.
    '''

    setup_logging(cla.debug)

    known_data_info =  cla.config.get(cla.external_model)
    if known_data_info is None:
        msg = ('No data stores have been defined for',
               f'{cla.external_model}!')
        raise KeyError(msg)

    unavailable = {}
    for data_store in cla.data_stores:
        logging.info(f'Checking {data_store} for {cla.external_model}')
        store_specs = known_data_info.get(data_store, {})

        if data_store == 'disk':
            file_names = cla.file_names if cla.file_names else \
                known_data_info.get('hpss', {}).get('file_names')
            logging.debug(f'User supplied file names are: {file_names}')
            if not file_names:
                msg = ('No file name found. They must be provided \
                        either on the command line or on in a config file.')
                raise argparse.ArgumentTypeError(msg)
            unavailable = get_requested_files(cla,
                                              file_names=file_names,
                                              input_loc=cla.input_file_path,
                                              method='disk',
                                              )

        elif not store_specs:
            msg = (f'No information is available for {data_store}.')
            raise KeyError(msg)

        if store_specs.get('protocol') == 'download':
            file_names = store_specs.get('file_names')
            if not file_names:
                msg = ('No file name found. They must be provided \
                        either on the command line or on in a config file.')
                raise argparse.ArgumentTypeError(msg)

            unavailable = get_requested_files(cla,
                                              file_names=file_names,
                                              input_loc=store_specs['url'],
                                              method='download',
                                              )

        if store_specs.get('protocol') == 'htar':
            unavailable = hpss_requested_files(cla, store_specs)

        if not unavailable:
            # All files are found. Stop looking!
            break

        logging.warning(f'Requested files are unavialable from {data_store}')

    if unavailable:
        logging.error('Could not find any of the requested files.')
        sys.exit(1)

def parse_args():

    '''
    Function maintains the arguments accepted by this script. Please see
    Python's argparse documenation for more information about settings of each
    argument.
    '''

    description=(
    'Allowable Python templates for paths, urls, and file names are '\
    ' defined in the fill_template function and include:\n' \
    f'{"-"*120}\n' \
    f'{fill_template("null", dt.datetime.now(), templates_only=True)}')
    parser = argparse.ArgumentParser(
        description=description,
    )

    # Required
    parser.add_argument(
        '--anl_or_fcst',
        choices=('anl', 'fcst'),
        help='Flag for whether analysis or forecast \
        files should be gathered',
        required=True,
        )
    parser.add_argument(
        '--config',
        help='Full path to a configuration file containing paths and \
        naming conventions for known data streams. The default included \
        in this repository is in ush/templates/data_locations.yml',
        type=config_exists,
        )
    parser.add_argument(
        '--cycle_date',
        help='Cycle date of the data to be retrieved in YYYYMMDDHH \
        format.',
        required=True,
        type=to_datetime,
        )
    parser.add_argument(
        '--data_stores',
        help='List of priority data_stores. Tries first list item \
        first. Choices: hpss, nomads, aws, disk',
        nargs='*',
        required=True,
        type=to_lower,
        )
    parser.add_argument(
        '--external_model',
        choices=('FV3GFS', 'GSMGFS', 'HRRR', 'NAM', 'RAP', 'RAPx',
        'HRRRx'),
        help='External model label. This input is case-sensitive',
        required=True,
        )
    parser.add_argument(
        '--fcst_hrs',
        help='A list describing forecast hours.  If one argument, \
        one fhr will be processed.  If 2 or 3 arguments, a sequence \
        of forecast hours [start, stop, [increment]] will be \
        processed.  If more than 3 arguments, the list is processed \
        as-is.',
        nargs='+',
        required=True,
        type=int,
        )
    parser.add_argument(
        '--output_path',
        help='Path to a location on disk. Path is expected to exist.',
        required=True,
        type=os.path.abspath,
        )

    # Optional
    parser.add_argument(
        '--debug',
        action='store_true',
        help='Print debug messages',
        )
    parser.add_argument(
        '--file_names',
        help='A YAML-formatted string that indicates the naming \
        convention the be used for the files retrieved from disk. If \
        not provided, the default names from hpss are used.',
        type=load_str,
        )
    parser.add_argument(
        '--file_type',
        choices=('grib2', 'nemsio', 'netcdf'),
        help='External model file format',
        )
    parser.add_argument(
        '--input_file_path',
        help='A path to data stored on disk. The path may contain \
        Python templates. File names may be supplied using the \
        --file_names flag, or the default naming convention will be \
        taken from the --config file.',
        nargs='*',
        )
    return parser.parse_args()

if __name__ == '__main__':

    CLA = parse_args()
    CLA.output_path = path_exists(CLA.output_path)
    CLA.fcst_hrs = fhr_list(CLA.fcst_hrs)

    if 'disk' in CLA.data_stores:
        # Make sure a path was provided.
        if not CLA.input_file_path:
            raise argparse.ArgumentTypeError(
                ('You must provide an input_file_path when choosing ' \
                 ' disk as a data store!'))

    if 'hpss' in CLA.data_stores:
        # Make sure hpss module is loaded
        try:
            output = subprocess.run('which hsi',
                                    check=True,
                                    shell=True,
                                    capture_output=True,
                                    )
        except subprocess.CalledProcessError:
            logging.error('You requested the hpss data store, but ' \
                    'the HPSS module isn\'t loaded. This data store ' \
                    'is only available on NOAA compute platforms.')

    main(CLA)
