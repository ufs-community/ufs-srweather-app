#!/usr/bin/env python3

import argparse
import yaml
import sys
import os
from textwrap import dedent

from .environment import list_to_str, str_to_list
from .print_msg import print_err_msg_exit
from .run_command import run_command

def load_shell_config(config_file):
    """ Loads old style shell config files.
    We source the config script in a subshell and gets the variables it sets

    Args:
         config_file: path to config file script
    Returns:
         dictionary that should be equivalent to one obtained from parsing a yaml file.
    """

    # Save env vars before and after sourcing the scipt and then
    # do a diff to get variables specifically defined/updated in the script
    # Method sounds brittle but seems to work ok so far
    code = dedent(f'''      #!/bin/bash
      (set -o posix; set) > /tmp/t1
      {{ . {config_file}; set +x; }} &>/dev/null
      (set -o posix; set) > /tmp/t2
      diff /tmp/t1 /tmp/t2 | grep "> " | cut -c 3-
    ''')
    (_,config_str,_) = run_command(code)
    lines = config_str.splitlines()
    
    #build the dictionary
    cfg = {}
    for l in lines:
        idx = l.find("=")
        k = l[:idx]
        v = str_to_list(l[idx+1:])
        cfg[k] = v
    return cfg

def cfg_to_yaml_str(cfg):
    """ Get contents of config file as a yaml string """

    return yaml.dump(cfg, sort_keys=False, default_flow_style=False)

def cfg_to_shell_str(cfg):
    """ Get contents of yaml file as shell script string"""

    shell_str = ''
    for k,v in cfg.items():
        v1 = list_to_str(v)
        if isinstance(v,list):
            shell_str += f'{k}={v1}\n'
        else:
            shell_str += f"{k}='{v1}'\n"
    return shell_str

def yaml_safe_load(file_name):
    """ Safe load a yaml file """

    try:
        with open(file_name,'r') as f:
            cfg = yaml.safe_load(f)
    except yaml.YAMLError as e:
        print_err_msg_exit(e)

    return cfg

def join(loader, node):
    """ Custom tag hangler to join strings """
    seq = loader.construct_sequence(node)
    return ''.join([str(i) for i in seq])

yaml.add_constructor('!join', join, Loader=yaml.SafeLoader)

def load_config_file(file_name):
    """ Choose yaml/shell file based on extension """
    ext = os.path.splitext(file_name)[1][1:]
    if ext == "sh":
        return load_shell_config(file_name)
    else:
        return yaml_safe_load(file_name)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=\
                        'Prints contents of yaml file as bash argument-value pairs.')
    parser.add_argument('--cfg','-c',dest='cfg',required=True,
                        help='yaml or regular shell config file to parse')
    parser.add_argument('--output-type','-o',dest='out_type',required=False,
                        help='output format: "shell": shell format, any other: yaml format ')

    args = parser.parse_args()
    cfg = load_config_file(args.cfg)

    if args.out_type == 'shell':
        print( cfg_to_shell_str(cfg) )
    else:
        print( cfg_to_yaml_str(cfg) )

