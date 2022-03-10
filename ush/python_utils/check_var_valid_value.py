#!/usr/bin/env python3

from .print_msg import print_err_msg_exit

def check_var_valid_value(var, values, err_msg=None):
    """ Check if specified variable has a valid value

    Args:
        var: the variable
        values: list of valid values
        err_msg: additional error message to print
    Returns:
        True: if var has valid value, exit(1) otherwise
    """

    if var not in values:
        if err_msg is not None:
            err_msg = f'The value specified in var = {var} is not supported.'
        print_err_msg_exit(err_msg + f'{var} must be set to one of the following:\n   {values}')
    return True

