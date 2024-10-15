#!/usr/bin/env python3

import os
from .print_msg import print_err_msg_exit


def cmd_vrfy(cmd, *args):
    """Executes system command

    Args:
        cmd (str): The command
        *args: Its arguments
    Returns:
        ret: Exit code
    """

    cmd += " " + " ".join([str(a) for a in args])
    ret = os.system(cmd)
    if ret != 0:
        print_err_msg_exit(f"System call '{cmd}' failed.")
    return ret


def cp_vrfy(*args):
    """Checks that the ``cp`` command executed successfully

    Args:
        *args: Iterable object containing command with its command line arguments
    Returns:
        Exit code
    """
    return cmd_vrfy("cp", *args)


def rsync_vrfy(*args):
    """Checks that the ``rsync`` command executed successfully

    Args:
        *args: Iterable object containing command with its command line arguments
    Returns:
        Exit code
    """
    return cmd_vrfy("rsync", *args)


def mv_vrfy(*args):
    """Checks that the ``mv`` command executed successfully

    Args:
        *args: Iterable object containing command with its command line arguments
    Returns:
        Exit code
    """
    return cmd_vrfy("mv", *args)


def rm_vrfy(*args):
    """Checks that the ``rm`` command executed successfully

    Args:
        *args: Iterable object containing command with its command line arguments
    Returns:
        Exit code
    """
    return cmd_vrfy("rm", *args)


def ln_vrfy(*args):
    """Checks that the ``ln`` command executed successfully

    Args:
        *args: Iterable object containing command with its command line arguments
    Returns:
        Exit code
    """
    return cmd_vrfy("ln", *args)


def mkdir_vrfy(*args):
    """Checks that the ``mkdir`` command executed successfully

    Args:
        *args: Iterable object containing command with its command line arguments
    Returns:
        Exit code
    """
    return cmd_vrfy("mkdir", *args)


def cd_vrfy(*args):
    """Checks that the ``cd`` command executed successfully

    Args:
        *args: Iterable object containing command with its command line arguments
    Returns:
        Exit code
    """
    return os.chdir(*args)
