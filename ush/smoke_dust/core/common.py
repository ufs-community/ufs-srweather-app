"""Contains common functionality used across smoke/dust."""

from contextlib import contextmanager
from pathlib import Path
from typing import Tuple, Literal, Dict

import numpy as np
import pandas as pd
from mpi4py import MPI
from netCDF4 import Dataset

from smoke_dust.core.variable import SmokeDustVariable, SD_VARS


@contextmanager
def open_nc(
    path: Path,
    mode: Literal["r", "w", "a"] = "r",
    clobber: bool = False,
    parallel: bool = True,
) -> Dataset:
    """
    Open a netCDF file for various operations.

    Args:
        path: Path to the target netCDF file.
        mode: Mode to open the file in.
        clobber: If True, overwrite an existing file.
        parallel: If True, open the netCDF for parallel operations.

    Returns:
        A netCDF dataset object.
    """
    nc_ds = Dataset(
        path,
        mode=mode,
        clobber=clobber,
        parallel=parallel,
        comm=MPI.COMM_WORLD,
        info=MPI.Info(),
    )
    try:
        yield nc_ds
    finally:
        nc_ds.close()


def create_sd_coordinate_variable(
    nc_ds: Dataset,
    sd_variable: SmokeDustVariable,
) -> None:
    """
    Create a smoke/dust netCDF spatial coordinate variable.

    Args:
        nc_ds: Dataset to update.
        sd_variable: Contains variable metadata.
    """
    var_out = nc_ds.createVariable(
        sd_variable.name, "f4", ("lat", "lon"), fill_value=sd_variable.fill_value_float
    )
    var_out.units = sd_variable.units
    var_out.long_name = sd_variable.long_name
    var_out.standard_name = sd_variable.name
    var_out.FillValue = sd_variable.fill_value_str
    var_out.coordinates = "geolat geolon"


def create_sd_variable(
    nc_ds: Dataset,
    sd_variable: SmokeDustVariable,
    fill_first_time_index: bool = True,
) -> None:
    """
    Create a smoke/dust netCDF variable.

    Args:
        nc_ds: Dataset to update
        sd_variable: Contains variable metadata
        fill_first_time_index: If True, fill the first time index with provided `fill_value_float`
    """
    var_out = nc_ds.createVariable(
        sd_variable.name,
        "f4",
        ("t", "lat", "lon"),
        fill_value=sd_variable.fill_value_float,
    )
    var_out.units = sd_variable.units
    var_out.long_name = sd_variable.long_name
    var_out.standard_name = sd_variable.long_name
    var_out.FillValue = sd_variable.fill_value_str
    var_out.coordinates = "t geolat geolon"
    if fill_first_time_index:
        try:
            var_out.set_collective(True)
        except RuntimeError:
            # Allow this function to work with parallel and non-parallel datasets. If the dataset
            # is not opened in parallel this error message is returned:
            # RuntimeError: NetCDF: Parallel operation on file opened for non-parallel access
            pass
        var_out[0, :, :] = sd_variable.fill_value_float
        try:
            var_out.set_collective(False)
        except RuntimeError:
            pass


def create_template_emissions_file(
    nc_ds: Dataset, grid_shape: Tuple[int, int], is_dummy: bool = False
):
    """
    Create a smoke/dust template netCDF emissions file.

    Args:
        nc_ds: The target netCDF dataset object.
        grid_shape: The grid shape to create.
        is_dummy: Converted to a netCDF attribute to indicate if the created file is dummy
            emissions or will contain actual values.
    """
    nc_ds.createDimension("t", None)
    nc_ds.createDimension("lat", grid_shape[0])
    nc_ds.createDimension("lon", grid_shape[1])
    setattr(nc_ds, "PRODUCT_ALGORITHM_VERSION", "Beta")
    setattr(nc_ds, "TIME_RANGE", "1 hour")
    setattr(nc_ds, "is_dummy", str(is_dummy))

    for varname in ["geolat", "geolon"]:
        create_sd_coordinate_variable(nc_ds, SD_VARS.get(varname))


def create_descriptive_statistics(
    container: Dict[str, np.ma.MaskedArray],
    origin: Literal["src", "dst_unmasked", "dst_masked", "derived"],
    path: Path,
) -> pd.DataFrame:
    """
    Create a standard set of descriptive statistics using `pandas`.


    Args:
        container: A dictionary mapping names to masked arrays.
        origin: A tag to indicate the data origin to add to the created dataframe.
        path: Path to the netCDF file where the container data originated.

    Returns:
        A dataframe containing descriptive statistics fields.
    """
    data_frame = pd.DataFrame.from_dict({k: v.filled(np.nan).ravel() for k, v in container.items()})
    desc = data_frame.describe()
    adds = {}
    for field_name in container.keys():
        adds[field_name] = [
            data_frame[field_name].sum(),
            data_frame[field_name].isnull().sum(),
            origin,
            path,
        ]
    desc = pd.concat([desc, pd.DataFrame(data=adds, index=["sum", "count_null", "origin", "path"])])
    return desc
