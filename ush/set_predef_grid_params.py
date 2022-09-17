#!/usr/bin/env python3

import unittest
import os

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


def set_predef_grid_params():
    """Sets grid parameters for the specified predfined grid

    Args:
        None
    Returns:
        None
    """
    # import all environement variables
    IMPORTS = [
        "PREDEF_GRID_NAME",
        "QUILTING",
        "DT_ATMOS",
        "LAYOUT_X",
        "LAYOUT_Y",
        "BLOCKSIZE",
    ]
    import_vars(env_vars=IMPORTS)

    USHdir = os.path.dirname(os.path.abspath(__file__))
    params_dict = load_config_file(os.path.join(USHdir, "predef_grid_params.yaml"))
    params_dict = params_dict[PREDEF_GRID_NAME]

    # if QUILTING = False, remove key
    if not QUILTING:
        params_dict.pop("QUILTING")
    else:
        params_dict = flatten_dict(params_dict)

    # take care of special vars
    special_vars = ["DT_ATMOS", "LAYOUT_X", "LAYOUT_Y", "BLOCKSIZE"]
    for var in special_vars:
        if globals()[var] is not None:
            params_dict[var] = globals()[var]

    # export variables to environment
    export_vars(source_dict=params_dict)

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
