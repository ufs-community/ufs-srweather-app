#!/usr/bin/env python3

import os
import inspect
import shlex
from datetime import datetime, date
from types import ModuleType


def str_to_date(s):
    """Gets Python datetime object from string.

    Args:
        s (str): A string
    Returns:
        Datetime object or None
    """
    v = None
    try:
        l = len(s)
        if l == 8:
            v = datetime.strptime(s, "%Y%m%d")
        elif l == 10:
            v = datetime.strptime(s, "%Y%m%d%H")
        elif l == 12:
            v = datetime.strptime(s, "%Y%m%d%H%M")
        elif l == 14:
            v = datetime.strptime(s, "%Y%m%d%H%M%S")
    except:
        v = None
    return v


def date_to_str(d, format="%Y%m%d%H%M"):
    """Gets string from Python datetime object.
    By default it converts to ``YYYYMMDDHHmm`` format unless told otherwise by passing a different format.

    Args:
        d (datetime.datetime): Datetime object
        format (str): Format of the datetime string; default is ``"%Y%m%d%H%M"`` (see `format codes <https://docs.python.org/3/library/datetime.html#format-codes>`_ for other options).
    Returns:
        String in YYYYMMDDHHmm or shorter version of it
    """
    v = d.strftime(format)
    return v


def str_to_type(s, return_string=0):
    """Checks whether the string is a float, int, boolean, datetime, or just regular string.
    This will be used to automatically convert environment variables to data types
    that are more convenient to work with. If you don't want this functionality,
    pass ``return_string = 1``.

    Args:
        s (str): A string
        return_string (int): Set to ``1`` to return the string itself. Set to ``2`` to return the string itself only for a datetime object
    Returns:
        A float, int, boolean, datetime, or the string itself when all else fails
    """
    s = s.strip("\"'")
    if return_string != 1:
        if s.lower() in ["true", "yes", "yeah"]:
            return True
        if s.lower() in ["false", "no", "nope"]:
            return False
        if s in ["None", "null"]:
            return None
        v = str_to_date(s)
        if v is not None:
            if return_string == 2:
                return s
            return v
        # int
        try:
            v = int(s)
            # treat integers that start with 0 as string
            if len(s) > 1 and s[0] == "0":
                return s
            else:
                return v
        except:
            pass
        # float
        try:
            v = float(s)
            return v
        except:
            pass
    return s


def type_to_str(v):
    """Gets a string representing the value of a given float, int, boolean, date or list of these types. 

    Args:
        v: A variable of the above types
    Returns:
        A string
    """
    if isinstance(v, bool):
        return "TRUE" if v else "FALSE"
    elif isinstance(v, (int, float)):
        pass
    elif isinstance(v, date):
        return date_to_str(v)
    elif v is None:
        return ""
    return str(v)


def list_to_str(v, oneline=False):
    """Given a string or list of strings, constructs a string
    to be used on right hand side of shell environment variables.

    Args:
        v: A string/number, list of strings/numbers, or null string(``''``)
        oneline (bool): If the string is a single line (True) or multiple (False) ?
    Returns:
        A string
    """
    if isinstance(v, str):
        return v
    if isinstance(v, list):
        v = [type_to_str(i) for i in v]
        if oneline or len(v) <= 4:
            shell_str = '( "' + '" "'.join(v) + '" )'
        else:
            shell_str = '( \\\n"' + '" \\\n"'.join(v) + '" \\\n)'
    else:
        shell_str = f"{type_to_str(v)}"

    return shell_str


def str_to_list(v, return_string=0):
    """Constructs a string or list of strings based on the given string.
    Basically does the reverse operation of ``list_to_str``.

    Args:
        v: A string
    Returns:
        A string, a list of strings, or a null string(``''``)
    """

    if not isinstance(v, str):
        return v
    v = v.strip()
    if not v:
        return None
    if (v[0] == "(" and v[-1] == ")") or (v[0] == "[" and v[-1] == "]"):
        v = v[1:-1]
        v = v.replace(",", " ")
        tokens = shlex.split(v)
        lst = []
        for itm in tokens:
            itm = itm.strip()
            if itm == "":
                continue
            # bash arrays could be stored with indices ([0]=hello ...)
            if "=" in itm:
                idx = itm.find("=")
                itm = itm[idx + 1 :]
            lst.append(str_to_type(itm, return_string))
        return lst
    return str_to_type(v, return_string)


def set_env_var(param, value):
    """Sets an environment variable.

    Args:
        param: The variable to set
        value: A string, a list of strings, or None
    Returns:
        None
    """

    os.environ[param] = list_to_str(value)


def get_env_var(param):
    """Gets the value of an environment variable

    Args:
        param: The environment variable
    Returns:
        A string, a list of strings, or None
    """

    if not param in os.environ:
        return None
    value = os.environ[param]
    return str_to_list(value)


def import_vars(dictionary=None, target_dict=None, env_vars=None):
    """Imports all (or a select few) environment/dictionary variables as Python global
    variables of the caller module. Calls this function at the beginning of a function
    that uses environment variables.

    Note that for read-only environment variables, calling this function once at the
    beginning should be enough. However, if the variable is modified in the module it is
    called from, the variable should be explicitly tagged as ``global``, and then its value
    should be exported back to the environment with a call to ``export_vars()``:

    .. code-block:: console

        import_vars() # import all environment variables
        global MY_VAR, MY_LIST_VAR
        MY_PATH = "/path/to/somewhere"
        MY_LIST_VAR.append("Hello")
        export_vars() # this exports all global variables

    This is because in shell scripting assumes that everything is global unless specifically tagged local, while the opposite is true
    for Python.

    Args:
        dictionary  (dict): Source dictionary
        target_dict (dict): Target dictionary
        env_vars    (list): List of selected environment variables to import or ``None``, in which case all environment variables are imported
    Returns:
        None
    """
    if dictionary is None:
        dictionary = os.environ

    if target_dict is None:
        target_dict = inspect.stack()[1][0].f_globals

    if env_vars is None:
        env_vars = dictionary
    else:
        env_vars = {k: dictionary[k] if k in dictionary else None for k in env_vars}

    for k, v in env_vars.items():
        # Don't replace variable with empty value
        if not ((k in target_dict) and (v is None or v == "")):
            target_dict[k] = str_to_list(v)


def export_vars(dictionary=None, source_dict=None, env_vars=None):
    """Exports all (or a select few) global variables of the caller modules
    to the environment/dictionary. Calls this function at the end of
    a function that updates environment variables.

    Args:
        dictionary  (dict): Target dictionary to set
        source_dict (dict): Source dictionary
        env_vars    (list): List of selected environment variables to export or ``None``, in which case all environment variables are exported
    Returns:
        None
    """
    if dictionary is None:
        dictionary = os.environ

    if source_dict is None:
        source_dict = inspect.stack()[1][0].f_globals

    if env_vars is None:
        env_vars = source_dict
    else:
        env_vars = {k: source_dict[k] if k in source_dict else None for k in env_vars}

    for k, v in env_vars.items():
        # skip functions and other unlikely variable names
        if callable(v):
            continue
        if isinstance(v, ModuleType):
            continue
        if not k or k[0] == "_":
            continue
        dictionary[k] = list_to_str(v)
