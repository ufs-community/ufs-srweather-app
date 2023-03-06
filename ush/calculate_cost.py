#!/usr/bin/env python3

import os
import unittest
import argparse

from python_utils import (
    set_env_var,
    load_config_file,
    flatten_dict,
)

from set_predef_grid_params import set_predef_grid_params
from set_gridparams_ESGgrid import set_gridparams_ESGgrid
from set_gridparams_GFDLgrid import set_gridparams_GFDLgrid


def calculate_cost(config_fn):
    ushdir = os.path.dirname(os.path.abspath(__file__))

    cfg_u = load_config_file(config_fn)
    cfg_u = flatten_dict(cfg_u)

    if 'PREDEF_GRID_NAME' in cfg_u:
        params_dict = set_predef_grid_params(
            USHdir=ushdir,
            grid_name=cfg_u['PREDEF_GRID_NAME'],
            quilting=True
        )

        # merge cfg_u with defaults, duplicate keys in cfg_u will overwrite defaults
        cfg = {**params_dict, **cfg_u}
    else:
        cfg = cfg_u

    # number of gridpoints (nx*ny) depends on grid generation method
    if cfg['GRID_GEN_METHOD'] == "GFDLgrid":
        grid_params = set_gridparams_GFDLgrid(
            lon_of_t6_ctr=cfg['GFDLgrid_LON_T6_CTR'],
            lat_of_t6_ctr=cfg['GFDLgrid_LAT_T6_CTR'],
            res_of_t6g=cfg['GFDLgrid_NUM_CELLS'],
            stretch_factor=cfg['GFDLgrid_STRETCH_FAC'],
            refine_ratio_t6g_to_t7g=cfg['GFDLgrid_REFINE_RATIO'],
            istart_of_t7_on_t6g=cfg['GFDLgrid_ISTART_OF_RGNL_DOM_ON_T6G'],
            iend_of_t7_on_t6g=cfg['GFDLgrid_IEND_OF_RGNL_DOM_ON_T6G'],
            jstart_of_t7_on_t6g=cfg['GFDLgrid_JSTART_OF_RGNL_DOM_ON_T6G'],
            jend_of_t7_on_t6g=cfg['GFDLgrid_JEND_OF_RGNL_DOM_ON_T6G'],
            run_envir="community",
            verbose=False,
            nh4=4,
        )

    elif cfg['GRID_GEN_METHOD'] == "ESGgrid":
        constants = load_config_file(os.path.join(ushdir, "constants.yaml"))
        grid_params = set_gridparams_ESGgrid(
            lon_ctr=cfg['ESGgrid_LON_CTR'],
            lat_ctr=cfg['ESGgrid_LAT_CTR'],
            nx=cfg['ESGgrid_NX'],
            ny=cfg['ESGgrid_NY'],
            pazi=cfg['ESGgrid_PAZI'],
            halo_width=cfg['ESGgrid_WIDE_HALO_WIDTH'],
            delx=cfg['ESGgrid_DELX'],
            dely=cfg['ESGgrid_DELY'],
            constants=constants["constants"],
        )
    else:
        raise ValueError("GRID_GEN_METHOD is set to an invalid value")

    cost = [cfg['DT_ATMOS'], grid_params["NX"] * grid_params["NY"] ]

    # reference grid (6-hour forecast on RRFS_CONUS_25km)
    PREDEF_GRID_NAME = "RRFS_CONUS_25km"

    refgrid = set_predef_grid_params(
        USHdir=ushdir,
        grid_name=PREDEF_GRID_NAME,
        quilting=True,
    )

    cost.extend([refgrid['DT_ATMOS'], refgrid['ESGgrid_NX'] * refgrid['ESGgrid_NY']])

    return cost


# interface
if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Calculates parameters needed for calculating cost."
    )
    parser.add_argument(
        "--cfg",
        "-c",
        dest="cfg",
        required=True,
        help="config file containing grid params",
    )
    args = parser.parse_args()

    params = calculate_cost(args.cfg)
    print(" ".join(map(str, params)))


class Testing(unittest.TestCase):
    def test_calculate_cost(self):
        USHdir = os.path.dirname(os.path.abspath(__file__))
        params = calculate_cost(None)
        self.assertCountEqual(params, [36, 1987440, 36, 28689])

    def setUp(self):
        set_env_var("DEBUG", False)
        set_env_var("VERBOSE", False)
        set_env_var("PREDEF_GRID_NAME", "RRFS_CONUS_3km")
        set_env_var("DT_ATMOS", 36)
        set_env_var("LAYOUT_X", 18)
        set_env_var("LAYOUT_Y", 36)
        set_env_var("BLOCKSIZE", 28)
        set_env_var("QUILTING", False)
        set_env_var("RUN_ENVIR", "community")
