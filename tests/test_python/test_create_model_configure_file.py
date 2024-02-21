""" Tests for create_model_configure_file.py"""

#pylint: disable=invalid-name
from datetime import datetime
import os
import unittest

from python_utils import set_env_var

from create_model_configure_file import create_model_configure_file


class Testing(unittest.TestCase):
    """ Define tests"""

    def test_create_model_configure_file(self):
        """ Test that the function returns True when configured with
        valid input data. """
        path = os.path.join(os.getenv("USHdir"), "test_data")
        self.assertTrue(
            create_model_configure_file(
                run_dir=path,
                cdate=datetime(2021, 1, 1),
                fcst_len_hrs=72,
                fhrot=0,
                sub_hourly_post=True,
                dt_subhourly_post_mnts=4,
                dt_atmos=1,
            )
        )

    def setUp(self):
        test_dir = os.path.dirname(os.path.abspath(__file__))
        USHdir = os.path.join(test_dir, "..", "..", "ush")
        PARMdir = os.path.join(USHdir, "..", "parm")
        MODEL_CONFIG_FN = "model_configure"
        MODEL_CONFIG_TMPL_FP = os.path.join(PARMdir, MODEL_CONFIG_FN)

        set_env_var("DEBUG", True)
        set_env_var("VERBOSE", True)
        set_env_var("QUILTING", True)
        set_env_var("WRITE_DOPOST", True)
        set_env_var("USHdir", USHdir)
        set_env_var("MODEL_CONFIG_FN", MODEL_CONFIG_FN)
        set_env_var("MODEL_CONFIG_TMPL_FP", MODEL_CONFIG_TMPL_FP)
        set_env_var("FCST_LEN_HRS", 72)
        set_env_var("FHROT", 0)
        set_env_var("DT_ATMOS", 1)
        set_env_var("RESTART_INTERVAL", 4)
        set_env_var("ITASKS", 1)

        set_env_var("WRTCMP_write_groups", 1)
        set_env_var("WRTCMP_write_tasks_per_group", 2)
        set_env_var("WRTCMP_output_grid", "lambert_conformal")
        set_env_var("WRTCMP_cen_lon", -97.5)
        set_env_var("WRTCMP_cen_lat", 35.0)
        set_env_var("WRTCMP_stdlat1", 35.0)
        set_env_var("WRTCMP_stdlat2", 35.0)
        set_env_var("WRTCMP_nx", 199)
        set_env_var("WRTCMP_ny", 111)
        set_env_var("WRTCMP_lon_lwr_left", -121.23349066)
        set_env_var("WRTCMP_lat_lwr_left", 23.41731593)
        set_env_var("WRTCMP_dx", 3000.0)
        set_env_var("WRTCMP_dy", 3000.0)
