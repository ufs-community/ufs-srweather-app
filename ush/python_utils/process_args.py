#!/usr/bin/env python3

from textwrap import dedent
from .check_var_valid_value import check_var_valid_value

def process_args(valid_args, **kwargs):
    """ Function to process a list of variable name-value pairs.
    It checks whether each argument is a valid argument or not.

    Args:
        valid_args: List of valid arguments
        **kwargs: keyword arguments
    Returns:
        A dictionary of all valid (arg,value) pairs
    """
  
    if valid_args[0] == '__unset__':
        valid_arg_names = []
    else:
        valid_arg_names = valid_args 
    num_valid_args = len(valid_arg_names)
    num_arg_val_pairs = len(kwargs)

    if num_arg_val_pairs > num_valid_args:
        print_err_msg_exit(f'''
            The number of argument-value pairs specified on the command line (num_-
            arg_val_pairs) must be less than or equal to the number of valid argu-
            ments (num_valid_args) specified in the array valid_arg_names:
              num_arg_val_pairs = {num_arg_val_pairs}
              num_valid_args = {num_valid_args}
              valid_arg_names = ( {valid_arg_names_str})''')

    if num_valid_args == 0:
        return None

    values_args = [None] * num_valid_args

    for i,a in enumerate(valid_args):
        if a is None:
            print_err_msg_exit(f'''
                The list of valid arguments (valid_arg_names) cannot contain empty elements, 
                but the element with index i={i} is empty:
                  valid_arg_names = ( {valid_arg_names})
                  valid_arg_names[{i}] = \"{valid_arg_names[i]}\"''')          

    for arg_name,arg_value in kwargs.items():
        err_msg=dedent(f'''
            The specified argument name (arg_name) in the current argument-value 
            pair (arg_val_pair) is not valid:
              arg_name = \"{arg_name}\"
              arg_val = \"{arg_value}\"\n''')
        check_var_valid_value(arg_name, valid_arg_names, err_msg)

        idx = valid_arg_names.index(arg_name)
        if values_args[idx] is not None:
            print_err_msg_exit(f'''
                The current argument has already been assigned a value:
                  arg_name = \"{arg_name}\"
                  key_value_pair = {kwargs}
                Please assign values to arguments only once on the command line.''')
        values_args[idx] = arg_value
        
    return dict(zip(valid_args,values_args))

