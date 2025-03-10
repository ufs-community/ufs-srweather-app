"""Forecast cycle definitions for smoke/dust."""

import abc
import datetime as dt
import fnmatch
import glob
import logging
from pathlib import Path
from typing import Any

import numpy as np
import pandas as pd
import xarray as xr
from pydantic import BaseModel, field_validator

from smoke_dust.core.common import (
    open_nc,
    create_sd_variable,
    create_template_emissions_file,
)
from smoke_dust.core.context import SmokeDustContext, EmissionVariable, EbbDCycle
from smoke_dust.core.variable import SD_VARS


class AverageFrpOutput(BaseModel):
    """Output expected from the ``average_frp`` method."""

    model_config = {"arbitrary_types_allowed": True}
    data: dict[str, np.ndarray]

    @field_validator("data", mode="before")
    @classmethod
    def _validate_data_(cls, value: dict[str, np.ndarray]) -> dict[str, np.ndarray]:
        if set(value.keys()) != {"frp_avg_hr", "ebb_smoke_hr"}:
            raise ValueError
        return value


class AbstractSmokeDustCycleProcessor(abc.ABC):
    """Base class for all smoke/dust cycle processors."""

    def __init__(self, context: SmokeDustContext):
        self._context = context

        # On-demand/cached property values
        self._cycle_metadata = None
        self._cycle_dates = None

    @property
    def cycle_dates(self) -> pd.DatetimeIndex:
        """Create the forecast dates for cycle."""
        if self._cycle_dates is not None:
            return self._cycle_dates
        start_datetime = self.create_start_datetime()
        self.log(f"{start_datetime=}")
        cycle_dates = pd.date_range(start=start_datetime, periods=24, freq="h").strftime("%Y%m%d%H")
        self._cycle_dates = cycle_dates
        return self._cycle_dates

    @property
    def cycle_metadata(self) -> pd.DataFrame:
        """Create forecast metadata consisting of:

        * ``forecast_date``: The forecast timestep as a `datetime` object.
        * ``rave_interpolated``: To the date's corresponding interpolated RAVE file. Null if not
            found.
        * ``rave_raw``: Raw RAVE data before interpolation. Null if not found.
        """
        if self._cycle_metadata is not None:
            return self._cycle_metadata

        # Collect metadata on data files related to forecast dates
        self.log("creating forecast metadata")
        intp_path = []
        rave_to_forecast = []
        for date in self.cycle_dates:
            # Check for pre-existing interpolated RAVE data
            file_path = (
                Path(self._context.intp_dir) / f"{self._context.rave_to_intp}{date}00_{date}59.nc"
            )
            if file_path.exists() and file_path.is_file():
                try:
                    resolved = file_path.resolve(strict=True)
                except FileNotFoundError:
                    continue
                else:
                    intp_path.append(resolved)
            else:
                intp_path.append(None)

            # Check for raw RAVE data
            wildcard_name = f"*-3km*{date}*{date}59590*.nc"
            name_retro = f"*3km*{date}*{date}*.nc"
            found = False
            for rave_path in self._context.ravedir.iterdir():
                if fnmatch.fnmatch(str(rave_path), wildcard_name) or fnmatch.fnmatch(
                    str(rave_path), name_retro
                ):
                    rave_to_forecast.append(rave_path)
                    found = True
                    break
            if not found:
                rave_to_forecast.append(None)

        self.log(f"{self.cycle_dates}", level=logging.DEBUG)
        self.log(f"{intp_path=}", level=logging.DEBUG)
        self.log(f"{rave_to_forecast=}", level=logging.DEBUG)
        data_frame = pd.DataFrame(
            data={
                "forecast_date": self.cycle_dates,
                "rave_interpolated": intp_path,
                "rave_raw": rave_to_forecast,
            }
        )
        self._cycle_metadata = data_frame
        return data_frame

    def log(self, *args: Any, **kwargs: Any) -> None:
        """
        See ``SmokeDustContext.log``.
        """
        self._context.log(*args, **kwargs)

    @abc.abstractmethod
    def flag(self) -> EbbDCycle:
        """
        The cycle flag associated with the processor.
        """

    @abc.abstractmethod
    def create_start_datetime(self) -> dt.datetime:
        """
        Creates the cycle's start datetime. Used when searching for RAVE files to use for the
        forecast.
        """

    @abc.abstractmethod
    def average_frp(self) -> AverageFrpOutput:
        """
        Calculate fire radiative power and smoke emissions from biomass burning.

        Returns:
            Fire radiative power and smoke emissions.
        """

    @abc.abstractmethod
    def run(self) -> None:
        """
        Create smoke/dust ICs emissions file.
        """

    def finalize(self) -> None:
        """Optional override for subclasses."""


