#!/usr/bin/env python3
#pylint: disable=consider-using-f-string, duplicate-code

'''
This utility renders a Jinja2 template using user-supplied configuration options
via YAML or environment variables.
'''

import argparse
import inspect
import logging
import os
import sys

#from uwtools.j2template import J2Template
from j2template import J2Template
#from uwtools import config
import config
#from uwtools.utils import cli_helpers
import cli_helpers


def parse_args(argv):

    '''
    Function maintains the arguments accepted by this script. Please see
    Python's argparse documentation for more information about settings of each
    argument.
    '''

    parser = argparse.ArgumentParser(
       description='Update a Jinja2 Template with user-defined settings.'
    )
    parser.add_argument(
        '-o', '--outfile',
        help='Full path to output file',
        )
    parser.add_argument(
        '-i', '--input_template',
        help='Path to a Jinja2 template file.',
        required=True,
        type=cli_helpers.path_if_file_exists,
        )
    parser.add_argument(
        '-c', '--config_file',
        help='Optional path to a YAML configuration file. If not provided, '
        'os.environ is used to configure.',
        type=cli_helpers.path_if_file_exists,
        )
    parser.add_argument(
        'config_items',
        help='Any number of configuration settings that will override values '
        'found in YAML or user environment.',
        metavar='KEY=VALUE',
        nargs='*',
        )
    parser.add_argument(
        '-d', '--dry_run',
        action='store_true',
        help='If provided, print rendered template to stdout only',
        )
    parser.add_argument(
        '--values_needed',
        action='store_true',
        help='If provided, print a list of required configuration settings to stdout',
        )
    parser.add_argument(
        '-v', '--verbose',
        action='store_true',
        help='If provided, print all logging messages.',
        )
    parser.add_argument(
        '-q', '--quiet',
        action='store_true',
        help='If provided, print no logging messages',
        )
    parser.add_argument(
        '-l', '--log_file',
        help='Optional path to a specified log file',
        default=os.path.join(os.path.dirname(__file__), "templater.log")
        )
    return parser.parse_args(argv)

def setup_config_obj(user_args, log_name=None):

    ''' Return a dictionary config object from a user-supplied config,
    the os environment, and the command line arguments. '''

    log = logging.getLogger(log_name)
    if user_args.config_file:
        config_type = cli_helpers.get_file_type(user_args.config_file)
        cfg_obj = getattr(config, f"{config_type}Config")
        cfg = cfg_obj(user_args.config_file)
        log.debug("User config will be used to fill template.")
    else:
        cfg = os.environ
        log.debug("Environment variables will be used to fill template.")

    if user_args.config_items:
        user_settings = cli_helpers.dict_from_config_args(user_args.config_items)
        cfg.update(user_settings)
        log.debug("Overwriting config with settings on command line")

    return cfg

def set_template(argv):
    '''Main section for rendering and writing a template file'''
    user_args = parse_args(argv)

    name = f"{inspect.stack()[0][3]}"
    log = cli_helpers.setup_logging(user_args, log_name=name)

    log.info(f"""Running {name} with args: """)
    log.info(f"""{('-' * 70)}""")
    log.info(f"""{('-' * 70)}""")
    for name, val in user_args.__dict__.items():
        if name not in ["config"]:
            log.info("{name:>15s}: {val}".format(name=name, val=val))
    log.info(f"""{('-' * 70)}""")
    log.info(f"""{('-' * 70)}""")

    cfg = setup_config_obj(user_args, log_name=log.name)

    # instantiate Jinja2 environment and template
    template = J2Template(cfg, user_args.input_template,
                          log_name=log.name)

    undeclared_variables = template.undeclared_variables

    if user_args.values_needed:
        # Gather the undefined template variables
        log.info('Values needed for this template are:')
        for var in sorted(undeclared_variables):
            log.info(var)
        return

    # Check for missing values
    missing = []
    for var in undeclared_variables:
        if var not in cfg.keys():
            missing.append(var)

    if missing:
        log.critical("ERROR: Template requires variables that are not provided")
        for key in missing:
            log.critical(f"  {key}")
        msg = "Missing values needed by template"
        log.critical(msg)
        raise ValueError(msg)

    if user_args.dry_run:
        if user_args.outfile:
            log.info(r"warning file {outfile} ".format(outfile=user_args.outfile),
                 r"not written when using --dry_run")
        # apply switch to allow user to view the results of rendered template
        # instead of writing to disk
        # Render the template with the specified config object
        rendered_template = template.render_template()
        log.info(rendered_template)
    else:
        # write out rendered template to file
        template.dump_file(user_args.outfile)

if __name__ == '__main__':
    set_template(sys.argv[1:])
