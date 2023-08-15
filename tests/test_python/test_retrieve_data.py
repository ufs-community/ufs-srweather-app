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

To ensure all output is printed for debugging or to monitor test progress,
omit the "-b" flag.
"""
import datetime
import glob
import os
import tempfile
import unittest

import retrieve_data


@unittest.skipIf(os.environ.get("UNIT_TEST") == "true", "Skipping functional tests")
class FunctionalTesting(unittest.TestCase):

    """Test class for retrieve data"""

    def setUp(self):
        self.path = os.path.dirname(__file__)
        self.config = os.path.join(
            self.path,
            "..",
            "..",
            "parm",
            "data_locations.yml"
            )
        threedaysago = datetime.datetime.today() - datetime.timedelta(days=3)
        # Set test dates to retrieve, based on important dates in HPSS history:
        # 2019061200 - First operational FV3GFS cycle
        # 2020022518, 2020022600 - Changes to operational FV3GFS files between these cycles
        # 2020022612, 2020022618 - Changes to RAP hpss filenames between these cycles
        # 2021032018, 2021032100 - nemsio format replaced with netcdf between these cycles
        # 2022062700, 2022062706 - Changes to RAP hpss filenames between these cycles
        self.dates={}
        self.dates["FV3GFSgrib2"]  = ['2019061200',
                                      '2020022600',
                                      threedaysago.strftime('%Y%m%d') + '12']
        self.dates["FV3GFSnemsio"] = ['2019061200',
                                      '2020022518',
                                      '2021032018']
        self.dates["FV3GFSnetcdf"] = ['2021032100',
                                      threedaysago.strftime('%Y%m%d') + '00']
        self.dates["RAPhpss"]      = ['2018071118',
                                      '2020022618',
                                      threedaysago.strftime('%Y%m%d') + '06']
        self.dates["RAPaws"]       = ['2021022200',
                                      threedaysago.strftime('%Y%m%d%H')]


    @unittest.skipIf(os.environ.get("CI") == "true", "Skipping HPSS tests")
    def test_fv3gfs_grib2_from_hpss(self):
        """Get FV3GFS grib2 files from HPSS for LBCS, offset by 6 hours"""

        for date in self.dates["FV3GFSgrib2"]:
            with tempfile.TemporaryDirectory(dir=self.path) as tmp_dir:
                os.chdir(tmp_dir)
                # fmt: off
                args = [
                    '--file_set', 'fcst',
                    '--config', self.config,
                    '--cycle_date', date,
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
    def test_fv3gfs_nemsio_lbcs_from_hpss(self):

        """Get FV3GFS nemsio files from HPSS for LBCS"""

        for date in self.dates["FV3GFSnemsio"]:
            with tempfile.TemporaryDirectory(dir=self.path) as tmp_dir:
                os.chdir(tmp_dir)

                # fmt: off
                args = [
                    '--file_set', 'fcst',
                    '--config', self.config,
                    '--cycle_date', date,
                    '--data_stores', 'hpss',
                    '--data_type', 'FV3GFS',
                    '--fcst_hrs', '24',
                    '--output_path', tmp_dir,
                    '--ics_or_lbcs', 'LBCS',
                    '--debug',
                    '--file_fmt', 'nemsio',
                ]
                # fmt: on

                retrieve_data.main(args)

                # Verify files exist in temp dir

                path = os.path.join(tmp_dir, "*")
                files_on_disk = glob.glob(path)
                self.assertEqual(len(files_on_disk), 1)

    @unittest.skipIf(os.environ.get("CI") == "true", "Skipping HPSS tests")
    def test_fv3gfs_netcdf_lbcs_from_hpss(self):

        """Get FV3GFS netcdf files from HPSS for LBCS. Tests fcst lead
        times > 40 hours, since they come from a different archive file.
        """

        for date in self.dates["FV3GFSnetcdf"]:
            with tempfile.TemporaryDirectory(dir=self.path) as tmp_dir:
                os.chdir(tmp_dir)

                # fmt: off
                args = [
                    '--file_set', 'fcst',
                    '--config', self.config,
                    '--cycle_date', date,
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

        with tempfile.TemporaryDirectory(dir=self.path) as tmp_dir:
            os.chdir(tmp_dir)

            out_path_tmpl = os.path.join(tmp_dir, "mem{mem:03d}")

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

        with tempfile.TemporaryDirectory(dir=self.path) as tmp_dir:
            os.chdir(tmp_dir)

            out_path_tmpl = os.path.join(tmp_dir, "mem{mem:03d}")

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

        with tempfile.TemporaryDirectory(dir=self.path) as tmp_dir:
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

        with tempfile.TemporaryDirectory(dir=self.path) as tmp_dir:
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

        with tempfile.TemporaryDirectory(dir=self.path) as tmp_dir:
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

        with tempfile.TemporaryDirectory(dir=self.path) as tmp_dir:
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
    @unittest.skipIf(os.environ.get("CI") == "true", "Skipping HPSS tests")
    def test_rap_ics_from_hpss(self):

        """Get RAP ICS from aws offset by 3 hours"""

        for date in self.dates["RAPhpss"]:
            with tempfile.TemporaryDirectory(dir=self.path) as tmp_dir:
                os.chdir(tmp_dir)

                # fmt: off
                args = [
                    '--file_set', 'anl',
                    '--config', self.config,
                    '--cycle_date', date,
                    '--data_stores', 'hpss',
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

    def test_rap_ics_from_aws(self):

        """Get RAP ICS from aws offset by 3 hours"""

        for date in self.dates["RAPaws"]:
            with tempfile.TemporaryDirectory(dir=self.path) as tmp_dir:
                os.chdir(tmp_dir)

                # fmt: off
                args = [
                    '--file_set', 'anl',
                    '--config', self.config,
                    '--cycle_date', date,
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

        with tempfile.TemporaryDirectory(dir=self.path) as tmp_dir:
            os.chdir(tmp_dir)

            # fmt: off
            args = [
                '--file_set', 'fcst',
                '--config', self.config,
                '--cycle_date', '2022062509',
                '--data_stores', 'aws',
                '--data_type', 'RAP',
                '--fcst_hrs', '3', '45', '6',
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

    def test_ufs_ics_from_aws(self):

        """Get UFS-CASE-STUDY ICS from aws"""

        with tempfile.TemporaryDirectory(dir=self.path) as tmp_dir:
            os.chdir(tmp_dir)

            # fmt: off
            args = [
                '--file_set', 'anl',
                '--config', self.config,
                '--cycle_date', '2020072300',
                '--data_stores', 'aws',
                '--data_type', 'UFS-CASE-STUDY',
                '--fcst_hrs', '0',
                '--output_path', tmp_dir,
                '--ics_or_lbcs', 'ICS',
                '--debug',
                '--file_fmt', 'nemsio',
                '--check_file',
            ]
            # fmt: on

            # Testing that there is no failure
            retrieve_data.main(args)

    def test_ufs_lbcs_from_aws(self):

        """Get UFS-CASE-STUDY LBCS from aws for 3 hour boundary conditions"""

        with tempfile.TemporaryDirectory(dir=self.path) as tmp_dir:
            os.chdir(tmp_dir)

            # fmt: off
            args = [
                '--file_set', 'fcst',
                '--config', self.config,
                '--cycle_date', '2020072300',
                '--data_stores', 'aws',
                '--data_type', 'UFS-CASE-STUDY',
                '--fcst_hrs', '3', '6', '3',
                '--output_path', tmp_dir,
                '--ics_or_lbcs', 'LBCS',
                '--debug',
                '--file_fmt', 'nemsio',
                '--check_file',
            ]
            # fmt: on

            # Testing that there is no failure
            retrieve_data.main(args)

    @unittest.skipIf(os.environ.get("CI") == "true", "Skipping HPSS tests")
    def test_rap_obs_from_hpss(self):

        """Get RAP observations from hpss for a 06z time"""

        with tempfile.TemporaryDirectory(dir=self.path) as tmp_dir:
            os.chdir(tmp_dir)

            # fmt: off
            args = [
                '--file_set', 'obs',
                '--config', self.config,
                '--cycle_date', '2023032106',
                '--data_stores', 'hpss',
                '--data_type', 'RAP_obs',
                '--output_path', tmp_dir,
                '--debug',
            ]
            # fmt: on

            retrieve_data.main(args)

            # Verify files exist in temp dir

            path = os.path.join(tmp_dir, "*")
            files_on_disk = glob.glob(path)
            self.assertEqual(len(files_on_disk), 30)

    @unittest.skipIf(os.environ.get("CI") == "true", "Skipping HPSS tests")
    def test_rap_e_obs_from_hpss(self):

        """Get RAP observations from hpss for a 12z time;
           at 00z and 12z we expect to see additional files
           with the 'rap_e' naming convention"""

        with tempfile.TemporaryDirectory(dir=self.path) as tmp_dir:
            os.chdir(tmp_dir)

            # fmt: off
            args = [
                '--file_set', 'obs',
                '--config', self.config,
                '--cycle_date', '2023032112',
                '--data_stores', 'hpss',
                '--data_type', 'RAP_obs',
                '--output_path', tmp_dir,
                '--debug',
            ]
            # fmt: on

            retrieve_data.main(args)

            # Verify files exist in temp dir

            path = os.path.join(tmp_dir, "*")
            files_on_disk = glob.glob(path)
            self.assertEqual(len(files_on_disk), 37)
