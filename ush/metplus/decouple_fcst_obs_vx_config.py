#!/usr/bin/env python3

import os
import sys
import glob
import argparse
import yaml

import logging
import textwrap
from textwrap import indent, dedent

import pprint
import subprocess

from pathlib import Path
file = Path(__file__).resolve()
home_dir = file.parents[2]
ush_dir = Path(os.path.join(home_dir, 'ush')).resolve()
sys.path.append(str(ush_dir))

from python_utils import (
    log_info,
    load_config_file,
)


def get_pprint_str(var, indent_str=''):
    """
    Function to format a python variable as a pretty-printed string and add
    indentation.

    Arguments:
    ---------
    var:
      A variable.

    indent_str:
      String to be added to the beginning of each line of the pretty-printed
      form of var.  This usually consists of multiple space characters.

    Returns:
    -------
    var_str:
      Formatted string containing contents of variable.
    """

    var_str = pprint.pformat(var, compact=True)
    var_str = var_str.splitlines(True)
    var_str = [indent_str + s for s in var_str]
    var_str = ''.join(var_str)

    return var_str


def create_pprinted_msg(vars_dict, indent_str='', add_nl_after_varname=False):
    """
    Function to create an output message (string) containing one or more
    variables' names, with each name followed possibly by a newline, an equal
    sign, and the pretty-printed value of the variable.  Each variable name
    starts on a new line.

    Arguments:
    ---------
    vars_dict:
      Dictionary containing the variable names (the keys) and their values
      (the values).

    indent_str:
      String to be added to the beginning of each line of the string before
      returning it.  This usually consists of multiple space characters.

    add_nl_after_varname:
      Flag indicating whether to add a newline after the variable name (and
      before the equal sign).

    Returns:
    -------
    vars_str:
      Formatted string containing contents of variable.
    """

    space_or_nl = ' '
    one_or_zero = 1
    if add_nl_after_varname:
        space_or_nl = '\n'
        one_or_zero = 0

    vars_str = ''
    for var_name, var_value in vars_dict.items():
        pprint_indent_str = ' '*(2 + one_or_zero*(1 + len(var_name)))
        tmp = f'{var_name}' + space_or_nl + '= ' + \
            get_pprint_str(var_value, pprint_indent_str).lstrip()
        vars_str = '\n'.join([vars_str, tmp])

    vars_str = indent(vars_str, indent_str)

    return vars_str


def extract_fcst_obs_vals_from_cpld(item_cpld):
    """
    Function to parse the "coupled" value of an item (obtained from the coupled
    verification (vx) configuration dictionary) to extract from it the item's
    value for forecasts and its value for observations.  The coupled item
    (item_cpld) is a string that may correspond to a field name, a level, or
    a threshold.  It can be the name of a key in a key-value pair in the
    coupled vx configuration dictionary, or it can be the value (or, if the
    value is a list of strings, one of the elements in that list).

    If item_cpld has the form

        item_cpld = str1 + delim_str + str2

    where delim_str is a delimiter string (e.g. delim_str may be set to '%%'),
    then the forecast and observation values of the item are given by

        item_fcst = str1
        item_obs = str2

    For example, if delim_str = '%%' and

        item_cpld = 'ABCD%%EFGH'

    then

        item_fcst = 'ABCD'
        item_obs = 'EFGH'

    Alternatively, if delim_str is not be a substring within item_cpld so that
    item_cpld has the form

        item_cpld = str1

    then item_fcst and item_obs are given by

        item_fcst = str1
        item_obs = str1

    For example, if

        item_cpld = 'ABCD'

    then

        item_fcst = 'ABCD'
        item_obs = 'ABCD'

    Arguments:
    ---------
    item_cpld
      String representing a "coupled" item (field name, level, or threshold).
      containing both the item's forecast value and its observations value.

    Returns:
    -------
    item_fcst, item_obs:
      Strings containing the values of the item for forecasts and observations,
      respectively.
    """

    # Set the delimiter string.
    delim_str = '%%'

    # Parse the string containing the coupled value of the item to extract
    # its forecast and observation values.
    tmp = item_cpld.split(delim_str)
    num_delim_strs = len(tmp) - 1
    item_fcst = tmp[0].strip()
    if num_delim_strs == 0:
        item_obs = item_fcst
    elif num_delim_strs == 1:
        item_obs = tmp[1].strip()
    else:
        msg = dedent(f"""
            The delimiter string (delim_str) appears more than once in the current
            coupled item value (item_cpld):
              delim_str = {get_pprint_str(delim_str)}
              item_cpld = {get_pprint_str(item_cpld)}
              num_delim_strs = {get_pprint_str(num_delim_strs)}
            Stopping.
            """)
        logging.error(msg)
        raise ValueError(msg)

    return item_fcst, item_obs


