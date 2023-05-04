#!/usr/bin/env python3

"""
This file provides utilities for processing different configuration file formats.
Supported formats include:
    a) YAML
    b) JSON
    c) SHELL
    d) INI
    e) XML

Typical usage involves first loading the config file, then using the dictionary
returnded by load_config to make queries.

"""

import argparse
import configparser
import datetime
import json
import os
import pathlib
import re
from textwrap import dedent
import xml.etree.ElementTree as ET
from xml.dom import minidom

import jinja2
#
# Note: yaml may not be available in which case we suppress
# the exception, so that we can have other functionality
# provided by this module.
#
try:
    import yaml
except ModuleNotFoundError:
    pass

from .environment import list_to_str, str_to_list, str_to_type
from .run_command import run_command

##########
# YAML
##########
def load_yaml_config(config_file):
    """Safe load a yaml file"""

    with open(config_file, "r") as f:
        cfg = yaml.safe_load(f)

    return cfg


try:

    class custom_dumper(yaml.Dumper):
        """Custom yaml dumper to correct list indentation"""

        def increase_indent(self, flow=False, indentless=False):
            return super(custom_dumper, self).increase_indent(flow, False)

    def str_presenter(dumper, data):
        if len(data.splitlines()) > 1:
            return dumper.represent_scalar("tag:yaml.org,2002:str", data, style="|")
        return dumper.represent_scalar("tag:yaml.org,2002:str", data)

    yaml.add_representer(str, str_presenter)

except NameError:
    pass


def cfg_to_yaml_str(cfg):
    """Get contents of config file as a yaml string"""

    return yaml.dump(
        cfg, sort_keys=False, default_flow_style=False
    )

def cycstr(loader, node):

    ''' Returns a cyclestring Element whose content corresponds to the
    input node argument '''

    arg = loader.construct_scalar(node)
    return f'<cyclestr>{arg}</cyclestr>'

def include(filepaths):

    ''' Returns a dictionary that includes the contents of the referenced
    YAML file(s). '''

    srw_path = pathlib.Path(__file__).resolve().parents[0].parents[0]

    cfg = {}
    for filepath in filepaths:
        abs_path = filepath
        if not os.path.isabs(filepath):
            abs_path = os.path.join(os.path.dirname(srw_path), filepath)
        with open(abs_path, 'r') as fp:
            contents = yaml.load(fp, Loader=yaml.SafeLoader)
        for key, value in contents.items():
            cfg[key] = value
    return yaml.dump(cfg, sort_keys=False)

def join_str(loader, node):
    """Custom tag hangler to join strings"""
    seq = loader.construct_sequence(node)
    return "".join([str(i) for i in seq])

def startstopfreq(loader, node):

    ''' Returns a Rocoto-formatted string for the contents of a cycledef
    tag. Assume that the items in the node are env variables, and return
    a Rocoto-formatted string'''

    args = loader.construct_sequence(node)

    # Try to fill the values from environment values, default to the
    # value provided in the entry.
    start, stop, freq = (os.environ.get(arg, arg) for arg in args)

    return f'{start}00 {stop}00 {freq}:00:00'

def nowtimestamp(loader, node):
    return "id_" + str(int(datetime.datetime.now().timestamp()))

try:
    yaml.add_constructor("!cycstr", cycstr, Loader=yaml.SafeLoader)
    yaml.add_constructor("!include", include, Loader=yaml.SafeLoader)
    yaml.add_constructor("!join_str", join_str, Loader=yaml.SafeLoader)
    yaml.add_constructor("!startstopfreq", startstopfreq, Loader=yaml.SafeLoader)
    yaml.add_constructor("!nowtimestamp", nowtimestamp ,Loader=yaml.SafeLoader)
except NameError:
    pass



def path_join(arg):
    """A filter for jinja2 that joins paths"""

    return os.path.join(*arg)

def days_ago(arg):
    """A filter for jinja2 that gives us a date string for x number of
    days ago"""

    return (datetime.date.today() -
            datetime.timedelta(days=arg)).strftime("%Y%m%d00")

