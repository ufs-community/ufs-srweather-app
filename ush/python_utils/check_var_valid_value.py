#!/usr/bin/env python3


def check_var_valid_value(var, values):
    """Checks if specified variable has a valid value

    Args:
        var: The variable
        values (list): Valid values
    Returns:
        True: If ``var`` has valid value; ``exit(1)`` otherwise
    Raises:
        ValueError: If ``var`` has an invalid value
    """

    if not var:
        var = ""
    if var not in values:
        raise ValueError(f"Got '{var}', expected one of the following:\n   {values}")
    return True
