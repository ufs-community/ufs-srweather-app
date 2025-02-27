"""Test emissions processing for smoke/dust."""

from pathlib import Path
from typing import Type

import numpy as np
import pandas as pd
import pytest
from _pytest.fixtures import SubRequest
from netCDF4 import Dataset
from pydantic import BaseModel
from pytest_mock import MockerFixture

from smoke_dust.core.context import SmokeDustContext
from smoke_dust.core.cycle import (
    AbstractSmokeDustCycleProcessor,
    SmokeDustCycleOne,
    SmokeDustCycleTwo,
)
from smoke_dust.core.preprocessor import SmokeDustPreprocessor
from test_python.test_smoke_dust.conftest import (
    FakeGridOutShape,
    create_fake_grid_out,
    create_fake_context,
    create_file_hash,
    create_fake_restart_files,
)


def create_fake_rave_interpolated(
    root_dir: Path,
    cycle_dates: pd.DatetimeIndex,
    shape: FakeGridOutShape,
    rave_to_intp: str,
) -> None:
    """
    Create fake interpolated RAVE data.

    Args:
        root_dir: The directory to create fake interpolated data in.
        cycle_dates: The series of dates to create the interpolated data for.
        shape: The output grid shape.
        rave_to_intp: Filename prefix to use for output files.
    """
    for date in cycle_dates:
        intp_file = root_dir / f"{rave_to_intp}{date}00_{date}59.nc"
        dims = ("t", "lat", "lon")
        with Dataset(intp_file, "w") as nc_ds:
            nc_ds.createDimension("t")
            nc_ds.createDimension("lat", shape.y_size)
            nc_ds.createDimension("lon", shape.x_size)
            for varname in ["frp_avg_hr", "FRE"]:
                var = nc_ds.createVariable(varname, "f4", dims)
                var[0, ...] = np.ones(shape.as_tuple)


def create_fake_veg_map(root_dir: Path, shape: FakeGridOutShape) -> None:
    """
    Create a fake vegetation map data file.

    Args:
        root_dir: The directory to create the file in.
        shape: Shape of the output grid.
    """
    with Dataset(root_dir / "veg_map.nc", "w") as nc_ds:
        nc_ds.createDimension("grid_yt", shape.y_size)
        nc_ds.createDimension("grid_xt", shape.x_size)
        emiss_factor = nc_ds.createVariable("emiss_factor", "f4", ("grid_yt", "grid_xt"))
        emiss_factor[:] = np.ones((shape.y_size, shape.x_size))


class ExpectedData(BaseModel):
    """Holds expected data to test against."""

    flag: str
    klass: Type[AbstractSmokeDustCycleProcessor]
    hash: str


class DataForTest(BaseModel):
    """Holds data objects used by the test."""

    model_config = {"arbitrary_types_allowed": True}
    context: SmokeDustContext
    preprocessor: SmokeDustPreprocessor
    expected: ExpectedData


@pytest.fixture(
    params=[
        ExpectedData(flag="1", klass=SmokeDustCycleOne, hash="d124734dfce7ca914391e35a02e4a7d2"),
        ExpectedData(flag="2", klass=SmokeDustCycleTwo, hash="6752199f1039edc936a942f3885af38b"),
    ],
    ids=lambda p: f"ebb_dcycle={p.flag}",
)
def data_for_test(
    request: SubRequest, tmp_path: Path, fake_grid_out_shape: FakeGridOutShape
) -> DataForTest:
    """
    Creates the necessary test data including data files.
    """
    create_fake_grid_out(tmp_path, fake_grid_out_shape)
    create_fake_veg_map(tmp_path, fake_grid_out_shape)
    context = create_fake_context(tmp_path, overrides={"ebb_dcycle": request.param.flag})
    preprocessor = SmokeDustPreprocessor(context)
    create_fake_restart_files(tmp_path, preprocessor.cycle_dates, fake_grid_out_shape)
    create_fake_rave_interpolated(
        tmp_path,
        preprocessor.cycle_dates,
        fake_grid_out_shape,
        context.predef_grid.value + "_intp_",
    )
    return DataForTest(context=context, preprocessor=preprocessor, expected=request.param)


class TestSmokeDustPreprocessor:  # pylint: disable=too-few-public-methods
    """Tests for the smoke/dust preprocessor."""

    def test_run(
        self,
        data_for_test: DataForTest,  # pylint: disable=redefined-outer-name
        mocker: MockerFixture,
    ) -> None:
        """Test core capabilities of the preprocessor. Note this does not test regridding."""
        # pylint: disable=protected-access
        preprocessor = data_for_test.preprocessor
        spy1 = mocker.spy(preprocessor._context.__class__, "create_dummy_emissions_file")
        regrid_processor_class = preprocessor._regrid_processor.__class__
        spy2 = mocker.spy(regrid_processor_class, "_run_impl_")
        spy3 = mocker.spy(regrid_processor_class, "run")
        cycle_processor_class = preprocessor._cycle_processor.__class__
        spy4 = mocker.spy(cycle_processor_class, "run")
        spy5 = mocker.spy(cycle_processor_class, "average_frp")

        assert isinstance(preprocessor._cycle_processor, data_for_test.expected.klass)
        assert preprocessor._cycle_processor._cycle_metadata is None
        # pylint: enable=protected-access
        assert not data_for_test.context.emissions_path.exists()

        preprocessor.run()
        spy1.assert_not_called()
        spy2.assert_not_called()
        spy3.assert_called_once()
        spy4.assert_called_once()
        spy5.assert_called_once()

        assert data_for_test.context.emissions_path.exists()
        assert create_file_hash(data_for_test.context.emissions_path) == data_for_test.expected.hash