def extend_yaml(yaml_dict, full_dict=None, parent=None):
    """
    Updates yaml_dict inplace by rendering any existing Jinja2 templates
    that exist in a value.
    """

    if full_dict is None:
        full_dict = yaml_dict

    if parent is None:
        full_dict = yaml_dict

    if not isinstance(yaml_dict, dict):
        return

    for k, val in yaml_dict.items():

        if isinstance(val, dict):
            extend_yaml(val, full_dict, yaml_dict)
        else:

            if not isinstance(val, list):
                val = [val]

            for v_idx, v in enumerate(val):
                # Save a bit of compute and only do this part for strings that
                # contain the jinja double brackets.
                v_str = str(v.text) if isinstance(v, ET.Element) else str(v)
                if isinstance(v, ET.Element):
                    print('ELEMENT VSTR', v_str, v.text, yaml_dict)
                is_a_template = any((ele for ele in ["{{", "{%"] if ele in v_str))
                if is_a_template:
                    # Find expressions first, and process them as a single template
                    # if they exist
                    # Find individual double curly brace template in the string
                    # otherwise. We need one substitution template at a time so that
                    # we can opt to leave some un-filled when they are not yet set.
                    # For example, we can save cycle-dependent templates to fill in
                    # at run time.
                    if "{%" in v_str:
                        templates = [v_str]
                    else:
                        # Separates out all the double curly bracket pairs
                        templates = [m.group() for m in
                                re.finditer(r"{{[^}]*}}|\S", v_str)  if '{{'
                                in m.group()]
                    data = []
                    for template in templates:
                        j2env = jinja2.Environment(
                            loader=jinja2.BaseLoader, undefined=jinja2.StrictUndefined
                        )
                        j2env.filters["path_join"] = path_join
                        j2env.filters["days_ago"] = days_ago
                        j2env.filters["include"] = include
                        try:
                            j2tmpl = j2env.from_string(template)
                        except:
                            print(f"ERROR filling template: {template}, {v_str}")
                            raise
                        try:
                            # Fill in a template that has the appropriate variables
                            # set.
                            template = j2tmpl.render(parent=parent, **yaml_dict, **full_dict)
                        except jinja2.exceptions.UndefinedError as e:
                            # Leave a templated field as-is in the resulting dict
                            pass
                        except ValueError:
                            pass
                        except TypeError:
                            pass
                        except ZeroDivisionError:
                            pass
                        except:
                            print(f"{k}: {template}")
                            raise

                        data.append(template)

                    convert_type = True
                    for tmpl, rendered in zip(templates, data):
                        v_str = v_str.replace(tmpl, rendered)
                        if "string" in tmpl:
                            convert_type = False

                    if convert_type:
                        v_str = str_to_type(v_str)

                    if isinstance(v, ET.Element):
                        print('Replacing ET text with', v_str)
                        v.text = v_str
                    elif isinstance(yaml_dict[k], list):
                        yaml_dict[k][v_idx] = v_str
                    else:
                        # Put the full template line back together as it was,
                        # filled or not
                        yaml_dict[k] = v_str


##########
# JSON
##########
def load_json_config(config_file):
    """Load json config file"""

    try:
        with open(config_file, "r") as f:
            cfg = json.load(f)
    except json.JSONDecodeError as e:
        raise Exception(f"Unable to load json file {config_file}")

    return cfg


def cfg_to_json_str(cfg):
    """Get contents of config file as a json string"""

    return json.dumps(cfg, sort_keys=False, indent=4) + "\n"


##########
# SHELL
##########
def load_shell_as_ini_config(file_name, return_string=1):
    """Load shell config file with embedded structure in comments"""

    # read contents and replace comments as sections
    with open(file_name, "r") as file:
        cfg = file.read()
        cfg = cfg.replace("# [", "[")
        cfg = cfg.replace("\\\n", " ")

    # write content to temp file and load it as ini
    temp_file = os.path.join(os.getcwd(), "_temp." + str(os.getpid()) + ".ini")
    with open(temp_file, "w") as file:
        file.write(cfg)

    # load it as a structured ini file
    try:
        cfg = load_ini_config(temp_file, return_string)
    finally:
        os.remove(temp_file)

    return cfg


def load_shell_config(config_file, return_string=0):
    """Loads old style shell config files.
    We source the config script in a subshell and gets the variables it sets

    Args:
         config_file: path to config file script
    Returns:
         dictionary that should be equivalent to one obtained from parsing a yaml file.
    """

    # First try to load it as a structured shell config file
    try:
        cfg = load_shell_as_ini_config(config_file, return_string)
        return cfg
    except:
        pass

    # Save env vars before and after sourcing the scipt and then
    # do a diff to get variables specifically defined/updated in the script
    # Method sounds brittle but seems to work ok so far
    pid = os.getpid()
    code = dedent(
        f"""      #!/bin/bash
      t1="./t1.{pid}"
      t2="./t2.{pid}"
      (set -o posix; set) > $t1
      {{ . {config_file}; set +x; }} &>/dev/null
      (set -o posix; set) > $t2
      diff $t1 $t2 | grep "> " | cut -c 3-
      rm -rf $t1 $t2
    """
    )
    (_, config_str, _) = run_command(code)
    lines = config_str.splitlines()

    # build the dictionary
    cfg = {}
    for l in lines:
        idx = l.find("=")
        k = l[:idx]
        v = str_to_list(l[idx + 1 :], return_string)
        cfg[k] = v
    return cfg


