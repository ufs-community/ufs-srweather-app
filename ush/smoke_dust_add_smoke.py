#!/usr/bin/env python3

from typing import Tuple
import xarray as xr
import numpy as np
import os


def populate_data(data: np.ndarray, target_shape: Tuple) -> np.ndarray:
    """
    Extracted variables need to match the target shape so we first populating it into a zero array.

    Args:
        data: The extracted data to be adjusted
        target_shape: The shape of the target data array

    Returns:
        The adjusted data array
    """
    populated_data = np.zeros(target_shape)
    populated_data[: data.shape[0], :, :] = data
    return populated_data


def main() -> None:
    # File paths
    source_file = "fv_tracer.res.tile1.nc"
    target_file = "gfs_data.tile7.halo0.nc"

    # Check if the source file exists
    if not os.path.exists(source_file):
        print(f"Source file '{source_file}' does not exist. Exiting...")
        return

    # Open the source file and extract data
    data_to_extract = xr.open_dataset(source_file)
    print("DATA FILE:", data_to_extract)

    smoke_2_add = data_to_extract["smoke"][0, :, :, :]
    dust_2_add = data_to_extract["dust"][0, :, :, :]
    coarsepm_2_add = data_to_extract["coarsepm"][0, :, :, :]

    print("Max values in source file:", smoke_2_add.max())

    # Open the target file and load it into memory
    file_input = xr.open_dataset(target_file).load()
    file_input.close()  # to remove permission error below
    print("TARGET FILE:", file_input)
    # Drop the 'smoke' variable if it exists in both the source and target files
    if "smoke" in file_input.variables and "smoke" in data_to_extract.variables:
        file_input = file_input.drop("smoke")

    # Determine the shape of the new variables based on the target file dimensions
    lev_dim = file_input.dims["lev"]
    lat_dim = file_input.dims["lat"]
    lon_dim = file_input.dims["lon"]

    # Populate the extracted data to match the target shape
    # smoke_2_add_populated = populate_data(smoke_2_add, (lev_dim, lat_dim, lon_dim))
    # dust_2_add_populated = populate_data(dust_2_add, (lev_dim, lat_dim, lon_dim))
    # coarsepm_2_add_populated = populate_data(coarsepm_2_add, (lev_dim, lat_dim, lon_dim))

    # print('Max values in populated data:', smoke_2_add_populated.max(), dust_2_add_populated.max(), coarsepm_2_add_populated.max())

    # Create new data arrays filled with zeros
    smoke_zero = xr.DataArray(
        np.zeros((lev_dim, lat_dim, lon_dim)),
        dims=["lev", "lat", "lon"],
        attrs={"units": "ug/kg"},
    )
    dust_zero = xr.DataArray(
        np.zeros((lev_dim, lat_dim, lon_dim)),
        dims=["lev", "lat", "lon"],
        attrs={"units": "ug/kg"},
    )
    coarsepm_zero = xr.DataArray(
        np.zeros((lev_dim, lat_dim, lon_dim)),
        dims=["lev", "lat", "lon"],
        attrs={"units": "ug/kg"},
    )

    # Assign the data arrays to the dataset, initially with zeros
    file_input["smoke"] = smoke_zero
    file_input["dust"] = dust_zero
    file_input["coarsepm"] = coarsepm_zero

    # Populate the variables with the adjusted data
    file_input["smoke"][1:66, :, :] = smoke_2_add
    file_input["dust"][1:66, :, :] = dust_2_add
    file_input["coarsepm"][1:66, :, :] = coarsepm_2_add

    print("FINAL FILE:", file_input)
    # Save the modified dataset back to the file
    file_input.to_netcdf(target_file, mode="w")

    # Reopen the target file to check the variables
    with xr.open_dataset(target_file) as file_input:
        print("Max values in target file after update:")
        print("smoke:", file_input["smoke"].max().item())
        print("dust:", file_input["dust"].max().item())
        print("coarsepm:", file_input["coarsepm"].max().item())


if __name__ == "__main__":
    main()
