#!/usr/bin/env python3

import subprocess

def run_command(cmd):
    """ Run system command in a subprocess

    Args:
        cmd: command to execute
    Returns:
        Tuple of (exit code, std_out, std_err)
    """
    proc = subprocess.Popen(cmd,
                            stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE,
                            shell=True,
                            universal_newlines=True)

    std_out, std_err = proc.communicate()

    # strip trailing newline character
    return (proc.returncode,
            std_out.rstrip('\n'),
            std_err.rstrip('\n'))

