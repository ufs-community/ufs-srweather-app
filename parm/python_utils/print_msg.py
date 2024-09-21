#!/usr/bin/env python3

import traceback
import sys
from textwrap import dedent, indent
from logging import getLogger


def print_err_msg_exit(error_msg="", stack_trace=True):
    """Function to print out an error message to stderr and exit.
    It can optionally print the stack trace as well.

    Args:
        error_msg : error message to print
        stack_trace : set to True to print stack trace
    Returns:
        None
    """
    if stack_trace:
        traceback.print_stack(file=sys.stderr)

    msg_footer = "\nExiting with nonzero status."
    print("FATAL ERROR: " + dedent(error_msg) + msg_footer, file=sys.stderr)
    sys.exit(1)


def print_info_msg(info_msg, verbose=True):
    """Function to print information message to stdout, when verbose
    is set to True. It does proper "dedentation" that is needed for readability
    of python code.

    Args:
        info_msg : info message to print
        verbose : set to False to silence printing
    Returns:
        True: if message is successfully printed
    """

    if verbose:
        print(dedent(info_msg))
        return True
    return False


def log_info(info_msg, verbose=True, dedent_=True):
    """Function to print information message using the logging module. This function
    should not be used if python logging has not been initialized.

    Args:
        info_msg : info message to print
        verbose : set to False to silence printing
        dedent_ : set to False to disable "dedenting" (print string as-is)
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
