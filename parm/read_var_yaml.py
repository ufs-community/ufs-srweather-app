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
    parser.add_argument('-f', '--file_path', required=True, help='path to YAML file')
    args = parser.parse_args()
    var_values = read_var_yaml(args.var_name, args.file_path) 
    values_sh = change_to_shell(var_values)

    print(values_sh)


# =================================================================== CHJ =====
def read_var_yaml(var_name, file_path):
# =================================================================== CHJ =====
    """ Read values for a specific variable across all groups in a YAML file. """
    with open(file_path, 'r') as file:
        data_yaml = yaml.safe_load(file)

    for group_name, group_data in data_yaml.items():
        if var_name in group_data:
            values = group_data[var_name]

    return values


# =================================================================== CHJ =====
def change_to_shell(var_values):
# =================================================================== CHJ =====
    if isinstance(var_values, bool):
        values_sh = str(var_values).upper()
    elif isinstance(var_values, str):
        values_sh = f'"{var_values}"'
    elif isinstance(var_values, int):
        values_sh = f'"{var_values}"'
    elif isinstance(var_values, list):
        values_sh = f'''({ ' '.join(f'"{value}"' for value in var_values) })'''
    else:
        if var_values == None:
            values_sh = ""
        else:
            values_sh = var_values

    return values_sh


# Main call ========================================================= CHJ =====
if __name__=='__main__':
    main()

