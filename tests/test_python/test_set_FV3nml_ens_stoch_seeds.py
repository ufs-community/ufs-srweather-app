""" Tests for set_FV3nml_ens_stoch_seeds.py """

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

from set_FV3nml_ens_stoch_seeds import set_FV3nml_ens_stoch_seeds

class Testing(unittest.TestCase):
    """ Define the tests """
    def test_set_FV3nml_ens_stoch_seeds(self):
        """ Call the function and make sure it doesn't fail"""
        os.chdir(self.mem_dir)
        set_FV3nml_ens_stoch_seeds(cdate=self.cdate)

    def setUp(self):
        define_macos_utilities()
        set_env_var("DEBUG", True)
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
            os.path.join(EXPTDIR, "input.nml_base"),
        )


        set_env_var("USHdir", USHdir)
        set_env_var("ENSMEM_INDX", 2)
        set_env_var("FV3_NML_FN", "input.nml")
        set_env_var("FV3_NML_FP", os.path.join(EXPTDIR, "input.nml_base"))
        set_env_var("DO_SHUM", True)
        set_env_var("DO_SKEB", True)
        set_env_var("DO_SPPT", True)
        set_env_var("DO_SPP", True)
        set_env_var("DO_LSM_SPP", True)
        ISEED_SPP = [4, 5, 6, 7, 8]
        set_env_var("ISEED_SPP", ISEED_SPP)

    def tearDown(self):
        self.tmp_dir.cleanup()
