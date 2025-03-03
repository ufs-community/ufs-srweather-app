"""Implements the smoke/dust regrid processor."""

import logging
from copy import copy, deepcopy
from typing import Any

import esmpy
import numpy as np
import pandas as pd

from smoke_dust.core.common import (
    create_template_emissions_file,
    create_sd_variable,
    create_descriptive_statistics,
    open_nc,
)
from smoke_dust.core.context import RaveQaFilter, SmokeDustContext, PredefinedGrid
from smoke_dust.core.regrid.common import (
    GridSpec,
    GridWrapper,
    FieldWrapper,
    load_variable_data,
    NcToGrid,
    NcToField,
    mask_edges,
)
from smoke_dust.core.variable import SD_VARS


class SmokeDustRegridProcessor:
    """Regrids smoke/dust data to the forecast grid."""

    def __init__(self, context: SmokeDustContext):
        self._context = context
        self._esmpy_manager = esmpy.Manager(debug=self._context.esmpy_debug)

        # Holds interpolation descriptive statistics
        self._interpolation_stats = None

        # Caches regridding objects
        self.__src_gwrap = None
        self.__dst_gwrap = None
        self.__dst_output_gwrap = None
        self.__regridder = None

    def log(self, *args: Any, **kwargs: Any) -> None:
        """See ``SmokeDustContext.log``."""
        self._context.log(*args, **kwargs)

    def run(self, cycle_metadata: pd.DataFrame) -> None:
        """Run the regrid processor. This may be run in parallel using MPI."""
        # Select which RAVE files to interpolate
        rave_to_interpolate = cycle_metadata[
            cycle_metadata["rave_interpolated"].isnull() & ~cycle_metadata["rave_raw"].isnull()
        ]
        if len(rave_to_interpolate) == 0:
            self.log("all rave files have been interpolated")
            return

        self._run_impl_(cycle_metadata, rave_to_interpolate)

    @property
    def _src_gwrap(self) -> GridWrapper:
        if self.__src_gwrap is None:
            self.log("creating source grid from RAVE file")
            src_nc2grid = NcToGrid(
                path=self._context.grid_in,
                spec=GridSpec(
                    x_center="grid_lont",
                    y_center="grid_latt",
                    x_dim=("grid_xt",),
                    y_dim=("grid_yt",),
                    x_corner="grid_lon",
                    y_corner="grid_lat",
                    x_corner_dim=("grid_x",),
                    y_corner_dim=("grid_y",),
                ),
            )
            self.__src_gwrap = src_nc2grid.create_grid_wrapper()
        return self.__src_gwrap

    @property
    def _dst_gwrap(self) -> GridWrapper:
        if self.__dst_gwrap is None:
            self.log("creating destination grid from RRFS grid file")
            dst_nc2grid = NcToGrid(
                path=self._context.grid_out,
                spec=GridSpec(
                    x_center="grid_lont",
                    y_center="grid_latt",
                    x_dim=("grid_xt",),
                    y_dim=("grid_yt",),
                    x_corner="grid_lon",
                    y_corner="grid_lat",
                    x_corner_dim=("grid_x",),
                    y_corner_dim=("grid_y",),
                ),
            )
            self.__dst_gwrap = dst_nc2grid.create_grid_wrapper()
        return self.__dst_gwrap

    @property
    def _dst_output_gwrap(self) -> GridWrapper:
        if self.__dst_output_gwrap is None:
            # We are translating metadata and some structure for the destination grid.
            dst_output_gwrap = copy(self._dst_gwrap)
            dst_output_gwrap.corner_dims = None
            dst_output_gwrap.spec = GridSpec(
                x_center="geolon", y_center="geolat", x_dim=("lon",), y_dim=("lat",)
            )
            dst_output_gwrap.dims = deepcopy(self._dst_gwrap.dims)
            dst_output_gwrap.dims.value[0].name = ("lon",)
            dst_output_gwrap.dims.value[1].name = ("lat",)
            self.__dst_output_gwrap = dst_output_gwrap
        return self.__dst_output_gwrap

    def _get_regridder_(self, src_fwrap: FieldWrapper, dst_fwrap: FieldWrapper) -> esmpy.Regrid:
        if self.__regridder is None:
            self.log("creating regridder")
            self.log(f"{src_fwrap.value.data.shape=}", level=logging.DEBUG)
            self.log(f"{dst_fwrap.value.data.shape=}", level=logging.DEBUG)
            if (
                self._context.predef_grid == PredefinedGrid.RRFS_NA_13KM
                or self._context.regrid_in_memory
            ):
                # ESMF does not like reading the weights for this field combination (rc=-1). The
                # error can be bypassed by creating weights in-memory.
                self.log("creating regridding in-memory")
                regridder = esmpy.Regrid(
                    src_fwrap.value,
                    dst_fwrap.value,
                    regrid_method=esmpy.RegridMethod.CONSERVE,
                    unmapped_action=esmpy.UnmappedAction.IGNORE,
                    ignore_degenerate=True,
                    # Can be used to create a weight file for testing
                    # filename="/opt/project/weight_file.nc"
                )
            else:
                self.log("creating regridding from file")
                regridder = esmpy.RegridFromFile(
                    src_fwrap.value,
                    dst_fwrap.value,
                    filename=str(self._context.weightfile),
                )
            self.__regridder = regridder
        return self.__regridder

    def _run_impl_(self, cycle_metadata: pd.DataFrame, rave_to_interpolate: pd.Series) -> None:
        for row_idx, row_data in rave_to_interpolate.iterrows():
            row_dict = row_data.to_dict()
            self.log(f"processing RAVE interpolation row: {row_idx}, {row_dict}")

            forecast_date = row_data["forecast_date"]
            output_file_path = (
                self._context.intp_dir
                / f"{self._context.rave_to_intp}{forecast_date}00_{forecast_date}59.nc"
            )
            self.log(f"creating output file: {output_file_path}")
            with open_nc(output_file_path, "w") as nc_ds:
                create_template_emissions_file(nc_ds, self._context.grid_out_shape)
                for varname in ["frp_avg_hr", "FRE"]:
                    create_sd_variable(nc_ds, SD_VARS.get(varname))

            self._dst_output_gwrap.fill_nc_variables(output_file_path)

            for field_name in self._context.vars_emis:
                match field_name:
                    case "FRP_MEAN":
                        dst_field_name = "frp_avg_hr"
                    case "FRE":
                        dst_field_name = "FRE"
                    case _:
                        raise NotImplementedError(field_name)

                self.log("creating destination field", level=logging.DEBUG)
                dst_nc2field = NcToField(
                    path=output_file_path,
                    name=dst_field_name,
                    gwrap=self._dst_output_gwrap,
                    dim_time=("t",),
                )
                dst_fwrap = dst_nc2field.create_field_wrapper()

                self.log("creating source field", level=logging.DEBUG)
                src_nc2field = NcToField(
                    path=row_data["rave_raw"],
                    name=field_name,
                    gwrap=self._src_gwrap,
                    dim_time=("time",),
                )
                src_fwrap = src_nc2field.create_field_wrapper()

                src_data = src_fwrap.value.data
                match field_name:
                    case "FRP_MEAN":
                        src_data[:] = np.where(src_data == -1.0, 0.0, src_data)
                    case "FRE":
                        src_data[:] = np.where(src_data > 1000.0, src_data, 0.0)
                    case _:
                        raise NotImplementedError(field_name)

                if self._context.rave_qa_filter == RaveQaFilter.HIGH:
                    with open_nc(row_data["rave_raw"], parallel=True) as rave_ds:
                        rave_qa = load_variable_data(
                            rave_ds.variables["QA"],  # pylint: disable=unsubscriptable-object
                            src_fwrap.dims,
                        )
                    set_to_zero = rave_qa < 2
                    self.log(
                        f"RAVE QA filter applied: {self._context.rave_qa_filter=}; "
                        f"{set_to_zero.size=}; {np.sum(set_to_zero)=}"
                    )
                    src_data[set_to_zero] = 0.0
                else:
                    if self._context.rave_qa_filter != RaveQaFilter.NONE:
                        raise NotImplementedError

                # Execute the ESMF regridding
                self.log("run regridding", level=logging.DEBUG)
                regridder = self._get_regridder_(src_fwrap, dst_fwrap)
                _ = regridder(src_fwrap.value, dst_fwrap.value)

                # Persist the destination field
                self.log("filling netcdf", level=logging.DEBUG)
                dst_fwrap.fill_nc_variable(output_file_path)

            # Update the forecast metadata with the interpolated RAVE file data
            cycle_metadata.loc[row_idx, "rave_interpolated"] = output_file_path
            row_data["rave_interpolated"] = output_file_path

            if self._context.rank == 0:
                self._regrid_postprocessing_(row_data)

        if (
            self._context.rank == 0
            and self._context.should_calc_desc_stats
            and self._interpolation_stats is not None
        ):
            cycle_dates = cycle_metadata["forecast_date"]
            stats_path = (
                self._context.intp_dir
                / f"stats_regridding_{cycle_dates.min()}_{cycle_dates.max()}.csv"
            )
            self.log(f"writing interpolation statistics: {stats_path=}")
            self._interpolation_stats.to_csv(stats_path, index=False)

    def _regrid_postprocessing_(self, row_data: pd.Series) -> None:
        self.log("_run_interpolation_postprocessing: enter", level=logging.DEBUG)

        calc_stats = self._context.should_calc_desc_stats

        field_names_dst = [
            "frp_avg_hr",
            "FRE",
        ]
        with open_nc(row_data["rave_interpolated"], parallel=False) as nc_ds:
            dst_data = {ii: nc_ds.variables[ii][:] for ii in field_names_dst}
        if calc_stats:
            # Do these calculations before we modify the arrays since edge masking is inplace
            dst_desc_unmasked = create_descriptive_statistics(dst_data, "dst_unmasked", None)

        # Mask edges to reduce model edge effects
        self.log("masking edges", level=logging.DEBUG)
        for value in dst_data.values():
            # Operation is inplace
            mask_edges(value[0, :, :])

        # Persist masked data to disk
        with open_nc(row_data["rave_interpolated"], parallel=False, mode="a") as nc_ds:
            for key, value in dst_data.items():
                nc_ds.variables[key][:] = value

        if calc_stats:
            with open_nc(row_data["rave_raw"], parallel=False) as nc_ds:
                src_desc = create_descriptive_statistics(
                    {ii: nc_ds.variables[ii][:] for ii in self._context.vars_emis},
                    "src",
                    row_data["rave_raw"],
                )
                src_desc.rename(columns={"FRP_MEAN": "frp_avg_hr"}, inplace=True)
            dst_desc_masked = create_descriptive_statistics(
                dst_data, "dst_masked", row_data["rave_interpolated"]
            )
            summary = pd.concat(
                [ii.transpose() for ii in [src_desc, dst_desc_unmasked, dst_desc_masked]]
            )
            summary.index.name = "variable"
            summary["forecast_date"] = row_data["forecast_date"]
            summary.reset_index(inplace=True)
            if self._interpolation_stats is None:
                self._interpolation_stats = summary
            else:
                self._interpolation_stats = pd.concat([self._interpolation_stats, summary])

        self.log("_run_interpolation_postprocessing: exit", level=logging.DEBUG)
