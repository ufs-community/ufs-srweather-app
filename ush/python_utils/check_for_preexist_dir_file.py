#!/usr/bin/env python3

import os
from datetime import datetime
from textwrap import dedent
from .check_var_valid_value import check_var_valid_value
from .filesys_cmds_vrfy import rm_vrfy, mv_vrfy, rsync_vrfy
from .print_msg import log_info


def check_for_preexist_dir_file(path, method):
    """Checks for a preexisting directory or file and, if present, deals with it
    according to the specified method

    Args:
        path   (str): Path to directory
        method (str): Could be any of [ ``'delete'``, ``'reuse'``, ``'rename'``, ``'quit'`` ]
    Returns:
        None
    Raises:
        ValueError: If an invalid method for dealing with a pre-existing directory is specified
        FileExistsError: If the specified directory or file already exists
    """

    try:
        check_var_valid_value(method, ["delete", "reuse", "rename", "quit"])
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
        elif method == "rename" or method == "reuse":
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
            if method == "rename":
                mv_vrfy(path, new_path)
            else:
                rsync_vrfy(path, new_path)
        else:
            raise FileExistsError(
                dedent(
                    f"""
                Specified directory or file already exists
                    {path}"""
                )
            )
