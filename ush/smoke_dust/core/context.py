"""Context object for smoke/dust holding external and derived parameters."""

import datetime as dt
import logging
import logging.config
import os
from enum import unique, StrEnum
from pathlib import Path
from typing import Union, Annotated, Any

from mpi4py import MPI
from pydantic import BaseModel, model_validator, BeforeValidator, Field

from smoke_dust.core.common import open_nc, create_template_emissions_file, create_sd_variable
from smoke_dust.core.variable import SD_VARS


@unique
class PredefinedGrid(StrEnum):
    """Predefined grids supported by smoke/dust."""

    RRFS_CONUS_25KM = "RRFS_CONUS_25km"
    RRFS_CONUS_13KM = "RRFS_CONUS_13km"
    RRFS_CONUS_3KM = "RRFS_CONUS_3km"
    RRFS_NA_3KM = "RRFS_NA_3km"
    RRFS_NA_13KM = "RRFS_NA_13km"


@unique
class EbbDCycle(StrEnum):
    """Emission forecast cycle method.

    * ``1``: Estimate emissions and fire radiative power.
    * ``2``: In addition to `1`, also create inputs to forecast hourly wildfire potential.
    """

    ONE = "1"
    TWO = "2"


@unique
class RaveQaFilter(StrEnum):
    """
    Quality assurance flag filtering to apply to input RAVE data. RAVE QA filter values range from
    one to three.

    * ``none``: Do not apply any QA filtering.
    * ``high``: QA flag values less than `2` are set to zero for derived fire radiative energy
        fields.
    """

    NONE = "none"
    HIGH = "high"


@unique
class LogLevel(StrEnum):
    """Logging level for the preprocessor."""

    INFO = "info"
    DEBUG = "debug"


@unique
class EmissionVariable(StrEnum):
    """Maps RAVE and smoke/dust variable names."""

    FRE = "FRE"
    FRP = "FRP"

    def rave_name(self) -> str:
        """Convert to a RAVE name."""
        other = {self.FRP: "FRP_MEAN", self.FRE: "FRE"}
        return other[self]

    def smoke_dust_name(self) -> str:
        """Convert to a smoke/dust name."""
        other = {self.FRP: "frp_avg_hr", self.FRE: "FRE"}
        return other[self]


def _format_path_(value: Union[Path, str]) -> Path:
    return Path(value).expanduser().resolve(strict=True)


def _format_read_path_(value: Union[Path, str]) -> Path:
    path = _format_path_(value)
    errors = []
    if not path.exists():
        errors.append(f"path does not exist: {path}")
    if not os.access(path, os.R_OK):
        errors.append(f"path is not readable: {path}")
    if not path.is_dir():
        errors.append(f"path is not a directory: {path}")
    if len(errors) > 0:
        raise OSError(errors)
    return path


def _format_write_path_(value: Union[Path, str]) -> Path:
    path = _format_path_(value)
    errors = []
    if not path.exists():
        errors.append(f"path does not exist: {path}")
    if not os.access(path, os.W_OK):
        errors.append(f"path is not writable: {path}")
    if not path.is_dir():
        errors.append(f"path is not a directory: {path}")
    if len(errors) > 0:
        raise OSError(errors)
    return path


def _format_restart_interval_(value: Any) -> tuple[int, ...]:
    if isinstance(value, str):
        return tuple(int(num) for num in value.split(" "))
    return value


ReadPathType = Annotated[Path, BeforeValidator(_format_read_path_)]
WritePathType = Annotated[Path, BeforeValidator(_format_write_path_)]


