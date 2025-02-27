"""Test the main entrypoint for generating fire emission ICs."""

import os
import subprocess
from pathlib import Path

from pytest_mock import MockerFixture
from typer.testing import CliRunner

from smoke_dust.core.preprocessor import SmokeDustPreprocessor
from smoke_dust.generate_emissions import app
from test_python.test_smoke_dust.conftest import create_fake_grid_out, FakeGridOutShape


def test(tmp_path: Path, fake_grid_out_shape: FakeGridOutShape, mocker: MockerFixture) -> None:
    """Test invoking emissions generation."""
    mock_proc = mocker.Mock(spec=SmokeDustPreprocessor)
    mocker.patch("smoke_dust.generate_emissions.SmokeDustPreprocessor", return_value=mock_proc)
    create_fake_grid_out(tmp_path, fake_grid_out_shape)
    strpath = str(tmp_path)
    runner = CliRunner()
    os.environ["CDATE"] = "2019072200"
    os.environ["COMIN_SMOKE_DUST_COMMUNITY"] = strpath

    try:
        args = [
            "--staticdir",
            strpath,
            "--ravedir",
            strpath,
            "--intp-dir",
            strpath,
            "--predef-grid",
            "RRFS_CONUS_25km",
            "--ebb-dcycle",
            "2",
            "--restart-interval",
            "6 12 18 24",
            "--persistence",
            "False",
            "--rave-qa-filter",
            "none",
            "--log-level",
            "debug",
        ]
        result = runner.invoke(app, args, catch_exceptions=False)
    except:
        for env_var in ["CDATE", "COMIN_SMOKE_DUST_COMMUNITY"]:
            os.unsetenv(env_var)
        raise
    print(result.output)

    assert result.exit_code == 0
    mock_proc.run.assert_called_once()
    mock_proc.finalize.assert_called_once()


def test_help() -> None:
    """Test that the help message can be displayed."""
    cli_path = (
        Path(__file__).parent.parent.parent.parent / "ush" / "smoke_dust" / "generate_emissions.py"
    )
    subprocess.check_call(["python", str(cli_path), "--help"])
