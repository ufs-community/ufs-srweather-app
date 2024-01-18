#!/usr/bin/env python3

import os
import sys
import glob
import argparse
import yaml

import logging
import textwrap
from textwrap import dedent

import pprint
import subprocess

#from plot_vx_metviewer import plot_vx_metviewer
#from plot_vx_metviewer import get_pprint_str

from pathlib import Path
file = Path(__file__).resolve()
print(f"file = {file}")
home_dir = file.parents[2]
print(f"home_dir = {home_dir}")
ush_dir = Path(os.path.join(home_dir, 'ush')).resolve()
print(f"ush_dir = {ush_dir}")
sys.path.append(str(ush_dir))

from python_utils import (
    log_info,
    load_config_file,
)


def get_pprint_str(x, indent_str):
    """Format a variable as a pretty-printed string and add indentation.

    Arguments:
      x:           A variable.
      indent_str:  String to be added to the beginning of each line of the
                   pretty-printed form of x.

    Return:
      x_str:       Formatted string containing contents of variable.
    """

    x_str = pprint.pformat(x, compact=True, sort_dicts=False)
    x_str = x_str.splitlines(True)
    x_str = [indent_str + s for s in x_str]
    x_str = ''.join(x_str)

    return x_str

#def separate_fcst_obs_info(field_group):
def separate_fcst_obs_info(det_or_ens):
    """
    This macro extracts from the input dictionary fields_levels_threshes that
    contains information on field names, levels, and thresholds for both the
    forecasts and observations into two dictionaries, one containing this 
    information for the forecasts and another for the observations.  It then
    prints out one of these two resultig dictionaries as a "return" value. 
    (It would be nice to return both, but that requires more complicated 
    code in the calling routine.)

    Arguments:
      args:  
    """

    # Set up logging.
    # If the name/path of a log file has been specified in the command line arguments,
    # place the logging output in it (existing log files of the same name are overwritten).
    # Otherwise, direct the output to the screen.
    log_level = str.upper('debug')
    #FORMAT = "[%(levelname)s:%(name)s:  %(filename)s, line %(lineno)s: %(funcName)s()] %(message)s"
    #if args.log_fp:
    #    logging.basicConfig(level=log_level, format=FORMAT, filename=args.log_fp, filemode='w')
    #else:
    #    logging.basicConfig(level=log_level, format=FORMAT)

    metplus_conf_dir = Path(os.path.join(home_dir, 'parm', 'metplus')).resolve()
    print(f'==>> metplus_conf_dir = {metplus_conf_dir}')
    config_fn = ''.join(['vx_config_', det_or_ens, '.yaml'])
    config_fp = Path(os.path.join(metplus_conf_dir, config_fn)).resolve()
    config_dict = load_config_file(config_fp)

    #logging.debug(f"""\nconfig_dict =\n{get_pprint_str(config_dict, '  ')}\n""")
    print(f"""\nconfig_dict =\n{get_pprint_str(config_dict, '  ')}\n""")
    #print(f'config_dict = {config_dict}')
    #laskjdfl

    #print(f'field_group = {field_group}')
    #fields_levels_threshes_both = config_dict[field_group]
    fgs_fields_levels_threshes_both = config_dict

    # Set the character that, in the various strings representing a field,
    # level, or threshold, separates the forecast value from the observation
    # value.
    sep_char = '|'

    # Separate the information in the given field name, levels, and thresholds  
    # dictionary into a fields-and-levels-and-thresholds dictionary for forecasts
    # and another one for thresholds.

    # The following have to be lists of dictionaries instead of dictionaries
    # of dictionaries because the field names could be identical and thus 
    # cannot be used as dictionary keys at the top level.
    #fgs_fields_levels_threshes_fcst = []
    #fgs_fields_levels_threshes_obs = []
    fgs_fields_levels_threshes_fcst = {}
    fgs_fields_levels_threshes_obs = {}
    for field_group, fields_levels_threshes_both in fgs_fields_levels_threshes_both.items():

        # Loop over the field names associated with the current field group.
        #fields_levels_threshes_fcst = {}
        #fields_levels_threshes_obs = {}
        fields_levels_threshes_fcst = []
        fields_levels_threshes_obs = []
        for field_both, levels_threshes_both in fields_levels_threshes_both.items():
    
            # Parse the current field name to extract the forecast field name and the
            # observation field name.
            tmp = field_both.split('|')
            num_sep_chars = len(tmp) - 1
            field_fcst = tmp[0].strip()
            if num_sep_chars == 0:
                field_obs = field_fcst
            elif num_sep_chars == 1:
                field_obs = tmp[1].strip()
            else:
                error_msg
    
            print(f'        field_fcst = {field_fcst}')
            print(f'        field_obs = {field_obs}')
    
            # Loop over the levels associated with the current field.
            levels_threshes_fcst = {}
            levels_threshes_obs = {}
            for level_both, threshes_both in levels_threshes_both.items():
    
                # Parse the current level to extract the forecast level and the observation
                # level.
                tmp = level_both.split('|')
                num_sep_chars = len(tmp) - 1
                level_fcst = tmp[0].strip()
                if num_sep_chars == 0:
                    level_obs = level_fcst
                elif num_sep_chars == 1:
                    level_obs = tmp[1].strip()
                else:
                    error_msg
    
                # Loop over the thresholds associated with the current level.
                threshes_fcst = []
                threshes_obs = []
                for thresh_both in threshes_both:
    
                    # Parse the current threshold to extract the forecast threshold and the
                    # observation threshold.
                    tmp = thresh_both.split('|')
                    num_sep_chars = len(tmp) - 1
                    thresh_fcst = tmp[0].strip()
                    if num_sep_chars == 0:
                        thresh_obs = thresh_fcst
                    elif num_sep_chars == 1:
                        thresh_obs = tmp[1].strip()
                    else:
                        error_msg
    
                    # Append the current forecast threshold to the list of forecast thresholds
                    # corresponding to the current field and level.  Then do the same for the
                    # observations.
                    threshes_fcst.append(thresh_fcst)
                    threshes_obs.append(thresh_obs)
    
                print(f'            threshes_fcst = {threshes_fcst}')
                print(f'            threshes_obs = {threshes_obs}')
    
                # Set the key-value pair consisting of the current forecast level (the key)
                # and corresponding list of forecast thresholds (the value) in the levels-
                # and-thresholds forecast dictionary of the current field.  Then do the
                # same for the observations.
                levels_threshes_fcst[level_fcst] = threshes_fcst
                levels_threshes_obs[level_obs] = threshes_obs
    
            print(f'        levels_threshes_fcst = {levels_threshes_fcst}')
            print(f'        levels_threshes_obs = {levels_threshes_obs}')
    
            # Set the key-value pair consisting of the current forecast field name (the
            # key) and corresponding forecast levels-and-thresholds forecast dictionary
            # (the value) in the fields-and-levels-and-thresholds forecast dictionary.
            # Then do the same for the observations.
            #fields_levels_threshes_fcst[field_fcst] = levels_threshes_fcst
            #fields_levels_threshes_obs[field_obs] = levels_threshes_obs
            fields_levels_threshes_fcst.append({field_fcst: levels_threshes_fcst})
            fields_levels_threshes_obs.append({field_obs: levels_threshes_obs})
    
        print(f'    fields_levels_threshes_fcst = {fields_levels_threshes_fcst}')
        print(f'    fields_levels_threshes_obs = {fields_levels_threshes_obs}')

        # Set the key-value pair consisting of the current ...
        # Then do the same for the observations.
        #fgs_fields_levels_threshes_fcst.append(fields_levels_threshes_fcst)
        #fgs_fields_levels_threshes_obs.append(fields_levels_threshes_obs)
        fgs_fields_levels_threshes_fcst[field_group] = fields_levels_threshes_fcst
        fgs_fields_levels_threshes_obs[field_group] = fields_levels_threshes_obs

    print(f'')
    print(f"""\nfgs_fields_levels_threshes_fcst =\n{get_pprint_str(fgs_fields_levels_threshes_fcst, '  ')}\n""")
    print(f'')
    print(f"""\nfgs_fields_levels_threshes_obs =\n{get_pprint_str(fgs_fields_levels_threshes_obs, '  ')}\n""")

    # Combine forecast and obs verfication dictionaries into one and
    # write to a yaml file.
    vx_config_dict = {'fcst': fgs_fields_levels_threshes_fcst,
                      'obs': fgs_fields_levels_threshes_obs}
    dict_to_str = get_pprint_str(vx_config_dict, '  ')
    # Convert the dictionary of jinja variable settings above to yaml format
    # and write it to a temporary yaml file for reading by the set_template
    # function.
    filename = ''.join(['tmp.vx_config_', det_or_ens, '_dict.split_fcst_obs.txt'])
    filepath = Path(os.path.join(metplus_conf_dir, filename)).resolve()
    print(f'==>> filepath = {filepath}')
    with open(f'{filepath}', 'w') as fn:
        #yaml_vars = yaml.dump(vx_config_dict, fn)
        #pprint.pformat(vx_config_dict, fn, sort_dicts=False)
        fn.write(dict_to_str)

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

    parser.add_argument('--det_or_ens',
                        type=str,
                        required=True, default='det',
                        help=dedent(f'''String that determines whether to read in the deterministic
                                        or ensemble verification configuration file.'''))

    args = parser.parse_args()

    separate_fcst_obs_info(det_or_ens=args.det_or_ens)


