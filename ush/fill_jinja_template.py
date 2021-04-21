#!/usr/bin/env python3

'''
This utility fills in a user-supplied Jinja template from either a YAML file, or
command line arguments.

The user configuration file and commandline arguments should be YAML-formatted.
This script will support a single- or two-level YAML config file. For example:

    1. expt1:
         date_first_cycl: !datetime 2019043000
         date_last_cycl: !datetime 2019050100
         cycl_freq: !!str 12:00:00

       expt2:
         date_first_cycl: !datetime 2019061012
         date_last_cycl: !datetime 2019061212
         cycl_freq: !!str 12:00:00

    2. date_first_cycl: !datetime 2019043000
       date_last_cycl: !datetime 2019050100
       cycl_freq: !!str 12:00:00

    In Case 1, provide the name of the file and the section title, e.g. expt2,
    to the -c command line argument. Only provide the name of the file in -c
    option if it's configured as in Case 2 above.


Supported YAML Tags:

    The script supports additional YAML configuration tags.

    !datetime      Converts an input string formatted as YYYYMMDDHH[mm[ss]] to a
                   Python datetime object
    !join          Uses os.path.join to join a list as a path.

Expected behavior:

    - The template file is required. Script fails if not provided.
    - Command line arguments in the -u setting override the -c settings.

'''

import datetime as dt
import os

import argparse
import jinja2 as j2
from jinja2 import meta
import yaml


def join(loader, node):

    ''' Uses os to join a list as a path. '''

    return os.path.join(*loader.construct_sequence(node))

def to_datetime(loader, node):

    ''' Converts a date string with format YYYYMMDDHH[MM[SS]] to a datetime
    object. '''

    value = loader.construct_scalar(node)
    val_len = len(value)


    # Check that the input string contains only numbers and is expected length.
    if val_len not in [10, 12, 14] or not value.isnumeric():
        msg = f'{value} does not conform to input format YYYYMMDDHH[MM[SS]]'
        raise ValueError(msg)

    # Use a subset of the string corresponding to the input length of the string
    # 2 chosen here since Y is a 4 char year.
    date_format = '%Y%m%d%H%M%S'[0:val_len-2]

    return dt.datetime.strptime(value, date_format)

yaml.add_constructor('!datetime', to_datetime, Loader=yaml.SafeLoader)
yaml.add_constructor('!join', join, Loader=yaml.SafeLoader)

def file_exists(arg):

    ''' Checks whether a file exists, and returns the path if it does. '''

    if not os.path.exists(arg):
        msg = f'{arg} does not exist!'
        raise argparse.ArgumentTypeError(msg)

    return arg

def config_exists(arg):

    '''
    Checks whether the config file exists and if it contains the input
    section. Returns the config as a Python dict.
    '''

    if len(arg) > 2:
        msg = f'{len(arg)} arguments were provided for config. Only 2 allowed!'
        raise argparse.ArgumentTypeError(msg)

    file_name = file_exists(arg[0])
    section_name = arg[1] if len(arg) == 2 else None

    # Load the YAML file into a dictionary
    with open(file_name, 'r') as fn:
        cfg = yaml.load(fn, Loader=yaml.SafeLoader)

    if section_name:
        try:
            cfg = cfg[section_name]
        except KeyError:
            msg = f'Section {section_name} does not exist in top level of {file_name}'
            raise argparse.ArgumentTypeError(msg)

    return cfg


def load_config(arg):

    '''
    Check to ensure that the provided config file exists. If it does, load it
    with YAML's safe loader and return the resulting dict.
    '''

    # Check for existence of file
    if not os.path.exists(arg):
        msg = f'{arg} does not exist!'
        raise argparse.ArgumentTypeError(msg)

    return yaml.safe_load(arg)

def load_str(arg):

    ''' Load a dict string safely using YAML. Return the resulting dict.  '''

    return yaml.load(arg, Loader=yaml.SafeLoader)

def path_ok(arg):

    '''
    Check whether the path to the file exists, and is writeable. Return the path
    if it passes all checks, otherwise raise an error.
    '''

    # Get the absolute path provided by arg
    dir_name = os.path.abspath(os.path.dirname(arg))

    # Ensure the arg path exists, and is writable. Raise error if not.
    if os.path.lexists(dir_name) and os.access(dir_name, os.W_OK):
        return arg

    msg = f'{arg} is not a writable path!'
    raise argparse.ArgumentTypeError(msg)


def parse_args():

    '''
    Function maintains the arguments accepted by this script. Please see
    Python's argparse documenation for more information about settings of each
    argument.
    '''

    parser = argparse.ArgumentParser(
        description='Fill in a Rocoto XML template.'
    )

    # Optional
    parser.add_argument('-c', '--config',
                        help='Full path to a YAML user config file, and a \
                        top-level section to use (optional).',
                        nargs='*',
                        type=load_config,
                        )
    parser.add_argument('-q', '--quiet',
                        action='store_true',
                        help='Suppress all output',
                        )
    parser.add_argument('-u', '--user_config',
                        help='Command-line user config options in YAML-formatted string',
                        type=load_str,
                        )
    # Required
    parser.add_argument('-t', '--xml_template',
                        dest='template',
                        help='Full path to the jinja template',
                        required=True,
                        type=file_exists,
                        )
    parser.add_argument('-o', '--outxml',
                        dest='outxml',
                        help='Full path to the output Rocoto XML file.',
                        required=True,
                        type=path_ok,
                        )
    return parser.parse_args()

def update_dict(dest, newdict, quiet=False):

    '''
    Overwrites all values in dest dictionary section with key/value pairs from
    newdict. Does not support multi-layer update.

    Turn off print statements with quiet=True.

    Input:
        dest      A dict that is to be updated.
        newdict   A dict containing sections and keys corresponding to
                  those in dest and potentially additional ones, that will be used to
                  update the dest dict.
        quiet     An optional boolean flag to turn off output.
    Output:
        None
    Result:
        The dest dict is updated in place.
    '''

    if not quiet:
        print('*' * 50)

    for key, value in newdict.items():
        if not quiet:
            print(f'Overriding {key:>20} = {value}')

        # Set key in dict
        dest[key] = value

    if not quiet:
        print('*' * 50)


def main(cla):

    '''
    Loads a Jinja template, determines its necessary undefined variables,
    retrives them from user supplied settings, and renders the final result.
    '''

    # Create a Jinja Environment to load the template.
    env = j2.Environment(loader=j2.FileSystemLoader(cla.template))
    template_source = env.loader.get_source(env, '')
    template = env.get_template('')
    parsed_content = env.parse(template_source)

    # Gather all of the undefined variables in the template.
    template_vars = meta.find_undeclared_variables(parsed_content)

    # Read in the config options from the provided (optional) YAML file
    cfg = cla.config if cla.config is not None else {}

    # Update cfg with (optional) command-line entries, overriding those in YAML file
    if cla.user_config:
        update_dict(cfg, cla.user_config, quiet=cla.quiet)

    # Loop through all the undefined Jinja template variables, and grab the
    # required values from the config file.
    tvars = {}
    for var in template_vars:

        if cfg.get(var, "NULL") == "NULL":
            raise KeyError(f'{var} does not exist in user-supplied settings!')

        if not cla.quiet:
            print(f'{var:>25}: {cfg.get(var)}')

        tvars[var] = cfg.get(var)

    # Fill in XML template
    xml_contents = template.render(**tvars)
    with open(cla.outxml, 'w') as fn:
        fn.write(xml_contents)


if __name__ == '__main__':
    cla = parse_args()
    if cla.config:
        cla.config = config_exists(cla.config)
    main(cla)
