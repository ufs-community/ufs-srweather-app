#!/usr/bin/env python3

import re


def uppercase(s):
    """Converts a given string to uppercase

    Args:
        s (str): The string to change to uppercase
    Return:
        Uppercased string
    """

    return s.upper()


def lowercase(s):
    """Converts a given string to lowercase

    Args:
        s (str): The string to change to lowercase
    Return:
        Lowercased string
    """

    return s.lower()


def find_pattern_in_str(pattern, source):
    """Finds regex pattern in a string

    Args:
        pattern (str): Regex expression
        source  (str): Text string to search for regex expression
    Return:
        A tuple of matched groups or None
    """
    pattern = re.compile(pattern)
    for match in re.finditer(pattern, source):
        return match.groups()
    return None


def find_pattern_in_file(pattern, file_name):
    """Finds regex pattern in a file

    Args:
        pattern   (str): Regex expression
        file_name (str): Name of text file
    Return:
        A tuple of matched groups or None
    """
    pattern = re.compile(pattern)
    with open(file_name) as f:
        for line in f:
            for match in re.finditer(pattern, line):
                return match.groups()
    return None
