""" Tests for set_FV3nml_ens_stoch_seeds.py """

#pylint: disable=invalid-name

from datetime import datetime
import os
import unittest

from python_utils import (
  cd_vrfy,
  cp_vrfy,
  date_to_str,
  define_macos_utilities,
  mkdir_vrfy,
  set_env_var,
)

from set_FV3nml_ens_stoch_seeds import set_FV3nml_ens_stoch_seeds

class Testing(unittest.TestCase):
    """ Define the tests """
    def test_set_FV3nml_ens_stoch_seeds(self):
        """ Call the function and make sure it doesn't fail"""
        set_FV3nml_ens_stoch_seeds(cdate=self.cdate)

    def setUp(self):
        define_macos_utilities()
        set_env_var("DEBUG", True)
        set_env_var("VERBOSE", True)
        self.cdate = datetime(2021, 1, 1)
        test_dir = os.path.dirname(os.path.abspath(__file__))
        USHdir = os.path.join(test_dir, "..", "..", "ush")
        PARMdir = os.path.join(USHdir, "..", "parm")
        EXPTDIR = os.path.join(USHdir, "test_data", "expt")
        mkdir_vrfy("-p", EXPTDIR)
        cp_vrfy(
            os.path.join(PARMdir, "input.nml.FV3"),
            os.path.join(EXPTDIR, "input.nml"),
        )
        for i in range(2):
            mkdir_vrfy(
                "-p",
                os.path.join(
                    EXPTDIR,
                    f"{date_to_str(self.cdate,format='%Y%m%d%H')}{os.sep}mem{i+1}",
                ),
            )

        cd_vrfy(
            f"{EXPTDIR}{os.sep}{date_to_str(self.cdate,format='%Y%m%d%H')}{os.sep}mem2"
        )
        set_env_var("USHdir", USHdir)
        set_env_var("ENSMEM_INDX", 2)
        set_env_var("FV3_NML_FN", "input.nml")
        set_env_var("FV3_NML_FP", os.path.join(EXPTDIR, "input.nml"))
        set_env_var("DO_SHUM", True)
        set_env_var("DO_SKEB", True)
        set_env_var("DO_SPPT", True)
        set_env_var("DO_SPP", True)
        set_env_var("DO_LSM_SPP", True)
        ISEED_SPP = [4, 5, 6, 7, 8]
        set_env_var("ISEED_SPP", ISEED_SPP)
