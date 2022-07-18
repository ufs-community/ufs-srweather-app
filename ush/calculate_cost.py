#!/usr/bin/env python3

import os
import unittest
import argparse

from python_utils import set_env_var, import_vars, export_vars, load_config_file, flatten_dict

from set_predef_grid_params import set_predef_grid_params
from set_gridparams_ESGgrid import set_gridparams_ESGgrid
from set_gridparams_GFDLgrid import set_gridparams_GFDLgrid

def calculate_cost(config_fn):
    global PREDEF_GRID_NAME, QUILTING, GRID_GEN_METHOD

    #import all environment variables
    import_vars()

    #get grid config parameters (predefined or custom)
    if PREDEF_GRID_NAME:
        set_env_var('QUILTING',False)
        set_predef_grid_params()
        import_vars()
    else:
        cfg_u = load_config_file(config_fn)
        cfg_u = flatten_dict(cfg_u)
        import_vars(dictionary=cfg_u)
      
    #number of gridpoints (nx*ny) depends on grid generation method
    if GRID_GEN_METHOD == "GFDLgrid":
      (\
      LON_CTR,LAT_CTR,NX,NY,NHW,STRETCH_FAC,
      ISTART_OF_RGNL_DOM_WITH_WIDE_HALO_ON_T6SG,
      IEND_OF_RGNL_DOM_WITH_WIDE_HALO_ON_T6SG,
      JSTART_OF_RGNL_DOM_WITH_WIDE_HALO_ON_T6SG,
      JEND_OF_RGNL_DOM_WITH_WIDE_HALO_ON_T6SG \
      ) = \
        set_gridparams_GFDLgrid( \
        lon_of_t6_ctr=GFDLgrid_LON_T6_CTR, \
        lat_of_t6_ctr=GFDLgrid_LAT_T6_CTR, \
        res_of_t6g=GFDLgrid_NUM_CELLS, \
        stretch_factor=GFDLgrid_STRETCH_FAC, \
        refine_ratio_t6g_to_t7g=GFDLgrid_REFINE_RATIO, \
        istart_of_t7_on_t6g=GFDLgrid_ISTART_OF_RGNL_DOM_ON_T6G, \
        iend_of_t7_on_t6g=GFDLgrid_IEND_OF_RGNL_DOM_ON_T6G, \
        jstart_of_t7_on_t6g=GFDLgrid_JSTART_OF_RGNL_DOM_ON_T6G, \
        jend_of_t7_on_t6g=GFDLgrid_JEND_OF_RGNL_DOM_ON_T6G)

    elif GRID_GEN_METHOD == "ESGgrid":
      (\
      LON_CTR,LAT_CTR,NX,NY,PAZI,
      NHW,STRETCH_FAC,DEL_ANGLE_X_SG,DEL_ANGLE_Y_SG,
      NEG_NX_OF_DOM_WITH_WIDE_HALO,
      NEG_NY_OF_DOM_WITH_WIDE_HALO \
      ) = \
        set_gridparams_ESGgrid( \
        lon_ctr=ESGgrid_LON_CTR, \
        lat_ctr=ESGgrid_LAT_CTR, \
        nx=ESGgrid_NX, \
        ny=ESGgrid_NY, \
        pazi=ESGgrid_PAZI, \
        halo_width=ESGgrid_WIDE_HALO_WIDTH, \
        delx=ESGgrid_DELX, \
        dely=ESGgrid_DELY)

    cost = [DT_ATMOS, NX*NY]

    #reference grid (6-hour forecast on RRFS_CONUS_25km)
    PREDEF_GRID_NAME="RRFS_CONUS_25km"

    export_vars()
    set_predef_grid_params()
    import_vars()
    cost.extend([DT_ATMOS, ESGgrid_NX*ESGgrid_NY])
    
    return cost

#interface
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=\
             'Calculates parameters needed for calculating cost.')
    parser.add_argument('--cfg','-c',dest='cfg',required=True,
             help='config file containing grip params')
    args = parser.parse_args()

    params = calculate_cost(args.cfg)
    print(' '.join(map(str,params)))

class Testing(unittest.TestCase):
    def test_calculate_cost(self):
        USHDIR = os.path.dirname(os.path.abspath(__file__))
        config_fn = os.path.join(USHDIR, "config.community.sh")
        params = calculate_cost(config_fn)
        self.assertCountEqual(params, [36, 1987440, 36, 28689])

    def setUp(self):
        set_env_var('DEBUG',False)
        set_env_var('PREDEF_GRID_NAME',"RRFS_CONUS_3km")
        set_env_var('DT_ATMOS',36)
        set_env_var('LAYOUT_X',18)
        set_env_var('LAYOUT_Y',36)
        set_env_var('BLOCKSIZE',28)
        set_env_var('QUILTING',False)
        set_env_var('RADIUS_EARTH',6371200.0)
        set_env_var('DEGS_PER_RADIAN',57.2957795131)

