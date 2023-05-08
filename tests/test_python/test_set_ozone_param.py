""" Tests for set_ozone_param.py """

#pylint: disable=invalid-name

import os
import unittest

from set_ozone_param import set_ozone_param

class Testing(unittest.TestCase):
    """ Define the tests """
    def test_set_ozone_param(self):
        """ Test that when the CCPP phyiscs suite XML is provided that
        activates ozone, the expected ozone parameter is returned"""
        test_dir = os.path.dirname(os.path.abspath(__file__))
        USHdir = os.path.join(test_dir, "..", "..", "ush")
        ozone_param, _, _ = set_ozone_param(
            os.path.join(USHdir, "test_data", "suite_FV3_GSD_SAR.xml"),
            self.CYCLEDIR_LINKS_TO_FIXam_FILES_MAPPING,
        )
        self.assertEqual("ozphys_2015", ozone_param)

    def setUp(self):
        self.CYCLEDIR_LINKS_TO_FIXam_FILES_MAPPING = [
            "aerosol.dat                | global_climaeropac_global.txt",
            "co2historicaldata_2010.txt | fix_co2_proj/global_co2historicaldata_2010.txt",
            "co2historicaldata_2011.txt | fix_co2_proj/global_co2historicaldata_2011.txt",
            "co2historicaldata_2012.txt | fix_co2_proj/global_co2historicaldata_2012.txt",
            "co2historicaldata_2013.txt | fix_co2_proj/global_co2historicaldata_2013.txt",
            "co2historicaldata_2014.txt | fix_co2_proj/global_co2historicaldata_2014.txt",
            "co2historicaldata_2015.txt | fix_co2_proj/global_co2historicaldata_2015.txt",
            "co2historicaldata_2016.txt | fix_co2_proj/global_co2historicaldata_2016.txt",
            "co2historicaldata_2017.txt | fix_co2_proj/global_co2historicaldata_2017.txt",
            "co2historicaldata_2018.txt | fix_co2_proj/global_co2historicaldata_2018.txt",
            "co2historicaldata_2019.txt | fix_co2_proj/global_co2historicaldata_2019.txt",
            "co2historicaldata_2020.txt | fix_co2_proj/global_co2historicaldata_2020.txt",
            "co2historicaldata_2021.txt | fix_co2_proj/global_co2historicaldata_2021.txt",
            "co2historicaldata_glob.txt | global_co2historicaldata_glob.txt",
            "co2monthlycyc.txt          | co2monthlycyc.txt",
            "global_h2oprdlos.f77       | global_h2o_pltc.f77",
            "global_zorclim.1x1.grb     | global_zorclim.1x1.grb",
            "sfc_emissivity_idx.txt     | global_sfc_emissivity_idx.txt",
            "solarconstant_noaa_an.txt  | global_solarconstant_noaa_an.txt",
            "global_o3prdlos.f77        | ozprdlos_2015_new_sbuvO3_tclm15_nuchem.f77",
        ]
