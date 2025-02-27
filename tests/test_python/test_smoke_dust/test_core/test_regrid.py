"""Tests the regrid processor."""

import glob
import shutil
import subprocess
from pathlib import Path
from typing import Union

import numpy as np
import pytest
import xarray as xr
from _pytest.fixtures import SubRequest
from pydantic import BaseModel, Field
from pytest_mock import MockerFixture

from smoke_dust.core.context import SmokeDustContext
from smoke_dust.core.preprocessor import SmokeDustPreprocessor
from smoke_dust.core.regrid.processor import SmokeDustRegridProcessor
from test_python.test_smoke_dust.conftest import (
    FakeGridOutShape,
    create_fake_context,
    create_file_hash,
)


def ncdump(path: Path, header_only: bool = True) -> str:
    """
    Convenience wrapper for calling the ncdump utility.

    Args:
        path: Target netCDF file.
        header_only: If True, return only netCDF header information.

    Returns:
        Output from the ncdump program.
    """
    args = ["ncdump"]
    if header_only:
        args.append("-h")
    args.append(str(path))
    ret = subprocess.check_output(args).decode()
    print(ret, flush=True)
    return ret


class DataForTest(BaseModel):
    """Model holds objects needed for testing."""

    model_config = {"arbitrary_types_allowed": True}
    context: SmokeDustContext
    preprocessor: SmokeDustPreprocessor


class FakeGridParams(BaseModel):
    """Model for a fake RAVE/RRFS data file definition."""

    path: Path = Field(description="Path to the output data file.")
    shape: FakeGridOutShape = Field(description="Output grid shape.")
    with_corners: bool = Field(
        description="If True, create the output grid with corners", default=True
    )
    fields: Union[list[str], None] = Field(
        description="If provided, a list of field names to create in the output file.", default=None
    )
    min_lon: int = Field(
        description="The minimum longitude value as origin for grid generation.", default=230
    )
    min_lat: int = Field(
        description="The minimum latitude value as origin for grid generation.", default=25
    )
    ntime: Union[int, None] = Field(
        description="If provided, create the output fields with this many time steps.", default=1
    )


@pytest.fixture(params=[True, False], ids=lambda p: f"regrid_in_memory={p}")
def data_for_test(
    request: SubRequest,
    tmp_path: Path,
    fake_grid_out_shape: FakeGridOutShape,
    bin_dir: Path,
) -> DataForTest:
    """Create test data including any required data files."""
    weight_file = "weight_file.nc"
    shutil.copy(bin_dir / weight_file, tmp_path / "weight_file.nc")
    for name in ["ds_out_base.nc", "grid_in.nc"]:
        path = tmp_path / name
        _ = create_fake_rave_and_rrfs_like_data(
            FakeGridParams(path=path, shape=fake_grid_out_shape, fields=["area"], ntime=None)
        )
    context = create_fake_context(tmp_path, overrides={"regrid_in_memory": request.param})
    preprocessor = SmokeDustPreprocessor(context)
    for date in preprocessor.cycle_dates:
        path = tmp_path / f"Hourly_Emissions_3km_{date}_{date}.nc"
        _ = create_fake_rave_and_rrfs_like_data(
            FakeGridParams(path=path, shape=fake_grid_out_shape, fields=["FRP_MEAN", "FRE"])
        )
    return DataForTest(context=context, preprocessor=preprocessor)


def create_analytic_data_array(
    dims: list[str],
    lon_mesh: np.ndarray,
    lat_mesh: np.ndarray,
    ntime: Union[int, None] = None,
) -> xr.DataArray:
    """
    Create an analytic data array using lat/lon values.

    Args:
        dims: Names of the lat/lon dimensions. For example `["lat", "lon"]`.
        lon_mesh: A two-dimensional array of longitude values.
        lat_mesh: A two-dimensional array of latitude values.
        ntime: If provided, create the output data array with the provided number of time steps.

    Returns:
        An analytic data array.
    """
    deg_to_rad = 3.141592653589793 / 180.0
    analytic_data = 2.0 + np.cos(deg_to_rad * lon_mesh) ** 2 * np.cos(
        2.0 * deg_to_rad * (90.0 - lat_mesh)
    )
    if ntime is not None:
        time_modifier = np.arange(1, ntime + 1).reshape(ntime, 1, 1)
        analytic_data = analytic_data.reshape([1] + list(analytic_data.shape))
        analytic_data = np.repeat(analytic_data, ntime, axis=0)
        analytic_data = time_modifier * analytic_data
    return xr.DataArray(
        analytic_data,
        dims=dims,
    )


def create_fake_rave_and_rrfs_like_data(params: FakeGridParams) -> xr.Dataset:
    """
    Create fake RAVE and RRFS data. These data files share a common grid.

    Returns:
        The created dataset object.
    """
    if params.path.exists():
        raise ValueError(f"path exists: {params.path}")
    lon = np.arange(params.shape.x_size, dtype=float) + params.min_lon
    lat = np.arange(params.shape.y_size, dtype=float) + params.min_lat
    lon_mesh, lat_mesh = np.meshgrid(lon, lat)
    nc_ds = xr.Dataset()
    dims = ["grid_yt", "grid_xt"]
    nc_ds["grid_lont"] = xr.DataArray(lon_mesh, dims=dims)
    nc_ds["grid_latt"] = xr.DataArray(lat_mesh, dims=dims)
    if params.with_corners:
        lonc = np.hstack((lon - 0.5, [lon[-1] + 0.5]))
        latc = np.hstack((lat - 0.5, [lat[-1] + 0.5]))
        lonc_mesh, latc_mesh = np.meshgrid(lonc, latc)
        nc_ds["grid_lon"] = xr.DataArray(lonc_mesh, dims=["grid_y", "grid_x"])
        nc_ds["grid_lat"] = xr.DataArray(latc_mesh, dims=["grid_y", "grid_x"])
    if params.fields is not None:
        if params.ntime is not None:
            field_dims = ["time"] + dims
        else:
            field_dims = dims
        for field in params.fields:
            nc_ds[field] = create_analytic_data_array(
                field_dims, lon_mesh, lat_mesh, ntime=params.ntime
            )
    nc_ds.to_netcdf(params.path)
    return nc_ds


class TestSmokeDustRegridProcessor:  # pylint: disable=too-few-public-methods
    """Tests for the smoke/dust regrid processor."""

    def test_run(
        self,
        data_for_test: DataForTest,  # pylint: disable=redefined-outer-name
        mocker: MockerFixture,
        tmp_path: Path,
    ) -> None:
        """Test the regrid processor."""
        spy1 = mocker.spy(SmokeDustRegridProcessor, "_run_impl_")
        regrid_processor = SmokeDustRegridProcessor(data_for_test.context)
        regrid_processor.run(data_for_test.preprocessor.cycle_metadata)
        spy1.assert_called_once()
        interpolated_files = glob.glob(
            f"*{data_for_test.context.rave_to_intp}*nc", root_dir=tmp_path
        )
        assert len(interpolated_files) == 24
        for intp_file in interpolated_files:
            fpath = tmp_path / intp_file
            assert create_file_hash(fpath) == "8e90b769137aad054a2e49559d209c4d"
