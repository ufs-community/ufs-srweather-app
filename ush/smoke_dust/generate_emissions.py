#!/usr/bin/env python3

"""
Python script for fire emissions preprocessing from RAVE FRP and FRE (Li et al.,2022)
Author: johana.romero-alvarez@noaa.gov
"""
import os
import sys
from enum import StrEnum, unique
from pathlib import Path

import typer

sys.path.append(str(Path(__file__).parent.parent))

# pylint: disable=wrong-import-position
from smoke_dust.core.context import (
    PredefinedGrid,
    EbbDCycle,
    RaveQaFilter,
    LogLevel,
    SmokeDustContext,
)
from smoke_dust.core.preprocessor import SmokeDustPreprocessor

# pylint: enable=wrong-import-position

os.environ["NO_COLOR"] = "1"
app = typer.Typer(pretty_exceptions_enable=False)


@unique
class StringBool(StrEnum):
    """Allow CLI to use boolean string arguments to avoid logic in shell scripts."""

    TRUE = "True"
    FALSE = "False"


# pylint: disable=line-too-long
@app.command()
def main(  # pylint:disable=too-many-arguments
    staticdir: Path = typer.Option(
        ..., "--staticdir", help="Path to the smoke and dust fixed files."
    ),
    ravedir: Path = typer.Option(
        ..., "--ravedir", help="Path to the directory containing RAVE data files (hourly)."
    ),
    intp_dir: Path = typer.Option(
        ..., "--intp-dir", help="Path to the directory containing interpolated RAVE data files."
    ),
    predef_grid: PredefinedGrid = typer.Option(
        ..., "--predef-grid", help="SRW predefined grid to use as the forecast domain."
    ),
    ebb_dcycle: EbbDCycle = typer.Option(..., "--ebb-dcycle", help="The forecast cycle to run."),
    restart_interval: str = typer.Option(
        ...,
        "--restart-interval",
        help="Restart intervals used for restart file search. For example '6 12 18 24'.",
    ),
    persistence: StringBool = typer.Option(
        ...,
        "--persistence",
        help="If true, use satellite observations from the previous day. Otherwise, use observations from the same day.",
    ),
    rave_qa_filter: RaveQaFilter = typer.Option(
        ..., "--rave-qa-filter", help="Filter level for RAVE QA flags when regridding fields."
    ),
    log_level: LogLevel = typer.Option(
        LogLevel.INFO, "--log-level", help="Logging level to use for the preprocessor."
    ),
    exit_on_error: StringBool = typer.Option(
        StringBool.TRUE,
        "--exit-on-error",
        help="If false, log errors and write a dummy emissions file but do not raise an exception.",
    ),
    regrid_in_memory: StringBool = typer.Option(
        StringBool.FALSE,
        "--regrid-in-memory",
        help="If true, do esmpy regridding in-memory as opposed to reading from the fixed weight file.",
    ),
):
    """Main entrypoint for generating ICs for smoke and dust."""
    # pylint:enable=line-too-long
    typer.echo("Welcome to interpolating RAVE and processing fire emissions!")

    context = SmokeDustContext(
        staticdir=staticdir,
        ravedir=ravedir,
        intp_dir=intp_dir,
        predef_grid=predef_grid,
        ebb_dcycle=ebb_dcycle,
        restart_interval=restart_interval,
        persistence=persistence,
        rave_qa_filter=rave_qa_filter,
        log_level=log_level,
        exit_on_error=exit_on_error,
        regrid_in_memory=regrid_in_memory,
    )
    # Uncomment to write environment data to the output log. Comment again when done.
    # if context.rank == 0:
    #     context.log(f"{os.environ=}")
    processor = SmokeDustPreprocessor(context)
    try:
        processor.run()
        processor.finalize()
    except Exception as e:  # pylint: disable=broad-exception-caught
        context.create_dummy_emissions_file()
        context.log("unhandled error", exc_info=e)

    typer.echo("Exiting. Bye!")


if __name__ == "__main__":
    app()
