'''
A standalone tool that reads a YAML file and generates a Rocoto XML.
'''


import argparse
from copy import deepcopy
from io import StringIO
import logging
import os
import pathlib
import re
import sys
from textwrap import dedent
import xml.etree.ElementTree as ET
import xml.dom.minidom as minidom

import jinja2
import yaml

from python_utils import extend_yaml

def load_config(arg):

    '''
    Check to ensure that the provided config file exists. If it does, load it
    with YAML's safe loader and return the resulting dict.
    '''

    # Check for existence of file
    if not os.path.exists(arg):
        msg = f'{arg} does not exist!'
        raise argparse.ArgumentTypeError(msg)

    with open(arg, 'r') as fn:
        cfg = yaml.load(fn, Loader=yaml.SafeLoader)

    return cfg

def path_join(arg):

    return os.path.join(*arg)

def prettify(elem):
    """Return a pretty-printed XML string for the Element.
    """
    rough_string = ET.tostring(elem, 'utf-8')
    reparsed = minidom.parseString(rough_string)
    # Remove the first line containing xml tag.
    reparsed = reparsed.toprettyxml(indent="  ")
    return reparsed.split('\n', 1)[-1]

def path_ok(arg):

    '''
    Check whether the path to the file exists, and is writeable. Return the path
    if it passes all checks, otherwise raise an error.
    '''

    # Get the absolute path provided by arg
    dir_name = os.path.abspath(os.path.dirname(arg))

    # Ensure the arg path exists, and is writable. Raise error if not.
    if os.path.lexists(dir_name) and os.access(dir_name, os.W_OK):
        return arg

    msg = f'{arg} is not a writable path!'
    raise argparse.ArgumentTypeError(msg)

def create_header(entities):

    ''' Create the workflow definition header for Rocoto (a string).
    Provide entities via a Python dict with keys describing the name of
    the entity, and values corresponding to the entity values. '''

    rocoto_header = dedent('''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE workflow [\n''')

    for ent, val in entities.items():
        rocoto_header+=f'<!ENTITY {ent} "{val}">\n'

    rocoto_header+=']>'

    return rocoto_header

def create_workflow_tree(workflow_config):

    ''' The workflow tree must contain a cycledef tag(s) and a log tag, each
    must be present in the workflow_config dict, along with any other
    workflow flag attributes.

    Common Rocoto workflow attributes include realtime, scheduler, and
    cyclethrottle.
    '''

    workflow = ET.Element('workflow', attrib=workflow_config.get('attrs'))

    cycledefs = workflow_config.get('cycledefs')

    # Generate all the cycledefs defined in the config
    for cycledef, cd_config in cycledefs.items():
        content = cd_config.pop('dates')
        print("contents", content)
        cycle = ET.SubElement(
            workflow,
            'cycledef',
            attrib=dict(group=cycledef, **cd_config)
            )
        cycle.text = content

    # Add a log SubElement
    log = ET.SubElement(workflow, 'log')
    log_loc = ET.SubElement(log, 'cyclestr')
    log_loc.text = workflow_config.get('log')

    return workflow

def element_or_text(value, parent):

    ''' Updates parent in place. If value is an ET.Element, it appends
    to the parent, but updates the text of parent, otherwise. '''

    if isinstance(value, ET.Element):
        parent.append(value)
    else:
        parent.text = str(value)


def build_dependency_tree(dep_dict, parent):

    ''' Recursively builds the dependency tree for Rocoto workflows by
    traversing the depths of an input dictionary.

    This section does not follow a strict structure, but allows
    for the nesting of dependencies as they would show up in the XML.

    Input:

      dep_dict:  Task dependencies. Each key must be unique, so label
                 duplicates with a suffix "_labelname". The label name
                 will be discarded.
      parent:    Each item will be a subelement (or child) of some other
                 Element in the tree. Specify the appropriate parent here.

    Returns:

      None. Updates the parent Element Tree by adding subelements to it.
    '''

    if not isinstance(dep_dict, dict):
        return

    for tag, values in dep_dict.items():
        tag_type = tag.split('_')[0]
        tag_values = deepcopy(values)
        attrs = {}
        content = tag_values
        if isinstance(tag_values, dict):
           attrs = tag_values.pop('attrs', {})
           content = tag_values.pop('text', None)

        xml_tag = ET.SubElement(parent, tag_type, attrib=attrs)
        if content is not None:
            element_or_text(content, xml_tag)
        build_dependency_tree(tag_values, xml_tag)