class SmokeDustCycleOne(AbstractSmokeDustCycleProcessor):
    """Creates ICs consisting of fire radiative power and smoke emissions from biomass burning."""

    flag = EbbDCycle.ONE

    def create_start_datetime(self) -> dt.datetime:
        if self._context.persistence:
            self.log(
                "Creating emissions for persistence method where satellite FRP persist from "
                "previous day"
            )
            start_datetime = self._context.fcst_datetime - dt.timedelta(days=1)
        else:
            self.log("Creating emissions using current date satellite FRP")
            start_datetime = self._context.fcst_datetime
        return start_datetime

    def run(self) -> None:
        derived = self.average_frp()
        self.log(f"creating 24-hour emissions file: {self._context.emissions_path}")
        with open_nc(self._context.emissions_path, "w", parallel=False, clobber=True) as ds_out:
            create_template_emissions_file(ds_out, self._context.grid_out_shape)
            with open_nc(self._context.grid_out, parallel=False) as ds_src:
                ds_out.variables["geolat"][:] = ds_src.variables["grid_latt"][:]
                ds_out.variables["geolon"][:] = ds_src.variables["grid_lont"][:]
            for var_name, fill_array in derived.data.items():
                create_sd_variable(ds_out, SD_VARS.get(var_name))
                ds_out.variables[var_name][:] = fill_array

    def average_frp(self) -> AverageFrpOutput:
        ebb_smoke_total = []
        frp_avg_hr = []

        with xr.open_dataset(self._context.veg_map) as nc_ds:
            emiss_factor = nc_ds["emiss_factor"].values
        with xr.open_dataset(self._context.grid_out) as nc_ds:
            target_area = nc_ds["area"].values

        for row_idx, row_df in self.cycle_metadata.iterrows():
            self.log(f"processing emissions: {row_idx}, {row_df.to_dict()}")
            with xr.open_dataset(row_df["rave_interpolated"]) as nc_ds:
                fre = nc_ds[EmissionVariable.FRE.smoke_dust_name()][0, :, :].values
                frp = nc_ds[EmissionVariable.FRP.smoke_dust_name()][0, :, :].values

            frp_avg_hr.append(frp)
            ebb_hourly = (fre * emiss_factor * self._context.beta * self._context.fg_to_ug) / (
                target_area * self._context.to_s
            )
            ebb_smoke_total.append(np.where(frp > 0, ebb_hourly, 0))

        frp_avg_reshaped = np.stack(frp_avg_hr, axis=0)
        ebb_total_reshaped = np.stack(ebb_smoke_total, axis=0)

        np.nan_to_num(frp_avg_reshaped, copy=False, nan=0.0)

        return AverageFrpOutput(
            data={
                "frp_avg_hr": frp_avg_reshaped,
                "ebb_smoke_hr": ebb_total_reshaped,
            }
        )


