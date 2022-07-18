#!/usr/bin/env python3

import unittest
import os

from python_utils import process_args,import_vars,export_vars,set_env_var,get_env_var,\
                         print_input_args,define_macos_utilities, load_config_file, \
                         cfg_to_yaml_str

def set_predef_grid_params():
    """ Sets grid parameters for the specified predfined grid 

    Args:
        None
    Returns:
        None
    """
    # import all environement variables
    IMPORTS = ['PREDEF_GRID_NAME', 'QUILTING', 'DT_ATMOS', 'LAYOUT_X', 'LAYOUT_Y', 'BLOCKSIZE']
    import_vars(env_vars=IMPORTS)

    USHDIR = os.path.dirname(os.path.abspath(__file__))
    params_dict = load_config_file(os.path.join(USHDIR,"predef_grid_params.yaml"))
    params_dict = params_dict[PREDEF_GRID_NAME]

    # if QUILTING = False, skip variables that start with "WRTCMP_"
    if not QUILTING:
        params_dict = {k: v for k,v in params_dict.items() \
                            if not k.startswith("WRTCMP_") }

    # take care of special vars
    special_vars = ['DT_ATMOS', 'LAYOUT_X', 'LAYOUT_Y', 'BLOCKSIZE']
    for var in special_vars:
        if globals()[var] is not None:
            params_dict[var] = globals()[var]

    # export variables to environment
    export_vars(source_dict=params_dict)
   
    return params_dict

if __name__ == "__main__":
    params_dict = set_predef_grid_params()
    print( cfg_to_shell_str(params_dict), end='' )

class Testing(unittest.TestCase):
    def test_set_predef_grid_params(self):
        set_predef_grid_params()
        self.assertEqual(get_env_var('GRID_GEN_METHOD'),"ESGgrid")
        self.assertEqual(get_env_var('ESGgrid_LON_CTR'),-97.5)

    def setUp(self):
        define_macos_utilities();
        set_env_var('DEBUG',False)
        set_env_var('PREDEF_GRID_NAME',"RRFS_CONUS_3km")
        set_env_var('DT_ATMOS',36)
        set_env_var('LAYOUT_X',18)
        set_env_var('LAYOUT_Y',36)
        set_env_var('BLOCKSIZE',28)
        set_env_var('QUILTING',False)

