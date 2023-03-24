"""
Functional test suite for gathering data using retreve_data.py.

The tests reflect some use cases of gathering various model input data
from HPSS and AWS. Obviously, HPSS tests will only be runnable on
machines with access to NOAA's HPSS system. AWS tests will be runnable
on any platform with an internet connection.

To run the full test suite:

    python -m unittest -b test_retrieve_data.py


To run a single test:

    python -m unittest -b test_retrieve_data.FunctionalTesting.test_rap_lbcs_from_aws
"""
import glob
import os
import tempfile
import unittest

import retrieve_data


class FunctionalTesting(unittest.TestCase):

    """Test class for retrieve data"""

    def setUp(self):
        self.path = os.path.dirname(__file__)
        self.config = f"{self.path}/../parm/data_locations.yml"

    @unittest.skipIf(os.environ.get("CI") == "true", "Skipping HPSS tests")
    def test_fv3gfs_grib2_lbcs_from_hpss(self):

        """Get FV3GFS grib2 files from HPSS for LBCS, offset by 6 hours"""

        with tempfile.TemporaryDirectory(dir=".") as tmp_dir:
            os.chdir(tmp_dir)

            # fmt: off
            args = [
                '--file_set', 'fcst',
                '--config', self.config,
                '--cycle_date', '2022062512',
                '--data_stores', 'hpss',
                '--data_type', 'FV3GFS',
                '--fcst_hrs', '6', '12', '3',
                '--output_path', tmp_dir,
                '--ics_or_lbcs', 'LBCS',
                '--debug',
                '--file_fmt', 'grib2',
            ]
            # fmt: on

            retrieve_data.main(args)

            # Verify files exist in temp dir

            path = os.path.join(tmp_dir, "*")
            files_on_disk = glob.glob(path)
            self.assertEqual(len(files_on_disk), 3)

    @unittest.skipIf(os.environ.get("CI") == "true", "Skipping HPSS tests")
    def test_fv3gfs_netcdf_lbcs_from_hpss(self):

        """Get FV3GFS netcdf files from HPSS for LBCS. Tests fcst lead
        times > 40 hours, since they come from a different archive file.
        """

        with tempfile.TemporaryDirectory(dir=".") as tmp_dir:
            os.chdir(tmp_dir)

            # fmt: off
            args = [
                '--file_set', 'fcst',
                '--config', self.config,
                '--cycle_date', '2022060112',
                '--data_stores', 'hpss',
                '--data_type', 'FV3GFS',
                '--fcst_hrs', '24', '48', '24',
                '--output_path', tmp_dir,
                '--ics_or_lbcs', 'LBCS',
                '--debug',
                '--file_fmt', 'netcdf',
            ]
            # fmt: on

            retrieve_data.main(args)

            # Verify files exist in temp dir

            path = os.path.join(tmp_dir, "*")
            files_on_disk = glob.glob(path)
            self.assertEqual(len(files_on_disk), 2)

    # GDAS Tests
    def test_gdas_ics_from_aws(self):

        """In real time, GDAS is used for LBCS with a 6 hour offset."""

        with tempfile.TemporaryDirectory(dir=".") as tmp_dir:
            os.chdir(tmp_dir)

            out_path_tmpl = os.path.join(tmp_dir, f"mem{{mem:03d}}")

            # fmt: off
            args = [
                '--file_set', 'anl',
                '--config', self.config,
                '--cycle_date', '2022052512',
                '--data_stores', 'aws',
                '--data_type', 'GDAS',
                '--fcst_hrs', '6', '9', '3',
                '--output_path', out_path_tmpl,
                '--ics_or_lbcs', 'LBCS',
                '--debug',
                '--file_fmt', 'netcdf',
                '--members', '9', '10',
            ]
            # fmt: on

            retrieve_data.main(args)

            # Verify files exist in temp dir
            for mem in [9, 10]:
                files_on_disk = glob.glob(
                    os.path.join(out_path_tmpl.format(mem=mem), "*")
                )
                self.assertEqual(len(files_on_disk), 2)

    # GEFS Tests
    @unittest.skipIf(os.environ.get("CI") == "true", "Skipping HPSS tests")
    def test_gefs_grib2_ics_from_aws(self):

        """Get GEFS grib2 a & b files for ICS offset by 6 hours."""

        with tempfile.TemporaryDirectory(dir=".") as tmp_dir:
            os.chdir(tmp_dir)

            out_path_tmpl = os.path.join(tmp_dir, f"mem{{mem:03d}}")

            # fmt: off
            args = [
                '--file_set', 'anl',
                '--config', self.config,
                '--cycle_date', '2022052512',
                '--data_stores', 'aws',
                '--data_type', 'GEFS',
                '--fcst_hrs', '6',
                '--output_path', out_path_tmpl,
                '--ics_or_lbcs', 'ICS',
                '--debug',
                '--file_fmt', 'netcdf',
                '--members', '1', '2',
            ]
            # fmt: on

            retrieve_data.main(args)

            # Verify files exist in temp dir
            for mem in [1, 2]:
                files_on_disk = glob.glob(
                    os.path.join(out_path_tmpl.format(mem=mem), "*")
                )
                self.assertEqual(len(files_on_disk), 2)

    # HRRR Tests
    @unittest.skipIf(os.environ.get("CI") == "true", "Skipping HPSS tests")
    def test_hrrr_ics_from_hpss(self):

        """Get HRRR ICS from hpss"""

        with tempfile.TemporaryDirectory(dir=".") as tmp_dir:
            os.chdir(tmp_dir)

            # fmt: off
            args = [
                '--file_set', 'anl',
                '--config', self.config,
                '--cycle_date', '2022062512',
                '--data_stores', 'hpss',
                '--data_type', 'HRRR',
                '--fcst_hrs', '0',
                '--output_path', tmp_dir,
                '--ics_or_lbcs', 'ICS',
                '--debug',
            ]
            # fmt: on

            retrieve_data.main(args)

            # Verify files exist in temp dir

            path = os.path.join(tmp_dir, "*")
            files_on_disk = glob.glob(path)
            self.assertEqual(len(files_on_disk), 1)

    @unittest.skipIf(os.environ.get("CI") == "true", "Skipping HPSS tests")
    def test_hrrr_lbcs_from_hpss(self):

        """Get HRRR LBCS from hpss for 3 hour boundary conditions"""

        with tempfile.TemporaryDirectory(dir=".") as tmp_dir:
            os.chdir(tmp_dir)

            # fmt: off
            args = [
                '--file_set', 'fcst',
                '--config', self.config,
                '--cycle_date', '2022062512',
                '--data_stores', 'hpss',
                '--data_type', 'HRRR',
                '--fcst_hrs', '3', '24', '3',
                '--output_path', tmp_dir,
                '--ics_or_lbcs', 'LBCS',
                '--debug',
            ]
            # fmt: on

            retrieve_data.main(args)

            # Verify files exist in temp dir

            path = os.path.join(tmp_dir, "*")
            files_on_disk = glob.glob(path)
            self.assertEqual(len(files_on_disk), 8)

    def test_hrrr_ics_from_aws(self):

        """Get HRRR ICS from aws"""

        with tempfile.TemporaryDirectory(dir=".") as tmp_dir:
            os.chdir(tmp_dir)

            # fmt: off
            args = [
                '--file_set', 'anl',
                '--config', self.config,
                '--cycle_date', '2022062512',
                '--data_stores', 'aws',
                '--data_type', 'HRRR',
                '--fcst_hrs', '0',
                '--output_path', tmp_dir,
                '--ics_or_lbcs', 'ICS',
                '--debug',
            ]
            # fmt: on

            retrieve_data.main(args)

            # Verify files exist in temp dir

            path = os.path.join(tmp_dir, "*")
            files_on_disk = glob.glob(path)
            self.assertEqual(len(files_on_disk), 1)

    def test_hrrr_lbcs_from_aws(self):

        """Get HRRR LBCS from aws for 3 hour boundary conditions"""

        with tempfile.TemporaryDirectory(dir=".") as tmp_dir:
            os.chdir(tmp_dir)
            
            # fmt: off
            args = [
                '--file_set', 'fcst',
                '--config', self.config,
                '--cycle_date', '2022062512',
                '--data_stores', 'aws',
                '--data_type', 'HRRR',
                '--fcst_hrs', '3', '24', '3',
                '--output_path', tmp_dir,
                '--ics_or_lbcs', 'LBCS',
                '--debug',
            ]
            # fmt: on

            retrieve_data.main(args)

            # Verify files exist in temp dir

            path = os.path.join(tmp_dir, "*")
            files_on_disk = glob.glob(path)
            self.assertEqual(len(files_on_disk), 8)

    # RAP tests
    def test_rap_ics_from_aws(self):

        """Get RAP ICS from aws offset by 3 hours"""

        with tempfile.TemporaryDirectory(dir=".") as tmp_dir:
            os.chdir(tmp_dir)

            # fmt: off
            args = [
                '--file_set', 'anl',
                '--config', self.config,
                '--cycle_date', '2022062509',
                '--data_stores', 'aws',
                '--data_type', 'RAP',
                '--fcst_hrs', '3',
                '--output_path', tmp_dir,
                '--ics_or_lbcs', 'ICS',
                '--debug',
            ]
            # fmt: on

            retrieve_data.main(args)

            # Verify files exist in temp dir

            path = os.path.join(tmp_dir, "*")
            files_on_disk = glob.glob(path)
            self.assertEqual(len(files_on_disk), 1)

    def test_rap_lbcs_from_aws(self):

        """Get RAP LBCS from aws for 6 hour boundary conditions offset
        by 3 hours. Use 09Z start time for longer LBCS."""

        with tempfile.TemporaryDirectory(dir=".") as tmp_dir:
            os.chdir(tmp_dir)

            # fmt: off
            args = [
                '--file_set', 'fcst',
                '--config', self.config,
                '--cycle_date', '2022062509',
                '--data_stores', 'aws',
                '--data_type', 'RAP',
                '--fcst_hrs', '3', '30', '6',
                '--output_path', tmp_dir,
                '--ics_or_lbcs', 'LBCS',
                '--debug',
            ]
            # fmt: on

            retrieve_data.main(args)

            # Verify files exist in temp dir

            path = os.path.join(tmp_dir, "*")
            files_on_disk = glob.glob(path)
            self.assertEqual(len(files_on_disk), 5)