def cfg_to_shell_str(cfg, kname=None):
    """Get contents of config file as shell script string"""

    shell_str = ""
    for k, v in cfg.items():
        if isinstance(v, dict):
            if kname:
                n_kname = f"{kname}.{k}"
            else:
                n_kname = f"{k}"
            shell_str += f"# [{n_kname}]\n"
            shell_str += cfg_to_shell_str(v, n_kname)
            shell_str += "\n"
            continue
        # others
        v1 = list_to_str(v)
        if isinstance(v, list):
            shell_str += f"{k}={v1}\n"
        else:
            # replace some problematic chars
            v1 = v1.replace("'", '"')
            v1 = v1.replace("\n", " ")
            # end problematic
            shell_str += f"{k}='{v1}'\n"
    return shell_str


##########
# INI
##########
def load_ini_config(config_file, return_string=0):
    """Load a config file with a format similar to Microsoft's INI files"""

    if not os.path.exists(config_file):
        raise FileNotFoundError(
            dedent(
                f"""
                The specified configuration file does not exist:
                '{config_file}'"""
            )
        )

    config = configparser.RawConfigParser()
    config.optionxform = str
    config.read(config_file)
    config_dict = {s: dict(config.items(s)) for s in config.sections()}
    for _, vs in config_dict.items():
        for k, v in vs.items():
            vs[k] = str_to_list(v, return_string)
    return config_dict


def get_ini_value(config, section, key):
    """Finds the value of a property in a given section"""

    if not section in config:
        raise KeyError(f"Section not found: {section}")
    else:
        return config[section][key]

    return None


def cfg_to_ini_str(cfg, kname=None):
    """Get contents of config file as ini string"""

    ini_str = ""
    for k, v in cfg.items():
        if isinstance(v, dict):
            if kname:
                n_kname = f"{kname}.{k}"
            else:
                n_kname = f"{k}"
            ini_str += f"[{n_kname}]\n"
            ini_str += cfg_to_ini_str(v, n_kname)
            ini_str += "\n"
            continue
        v1 = list_to_str(v, True)
        if isinstance(v, list):
            ini_str += f"{k}={v1}\n"
        else:
            ini_str += f"{k}='{v1}'\n"
    return ini_str


##########
# XML
##########
def xml_to_dict(root, return_string):
    """Convert an xml tree to dictionary"""

    cfg = {}
    for child in root:
        if len(list(child)) > 0:
            r = xml_to_dict(child, return_string)
            cfg[child.tag] = r
        else:
            cfg[child.tag] = str_to_list(child.text, return_string)
    return cfg


def dict_to_xml(d, tag):
    """Convert dictionary to an xml tree"""

    elem = ET.Element(tag)
    for k, v in d.items():
        if isinstance(v, dict):
            r = dict_to_xml(v, k)
            elem.append(r)
        else:
            child = ET.Element(k)
            child.text = list_to_str(v, True)
            elem.append(child)

    return elem


def load_xml_config(config_file, return_string=0):
    """Load xml config file"""

    tree = ET.parse(config_file)
    root = tree.getroot()
    cfg = xml_to_dict(root, return_string)
    return cfg


def cfg_to_xml_str(cfg):
    """Get contents of config file as a xml string"""

    root = dict_to_xml(cfg, "root")
    r = ET.tostring(root, encoding="unicode")
    r = minidom.parseString(r)
    r = r.toprettyxml(indent="  ")
    r = r.replace("&quot;", '"')
    return r


##################
# CONFIG utils
##################
def flatten_dict(dictionary, keys=None):
    """Flatten a recursive dictionary (e.g.yaml/json) to be one level deep

    Args:
        dictionary: the source dictionary
        keys: list of keys on top level whose contents to flatten, if None all of them
    Returns:
        A one-level deep dictionary for the selected set of keys
    """
    flat_dict = {}
    for k, v in dictionary.items():
        if not keys or k in keys:
            if isinstance(v, dict):
                r = flatten_dict(v)
                flat_dict.update(r)
            else:
                flat_dict[k] = v
    return flat_dict


def structure_dict(dict_o, dict_t):
    """Structure a dictionary based on a template dictionary

    Args:
        dict_o: dictionary to structure (flat one level structure)
        dict_t: template dictionary used for structuring
    Returns:
        A dictionary with contents of dict_o following structure of dict_t
    """
    struct_dict = {}
    for k, v in dict_t.items():
        if isinstance(v, dict):
            r = structure_dict(dict_o, v)
            if r:
                struct_dict[k] = r
        elif k in dict_o.keys():
            struct_dict[k] = dict_o[k]
    return struct_dict


