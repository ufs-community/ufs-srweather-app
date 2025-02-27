#!/bin/bash
# This script recreates technical documentation for the ush and tests/WE2E Python scripts
# If the tech docs produced here do not match the branch's contents, the script will fail

set -eo pipefail

# Install prerequisites
pip install Sphinx==7.4.7
pip install sphinx-rtd-theme
pip install sphinxcontrib-bibtex

# Regenerate tech docs in ush and tests/WE2E based on current state of scripts in those directories.
cd doc/TechDocs
sphinx-apidoc -fM --remove-old -o ./ush ../../ush
sphinx-apidoc -fM --remove-old -o ./tests/WE2E ../../tests/WE2E

# Check for mismatch between what comes out of this action and what is in the PR. 
status=`git status -s`

if [ -n "${status}" ]; then
  echo ${status}
  echo ""
  echo "Please update your Technical Documentation RST files."
  exit 1
else
  echo "Technical documentation is up-to-date."
  exit 0
fi