class SmokeDustCycleTwo(AbstractSmokeDustCycleProcessor):
    """
    In addition to outputs from cycle `1`, also creates ICs for forecasting hourly wildfire
    potential.
    """

    flag = EbbDCycle.TWO
    expected_restart_varnames = ("totprcp_ave", "rrfs_hwp_ave")

    def create_start_datetime(self) -> dt.datetime:
        self.log("Creating emissions for modulated persistence by Wildfire potential")
        return self._context.fcst_datetime - dt.timedelta(days=1, hours=1)

    def run(self) -> None:
        # pylint: disable=too-many-statements
        self.log("run: enter")

        cycle_metadata = self.cycle_metadata
        hwp_ave = []
        totprcp = np.zeros(self._context.grid_out_shape).ravel()

        phy_data_paths = list(self._find_restart_files_())
        if len(phy_data_paths) == 0:
            if self._context.allow_dummy_restart:
                self.log(
                    "restart files not found and dummy restart allowed. creating_dummy_emissions",
                    level=logging.WARN,
                )
                if self._context.rank == 0:
                    self._context.create_dummy_emissions_file()
                return
            raise FileNotFoundError("no restart files found")

        for phy_data_path in phy_data_paths:
            self.log(f"processing emissions for: {phy_data_path=}")
            with xr.open_dataset(phy_data_path) as nc_ds:
                hwp_values = nc_ds.rrfs_hwp_ave.values.ravel()
                tprcp_values = nc_ds.totprcp_ave.values.ravel()
                totprcp += np.where(tprcp_values > 0, tprcp_values, 0)
                hwp_ave.append(hwp_values)
        hwp_ave_arr = np.nanmean(hwp_ave, axis=0).reshape(*self._context.grid_out_shape)
        totprcp_ave_arr = totprcp.reshape(*self._context.grid_out_shape)
        xarr_hwp = xr.DataArray(hwp_ave_arr)
        xarr_totprcp = xr.DataArray(totprcp_ave_arr)

        derived = self.average_frp()

        t_fire = np.zeros(self._context.grid_out_shape)
        for date in cycle_metadata["forecast_date"]:
            rave_path = self._context.intp_dir / f"{self._context.rave_to_intp}{date}00_{date}59.nc"
            with xr.open_dataset(rave_path) as nc_ds:
                frp = nc_ds.frp_avg_hr[0, :, :].values
            dates_filtered = np.where(frp > 0, int(date[:10]), 0)
            t_fire = np.maximum(t_fire, dates_filtered)
        t_fire_flattened = [int(i) if i != 0 else 0 for i in t_fire.flatten()]
        hr_ends = [
            dt.datetime.strptime(str(hr), "%Y%m%d%H") if hr != 0 else 0 for hr in t_fire_flattened
        ]
        temp_fire_age = np.array(
            [
                ((self._context.fcst_datetime - i).total_seconds() / 3600 if i != 0 else 0)
                for i in hr_ends
            ]
        )
        fire_age = np.array(temp_fire_age).reshape(self._context.grid_out_shape)

        # Ensure arrays are not negative or NaN
        frp_avg_reshaped = np.clip(derived.data["frp_avg_hr"], 0, None)
        frp_avg_reshaped = np.nan_to_num(frp_avg_reshaped)

        ebb_tot_reshaped = np.clip(derived.data["ebb_smoke_hr"], 0, None)
        ebb_tot_reshaped = np.nan_to_num(ebb_tot_reshaped)

        fire_age = np.clip(fire_age, 0, None)
        fire_age = np.nan_to_num(fire_age)

        # Filter HWP Prcp arrays to be non-negative and replace NaNs
        filtered_hwp = xarr_hwp.where(frp_avg_reshaped > 0, 0).fillna(0)
        filtered_prcp = xarr_totprcp.where(frp_avg_reshaped > 0, 0).fillna(0)

        # Filter based on ebb_rate
        ebb_rate_threshold = 0  # Define an appropriate threshold if needed
        mask = ebb_tot_reshaped > ebb_rate_threshold

        filtered_hwp = filtered_hwp.where(mask, 0).fillna(0)
        filtered_prcp = filtered_prcp.where(mask, 0).fillna(0)
        frp_avg_reshaped = frp_avg_reshaped * mask
        ebb_tot_reshaped = ebb_tot_reshaped * mask
        fire_age = fire_age * mask

        self.log(f"creating emissions file: {self._context.emissions_path}")
        with open_nc(self._context.emissions_path, "w", parallel=False) as ds_out:
            create_template_emissions_file(ds_out, self._context.grid_out_shape)
            with open_nc(self._context.grid_out, parallel=False) as ds_src:
                ds_out.variables["geolat"][:] = ds_src.variables["grid_latt"][:]
                ds_out.variables["geolon"][:] = ds_src.variables["grid_lont"][:]

            var_map = {
                "frp_davg": frp_avg_reshaped,
                "ebb_rate": ebb_tot_reshaped,
                "fire_end_hr": fire_age,
                "hwp_davg": filtered_hwp,
                "totprcp_24hrs": filtered_prcp,
            }
            for varname, fill_array in var_map.items():
                create_sd_variable(ds_out, SD_VARS.get(varname))
                ds_out.variables[varname][0, :, :] = fill_array

        self.log("run: exit")
        # pylint: enable=too-many-statements

    def average_frp(self) -> AverageFrpOutput:
        self.log("average_frp: entering")

        frp_daily = np.zeros(self._context.grid_out_shape).ravel()
        ebb_smoke_total = []

        with xr.open_dataset(self._context.veg_map) as nc_ds:
            emiss_factor = nc_ds["emiss_factor"].values
        with xr.open_dataset(self._context.grid_out) as nc_ds:
            target_area = nc_ds["area"].values

        for row_idx, row_df in self.cycle_metadata.iterrows():
            self.log(f"processing emissions: {row_idx}, {row_df.to_dict()}")
            with xr.open_dataset(row_df["rave_interpolated"]) as nc_ds:
                fre = nc_ds[EmissionVariable.FRE.smoke_dust_name()][0, :, :].values
                frp = nc_ds[EmissionVariable.FRP.smoke_dust_name()][0, :, :].values

            ebb_hourly = (
                fre * emiss_factor * self._context.beta * self._context.fg_to_ug / target_area
            )
            ebb_smoke_total.append(np.where(frp > 0, ebb_hourly, 0).ravel())
            frp_daily += np.where(frp > 0, frp, 0).ravel()

        summed_array = np.sum(np.array(ebb_smoke_total), axis=0)
        num_zeros = len(ebb_smoke_total) - np.sum([arr == 0 for arr in ebb_smoke_total], axis=0)
        safe_zero_count = np.where(num_zeros == 0, 1, num_zeros)
        result_array = np.array(
            [
                (
                    summed_array[i] / 2
                    if safe_zero_count[i] == 1
                    else summed_array[i] / safe_zero_count[i]
                )
                for i in range(len(safe_zero_count))
            ]
        )
        result_array[num_zeros == 0] = summed_array[num_zeros == 0]
        ebb_total = result_array.reshape(self._context.grid_out_shape)
        ebb_total_reshaped = ebb_total / 3600
        temp_frp = np.array(
            [
                (frp_daily[i] / 2 if safe_zero_count[i] == 1 else frp_daily[i] / safe_zero_count[i])
                for i in range(len(safe_zero_count))
            ]
        )
        temp_frp[num_zeros == 0] = frp_daily[num_zeros == 0]
        frp_avg_reshaped = temp_frp.reshape(*self._context.grid_out_shape)

        np.nan_to_num(frp_avg_reshaped, copy=False, nan=0.0)

        self.log("average_frp: exiting")
        return AverageFrpOutput(
            data={
                "frp_avg_hr": frp_avg_reshaped,
                "ebb_smoke_hr": ebb_total_reshaped,
            }
        )

    def _find_restart_files_(
        self,
    ) -> tuple[Path, ...]:
        root_dir = self._context.hourly_hwpdir
        self.log(f"_find_restart_files_: {root_dir=}")
        potential_restart_files = [
            f"{cycle[:8]}.{cycle[8:10]}0000.phy_data.nc" for cycle in self.cycle_dates
        ]
        self.log(f"_find_restart_files_: {potential_restart_files=}")
        potential_restart_dirs = [root_dir / cycle / "RESTART" for cycle in self.cycle_dates]
        restart_dirs = [
            restart_dir for restart_dir in potential_restart_dirs if restart_dir.exists()
        ]
        self.log(f"_find_restart_files_: {restart_dirs=}")
        found_potentials = []
        restart_files = []
        for restart_dir in restart_dirs:
            filenames = glob.glob("**/*phy_data*nc", root_dir=restart_dir, recursive=True)
            for filename in filenames:
                self.log(f"_find_restart_files_: {filename=}", level=logging.DEBUG)
                path = restart_dir / filename
                if path.name in potential_restart_files and path.name not in found_potentials:
                    try:
                        resolved = path.resolve(strict=True)
                    except FileNotFoundError:
                        self.log(f"restart file link not resolvable: {path=}", level=logging.WARN)
                        continue
                    with open_nc(resolved, parallel=False) as nc_ds:
                        variables = nc_ds.variables.keys()  # pylint: disable=no-member
                        if all(
                            expected_var in variables
                            for expected_var in self.expected_restart_varnames
                        ):
                            self.log(
                                f"_find_restart_files_: found restart path {path=}",
                                level=logging.DEBUG,
                            )
                            restart_files.append(path)
                            found_potentials.append(path.name)
        return tuple(restart_files)


def create_cycle_processor(
    context: SmokeDustContext,
) -> AbstractSmokeDustCycleProcessor:
    """
    Factory function to create the smoke/dust cycle processor.
    """
    match context.ebb_dcycle:
        case EbbDCycle.ONE:
            return SmokeDustCycleOne(context)
        case EbbDCycle.TWO:
            return SmokeDustCycleTwo(context)
        case _:
            raise NotImplementedError(context.ebb_dcycle)
