#!/usr/bin/env python3

import os
from textwrap import dedent

from python_utils import (
    load_config_file,
    flatten_dict,
)


def set_predef_grid_params(USHdir, grid_name, quilting):
    """Sets grid parameters for the specified predefined grid

    Args:
        USHdir       (str) : Path to the SRW App ``ush`` directory
        grid_name    (str) : String specifying the predefined grid name
        quilting     (bool): Whether quilting should be used for output
    Returns:
        params_dict: A dictionary of grid parameters
    Raises: 
        KeyError: If a selected predefined grid is not found in ``predef_grid_params.yaml``.
    """

    params_dict = load_config_file(os.path.join(USHdir, "predef_grid_params.yaml"))
    try:
        params_dict = params_dict[grid_name]
    except KeyError:
        errmsg = dedent(
            f"""
            PREDEF_GRID_NAME = {grid_name} not found in predef_grid_params.yaml
            Check your config file settings."""
        )
        raise Exception(errmsg) from None

    # We don't need the quilting section if user wants it turned off
    if not quilting:
        params_dict.pop("QUILTING")
    else:
        params_dict = flatten_dict(params_dict)

    return params_dict
