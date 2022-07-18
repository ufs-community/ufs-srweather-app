#!/usr/bin/env python3


"""
This file provides utilities for processing different configuration file formats.
Supported formats include:
    a) YAML
    b) JSON
    c) SHELL
    d) INI

Typical usage involves first loading the config file, then using the dictionary
returnded by load_config to make queries.
"""

import argparse
try:
    import yaml
except:
    pass
import json
import sys
import os
from textwrap import dedent
import configparser

from .environment import list_to_str, str_to_list
from .print_msg import print_err_msg_exit
from .run_command import run_command

##########
# YAML
##########
def load_yaml_config(config_file):
    """ Safe load a yaml file """

    try:
        with open(config_file,'r') as f:
            cfg = yaml.safe_load(f)
    except yaml.YAMLError as e:
        print_err_msg_exit(e)

    return cfg

def cfg_to_yaml_str(cfg):
    """ Get contents of config file as a yaml string """

    return yaml.dump(cfg, sort_keys=False, default_flow_style=False)

def join_str(loader, node):
    """ Custom tag hangler to join strings """
    seq = loader.construct_sequence(node)
    return ''.join([str(i) for i in seq])

try:
    yaml.add_constructor('!join_str', join_str, Loader=yaml.SafeLoader)
except:
    pass

##########
# JSON
##########
def load_json_config(config_file):
    """ Load json config file """

    try:
        with open(config_file,'r') as f:
            cfg = json.load(f)
    except:
        print_err_msg_exit(e)

    return cfg
    
def cfg_to_json_str(cfg):
    """ Get contents of config file as a json string """

    return json.dumps(cfg,  sort_keys=False, indent=4)

##########
# SHELL
##########
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
    pid = os.getpid()
    code = dedent(f'''      #!/bin/bash
      t1="./t1.{pid}"
      t2="./t2.{pid}"
      (set -o posix; set) > $t1
      {{ . {config_file}; set +x; }} &>/dev/null
      (set -o posix; set) > $t2
      diff $t1 $t2 | grep "> " | cut -c 3-
      rm -rf $t1 $t2
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

def cfg_to_shell_str(cfg):
    """ Get contents of config file as shell script string"""

    shell_str = ''
    for k,v in cfg.items():
        if isinstance(v,dict):
            shell_str += f"# [{k}]\n"
            shell_str += cfg_to_shell_str(v)
            shell_str += "\n"
            continue
        v1 = list_to_str(v)
        if isinstance(v,list):
            shell_str += f'{k}={v1}\n'
        else:
            shell_str += f"{k}='{v1}'\n"
    return shell_str

##########
# INI
##########
def load_ini_config(config_file):
    """ Load a config file with a format similar to Microsoft's INI files"""

    if not os.path.exists(config_file):
        print_err_msg_exit(f'''
            The specified configuration file does not exist:
                  \"{config_file}\"''')
    
    config = configparser.ConfigParser()
    config.read(config_file)
    config_dict = {s:dict(config.items(s)) for s in config.sections()}
    return config_dict
    
def get_ini_value(config, section, key):
    """ Finds the value of a property in a given section"""

    if not section in config:
        print_err_msg_exit(f'''
            Section not found: 
              section = \"{section}\"
              valid sections = \"{config.keys()}\"''')
    else:
        return config[section][key]

    return None

def cfg_to_ini_str(cfg):
    """ Get contents of config file as ini string"""

    ini_str = ''
    for k,v in cfg.items():
        if isinstance(v,dict):
            ini_str += f"[{k}]\n"
            ini_str += cfg_to_ini_str(v)
            ini_str += "\n"
            continue
        v1 = list_to_str(v)
        if isinstance(v,list):
            ini_str += f'{k}={v1}\n'
        else:
            ini_str += f"{k}='{v1}'\n"
    return ini_str

##################
# CONFIG loader
##################
def load_config_file(file_name):
    """ Load config file based on file name extension """

    ext = os.path.splitext(file_name)[1][1:]
    if ext == "sh":
        return load_shell_config(file_name)
    elif ext == "cfg":
        return load_ini_config(file_name)
    elif ext == "json":
        return load_json_config(file_name)
    else:
        return load_yaml_config(file_name)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=\
                        'Prints contents of config file.')
    parser.add_argument('--cfg','-c',dest='cfg',required=True,
                        help='config file to parse')
    parser.add_argument('--output-type','-o',dest='out_type',required=False,
                        help='output format: can be any of ["shell", "yaml", "ini", "json"]')

    args = parser.parse_args()
    cfg = load_config_file(args.cfg)

    if args.out_type == 'shell':
        print( cfg_to_shell_str(cfg) )
    elif args.out_type == 'ini':
        print( cfg_to_ini_str(cfg) )
    elif args.out_type == 'json':
        print( cfg_to_json_str(cfg) )
    else:
        print( cfg_to_yaml_str(cfg) )

