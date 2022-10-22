#!/usr/bin/env python3

import os
from datetime import datetime
from textwrap import dedent
from .check_var_valid_value import check_var_valid_value
from .filesys_cmds_vrfy import rm_vrfy, mv_vrfy
from .print_msg import log_info


def check_for_preexist_dir_file(path, method):
    """Check for a preexisting directory or file and, if present, deal with it
    according to the specified method

    Args:
        path: path to directory
        method: could be any of [ 'delete', 'rename', 'quit' ]
    Returns:
        None
    """

    try:
        check_var_valid_value(method, ["delete", "rename", "quit"])
    except ValueError:
        errmsg = dedent(
            f"""
            Invalid method for dealing with pre-existing directory specified
            method = {method}
            """
        )
        raise ValueError(errmsg) from None

    if os.path.exists(path):
        if method == "delete":
            rm_vrfy(" -rf ", path)
        elif method == "rename":
            now = datetime.now()
            d = now.strftime("_old_%Y%m%d_%H%M%S")
            new_path = path + d
            log_info(
                f"""
                Specified directory or file already exists:
                    {path}
                Moving (renaming) preexisting directory or file to:
                    {new_path}"""
            )
            mv_vrfy(path, new_path)
        else:
            raise FileExistsError(
                dedent(
                    f"""
                Specified directory or file already exists
                    {path}"""
                )
            )
