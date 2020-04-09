#!/usr/bin/env python

'''
This utility updates a Fortran namelist file using the f90nml package. The
settings that are modified are pulled from variables set by the bash environment
from which the script is called, and/or a YAML user configuration file.

The user configuration file should contain a heirarchy that follows the
heirarchy for the Fortran namelist. An example of modifying an FV3 namelist:

    Configuration file contains:

    fv_core_nml:
      k_split: 4
      n_split: 5

    gfs_physics_nml:
      do_sppt: True

    The output namelist will differ from the input namelist by only these three
    settings. If one of these sections and/or variables did not previously
    exist, it will be automatically created. It is up to the user to ensure that
    configuration settings are provided under the correct sections and variable
    names.

The optional base configuration file (provided via the -c command line argument)
contains the known set of configurations used and supported by the community, if
using the one provided in ush/templates/FV3.input.yml. If maintaining this file
for a different set of configurations, ensure that the heirarchy is such that it
names the configuration at the top level (section), and the subsequent sections
match those in the F90 namelist that will be updated.

Expected behavior:

    - A Fortran namelist that contains only user-defined settings will be
      generated if no input namelist is provided.
    - An unmodified copy of an input namelist will be generated in the
      designated output location if no user-settings are provided.
    - Command-line-entered settings over-ride settings in YAML configuration
      file.

'''

import argparse
import os

import f90nml
import yaml


def config_exists(arg):

    '''
    Checks whether the config file exists and if it contains the input
    section. Returns the arg as provided if checks are passed.
    '''

    # Agument is expected to be a 2-item list of file name and internal section
    # name.
    file_name = arg[0]
    section_name = arg[1]

    # Check for existence of file
    if not os.path.exists(file_name):
        msg = f'{file_name} does not exist!'
        raise argparse.ArgumentTypeError(msg)

    # Load the YAML file into a dictionary
    with open(file_name, 'r') as fn:
        cfg = yaml.load(fn, Loader=yaml.Loader)

    # Grab only the section that is specified by the user
    try:
        cfg = cfg[section_name]
    except KeyError:
        msg = f'Section {section_name} does not exist in top level of {file_name}'
        raise argparse.ArgumentTypeError(msg)

    return [cfg, section_name]

def load_config(arg):

    '''
    Check to ensure that the provided config file exists. If it does, load it
    with YAML's safe loader and return the resulting dict.
    '''

    return yaml.safe_load(arg)

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
        description='Update a Fortran namelist with user-defined settings.'
    )

    # Required
    parser.add_argument('-o', '--outnml',
                        dest='outnml',
                        help='Required: Full path to output Fortran namelist.',
                        required=True,
                        type=path_ok,
                        )

    # Optional
    parser.add_argument('-c', '--config',
                        help='Full path to a YAML config file containing multiple \
                        configurations, and the top-level section to use. Optional.',
                        metavar=('[FILE,', 'SECTION]'),
                        nargs=2,
                        )
    parser.add_argument('-n', '--basenml',
                        dest='nml',
                        help='Full path the input Fortran namelist. Optional.',
                        )
    parser.add_argument('-q', '--quiet',
                        action='store_true',
                        help='If provided, suppress all output.',
                        )
    parser.add_argument('-u', '--user_config',
                        help='Command-line user config options in YAML-formatted \
                        string. These options will override any provided in an \
                        input file. Optional.',
                        metavar='YAML STRING',
                        type=load_config,
                        )
    return parser.parse_args()

def update_dict(dest, newdict, quiet=False):

    '''
    Overwrites all values in dest dictionary with values from newdict. Turn off
    print statements with queit=True.

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

    for sect, values in newdict:
        # If section is set to None, remove all contents from namelist
        if values is None:
            dest[sect] = {}
        else:
            for key, value in values.items():
                if not quiet:
                    print(f'Setting {sect}.{key} = {value}')

                # Remove key from dict if config is set to None
                if value is None:
                    _ = dest[sect].pop(key, None)
                else:

                    try:
                        dest[sect][key] = value
                    except KeyError:
                        # Namelist section did not exist. Create it and update the value.
                        dest[sect] = {}
                        dest[sect][key] = value

def main(cla):

    ''' Using input command line arguments (cla), update a Fortran namelist file. '''

    # Load namelist into dict
    nml = f90nml.Namelist()
    if cla.nml is not None:
        nml = f90nml.read(cla.nml)

    # Update namelist settings (nml) with config file settings (cfg)
    cfg = {}
    if cla.config is not None:
        cfg = cla.config
        update_dict(nml, cfg.items(), quiet=cla.quiet)

    # Update nml, overriding YAML if needed, with any command-line entries
    if cla.user_config:
        update_dict(nml, cla.user_config.items(), quiet=cla.quiet)

    # Write the resulting namelist to a file
    with open(cla.outnml, 'w') as fn:
        nml.write(fn)


if __name__ == '__main__':
    cla = parse_args()
    if cla.config:
        cla.config, _ = config_exists(cla.config)
    main(cla)
