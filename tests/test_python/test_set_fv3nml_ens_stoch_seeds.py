""" Tests for set_fv3nml_ens_stoch_seeds.py """

#pylint: disable=invalid-name

from datetime import datetime
import os
import tempfile
import unittest

from python_utils import (
  cp_vrfy,
  date_to_str,
  define_macos_utilities,
  mkdir_vrfy,
  set_env_var,
)

from set_fv3nml_ens_stoch_seeds import set_fv3nml_ens_stoch_seeds

class Testing(unittest.TestCase):
    """ Define the tests """
    def test_set_fv3nml_ens_stoch_seeds(self):
        """ Call the function and make sure it doesn't fail"""
        os.chdir(self.mem_dir)
        set_fv3nml_ens_stoch_seeds(cdate=self.cdate, expt_config=self.config)

    def setUp(self):
        define_macos_utilities()
        set_env_var("VERBOSE", True)
        self.cdate = datetime(2021, 1, 1)
        test_dir = os.path.dirname(os.path.abspath(__file__))
        USHdir = os.path.join(test_dir, "..", "..", "ush")
        PARMdir = os.path.join(USHdir, "..", "parm")

        # Create an temporary experiment directory
        # pylint: disable=consider-using-with
        self.tmp_dir = tempfile.TemporaryDirectory(
            dir=os.path.dirname(__file__),
            prefix="expt",
            )
        EXPTDIR = self.tmp_dir.name

        # Put this in the tmp_dir structure so it gets cleaned up
        self.mem_dir = os.path.join(
                    EXPTDIR,
                    f"{date_to_str(self.cdate,format='%Y%m%d%H')}",
                    "mem2",
                )

        mkdir_vrfy("-p", self.mem_dir)
        cp_vrfy(
            os.path.join(PARMdir, "input.nml.FV3"),
            os.path.join(self.mem_dir, "input.nml"),
        )


        set_env_var("ENSMEM_INDX", 2)

        self.config = {
            "workflow": {
                "VERBOSE": True,
                "FV3_NML_FN": "input.nml",
            },
            "global": {
                "DO_SHUM": True,
                "DO_SKEB": True,
                "DO_SPPT": True,
                "DO_SPP": True,
                "DO_LSM_SPP": True,
                "ISEED_SPP": [4, 5, 6, 7, 8],
            },
        }

    def tearDown(self):
        self.tmp_dir.cleanup()