def update_dict(dict_o, dict_t, provide_default=False):
    """Update a dictionary with another

    Args:
        dict_o: flat dictionary used as source
        dict_t: target dictionary to update
    Returns:
        None
    """
    for k, v in dict_o.copy().items():
        if isinstance(v, dict):
            if isinstance(dict_t.get(k), dict):
                update_dict(v, dict_t[k], provide_default)
            else:
                dict_t[k] = v
        elif v is None and k in dict_t.keys():
            # remove the key if the source dict has null entry
            del dict_t[k]
        elif k in dict_t.keys():
            if (
                (not provide_default)
                or (dict_t[k] is None)
                or (len(dict_t[k]) == 0)
                or ("{{" in dict_t[k])
            ):
                dict_t[k] = v
        elif k not in dict_t.keys():
            dict_t[k] = v


def check_structure_dict(dict_o, dict_t):
    """Check if a dictionary's structure follows a template.
    The invalid entries are returned as a dictionary.
    If all entries are valid, returns an empty dictionary

    Args:
        dict_o: target dictionary
        dict_t: template dictionary to compare structure to
    Returns:
        dict:  Invalid key-value pairs.
    """
    inval = {}
    for k, v in dict_o.items():
        if k in dict_t.keys():
            v1 = dict_t[k]
            if isinstance(v, dict) and isinstance(v1, dict):
                r = check_structure_dict(v, v1)
                if r:
                    inval.update(r)
        else:
            inval[k] = v
    return inval


def filter_dict(dict_o, keys_regex):
    """Filter dictionary keys based on a list of keys
    Args:
        dict_o: the source dictionary
        keys_regex: list of keys to retain (could be regex exp.)
    """

    keys = []
    for k in keys_regex:
        r = re.compile(k)
        keys += list(filter(r.match, dict_o.keys()))
    dict_t = {k: dict_o[k] for k in keys}
    return dict_t


##################
# CONFIG loader
##################
def load_config_file(file_name, return_string=0):
    """Load config file based on file name extension"""

    ext = os.path.splitext(file_name)[1][1:]
    if ext == "sh":
        return load_shell_config(file_name, return_string)
    if ext == "ini":
        return load_ini_config(file_name, return_string)
    if ext == "json":
        return load_json_config(file_name)
    if ext in ["yaml", "yml"]:
        return load_yaml_config(file_name)
    if ext == "xml":
        return load_xml_config(file_name, return_string)
    return None


##################
# CONFIG main
##################
def cfg_main():
    """Main function for converting and formatting between different config file formats"""

    parser = argparse.ArgumentParser(
        description="Utility for managing different config formats."
    )
    parser.add_argument(
        "--cfg", "-c", dest="cfg", required=True, help="Config file to parse"
    )
    parser.add_argument(
        "--output-type",
        "-o",
        dest="out_type",
        required=False,
        help='Output format: can be any of ["shell", "yaml", "ini", "json", "xml"]',
    )
    parser.add_argument(
        "--flatten",
        "-f",
        dest="flatten",
        action="store_true",
        required=False,
        help="Flatten resulting dictionary",
    )
    parser.add_argument(
        "--template-cfg",
        "-t",
        dest="template",
        required=False,
        help="Template config file used to structure a given config file",
    )
    parser.add_argument(
        "--keys",
        "-k",
        dest="keys",
        nargs="+",
        required=False,
        help="Include only these keys of dictionary for processing.\
                              Keys can be python regex expression.",
    )
    parser.add_argument(
        "--validate-cfg",
        "-v",
        dest="validate",
        required=False,
        help="Validation config file used to validate a given config file",
    )

    args = parser.parse_args()
    cfg = load_config_file(args.cfg, 2)

    if args.validate:
        cfg_t = load_config_file(args.validate, 1)
        r = check_structure_dict(cfg, cfg_t)
        if r:
            for k in r:
                print(f"INVALID ENTRY: {k}={r[k]}")
            print("FAILURE")
        else:
            print("SUCCESS")
    else:
        if args.template:
            cfg = flatten_dict(cfg)
            cfg_t = load_config_file(args.template, 1)
            cfg = structure_dict(cfg, cfg_t)

        if args.keys:
            cfg = filter_dict(cfg, args.keys)

        if args.flatten:
            cfg = flatten_dict(cfg)

        # convert to string and print
        if args.out_type in ["shell", "sh"]:
            print(cfg_to_shell_str(cfg), end="")
        elif args.out_type == "ini":
            print(cfg_to_ini_str(cfg), end="")
        elif args.out_type == "json":
            print(cfg_to_json_str(cfg), end="")
        elif args.out_type in ["yaml", "yml"]:
            print(cfg_to_yaml_str(cfg), end="")
        elif args.out_type == "xml":
            print(cfg_to_xml_str(cfg), end="")
        else:
            parser.print_help()
            parser.exit()
