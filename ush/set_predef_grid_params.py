#!/usr/bin/env python3

import unittest
import os
from textwrap import dedent

from python_utils import (
    load_config_file,
    flatten_dict,
)


def set_predef_grid_params(
    PREDEF_GRID_NAME,
    QUILTING,
    DT_ATMOS,
    LAYOUT_X,
    LAYOUT_Y,
    BLOCKSIZE,
):
    """Sets grid parameters for the specified predfined grid

    Args:
        PREDEF_GRID_NAME,
        QUILTING,
        DT_ATMOS,
        LAYOUT_X,
        LAYOUT_Y,
        BLOCKSIZE,
    Returns:
        Dictionary of grid parameters
    """

    USHdir = os.path.dirname(os.path.abspath(__file__))
    params_dict = load_config_file(os.path.join(USHdir, "predef_grid_params.yaml"))
    try:
        params_dict = params_dict[PREDEF_GRID_NAME]
    except KeyError:
        errmsg = dedent(
            f"""
            PREDEF_GRID_NAME = {PREDEF_GRID_NAME} not found in predef_grid_params.yaml
            Check your config file settings."""
        )
        raise Exception(errmsg) from None

    # if QUILTING = False, remove key
    if not QUILTING:
        params_dict.pop("QUILTING")
    else:
        params_dict = flatten_dict(params_dict)

    # take care of special vars
    if DT_ATMOS is not None:
        params_dict["DT_ATMOS"] = DT_ATMOS
    if LAYOUT_X is not None:
        params_dict["LAYOUT_X"] = LAYOUT_X
    if LAYOUT_Y is not None:
        params_dict["LAYOUT_Y"] = LAYOUT_Y
    if BLOCKSIZE is not None:
        params_dict["BLOCKSIZE"] = BLOCKSIZE

    return params_dict


class Testing(unittest.TestCase):
    def test_set_predef_grid_params(self):
        params_dict = set_predef_grid_params(
            PREDEF_GRID_NAME="RRFS_CONUS_3km",
            QUILTING=False,
            DT_ATMOS=36,
            LAYOUT_X=18,
            LAYOUT_Y=36,
            BLOCKSIZE=28,
        )
        self.assertEqual(params_dict["GRID_GEN_METHOD"], "ESGgrid")
        self.assertEqual(params_dict["ESGgrid_LON_CTR"], -97.5)
        params_dict = set_predef_grid_params(
            PREDEF_GRID_NAME="RRFS_CONUS_3km",
            QUILTING=True,
            DT_ATMOS=36,
            LAYOUT_X=18,
            LAYOUT_Y=36,
            BLOCKSIZE=28,
        )
        self.assertEqual(params_dict["WRTCMP_nx"], 1799)
