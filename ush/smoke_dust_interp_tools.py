#!/usr/bin/env python3

import datetime as dt
from typing import Tuple, List, Any

import pandas as pd
import os
import fnmatch
import xarray as xr
import numpy as np
from netCDF4 import Dataset
from numpy import ndarray
from pandas import Index
from xarray import DataArray

try:
    import esmpy as ESMF
except ImportError:
    # esmpy version 8.3.1 is required on Orion/Hercules
    import ESMF


def date_range(current_day: str, ebb_dcycle: int, persistence: str) -> Index:
    """
    Create date range, this is later used to search for RAVE and HWP from previous 24 hours.

    Args:
        current_day: The current forecast day and hour
        ebb_dcycle: Valid options are ``"1"`` and ``"2"``
        persistence: If ``True``, use satellite observations from previous day

    Returns:
        A string ``Index`` with values matching the forecast day and hour
    """
    print(f"Searching for interpolated RAVE for {current_day}")
    print(f"EBB CYCLE: {ebb_dcycle}")
    print(f"Persistence setting received: {persistence}")

    fcst_datetime = dt.datetime.strptime(current_day, "%Y%m%d%H")
    # persistence (bool): Determines if forecast should persist from previous day.

    if ebb_dcycle == 1:
        print("Find  RAVE for ebb_dcyc 1")
        if persistence == True:
            # Start date range from one day prior if persistence is True
            print(
                "Creating emissions for persistence method where satellite FRP persist from previous day"
            )
            start_datetime = fcst_datetime - dt.timedelta(days=1)
        else:
            # Start date range from the current date
            print("Creating emissions using  current date satellite FRP")
            start_datetime = fcst_datetime
        # Generate dates for 24 hours from start_datetime
        fcst_dates = pd.date_range(start=start_datetime, periods=24, freq="H").strftime(
            "%Y%m%d%H"
        )
    else:
        print("Creating emissions for modulated persistence by Wildfire potential")
        start_datetime = fcst_datetime - dt.timedelta(days=1, hours=1)

        fcst_dates = pd.date_range(start=start_datetime, periods=24, freq="H").strftime(
            "%Y%m%d%H"
        )

    print(f"Current cycle: {fcst_datetime}")
    return fcst_dates


def check_for_intp_rave(
    intp_dir: str, fcst_dates: Index, rave_to_intp: str
) -> Tuple[List[str], List[str], bool]:
    """
    Check if interpolated RAVE is available for the previous 24 hours

    Args:
        intp_dir: Path to directory containing interpolated RAVE files from previous cycles
        fcst_dates: Forecast data and hours to search ``intp_dir`` for
        rave_to_intp: Filename prefix for the interpolated RAVE files

    Returns:
        A tuple containing:
            * ``0``: The available forecast days/hours
            * ``1``: The unavailable (missing) forecast day/hours
            * ``2``: A boolean indicating if there are any interpolated RAVE files available
    """
    intp_avail_hours = []
    intp_non_avail_hours = []
    # There are four situations here.
    #   1) the file is missing (interpolate a new file)
    #   2) the file is present (use it)
    #   3) there is a link, but it's broken (interpolate a new file)
    #   4) there is a valid link (use it)
    for date in fcst_dates:
        file_name = f"{rave_to_intp}{date}00_{date}59.nc"
        file_path = os.path.join(intp_dir, file_name)
        file_exists = os.path.isfile(file_path)
        is_link = os.path.islink(file_path)
        is_valid_link = is_link and os.path.exists(file_path)

        if file_exists or is_valid_link:
            print(f"RAVE interpolated file available for {file_name}")
            intp_avail_hours.append(str(date))
        else:
            print(f"Interpolated file non available, interpolate RAVE for {file_name}")
            intp_non_avail_hours.append(str(date))

    print(
        f"Available interpolated files for hours: {intp_avail_hours}, Non available interpolated files for hours: {intp_non_avail_hours}"
    )

    inp_files_2use = len(intp_avail_hours) > 0

    return intp_avail_hours, intp_non_avail_hours, inp_files_2use


