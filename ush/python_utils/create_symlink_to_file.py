#!/usr/bin/env python3

import os

from .process_args import process_args
from .print_input_args import print_input_args
from .print_msg import print_err_msg_exit
from .check_var_valid_value import check_var_valid_value
from .filesys_cmds_vrfy import ln_vrfy

def create_symlink_to_file(target,symlink,relative=True):
    """ Create a symbolic link to the specified target file.

    Args:
        target: target file
        symlink: symbolic link to target file
        relative: optional argument to specify relative symoblic link creation
    Returns:
        None
    """

    print_input_args(locals())

    if target is None:
        print_err_msg_exit(f'''
            The argument \"target\" specifying the target of the symbolic link that
            this function will create was not specified in the call to this function:
              target = \"{target}\"''')

    if symlink is None:
        print_err_msg_exit(f'''
            The argument \"symlink\" specifying the target of the symbolic link that
            this function will create was not specified in the call to this function:
              symlink = \"{symlink}\"''')

    if not os.path.exists(target):
        print_err_msg_exit(f'''
            Cannot create symlink to specified target file because the latter does
            not exist or is not a file:
                target = \"{target}\"''')
    
    relative_flag=""
    if relative:
        RELATIVE_LINK_FLAG = os.getenv('RELATIVE_LINK_FLAG')
        if RELATIVE_LINK_FLAG is not None:
            relative_flag=f'{RELATIVE_LINK_FLAG}'

    ln_vrfy(f'-sf {relative_flag} {target} {symlink}')

