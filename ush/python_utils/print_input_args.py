#!/usr/bin/env python3

import os
import inspect
from textwrap import dedent

from .misc import lowercase
from .print_msg import print_info_msg
from .environment import import_vars

def print_input_args(valid_args):
    """ Prints function arguments for debugging purposes

    Args:
        valid_args: dictionary of arg-value pairs
    Returns:
        Number of printed arguments
    """

    # get verbosity from environment
    IMPORTS = ["DEBUG"]
    import_vars(env_vars=IMPORTS)
    
    if list(valid_args.keys())[0] == '__unset__':
        valid_arg_names = {}
    else:
        valid_arg_names = valid_args 
    num_valid_args = len(valid_arg_names)

    filename = inspect.stack()[1].filename
    function = inspect.stack()[1].function
    filename_base = os.path.basename(filename)

    if num_valid_args == 0:
        msg = dedent(f'''
            No arguments have been passed to function {function} in script {filename_base} located
                    
                \"{filename}\"''')
    else:
        msg = dedent(f'''
            The arguments to function {function} in script {filename_base} located
                    
                \"{filename}\"

            have been set as follows:\n\n''')

        for k,v in valid_arg_names.items():
            msg = msg + f'  {k}="{v}"\n'

    print_info_msg(msg,verbose=DEBUG)
    return num_valid_args