def check_for_raw_rave(
    RAVE: str, intp_non_avail_hours: List[str], intp_avail_hours: List[str]
) -> Tuple[List[List[str]], List[str], List[str], bool]:
    """
    Check if raw RAVE in intp_non_avail_hours list is available for interpolation.

    Args:
        RAVE: Directory containing the raw RAVE files
        intp_non_avail_hours: RAVE days/hours that are not available
        intp_avail_hours: RAVE day/hours that are available

    Returns:
        A tuple containing:
            * ``0``: Raw RAVE file paths that are available
            * ``1``: The days/hours of the available RAVE files
            * ``2``: The days/hours that are not available
            * ``3``: A boolean indicating if this is the first day of the forecast
    """
    rave_avail = []
    rave_avail_hours = []
    rave_nonavail_hours_test = []
    for date in intp_non_avail_hours:
        wildcard_name = f"*-3km*{date}*{date}59590*.nc"
        name_retro = f"*3km*{date}*{date}*.nc"
        matching_files = [
            f
            for f in os.listdir(RAVE)
            if fnmatch.fnmatch(f, wildcard_name) or fnmatch.fnmatch(f, name_retro)
        ]
        print(f"Find raw RAVE: {matching_files}")
        if not matching_files:
            print(f"Raw RAVE non_available for interpolation {date}")
            rave_nonavail_hours_test.append(date)
        else:
            print(f"Raw RAVE available for interpolation {matching_files}")
            rave_avail.append(matching_files)
            rave_avail_hours.append(date)

    print(
        f"Raw RAVE available: {rave_avail_hours}, rave_nonavail_hours: {rave_nonavail_hours_test}"
    )
    first_day = not rave_avail_hours and not intp_avail_hours

    print(f"FIRST DAY?: {first_day}")
    return rave_avail, rave_avail_hours, rave_nonavail_hours_test, first_day


def creates_st_fields(grid_in: str, grid_out: str) -> Tuple[
    ESMF.Field,
    ESMF.Field,
    DataArray,
    DataArray,
    ESMF.Grid,
    ESMF.Grid,
    DataArray,
    DataArray,
]:
    """
    Create source and target fields for regridding.

    Args:
        grid_in: Path to input grid
        grid_out: Path to output grid

    Returns:
        A tuple containing:
            * ``0``: Source ESMF field
            * ``1``: Destination ESMF field
            * ``2``: Destination latitudes
            * ``3``: Destination longitudes
            * ``4``: Source ESMF grid
            * ``5``: Destination ESMF grid
            * ``6``: Source latitude
            * ``7``: Destination area
    """
    # Open datasets with context managers
    with xr.open_dataset(grid_in) as ds_in, xr.open_dataset(grid_out) as ds_out:
        tgt_area = ds_out["area"]
        tgt_latt = ds_out["grid_latt"]
        tgt_lont = ds_out["grid_lont"]
        src_latt = ds_in["grid_latt"]

        srcgrid = ESMF.Grid(
            np.array(src_latt.shape),
            staggerloc=[ESMF.StaggerLoc.CENTER, ESMF.StaggerLoc.CORNER],
            coord_sys=ESMF.CoordSys.SPH_DEG,
        )
        tgtgrid = ESMF.Grid(
            np.array(tgt_latt.shape),
            staggerloc=[ESMF.StaggerLoc.CENTER, ESMF.StaggerLoc.CORNER],
            coord_sys=ESMF.CoordSys.SPH_DEG,
        )

        srcfield = ESMF.Field(srcgrid, name="test", staggerloc=ESMF.StaggerLoc.CENTER)
        tgtfield = ESMF.Field(tgtgrid, name="test", staggerloc=ESMF.StaggerLoc.CENTER)

    print("Grid in and out files available. Generating target and source fields")
    return (
        srcfield,
        tgtfield,
        tgt_latt,
        tgt_lont,
        srcgrid,
        tgtgrid,
        src_latt,
        tgt_area,
    )


