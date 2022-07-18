#!/usr/bin/env python3

import re

def uppercase(str):
    """ Function to convert a given string to uppercase

    Args:
        str: the string
    Return:
        Uppercased str
    """
    
    return str.upper()


def lowercase(str):
    """ Function to convert a given string to lowercase

    Args:
        str: the string
    Return:
        Lowercase str
    """
    
    return str.lower()

def find_pattern_in_str(pattern, source):
    """ Find regex pattern in a string

    Args:
        pattern: regex expression
        source: string
    Return:
        A tuple of matched groups or None
    """
    pattern = re.compile(pattern)
    for match in re.finditer(pattern,source):
        return match.groups()
    return None

def find_pattern_in_file(pattern, file_name):
    """ Find regex pattern in a file

    Args:
        pattern: regex expression
        file_name: name of text file
    Return:
        A tuple of matched groups or None
    """
    pattern = re.compile(pattern)
    with open(file_name) as f:
        for line in f:
            for match in re.finditer(pattern,line):
                return match.groups()
    return None

def flatten_dict(dictionary,keys=None):
    """ Faltten a recursive dictionary (e.g.yaml/json) to be one level deep
    Args:
      dictionary: the source dictionary
      keys: list of keys on top level whose contents to flatten, if None all of them
    Returns:
      A one-level deep dictionary for the selected set of keys
    """
    flat_dict = {}
    for k,v in dictionary.items():
        if not keys or k in keys:
            if isinstance(v,dict):
                r = flatten_dict(v)
                flat_dict.update(r)
            else:
                flat_dict[k] = v
    return flat_dict

