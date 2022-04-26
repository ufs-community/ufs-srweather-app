#!/usr/bin/env python3

import xml.etree.ElementTree as ET

def load_xml_file(xml_file):
    """ Loads xml file

    Args:
        xml_file: path to xml file
    Returns:
        root of the xml tree
    """
    tree = ET.parse(xml_file)
    return tree

def has_tag_with_value(tree, tag, value):
    """ Check if xml tree has a node with tag and value

    Args:
        tree: the xml tree
        tag: the tag
        value: text of tag
    Returns:
        Boolean
    """
    for node in tree.iter():
        if node.tag == tag and node.text == value:
            return True
    return False