def create_emiss_file(fout: Dataset, cols: int, rows: int) -> None:
    """
    Create necessary dimensions for the emission file.

    Args:
        fout: Dataset to update
        cols: Number of columns
        rows: Number of rows
    """
    fout.createDimension("t", None)
    fout.createDimension("lat", cols)
    fout.createDimension("lon", rows)
    setattr(fout, "PRODUCT_ALGORITHM_VERSION", "Beta")
    setattr(fout, "TIME_RANGE", "1 hour")


def Store_latlon_by_Level(
    fout: Dataset, varname: str, var: DataArray, long_name: str, units: str, fval: str
) -> None:
    """
    Store a 2D variable (latitude/longitude) in the file.

    Args:
        fout: Dataset to update
        varname: Variable name to create
        var: Variable data to store
        long_name: Variable long name
        units: Variable units
        fval: Variable fill value
    """
    var_out = fout.createVariable(varname, "f4", ("lat", "lon"))
    var_out.units = units
    var_out.long_name = long_name
    var_out.standard_name = varname
    fout.variables[varname][:] = var
    var_out.FillValue = fval
    var_out.coordinates = "geolat geolon"


def Store_by_Level(
    fout: Dataset, varname: str, long_name: str, units: str, fval: str
) -> None:
    """
    Store a 3D variable (time, latitude/longitude) in the file.

    Args:
        fout: Dataset to update
        varname: Name of the variable to create
        long_name: Long name of the variable to create
        units: Units of the variable to create
        fval: Fill value of the variable to create
    """
    var_out = fout.createVariable(varname, "f4", ("t", "lat", "lon"))
    var_out.units = units
    var_out.long_name = long_name
    var_out.standard_name = long_name
    var_out.FillValue = fval
    var_out.coordinates = "t geolat geolon"


def create_dummy(
    intp_dir: str,
    current_day: str,
    tgt_latt: DataArray,
    tgt_lont: DataArray,
    cols: int,
    rows: int,
) -> str:
    """
    Create a dummy RAVE interpolated file if first day or regridder fails.

    Args:
        intp_dir: Directory to create the dummy file in
        current_day: Current day (and hour?) to create the dummy file for
        tgt_latt: Target grid latitudes
        tgt_lont: Target grid longitudes
        cols: Number of columns
        rows: Number of rows

    Returns:
        A string stating the operation was successful.
    """
    file_path = os.path.join(intp_dir, f"SMOKE_RRFS_data_{current_day}00.nc")
    dummy_file = np.zeros((cols, rows))  # Changed to 3D to match the '3D' dimensions
    with Dataset(file_path, "w") as fout:
        create_emiss_file(fout, cols, rows)
        # Store latitude and longitude
        Store_latlon_by_Level(
            fout, "geolat", tgt_latt, "cell center latitude", "degrees_north", "-9999.f"
        )
        Store_latlon_by_Level(
            fout, "geolon", tgt_lont, "cell center longitude", "degrees_east", "-9999.f"
        )

        # Initialize and store each variable
        Store_by_Level(fout, "frp_davg", "Daily mean Fire Radiative Power", "MW", "0.f")
        fout.variables["frp_davg"][0, :, :] = dummy_file
        Store_by_Level(fout, "ebb_rate", "Total EBB emission", "ug m-2 s-1", "0.f")
        fout.variables["ebb_rate"][0, :, :] = dummy_file
        Store_by_Level(
            fout, "fire_end_hr", "Hours since fire was last detected", "hrs", "0.f"
        )
        fout.variables["fire_end_hr"][0, :, :] = dummy_file
        Store_by_Level(
            fout, "hwp_davg", "Daily mean Hourly Wildfire Potential", "none", "0.f"
        )
        fout.variables["hwp_davg"][0, :, :] = dummy_file
        Store_by_Level(fout, "totprcp_24hrs", "Sum of precipitation", "m", "0.f")
        fout.variables["totprcp_24hrs"][0, :, :] = dummy_file

    return "Emissions dummy file created successfully"


