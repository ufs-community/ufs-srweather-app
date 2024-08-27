#!/usr/bin/env python3

import os
from .print_msg import print_err_msg_exit


def cmd_vrfy(cmd, *args):
    """Execute system command

    Args:
        cmd: the command
        *args: its arguments
    Returns:
        Exit code
    """

    cmd += " " + " ".join([str(a) for a in args])
    ret = os.system(cmd)
    if ret != 0:
        print_err_msg_exit(f"System call '{cmd}' failed.")
    return ret


def cp_vrfy(*args):
    """Check that ``cp`` command executed successfully

    Args:
        *args: Iterable object containing command with its command line arguments
    Returns:
        Exit code
    """
    return cmd_vrfy("cp", *args)


def rsync_vrfy(*args):
    """Check that ``rsync`` command executed successfully

    Args:
        *args: Iterable object containing command with its command line arguments
    Returns:
        Exit code
    """
    return cmd_vrfy("rsync", *args)


def mv_vrfy(*args):
    """Check that ``mv`` command executed successfully

    Args:
        *args: Iterable object containing command with its command line arguments
    Returns:
        Exit code
    """
    return cmd_vrfy("mv", *args)


def rm_vrfy(*args):
    """Check that ``rm`` command executed successfully

    Args:
        *args: Iterable object containing command with its command line arguments
    Returns:
        Exit code
    """
    return cmd_vrfy("rm", *args)


def ln_vrfy(*args):
    """Check that ``ln`` command executed successfully

    Args:
        *args: Iterable object containing command with its command line arguments
    Returns:
        Exit code
    """
    return cmd_vrfy("ln", *args)


def mkdir_vrfy(*args):
    """Check that ``mkdir`` command executed successfully

    Args:
        *args: Iterable object containing command with its command line arguments
    Returns:
        Exit code
    """
    return cmd_vrfy("mkdir", *args)


def cd_vrfy(*args):
    """Check that ``cd`` command executed successfully

    Args:
        *args: Iterable object containing command with its command line arguments
    Returns:
        Exit code
    """
    return os.chdir(*args)