def decouple_fcst_obs_vx_config(vx_type, outfile_type, outdir='./', log_lvl='info', log_fp=''):
    """
    This function reads from a yaml configuration file the coupled verification
    (vx) configuration dictionary and parses it (i.e. decouples its contents)
    to produce two new configuration dictionaries -- one for forecasts and
    another for observations.  Here, by "coupled" dictionary, we mean one that
    contains items (keys and values) that store the forecast and observation
    values for various quantities (field names, levels, and thresholds) in
    combined/coupled form.  (See the documentation for the function
    extract_fcst_obs_vals_from_cpld() for more details of this coupled form.)
    This function then writes the two separate (decoupled) vx configuration
    dictionaries (one for forecasts and the other for observations) to a file.

    Arguments:
    ---------
      vx_type:
        Type of verification for which the coupled dictionary to be read in
        applies.  This can be 'det' (for deterministic verification) or 'ens'
        (for ensemble verification).
      outfile_type:
        Type of the output file.  This can be 'txt' (for the output to be saved
        in a pretty-printed text file) or 'yaml' (for the output to be saved in
        a yaml-formatted file.  Here, the "output" consists of the two separate
        vx configuration files (one for forecasts and another for observations).
      outdir:
        The directory in which to save the output file.
      log_lvl:
        The logging level to use.
      log_fp:
        Path to the log file.  Default is an empty string, so that logging output
        is sent to stdout.

    Returns:
    -------
      None
    """

    # Set up logging.
    log_level = str.upper(log_lvl)
    log_level = str.upper('debug')
    FORMAT = "[%(levelname)s:%(name)s:  %(filename)s, line %(lineno)s: %(funcName)s()] %(message)s"
    if log_fp:
        logging.basicConfig(level=log_level, format=FORMAT, filename=log_fp, filemode='w')
    else:
        logging.basicConfig(level=log_level, format=FORMAT)
    logging.basicConfig(level=log_level)

    # Load the yaml file containing the coupled forecast-and-observations
    # verification (vx) configuration dictionary.
    metplus_conf_dir = Path(os.path.join(home_dir, 'parm', 'metplus')).resolve()
    config_fn = ''.join(['vx_config_', vx_type, '.yaml'])
    config_fp = Path(os.path.join(metplus_conf_dir, config_fn)).resolve()
    fgs_fields_levels_threshes_cpld = load_config_file(config_fp)

    msg = create_pprinted_msg(
          vars_dict = {'fgs_fields_levels_threshes_cpld': fgs_fields_levels_threshes_cpld},
          indent_str = ' '*0,
          add_nl_after_varname = True)
    logging.debug(msg)

    # Loop through the field groups in the coupled vx configuration dictionary
    # and generate two separate vx configuration dictionaries, one for forecasts
    # and another for observations.
    fgs_fields_levels_threshes_fcst = {}
    fgs_fields_levels_threshes_obs = {}
    indent_incr = 4
    indent_size = indent_incr
    indent_str = ' '*indent_size
    for field_group, fields_levels_threshes_cpld in fgs_fields_levels_threshes_cpld.items():

        msg = create_pprinted_msg(
              vars_dict = {'field_group': field_group},
              indent_str = indent_str)
        logging.debug(msg)

        # Loop over the field names associated with the current field group.
        #
        # Note that the following variables have to be lists of dictionaries
        # (where each dictionary contains only one key-value pair) instead of
        # dictionaries because the field names might be repeated and thus cannot
        # be used as dictionary keys.  For example, in the ADPSFC field group,
        # the forecast fields CRAIN, CSNOW, CFRZR, and CICEP all have the
        # corresponding observation field PRWE but with different thresholds,
        # so although fields_levels_threshes_fcst could be a dictionary with
        # CRAIN, CSNOW, CFRZR, and CICEP as keys, fields_levels_threshes_obs
        # cannot be a dictionary because the string PRWE cannot be used as a key
        # more than once.
        fields_levels_threshes_fcst = []
        fields_levels_threshes_obs = []
        indent_size += indent_incr
        indent_str = ' '*indent_size
        for field_cpld, levels_threshes_cpld in fields_levels_threshes_cpld.items():

            msg = create_pprinted_msg(
                  vars_dict = {'field_cpld': field_cpld},
                  indent_str = indent_str)
            logging.debug(msg)

            # Parse the current coupled field name to extract the forecast and
            # observation field names.
            field_fcst, field_obs = extract_fcst_obs_vals_from_cpld(field_cpld)

            msg = create_pprinted_msg(
                  vars_dict = {'field_fcst': field_fcst, 'field_obs': field_obs},
                  indent_str = indent_str)
            logging.debug(msg)

            # Loop over the levels associated with the current field.
            levels_threshes_fcst = {}
            levels_threshes_obs = {}
            indent_size += indent_incr
            indent_str = ' '*indent_size
            for level_cpld, threshes_cpld in levels_threshes_cpld.items():

                msg = create_pprinted_msg(
                      vars_dict = {'level_cpld': level_cpld},
                      indent_str = indent_str)
                logging.debug(msg)

                # Parse the current coupled level to extract the forecast and observation
                # levels.
                level_fcst, level_obs = extract_fcst_obs_vals_from_cpld(level_cpld)

                msg = create_pprinted_msg(
                      vars_dict = {'level_fcst': level_fcst, 'level_obs': level_obs},
                      indent_str = indent_str)
                logging.debug(msg)

                # Loop over the thresholds associated with the current level.
                threshes_fcst = []
                threshes_obs = []
                indent_size += indent_incr
                indent_str = ' '*indent_size
                for thresh_cpld in threshes_cpld:

                    msg = create_pprinted_msg(
                          vars_dict = {'thresh_cpld': thresh_cpld},
                          indent_str = indent_str)
                    logging.debug(msg)

                    # Parse the current coupled threshold to extract the forecast and
                    # observation thresholds.
                    thresh_fcst, thresh_obs = extract_fcst_obs_vals_from_cpld(thresh_cpld)

                    msg = create_pprinted_msg(
                          vars_dict = {'thresh_fcst': thresh_fcst, 'thresh_obs': thresh_obs},
                          indent_str = indent_str)
                    logging.debug(msg)

                    threshes_fcst.append(thresh_fcst)
                    threshes_obs.append(thresh_obs)

                indent_size -= indent_incr
                indent_str = ' '*indent_size
                msg = create_pprinted_msg(
                      vars_dict = {'threshes_fcst': threshes_fcst,
                                   'threshes_obs': threshes_obs},
                      indent_str = indent_str,
                      add_nl_after_varname = True)
                logging.debug(msg)

                levels_threshes_fcst[level_fcst] = threshes_fcst
                levels_threshes_obs[level_obs] = threshes_obs

            indent_size -= indent_incr
            indent_str = ' '*indent_size
            msg = create_pprinted_msg(
                  vars_dict = {'levels_threshes_fcst': levels_threshes_fcst,
                               'levels_threshes_obs': levels_threshes_obs},
                  indent_str = indent_str,
                  add_nl_after_varname = True)
            logging.debug(msg)

            fields_levels_threshes_fcst.append({field_fcst: levels_threshes_fcst})
            fields_levels_threshes_obs.append({field_obs: levels_threshes_obs})

        indent_size -= indent_incr
        indent_str = ' '*indent_size
        msg = create_pprinted_msg(
              vars_dict = {'fields_levels_threshes_fcst': fields_levels_threshes_fcst,
                           'fields_levels_threshes_obs': fields_levels_threshes_obs},
              indent_str = indent_str,
              add_nl_after_varname = True)
        logging.debug(msg)

        fgs_fields_levels_threshes_fcst[field_group] = fields_levels_threshes_fcst
        fgs_fields_levels_threshes_obs[field_group] = fields_levels_threshes_obs

    indent_size -= indent_incr
    indent_str = ' '*indent_size
    msg = create_pprinted_msg(
          vars_dict = {'fgs_fields_levels_threshes_fcst': fgs_fields_levels_threshes_fcst,
                       'fgs_fields_levels_threshes_obs': fgs_fields_levels_threshes_obs},
          indent_str = indent_str,
          add_nl_after_varname = True)
    logging.debug(msg)

    # We now have a verification configuration dictionary for forecasts and
    # a separate one for the observations.  To conveniently write these to a
    # file, first place (wrap) them in a higher-level dictionary.
    vx_config_dict = {'fcst': fgs_fields_levels_threshes_fcst,
                      'obs': fgs_fields_levels_threshes_obs}

    # Write the contents of the higher-level dictionary to file.
    output_fn = ''.join(['vx_config_', vx_type, '.', outfile_type])
    output_fp = Path(os.path.join(outdir, output_fn)).resolve()
    with open(f'{output_fp}', 'w') as fn:
        if outfile_type == 'txt':
            dict_to_str = get_pprint_str(vx_config_dict, '  ')
            fn.write(dict_to_str)
        elif outfile_type == 'yaml':
            yaml_vars = yaml.dump(vx_config_dict, fn)

    return None
