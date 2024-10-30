#!/usr/bin/env python3

import traceback
import sys
from textwrap import dedent, indent
from logging import getLogger


def print_err_msg_exit(error_msg="", stack_trace=True):
    """Prints out an error message to standard error and exits.
    It can optionally print the stack trace as well.

    Args:
        error_msg    (str): Error message to print
        stack_trace (bool): Set to ``True`` to print stack trace
    """
    if stack_trace:
        traceback.print_stack(file=sys.stderr)

    msg_footer = "\nExiting with nonzero status."
    print("FATAL ERROR: " + dedent(error_msg) + msg_footer, file=sys.stderr)
    sys.exit(1)


def print_info_msg(info_msg, verbose=True):
    """
    Prints an informational message to standard output when ``verbose``
    is set to ``True``. It does proper "dedentation"/formatting that is needed for readability
    of Python code.

    Args:
        info_msg (str): Info message to print
        verbose (bool): Set to ``False`` to silence printing
    Returns:
        Boolean value: True if message is successfully printed; False if ``verbose`` is set to False. 
    """

    if verbose:
        print(dedent(info_msg))
        return True
    return False


def log_info(info_msg, verbose=True, dedent_=True):
    """
    Prints information message using the logging module. This function
    should not be used if Python logging has not been initialized.

    Args:
        info_msg (str): Info message to print
        verbose (bool): Set to ``False`` to silence printing
        dedent_ (bool): Set to ``False`` to disable "dedenting"/formatting and print string as-is
    Returns:
        None
    """

    # "sys._getframe().f_back.f_code.co_name" returns the name of the calling function
    logger = getLogger(sys._getframe().f_back.f_code.co_name)

    if verbose:
        if dedent_:
            logger.info(indent(dedent(info_msg), "  "))
        else:
            logger.info(info_msg)