def generate_regridder(
    rave_avail_hours: List[str],
    srcfield: ESMF.Field,
    tgtfield: ESMF.Field,
    weightfile: str,
    intp_avail_hours: List[str],
) -> Tuple[Any, bool]:
    """
    Generate an ESMF regridder unless we are using dummy emissions.
    Args:
        rave_avail_hours: The RAVE hours that are available
        srcfield: The source ESMF field
        tgtfield: The destination ESMF field
        weightfile: The ESMF weight field mapping the RAVE grid to the forecast grid
        intp_avail_hours: The available interpolated hours

    Returns:
        A tuple containing:
            * ``0``: ESMF regridder or none (if using dummy emissions)
            * ``1``: Boolean flag indicating if dummy emissions are being used
    """
    print("Checking conditions for generating regridder.")
    use_dummy_emiss = len(rave_avail_hours) == 0 and len(intp_avail_hours) == 0
    regridder = None

    if not use_dummy_emiss:
        try:
            print("Generating regridder.")
            regridder = ESMF.RegridFromFile(srcfield, tgtfield, weightfile)
            print("Regridder generated successfully.")
        except ValueError as e:
            print(f"Regridder failed due to a ValueError: {e}.")
        except OSError as e:
            print(
                f"Regridder failed due to an OSError: {e}. Check if the weight file exists and is accessible."
            )
        except (
            FileNotFoundError,
            IOError,
            RuntimeError,
            TypeError,
            KeyError,
            IndexError,
            MemoryError,
        ) as e:
            print(
                f"Regridder failed due to corrupted file: {e}. Check if RAVE file has a different grid or format. "
            )
        except Exception as e:
            print(f"An unexpected error occurred while generating regridder: {e}.")
    else:
        use_dummy_emiss = True

    return regridder, use_dummy_emiss


def mask_edges(data: ndarray, mask_width: int = 1) -> ndarray:
    """
    Mask edges of domain for interpolation.

    Args:
        data: The numpy array to mask
        mask_width: The width of the mask at each edge

    Returns:
        A numpy array of the masked edges
    """
    original_shape = data.shape
    if mask_width < 1:
        return data  # No masking if mask_width is less than 1

    # Mask top and bottom rows
    data[:mask_width, :] = np.nan
    data[-mask_width:, :] = np.nan

    # Mask left and right columns
    data[:, :mask_width] = np.nan
    data[:, -mask_width:] = np.nan
    assert data.shape == original_shape, "Data shape altered during masking."

    return data


