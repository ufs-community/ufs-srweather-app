#!/usr/bin/env python3

import unittest
import os
from textwrap import dedent

from python_utils import (
    import_vars,
    export_vars,
    set_env_var,
    get_env_var,
    print_input_args,
    define_macos_utilities,
    load_config_file,
    cfg_to_yaml_str,
    flatten_dict,
)


def set_predef_grid_params(USHdir, fcst_config):
    """Sets grid parameters for the specified predfined grid

    Args:
        None
    Returns:
        None
    """
    predef_grid_name = fcst_config['PREDEF_GRID_NAME']
    quilting = fcst_config['QUILTING']

    params_dict = load_config_file(os.path.join(USHdir, "predef_grid_params.yaml"))
    try:
        params_dict = params_dict[predef_grid_name]
    except KeyError:
        errmsg = dedent(f'''
                        PREDEF_GRID_NAME = {predef_grid_name} not found in predef_grid_params.yaml
                        Check your config file settings.''')
        raise Exception(errmsg) from None

    # We don't need the quilting section if user wants it turned off
    if not quilting:
        params_dict.pop("QUILTING")
    else:
        params_dict = flatten_dict(params_dict)

    return params_dict


if __name__ == "__main__":
    params_dict = set_predef_grid_params()
    print(cfg_to_shell_str(params_dict), end="")


class Testing(unittest.TestCase):
    def test_set_predef_grid_params(self):
        set_predef_grid_params()
        self.assertEqual(get_env_var("GRID_GEN_METHOD"), "ESGgrid")
        self.assertEqual(get_env_var("ESGgrid_LON_CTR"), -97.5)
        set_env_var("QUILTING", True)
        set_predef_grid_params()
        self.assertEqual(get_env_var("WRTCMP_nx"), 1799)

    def setUp(self):
        define_macos_utilities()
        set_env_var("DEBUG", False)
        set_env_var("PREDEF_GRID_NAME", "RRFS_CONUS_3km")
        set_env_var("DT_ATMOS", 36)
        set_env_var("LAYOUT_X", 18)
        set_env_var("LAYOUT_Y", 36)
        set_env_var("BLOCKSIZE", 28)
        set_env_var("QUILTING", False)
