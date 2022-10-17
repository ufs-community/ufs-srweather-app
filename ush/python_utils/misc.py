#!/usr/bin/env python3

import re


def uppercase(s):
    """Function to convert a given string to uppercase

    Args:
        s: the string
    Return:
        Uppercased str
    """

    return s.upper()


def lowercase(s):
    """Function to convert a given string to lowercase

    Args:
        s: the string
    Return:
        Lowercase str
    """

    return s.lower()


def find_pattern_in_str(pattern, source):
    """Find regex pattern in a string

    Args:
        pattern: regex expression
        source: string
    Return:
        A tuple of matched groups or None
    """
    pattern = re.compile(pattern)
    for match in re.finditer(pattern, source):
        return match.groups()
    return None


def find_pattern_in_file(pattern, file_name):
    """Find regex pattern in a file

    Args:
        pattern: regex expression
        file_name: name of text file
    Return:
        A tuple of matched groups or None
    """
    pattern = re.compile(pattern)
    with open(file_name) as f:
        for line in f:
            for match in re.finditer(pattern, line):
                return match.groups()
    return None
