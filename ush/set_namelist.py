#!/usr/bin/env python3

'''
This utility updates a Fortran namelist file using the f90nml package. The
settings that are modified are supplied via command line YAML-formatted string
and/or YAML configuration files.

Additionally, the tool can be used to create a YAML file from an input namelist,
or the difference between two namelists.

The user configuration file should contain a heirarchy that follows the
heirarchy for the Fortran namelist. An example of modifying an FV3 namelist:

    Configuration file contains:

    fv_core_nml:
      k_split: 4
      n_split: 5

    gfs_physics_nml:
      do_sppt: True

The output namelist will differ from the input namelist by only these three
settings. If one of these sections and/or variables did not previously exist, it
will be automatically created. It is up to the user to ensure that configuration
settings are provided under the correct sections and variable names.

The optional base configuration file (provided via the -c command line argument)
contains the known set of configurations used and supported by the community, if
using the one provided in ush/templates/FV3.input.yml. If maintaining this file
for a different set of configurations, ensure that the heirarchy is such that it
names the configuration at the top level (section), and the subsequent sections
match those in the F90 namelist that will be updated.

Examples

  To show help options:

    set_namelist.py -h

  To produce a namelist (fv3_expt.nml) by specifying a physics package:

    set_namelist.py -n templates/input.nml.FV3 -c templates/FV3.input.yml FV3_HRRR
        -o fv3_expt.nml

  To produce a YAML file (fv3_namelist.yml) from a user namelist:

    set_namelist.py -i my_namelist.nml -o fv3_namelist.nml -t yaml

  To produce a YAML file (fv3_my_namelist.yml) with differences from base nml:

    set_namelist.py -n templates/input.nml.FV3 -i my_namelist.nml -t yaml
        -o fv3_my_namelist.nml

Expected behavior:

    - A Fortran namelist that contains only user-defined settings will be
      generated if no input namelist is provided.
    - An unmodified copy of an input namelist will be generated in the
      designated output location if no user-settings are provided.
    - Command-line-entered settings over-ride settings in YAML configuration
      file.
    - Given a user namelist, the script can dump a YAML file.
    - Given a user namelist and a base namelist, the script can dump the
      difference in the two to a YAML file that can be included as a section
      in the supported configs.
'''

import argparse
import collections
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

    file_exists(file_name)

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

def file_exists(arg):

    ''' Check for existence of file '''

    if not os.path.exists(arg):
        msg = f'{arg} does not exist!'
        raise argparse.ArgumentTypeError(msg)

    return arg

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
    parser.add_argument('-o', '--outfile',
                        help='Required: Full path to output file. This is a \
                        namelist by default.',
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
    parser.add_argument('-i', '--input_nml',
                        help='Path to a user namelist. Use with -n and \
                        -t yaml to get a YAML file to use with workflow.',
                        type=file_exists,
                        )
    parser.add_argument('-n', '--basenml',
                        dest='nml',
                        help='Full path to the input Fortran namelist. Optional.',
                        type=file_exists,
                        )
    parser.add_argument('-t', '--type',
                        choices=['nml', 'yaml'],
                        default='nml',
                        help='Output file type.',
                        )
    parser.add_argument('-u', '--user_config',
                        help='Command-line user config options in YAML-formatted \
                        string. These options will override any provided in an \
                        input file. Optional.',
                        metavar='YAML STRING',
                        type=load_config,
                        )

    # Flags
    parser.add_argument('-q', '--quiet',
                        action='store_true',
                        help='If provided, suppress all output.',
                        )
    return parser.parse_args()

def dict_diff(dict1, dict2):

    '''
    Produces a dictionary of how dict2 differs from dict1
    '''

    diffs = {}

    # Loop through dict1 sections and key/value pairs
    for sect, items in dict1.items():
        for key, val in items.items():

            # If dict 2 has a different value, record the dict2 value
            if val != dict2.get(sect, {}).get(key, ''):
                if not diffs.get(sect):
                    diffs[sect] = {}
                diffs[sect][key] = dict2.get(sect, {}).get(key)

    # Loop through dict2 sections and key/value pairs to catch any settings that
    # may be present in the 2nd dict that weren't in the first.
    for sect, items in dict2.items():
        for key, val in items.items():

            # If dict1 has a diffent value than dict2, record the dict2 value
            if val != dict1.get(sect, {}).get(key, ''):

                # Check to make sure it hasn't already been recorded
                if diffs.get(sect, {}).get(key, 'DNE') == 'DNE':
                    if not diffs.get(sect):
                        diffs[sect] = {}
                    diffs[sect][key] = val
    return diffs

def to_dict(odict):

    ''' Recursively convert OrderedDict to Python dict. '''

    if not isinstance(odict, collections.OrderedDict):
        return odict

    ret = dict(odict)
    for key, value in ret.items():
        if isinstance(value, collections.OrderedDict):
            ret[key] = to_dict(value)
    return ret

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

    # Load base namelist into dict
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

    # Write the resulting file
    with open(cla.outfile, 'w') as fn:
        if cla.type == 'nml':
            nml.write(fn, sort=True)

        if cla.type == 'yaml':
            if cla.input_nml:
                input_nml = f90nml.read(cla.input_nml)

                # Determine how input_nml differs from the configured namelist
                diff = dict_diff(nml, input_nml)

                # Write diffs to YAML file
                yaml.dump(diff, fn)

            else:
                # Write the namelist to YAML file
                yaml.dump(to_dict(nml.todict()), fn)


if __name__ == '__main__':
    cla = parse_args()
    if cla.config:
        cla.config, _ = config_exists(cla.config)
    main(cla)
