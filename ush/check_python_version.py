#!/usr/bin/env python3

import sys
import logging
import platform
from textwrap import dedent


def check_python_version():
    """Checks for python version >= 3.6 and for presence of some
    non-standard packages (currently ``jinja2``, ``yaml``, ``f90nml``)
    
    Raises:
        ImportError: If checked packages are missing.
        Exception: If Python version is less than 3.6
    """

    # Check for non-standard python packages
    try:
        import jinja2
        import yaml
        import f90nml
    except ImportError as error:
        logging.error(
            dedent(
                """
                Error: Missing python package required by the SRW app
                """
            )
        )
        raise

    # check python version
    major, minor, patch = platform.python_version_tuple()
    if int(major) < 3 or int(minor) < 6:
        logging.error(
            dedent(
                f"""
                Error: python version must be 3.6 or higher
                Your python version is: {major}.{minor}"""
            )
        )
        raise Exception("Python version below 3.6")


if __name__ == "__main__":
    try:
        check_python_version()
    except:
        logging.exception(
            dedent(
                f"""
                *************************************************************************
                FATAL ERROR:
                The system does not meet minimum requirements for running the SRW app.
                Instructions for setting up python environments can be found on the web:
                https://github.com/ufs-community/ufs-srweather-app/wiki/Getting-Started
                *************************************************************************\n
                """
            )
        )
        sys.exit(1)
