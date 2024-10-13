#!/usr/bin/env python3

import argparse
import os
import sys
import yaml

# =================================================================== CHJ =====
def main():
# =================================================================== CHJ =====
    parser = argparse.ArgumentParser(description='read var values from YAML.')
    parser.add_argument('-i', '--var_name', required=True, help='input variable name')
    parser.add_argument('-n', '--new_value', required=True, help='new variable value')
    parser.add_argument('-f', '--file_path', required=True, help='path to YAML file')
    args = parser.parse_args()
    set_file_param(args.var_name, args.new_value, args.file_path)


# =================================================================== CHJ =====
def set_file_param(var_name, new_value, file_path):
# =================================================================== CHJ =====
    """ Replace variable values with specific ones. """
    with open(file_path, 'r') as file:
        data_yaml = yaml.safe_load(file)

    for group_name, group_data in data_yaml.items():
        if var_name in group_data:
            nm_group = group_name
            print("Group_name=",group_name," Var_name=",var_name)
            print("BEFORE: value=", data_yaml[group_name][var_name])
            data_yaml[group_name][var_name] = new_value
    print("AFTER: value=",data_yaml[nm_group][var_name])

    with open(file_path, 'w') as file:
        yaml.dump(data_yaml, file, default_flow_style=False, sort_keys=False)


# Main call ========================================================= CHJ =====
if __name__=='__main__':
    main()

