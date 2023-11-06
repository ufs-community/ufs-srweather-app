#!/usr/bin/env python3

import unittest
import os
from textwrap import dedent

from python_utils import (
    load_config_file,
    flatten_dict,
)


def set_predef_grid_params(USHdir, grid_name, quilting):
    """Sets grid parameters for the specified predefined grid

    Args:
        USHdir:      path to the SRW ush directory
        grid_name    str specifying the predefined grid name.
        quilting:    bool whether quilting should be used for output
    Returns:
        Dictionary of grid parameters
    """

    params_dict = load_config_file(os.path.join(USHdir, "predef_grid_params.yaml"))
    try:
        params_dict = params_dict[grid_name]
    except KeyError:
        errmsg = dedent(
            f"""
            PREDEF_GRID_NAME = {predef_grid_name} not found in predef_grid_params.yaml
            Check your config file settings."""
        )
        raise Exception(errmsg) from None

    # We don't need the quilting section if user wants it turned off
    if not quilting:
        params_dict.pop("QUILTING")
    else:
        params_dict = flatten_dict(params_dict)

    return params_dict


class Testing(unittest.TestCase):
    def test_set_predef_grid_params(self):
        ushdir = os.path.dirname(os.path.abspath(__file__))
        fcst_config = dict(
            PREDEF_GRID_NAME="RRFS_CONUS_3km",
            QUILTING=False,
            DT_ATMOS=36,
            LAYOUT_X=18,
            LAYOUT_Y=36,
            BLOCKSIZE=28,
        )
        params_dict = set_predef_grid_params(
            ushdir,
            fcst_config["PREDEF_GRID_NAME"],
            fcst_config["QUILTING"],
        )
        self.assertEqual(params_dict["GRID_GEN_METHOD"], "ESGgrid")
        self.assertEqual(params_dict["ESGgrid_LON_CTR"], -97.5)
        fcst_config = dict(
            PREDEF_GRID_NAME="RRFS_CONUS_3km",
            QUILTING=True,
            DT_ATMOS=36,
            LAYOUT_X=18,
            LAYOUT_Y=36,
            BLOCKSIZE=28,
        )
        params_dict = set_predef_grid_params(
            ushdir,
            fcst_config["PREDEF_GRID_NAME"],
            fcst_config["QUILTING"],
        )
        self.assertEqual(params_dict["WRTCMP_nx"], 1799)
