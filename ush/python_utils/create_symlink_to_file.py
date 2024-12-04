#!/usr/bin/env python3

import os
from pathlib import Path

from .print_input_args import print_input_args
from .print_msg import print_err_msg_exit


def create_symlink_to_file(target, symlink, relative=True):
    """Creates a symbolic link to the specified target file.

    Args:
        target   (str) : Target file
        symlink  (str) : Symbolic link to target file
        relative (bool): Optional argument to specify relative symbolic link creation
    Returns:
        None
    """

    print_input_args(locals())

    if target is None:
        print_err_msg_exit(
            f"""
            The argument 'target' specifying the target of the symbolic link that
            this function will create was not specified in the call to this function:
              target = '{target}'"""
        )

    if symlink is None:
        print_err_msg_exit(
            f"""
            The argument 'symlink' specifying the target of the symbolic link that
            this function will create was not specified in the call to this function:
              symlink = '{symlink}'"""
        )

    if not os.path.exists(target):
        print_err_msg_exit(
            f"""
            Cannot create symlink to specified target file because the latter does
            not exist or is not a file:
                target = '{target}'"""
        )

    if relative:
        symlink = Path(symlink).relative_to(Path(target))

    Path(target).symlink_to(symlink)
