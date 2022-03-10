#!/usr/bin/env python3

import os
import configparser

from .print_msg import print_err_msg_exit

def get_manage_externals_config_property(externals_cfg_fp, external_name, property_name):
    """
    This function searches a specified manage_externals configuration file
    and extracts from it the value of the specified property of the external
    with the specified name (e.g. the relative path in which the external
    has been/will be cloned by the manage_externals utility).
    
    Args:
    
      externals_cfg_fp:
         The absolute or relative path to the manage_externals configuration
         file that will be searched.
    
      external_name:
         The name of the external to search for in the manage_externals confi-
         guration file specified by externals_cfg_fp.
    
      property_name:
         The name of the property whose value to obtain (for the external spe-
         cified by external_name).
    
    Returns:
        The property value
    """

    if not os.path.exists(externals_cfg_fp):
        print_err_msg_exit(f'''
            The specified manage_externals configuration file (externals_cfg_fp) 
            does not exist:
              externals_cfg_fp = \"{externals_cfg_fp}\"''')
    
    config = configparser.ConfigParser()
    config.read(externals_cfg_fp)

    if not external_name in config.sections():
        print_err_msg_exit(f'''
            In the specified manage_externals configuration file (externals_cfg_fp), 
            the specified property (property_name) was not found for the the speci-
            fied external (external_name): 
              externals_cfg_fp = \"{externals_cfg_fp}\"
              external_name = \"{external_name}\"
              property_name = \"{property_name}\"''')
    else:
        return config[external_name][property_name]

    return None

