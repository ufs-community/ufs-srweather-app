#!/usr/bin/env python3


def check_var_valid_value(var, values):
    """Check if specified variable has a valid value

    Args:
        var: the variable
        values: list of valid values
    Returns:
        True: if var has valid value, exit(1) otherwise
    """

    if not var:
        var = ""
    if var not in values:
        raise ValueError(f"Got '{var}', expected one of the following:\n   {values}")
    return True