class SmokeDustContext(BaseModel):
    """Context object for smoke/dust."""

    # Values provided via command-line
    staticdir: ReadPathType = Field(description="Path to smoke and dust fixed files.")
    ravedir: ReadPathType = Field(
        description="Path to the directory containing RAVE data files (hourly)."
    )
    intp_dir: WritePathType = Field(
        description="Path to the directory containing interpolated RAVE data files."
    )
    predef_grid: PredefinedGrid = Field(
        description="SRW predefined grid to use as the forecast domain."
    )
    ebb_dcycle: EbbDCycle = Field(description="The forecast cycle to run.")
    restart_interval: Annotated[tuple[int, ...], BeforeValidator(_format_restart_interval_)] = (
        Field(
            description="Restart intervals used for restart file search. For example '6 12 18 24'."
        )
    )
    persistence: bool = Field(
        description="If true, use satellite observations from the previous day. Otherwise, use "
        "observations from the same day."
    )
    rave_qa_filter: RaveQaFilter = Field(
        description="Filter level for RAVE QA flags when regridding fields."
    )
    exit_on_error: bool = Field(
        description="If false, log errors and write a dummy emissions file but do not raise an "
        "exception."
    )
    log_level: LogLevel = Field(description="Logging level for the preprocessor")
    regrid_in_memory: bool = Field(
        description="If true, do esmpy regridding in-memory as opposed to reading from the fixed "
        "weight file.",
        default=False,
    )

    # Values provided via environment
    current_day: str = Field(description="The forecast date for the start of the cycle.")
    nwges_dir: ReadPathType = Field(description="Directory containing restart files.")

    # Fixed parameters
    should_calc_desc_stats: bool = False
    vars_emis: tuple[str] = ("FRP_MEAN", "FRE")
    beta: float = 0.3
    fg_to_ug: float = 1e6
    to_s: int = 3600
    rank: int = MPI.COMM_WORLD.Get_rank()
    esmpy_debug: bool = False
    allow_dummy_restart: bool = True

    # Set in _finalize_model_
    grid_out_shape: tuple[int, int] = (0, 0)
    _logger: Union[logging.Logger, None] = None

    @model_validator(mode="before")
    @classmethod
    def _initialize_values_(cls, values: dict) -> dict:

        # Format environment-level variables
        values["current_day"] = os.environ["CDATE"]
        values["nwges_dir"] = os.environ["COMIN_SMOKE_DUST_COMMUNITY"]

        return values

    @model_validator(mode="after")
    def _finalize_model_(self) -> "SmokeDustContext":
        self._logger = self._init_logging_()

        with open_nc(self.grid_out, parallel=False) as nc_ds:
            # pylint: disable=unsubscriptable-object
            self.grid_out_shape = (
                nc_ds.dimensions["grid_yt"].size,
                nc_ds.dimensions["grid_xt"].size,
            )
            # pylint: enable=unsubscriptable-object
        self.log(f"{self.grid_out_shape=}")
        return self

    @property
    def veg_map(self) -> Path:
        """Path to the vegetation map netCDF file which contains emission factors."""
        return self.staticdir / "veg_map.nc"

    @property
    def rave_to_intp(self) -> str:
        """File prefix for interpolated RAVE files."""
        return self.predef_grid.value + "_intp_"  # pylint: disable=no-member

    @property
    def grid_in(self) -> Path:
        """Path to the grid definition for RAVE data."""
        return self.staticdir / "grid_in.nc"

    @property
    def weightfile(self) -> Path:
        """Path to pre-calculated ESMF weights file mapping the RAVE grid to forecast grid."""
        return self.staticdir / "weight_file.nc"

    @property
    def grid_out(self) -> Path:
        """Path to the forecast grid definition."""
        return self.staticdir / "ds_out_base.nc"

    @property
    def hourly_hwpdir(self) -> Path:
        """Path to the root directory containing restart files."""
        assert isinstance(self.nwges_dir, Path)
        return self.nwges_dir.parent  # pylint: disable=no-member

    @property
    def emissions_path(self) -> Path:
        """Path to the output emissions files containing ICs for smoke/dust."""
        return self.intp_dir / f"SMOKE_RRFS_data_{self.current_day}00.nc"

    @property
    def fcst_datetime(self) -> dt.datetime:
        """The starting datetime object parsed from the `current_day`."""
        return dt.datetime.strptime(self.current_day, "%Y%m%d%H")

    def log(
        self,
        msg,
        level=logging.INFO,
        exc_info: Exception = None,
        stacklevel: int = 2,
    ):
        """
        Log a message.

        Args:
            msg: The message to log.
            level: An optional override for the message level.
            exc_info: If provided, log this exception and raise an error if `self.exit_on_error`
                is `True`.
            stacklevel: If greater than 1, the corresponding number of stack frames are skipped
                when computing the line number and function name.
        """
        if exc_info is not None:
            level = logging.ERROR
        self._logger.log(level, msg, exc_info=exc_info, stacklevel=stacklevel)
        if exc_info is not None and self.exit_on_error:
            raise exc_info

    def create_dummy_emissions_file(self) -> None:
        """Create a dummy emissions file. This occurs if it is the first day of the forecast or
        there is an exception and the context is set to not exit on error."""
        self.log("create_dummy_emissions_file: enter")
        self.log(f"{self.emissions_path=}")
        with open_nc(self.emissions_path, "w", parallel=False, clobber=True) as nc_ds:
            create_template_emissions_file(nc_ds, self.grid_out_shape, is_dummy=True)
            with open_nc(self.grid_out, parallel=False) as ds_src:
                # pylint: disable=unsubscriptable-object
                nc_ds.variables["geolat"][:] = ds_src.variables["grid_latt"][:]
                nc_ds.variables["geolon"][:] = ds_src.variables["grid_lont"][:]
                # pylint: enable=unsubscriptable-object

            for varname in [
                "frp_davg",
                "ebb_rate",
                "fire_end_hr",
                "hwp_davg",
                "totprcp_24hrs",
            ]:
                create_sd_variable(nc_ds, SD_VARS.get(varname))
        self.log("create_dummy_emissions_file: exit")

    def _init_logging_(self) -> logging.Logger:
        project_name = "smoke-dust-preprocessor"

        logging_config: dict = {
            "version": 1,
            "disable_existing_loggers": False,
            "formatters": {
                "plain": {
                    # pylint: disable=line-too-long
                    # Uncomment to report verbose output in logs; try to keep these two in sync
                    # "format": f"[%(name)s][%(levelname)s][%(asctime)s][%(pathname)s:%(lineno)d][%(process)d][%(thread)d][rank={self._rank}]: %(message)s"
                    "format": f"[%(name)s][%(levelname)s][%(asctime)s][%(filename)s:%(lineno)d][rank={self.rank}]: %(message)s"
                    # pylint: enable=line-too-long
                },
            },
            "handlers": {
                "default": {
                    "formatter": "plain",
                    "class": "logging.StreamHandler",
                    "stream": "ext://sys.stdout",
                    "filters": [],
                },
            },
            "loggers": {
                project_name: {
                    "handlers": ["default"],
                    "level": getattr(
                        logging, self.log_level.value.upper()  # pylint: disable=no-member
                    ),
                },
            },
        }
        logging.config.dictConfig(logging_config)
        return logging.getLogger(project_name)
