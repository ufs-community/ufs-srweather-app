import argparse
import random
import string
import sys
import xml.etree.ElementTree as ET

import yaml


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
    parser.add_argument('-i', '--inxml',
                    dest='inxml',
                    help='Full path to the Rocoto XML file.',
                    )

    parser.add_argument('--dryrun',
        action='store_true',
        help="Print rendered template to screen instead of output file",
        )
    return parser.parse_args(argv)


def main(argv):


    user_settings = parse_args(argv)

    # parse the xml
    xml_tree = ET.parse(user_settings.inxml)
    xml_root = xml_tree.getroot()

    xml_config = {}

    # The root attributes give us the workflow:attrs section
    xml_config['attrs'] = xml_root.attrib

    # Get the cycledefs
    cdefs = xml_root.findall('cycledef')
    xml_config['cycledefs'] = {}
    for cdef in cdefs:
        xml_config['cycledefs'].update(
                {cdef.attrib.get('group'): cdef.text })

    # Get the log
    xml_config['log'] = xml_root.find('log').text.strip()

    # Get the tasks
    xml_config['tasks'] = {}
    for task in xml_root.findall('task'):
        task_name = f'task_{task.attrib.pop("name")}'

        xml_config['tasks'].update({
            task_name: {
                'attrs': task.attrib,
                }
            })

        for envar in task.findall('envar'):
            if not xml_config['tasks'][task_name].get('envars'):
                xml_config['tasks'][task_name]['envars'] = {}
            name, value = [c for c in list(envar)]
            value = value.text or list(value)[0].text
            xml_config['tasks'][task_name]['envars'].update({
                    name.text: value,
                    })
            task.remove(envar)

        build_wflow_dict(xml_config['tasks'][task_name], task)

    print(yaml.dump(xml_config))

def build_wflow_dict(cfg, root):

    for element in list(root):
        tag = element.tag
        if cfg.get(tag) is not None:
            # create a short random string to add to the tag
            tag = f"{tag}_{''.join(random.choices(string.ascii_lowercase,k=5))}"
        if list(element):
            cfg[tag] = {}
            build_wflow_dict(cfg[tag], element)
        else:
            cfg[tag] = element.text.strip() if isinstance(element.text, str) else element.text






if __name__ == '__main__':
  main(sys.argv[1:])