def build_task(name, config, parent):

    ''' Create a task subelement of the parent that matches the provided
    Rocoto task config. A Rocoto task often has attributes like
    cycledefs and maxtries.

    To build a SubElement Rocoto task, it should be named (the name that
    shows up in the Rocoto database, and should include configuration
    items like environment variables (envar tags), entities (references
    to entities that were defined in the workflow definition),
    dependencies, and a variety of "simple" flags like walltime,
    command, nodes, etc.

    Input

      name:    The name of the task. This is a required argument, and
               typically comes from the YAML key that defines the task.
               However, an alternate name (especially in metatasks) may
               be provided as a different string in the task's
               attrs.name entry. The attrs.name entry takes precedence
      config:  a dictionary defining the configuration of the task
      parent:  the parent element of the task in the workflow tree. this
               could be the workflow or a metatask.

    Returns

      None. Updates the parent Element Tree by adding subelements to it.
    '''

    config = deepcopy(config)
    attrs = config.pop('attrs', {})
    if attrs.get('name') is None:
        attrs['name'] = name

    config['jobname'] = name
    extend_yaml(config)

    if name == 'get_extrn_lbcs':
      print('TASK CONFIG: ', config)
      exit()
    task_elem = ET.SubElement(parent, 'task', attrib=attrs)
    for tag, tag_value in config.items():
        if tag == 'envars':
            for var, var_value in tag_value.items():
                envar = ET.SubElement(task_elem, 'envar')
                var_name = ET.SubElement(envar, 'name')
                var_name.text = var
                var_val = ET.SubElement(envar, 'value')
                element_or_text(var_value, var_val)
        elif tag == 'entities':
            for entity in tag_value:
                element_or_text(entity, task_elem)
        elif tag == 'dependency':
            dep_tag = ET.SubElement(task_elem, tag)
            build_dependency_tree(tag_value, dep_tag)
        elif tag in ['nnodes', 'ppn', 'jobname']:
            continue
        else:
            task_tag = ET.SubElement(task_elem, tag)
            element_or_text(tag_value, task_tag)

def build_metatask(name, config, parent):

    ''' Create a metatask subelement of the workflow (or another
    metatask).

    Input

      name:    the metatask name. Provided via the key in the YAML
               config.
      config:  a dictionary defining the configuration of the task
      parent:  the parent element of the task in the workflow tree. this
               could be the workflow or a metatask.

    Returns

      None. Updates the parent Element Tree by adding subelements to it.

    '''
    attrs = config.get('attrs', {})
    attrs['name'] = name
    metatask_elem = ET.SubElement(parent, 'metatask', attrib=attrs)

    # Create the required variable tag. Remove vars from the config dict
    # as they are added to the tree to help with parsing the tasks.
    meta_vars = config.pop('var')
    for var, var_vals in meta_vars.items():
        var_name = dict(name=var)
        var_elem = ET.SubElement(metatask_elem, 'var', attrib=var_name)
        var_elem.text = var_vals

    # Create the subelements needed to complete the metatask
    build_task_elements(config, metatask_elem)

def build_task_elements(task_dict, parent):

    ''' A wrapper that determines the elements of a workflow given the
    keys in task_dict and builds out the tree to include metatasks or a
    set of single tasks. '''

    for task, task_config in task_dict.items():
        task_type, task_name = task.split('_', maxsplit=1)
        if task_type == 'metatask':
            # Do the metatask stuff
            build_metatask(task_name, task_config, parent)
        elif task_type == 'task':
            # Do the task stuff.
            build_task(task_name, task_config, parent)

def parse_args(argv):

    '''
    Function maintains the arguments accepted by this script. Please see
    Python's argparse documentation for more information about settings of each
    argument.
    '''

    parser = argparse.ArgumentParser(
        description='Create a Rocoto XML file from a YAML config.'''
    )

    parser.add_argument('-c', '--config',
                    help='Full path to a YAML user config file, and a \
                    top-level section to use (optional).',
                    )
    parser.add_argument('-o', '--outxml',
                    dest='outxml',
                    help='Full path to the output Rocoto XML file.',
                    type=path_ok,
                    )

    parser.add_argument('--dryrun',
        action='store_true',
        help="Print rendered template to screen instead of output file",
        )
    return parser.parse_args(argv)

def create_xml(argv, config_dict=None):

    ''' Builds the ElementTree corresponding to the Rocoto workflow
    described by a YAML config file and writes it out to an XML file.
    '''

    cla = parse_args(argv)

    if cla.config is not None:
        user_config = load_config(cla.config)

        for k, v in user_config.items():
            logging.debug(f'{k}: {v}')
        extend_yaml(user_config)
        extend_yaml(user_config)

    if isinstance(config_dict, dict):
        user_config = config_dict

    logging.info(f"Running create_xml with args: ")
    for name, val in cla.__dict__.items():
        logging.info(f"{name:>15s}: {val}")

    workflow_config = user_config.get('rocoto')

    logging.info(f"Workflow config settings are: ")
    logging.info(yaml.dump(workflow_config))

    # Generate the header with all the entity info as a string.
    header = create_header(workflow_config.get('entities', {}))

    # Generate the XML workflow as a tree
    # This is the part with all the cycle defs, log info, etc.
    workflow = create_workflow_tree(workflow_config)

    # Add all the workflow tasks/metatasks to the tree
    tasks = workflow_config.get('tasks', {})
    build_task_elements(tasks, workflow)

    # Write the full workflow, header and tree, to the desired output
    # location
    if cla.dryrun or not cla.outxml:
        logging.INFO(header)
        logging.INFO(prettify(workflow))
    else:
        with open(cla.outxml, 'w') as fn:
            fn.write(header)
            fn.write(prettify(workflow))

def setup_logging(logfile: str = "log.create_xml") -> None:
    """
    Sets up logging, printing high-priority (INFO and higher) messages to screen, and printing all
    messages with detailed timing and routine info in the specified text file.
    """
    logging.basicConfig(
        level=logging.DEBUG,
        format="%(name)-22s %(levelname)-8s %(message)s",
        filename=logfile,
        filemode="w",
    )
    logging.debug(f"Finished setting up debug file logging in {logfile}")
    console = logging.StreamHandler()
    console.setLevel(logging.INFO)
    logging.getLogger().addHandler(console)
    logging.debug("Logging set up successfully")

if __name__ == '__main__':

    setup_logging()
    create_xml(sys.argv[1:])

