# -*- coding: utf-8 -*-
#
# Configuration file for the Sphinx documentation builder.
#
# This file does only contain a selection of the most common options. For a
# full list see the documentation:
# http://www.sphinx-doc.org/en/master/config

# -- Path setup --------------------------------------------------------------

# If extensions (or modules to document with autodoc) are in another directory,
# add these directories to sys.path here. If the directory is relative to the
# documentation root, use os.path.abspath to make it absolute, like shown here.
#
import os
import sys
sys.path.insert(0, os.path.abspath('.'))



# -- Project information -----------------------------------------------------

project = 'UFS Short-Range Weather App Users Guide'
copyright = '2020, '
author = ' '

# The short X.Y version
version = 'v2.2.0'
# The full version, including alpha/beta/rc tags
release = 'v2.2.0'

numfig = True

# -- General configuration ---------------------------------------------------

# If your documentation needs a minimal Sphinx version, state it here.
#
# needs_sphinx = '1.0'

# Add any Sphinx extension module names here, as strings. They can be
# extensions coming with Sphinx (named 'sphinx.ext.*') or your custom
# ones.
extensions = [
    'sphinx_rtd_theme',
    'sphinx.ext.autodoc',
    'sphinx.ext.doctest',
    'sphinx.ext.intersphinx',
    'sphinx.ext.todo',
    'sphinx.ext.coverage',
    'sphinx.ext.mathjax',
    'sphinx.ext.ifconfig',
    'sphinx.ext.viewcode',
    'sphinx.ext.githubpages',
    'sphinx.ext.napoleon',
    'sphinxcontrib.bibtex',
]

bibtex_bibfiles = ['references.bib']
#bibtex_bibfiles = ['refs.bib']

# Add any paths that contain templates here, relative to this directory.
templates_path = ['_templates']

# The suffix(es) of source filenames.
# You can specify multiple suffix as a list of string:
#
# source_suffix = ['.rst', '.md']
source_suffix = '.rst'

# The master toctree document.
master_doc = 'index'

# The language for content autogenerated by Sphinx. Refer to documentation
# for a list of supported languages.
#
# This is also used if you do content translation via gettext catalogs.
# Usually you set "language" from the command line for these cases.
language = None

# List of patterns, relative to source directory, that match files and
# directories to ignore when looking for source files.
# This pattern also affects html_static_path and html_extra_path.
exclude_patterns = []

# The name of the Pygments (syntax highlighting) style to use.
pygments_style = 'sphinx'

# Documentation-wide substitutions

rst_prolog = """
.. |wflow_env| replace:: ``workflow_tools``
.. |activate| replace:: ``conda activate workflow_tools``
.. |prompt| replace:: ``(workflow_tools)``
.. |latestr| replace:: v2.2.0
.. |branch| replace:: ``release/public-v2.2.0``
.. |data| replace:: v2p2
"""

# -- Options for HTML output -------------------------------------------------

# The theme to use for HTML and HTML Help pages.  See the documentation for
# a list of builtin themes.
#
html_theme = 'sphinx_rtd_theme'
html_theme_path = ["_themes", ]

# Theme options are theme-specific and customize the look and feel of a theme
# further.  For a list of options available for each theme, see the
# documentation.
#
# html_theme_options = {}
html_theme_options = {"body_max_width": "none"}

# Add any paths that contain custom static files (such as style sheets) here,
# relative to this directory. They are copied after the builtin static files,
# so a file named "default.css" will overwrite the builtin "default.css".
#html_static_path = []
html_static_path = ['_static']
html_context = {}

def setup(app):
    app.add_css_file('custom.css')  # may also be an URL
    app.add_css_file('theme_overrides.css')  # may also be a URL

# Custom sidebar templates, must be a dictionary that maps document names
# to template names.
#
# The default sidebars (for documents that don't match any pattern) are
# defined by theme itself.  Builtin themes are using these templates by
# default: ``['localtoc.html', 'relations.html', 'sourcelink.html',
# 'searchbox.html']``.
#
# html_sidebars = {}


# -- Options for HTMLHelp output ---------------------------------------------

# Output file base name for HTML help builder.
htmlhelp_basename = 'UFS-SR-Weather-App'


# -- Options for LaTeX output ------------------------------------------------

latex_engine = 'pdflatex'
latex_elements = {
    # The paper size ('letterpaper' or 'a4paper').
      'papersize': 'letterpaper',

    # The font size ('10pt', '11pt' or '12pt').
      'pointsize': '11pt',

    # Additional stuff for the LaTeX preamble.
      'preamble': r'''
        \usepackage{charter}
        \usepackage[defaultsans]{lato}
        \usepackage{inconsolata}
    ''',
    # Release name prefix
      'releasename': ' ',

    # Latex figure (float) alignment
    #
    # 'figure_align': 'htbp',
}

# Grouping the document tree into LaTeX files. List of tuples
# (source start file, target name, title,
#  author, documentclass [howto, manual, or own class]).
latex_documents = [
    (master_doc, 'UFS-SRWeatherApp.tex', 'UFS Short-Range Weather App Users Guide',
     ' ', 'manual'),
]


# -- Options for manual page output ------------------------------------------

# One entry per manual page. List of tuples
# (source start file, name, description, authors, manual section).
man_pages = [
    (master_doc, 'UFS-SRWeatherApp', 'UFS Short-Range Weather App Users Guide',
     [author], 1)
]


# -- Options for Texinfo output ----------------------------------------------

# Grouping the document tree into Texinfo files. List of tuples
# (source start file, target name, title, author,
#  dir menu entry, description, category)
texinfo_documents = [
    (master_doc, 'UFS-SRWeatherApp', 'UFS Short-Range Weather App Users Guide',
     author, 'UFS-SRWeatherApp', 'One line description of project.',
     'Miscellaneous'),
]


# -- Options for Epub output -------------------------------------------------

# Bibliographic Dublin Core info.
epub_title = project

# The unique identifier of the text. This can be a ISBN number
# or the project homepage.
#
# epub_identifier = ''

# A unique identification for the text.
#
# epub_uid = ''

# A list of files that should not be packed into the epub file.
epub_exclude_files = ['search.html']


# -- Extension configuration -------------------------------------------------

# -- Options for intersphinx extension ---------------------------------------

# Example configuration for intersphinx: refer to the Python standard library.
intersphinx_mapping = {
   'hpc-stack': ('https://hpc-stack-epic.readthedocs.io/en/latest/', None),
   'spack-stack': ('https://spack-stack.readthedocs.io/en/1.4.1/', None),
   'met': ('https://met.readthedocs.io/en/latest/', None),
   'srw_v2.1.0': ('https://ufs-srweather-app.readthedocs.io/en/release-public-v2.1.0/', None),
   'ufs-wm': ('https://ufs-weather-model.readthedocs.io/en/latest/', None),
}

# COMMENT: Update hpc-stack ref to release docs! https://hpc-stack-epic.readthedocs.io/en/release-srw-public-v2.2.0/

# -- Options for todo extension ----------------------------------------------

# If true, `todo` and `todoList` produce output, else they produce nothing.
todo_include_todos = True