#
# -----------------------------------------------------------------------
#
# Call the function defined above.
#
# -----------------------------------------------------------------------
#
if __name__ == "__main__":

    parser = argparse.ArgumentParser(
        description='Read in and process verification configuration file'
    )

    default_vx_type = 'det'
    parser.add_argument('--vx_type',
                        type=str,
                        required=True,
                        choices=['det', 'ens'],
                        default=default_vx_type,
                        help=dedent(f"""
                            String that determines whether to read in the deterministic or ensemble
                            verification configuration file.
                        """))

    default_outfile_type = 'txt'
    parser.add_argument('--outfile_type',
                        type=str,
                        required=True,
                        choices=['txt', 'yaml'],
                        default=default_outfile_type,
                        help=dedent(f"""
                            Type of output file.  The output consists of a high-level dictionary
                            containing two keys:  'fcst' and 'obs'.  The value of 'fcst' is the vx
                            configuration dictionary for forecasts, and the value of 'obs' is the vx
                            dictionary for observations.  If outfile_type is set to 'txt', this high-
                            level dictionary is saved to a text file in a form that can be read in by
                            the SRW App's ex-scripts for the verification tasks.  In particular, this
                            form contains the curly braces and brackets that define dictionaries and
                            lists in python code (but that would normally not appear in a yaml file).
                            If outfile_type is set to 'yaml', then the high-level dictionary is saved
                            to a yaml-formatted file.
                            """))

    parser.add_argument('--outdir',
                        type=str,
                        required=False,
                        default='./',
                        help=dedent(f"""
                            Directory in which to place the output file containing the decoupled
                            (i.e. with forecast and observation information placed in separate data
                            structures) verifcation configuration information.
                            """))

    args = parser.parse_args()

    decouple_fcst_obs_vx_config(vx_type=args.vx_type, outfile_type=args.outfile_type, outdir=args.outdir)

