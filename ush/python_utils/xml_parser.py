#!/usr/bin/env python3

import xml.etree.ElementTree as ET


def load_xml_file(xml_file):
    """Loads XML file

    Args:
        xml_file: Path to XML file
    Returns:
        tree: Root of the XML tree
    """
    tree = ET.parse(xml_file)
    return tree


def has_tag_with_value(tree, tag, value):
    """Checks if XML tree has a node with tag and value

    Args:
        tree (xml.etree.ElementTree): The XML tree
        tag (str): The tag
        value (str): Text of tag
    Returns:
        Boolean value
    """
    for node in tree.iter():
        if node.tag == tag and node.text == value:
            return True
    return False