def interpolate_rave(
    RAVE: str,
    rave_avail: List[List[str]],
    rave_avail_hours: List[str],
    use_dummy_emiss: bool,
    vars_emis: List[str],
    regridder: Any,
    srcgrid: ESMF.Grid,
    tgtgrid: ESMF.Grid,
    rave_to_intp: str,
    intp_dir: str,
    tgt_latt: DataArray,
    tgt_lont: DataArray,
    cols: int,
    rows: int,
) -> None:
    """
    Process a RAVE file for interpolation.

    Args:
        RAVE: Path to the raw RAVE files
        rave_avail: List of RAVE days/hours that are available
        rave_avail_hours: List of RAVE hours that are available
        use_dummy_emiss: True if we are using dummy emissions
        vars_emis: Names of the emission variables
        regridder: The ESMF regridder object (i.e. route handle). This is None if we are using dummy emissions.
        srcgrid: The source ESMF grid
        tgtgrid: The destination ESMF grid
        rave_to_intp: The prefix of RAVE files to interpolate
        intp_dir: The RAVE directory containing interpolated files
        tgt_latt: The destination grid latitudes
        tgt_lont: The destination grid longitudes
        cols: Number of columns in the destination
        rows: Number of rows in the destination
    """
    for index, current_hour in enumerate(rave_avail_hours):
        file_name = rave_avail[index]
        rave_file_path = os.path.join(RAVE, file_name[0])

        print(f"Processing file: {rave_file_path} for hour: {current_hour}")

        if not use_dummy_emiss and os.path.exists(rave_file_path):
            try:
                with xr.open_dataset(rave_file_path, decode_times=False) as ds_togrid:
                    try:
                        ds_togrid = ds_togrid[["FRP_MEAN", "FRE"]]
                    except KeyError as e:
                        print(f"Missing required variables in {rave_file_path}: {e}")
                        continue

                    output_file_path = os.path.join(
                        intp_dir, f"{rave_to_intp}{current_hour}00_{current_hour}59.nc"
                    )
                    print("=============before regridding===========", "FRP_MEAN")
                    print(np.sum(ds_togrid["FRP_MEAN"], axis=(1, 2)))

                    try:
                        with Dataset(output_file_path, "w") as fout:
                            create_emiss_file(fout, cols, rows)
                            Store_latlon_by_Level(
                                fout,
                                "geolat",
                                tgt_latt,
                                "cell center latitude",
                                "degrees_north",
                                "-9999.f",
                            )
                            Store_latlon_by_Level(
                                fout,
                                "geolon",
                                tgt_lont,
                                "cell center longitude",
                                "degrees_east",
                                "-9999.f",
                            )

                            for svar in vars_emis:
                                try:
                                    srcfield = ESMF.Field(
                                        srcgrid,
                                        name=svar,
                                        staggerloc=ESMF.StaggerLoc.CENTER,
                                    )
                                    tgtfield = ESMF.Field(
                                        tgtgrid,
                                        name=svar,
                                        staggerloc=ESMF.StaggerLoc.CENTER,
                                    )
                                    src_rate = ds_togrid[svar].fillna(0)
                                    src_QA = xr.where(
                                        ds_togrid["FRE"] > 1000, src_rate, 0.0
                                    )
                                    srcfield.data[...] = src_QA[0, :, :]
                                    tgtfield = regridder(srcfield, tgtfield)
                                    masked_tgt_data = mask_edges(
                                        tgtfield.data, mask_width=1
                                    )

                                    if svar == "FRP_MEAN":
                                        Store_by_Level(
                                            fout,
                                            "frp_avg_hr",
                                            "Mean Fire Radiative Power",
                                            "MW",
                                            "0.f",
                                        )
                                        tgt_rate = masked_tgt_data
                                        fout.variables["frp_avg_hr"][0, :, :] = tgt_rate
                                        print(
                                            "=============after regridding==========="
                                            + svar
                                        )
                                        print(np.sum(tgt_rate))
                                    elif svar == "FRE":
                                        Store_by_Level(fout, "FRE", "FRE", "MJ", "0.f")
                                        tgt_rate = masked_tgt_data
                                        fout.variables["FRE"][0, :, :] = tgt_rate
                                except (ValueError, KeyError) as e:
                                    print(
                                        f"Error processing variable {svar} in {rave_file_path}: {e}"
                                    )
                    except (
                        OSError,
                        IOError,
                        RuntimeError,
                        FileNotFoundError,
                        TypeError,
                        IndexError,
                        MemoryError,
                    ) as e:
                        print(
                            f"Error creating or writing to NetCDF file {output_file_path}: {e}"
                        )
            except (
                OSError,
                IOError,
                RuntimeError,
                FileNotFoundError,
                TypeError,
                IndexError,
                MemoryError,
            ) as e:
                print(f"Error reading NetCDF file {rave_file_path}: {e}")
        else:
            print(f"File not found or dummy emissions required: {rave_file_path}")
