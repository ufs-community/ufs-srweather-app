"""Smoke/dust preprocessor core implementation."""

from typing import Any

import pandas as pd

from smoke_dust.core.context import SmokeDustContext
from smoke_dust.core.cycle import create_cycle_processor
from smoke_dust.core.regrid.processor import SmokeDustRegridProcessor


class SmokeDustPreprocessor:
    """Implements smoke/dust preprocessing such as regridding and IC value calculations."""

    def __init__(self, context: SmokeDustContext) -> None:
        self._context = context
        self.log("__init__: enter")

        # Processes regridding from source data to destination analysis grid
        self._regrid_processor = SmokeDustRegridProcessor(context)
        # Processes cycle-specific data transformations
        self._cycle_processor = create_cycle_processor(context)

        self.log(f"{self._context=}")
        self.log("__init__: exit")

    def log(self, *args: Any, **kwargs: Any) -> None:
        """See ``SmokeDustContext.log``."""
        self._context.log(*args, **kwargs)

    @property
    def cycle_dates(self) -> pd.DatetimeIndex:
        """See ``AbstractSmokeDustCycleProcessor.cycle_dates``."""
        return self._cycle_processor.cycle_dates

    @property
    def cycle_metadata(self) -> pd.DataFrame:
        """See ``AbstractSmokeDustCycleProcessor.cycle_metadata``."""
        return self._cycle_processor.cycle_metadata

    @property
    def is_first_day(self) -> bool:
        """``True`` if this is considered the "first day" of the simulation where there is no
        interpolated or raw RAVE data available."""

        cycle_metadata = self._cycle_processor.cycle_metadata
        is_first_day = (
            cycle_metadata["rave_interpolated"].isnull().all()
            and cycle_metadata["rave_raw"].isnull().all()
        )
        self.log(f"{is_first_day=}")
        return is_first_day

    def run(self) -> None:
        """Run the preprocessor."""
        self.log("run: entering")
        if self.is_first_day:
            if self._context.rank == 0:
                self._context.create_dummy_emissions_file()
        else:
            self._regrid_processor.run(self._cycle_processor.cycle_metadata)
            if self._context.rank == 0:
                self._cycle_processor.run()
        self.log("run: exiting")

    def finalize(self) -> None:
        """Finalize the preprocessor."""
        self.log("finalize: exiting")
