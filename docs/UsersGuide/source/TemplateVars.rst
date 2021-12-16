.. _TemplateVars:

==============================================================
Using Template Variables in the Experiment Configuration Files
==============================================================
The SRW App's experiment configuration system supports the use of template variables 
in ``config_defaults.sh`` and ``config.sh``.  A template variable --- or, more briefly, 
a "template" --- is an experiment configuration variable that contains in its definition 
references to values of other variables.  If the template is defined properly as 
described below, then these references will **not** be immediately expanded (i.e. set 
to the values of the referenced variables) at the time the experiment's variable 
definitions file (``var_defns.sh``) is sourced.  This allows a developer to source 
``var_defns.sh`` in a bash script or function and then use bash's ``eval`` built-in 
command to expand the referenced variables and evaluate the resulting contents of the 
template (the call to ``eval`` must come **after** ``var_defns.sh`` is sourced).  Thus, 
templates provide a way of defining macros that can be applied (evaluated) once the 
variables that they reference become defined.  (In the following, we describe the use 
of templates in bash scripts, but the comments apply equally well to bash functions.)

As an example, consider a template named ``MY_CMD`` that is defined in ``config_defaults.sh`` 
(or redefined by the user in ``config.sh``) as follows:

   .. code-block:: none

     MY_CMD='cd \${some_dir}'

Here, ``some_dir`` may be an experiment variable defined in ``var_defns.sh`` or a 
local variable in a script that sources ``var_defns.sh`` and then expands and 
evaluates ``MY_CMD`` using ``eval``.  After the experiment generation system 
constructs ``var_defns.sh`` from the given ``config_defaults.sh`` and ``config.sh`` 
files, ``MY_CMD`` will be defined as follows in ``var_defns.sh``:

   .. code-block:: none

     MY_CMD="cd \${some_dir}"

Note that double quotes appear on the right-hand side of this automatically-generated 
definition, as opposed to single quotes in the default or user-specified definition 
in ``config_defaults.sh`` or ``config.sh``.  This is expected and is the correct behavior.

To demonstrate how ``MY_CMD`` can be used in a script, first consider the case in which 
``some_dir`` is an experiment variable defined in ``var_defns.sh``.  Then the contents 
of ``var_defns.sh`` will be as follows: 

   .. code-block:: none 

     ...
     MY_CMD="cd \${some_dir}"  # MY_CMD defined as a template variable.
     ...
     some_dir="20200715"       # some_dir defined as a literal string.
     ...

The order in which these two lines appear in ``var_defns.sh`` may be reversed, but that 
will not matter since the dollar sign in the definition of ``MY_CMD`` is escaped (so 
that bash will not attempt to expand ``${some_dir}`` to the value of ``some_dir`` when 
``var_defns.sh`` is sourced).  Then the following code snippet in a script will evaluate 
the contents of ``MY_CMD`` using the value of ``some_dir`` in ``var_defns.sh``:

   .. code-block:: none

     ...
     . var_defns.sh       # Source the experiment's variable definitions file (assuming
                          # it is in the current directory).  This defines the MY_CMD
                          # template variable (in addition to other variables).
     ...
     eval ${MY_CMD}       # Use eval to evaluate the contents of MY_CMD.  The value of
                          # some_dir set in var_defns.sh is substituted for ${some_dir}
                          # in MY_CMD before MY_CMD is evaluated.
     ...

Next, consider the case in which ``some_dir`` is not an experiment variable, i.e. it 
does not appear in ``var_defns.sh``.  In this case, ``some_dir`` must be defined in 
the script at some point **before** ``MY_CMD`` is used (i.e. expanded and evaluated). 
Otherwise, the evaluation of ``MY_CMD`` may give incorrect or unexpected results (if 
undefined variables are allowed in the script, in which case a null string will be 
substitued for ``${some_dir}`` in ``MY_CMD`` before the latter is evaluated), or it 
will cause the script to fail (if undefined variables are prohibited in the script 
via ``set -u``, which is the case in most of the SRW App scripts and functions).  Thus, 
the following code snippet in a script will evaluate the contents of ``MY_CMD`` using 
a locally-set value of ``some_dir``:

   .. code-block:: none

     ...
     . var_defns.sh       # Source the experiment's variable definitions file (assuming
                          # it is in the current directory).  This defines the MY_CMD
                          # template variable (in addition to other variables).
     ...
     some_dir="20200715"  # Set the local variable some_dir.
     ...
     eval ${MY_CMD}       # Use eval to evaluate the contents of MY_CMD.  The value of 
                          # some_dir specified in this file a few lines above is substituted 
                          # for ${some_dir} in MY_CMD before MY_CMD is evaluated.
     ...

Note that it is important to use single quotes when defining templates in 
``config_defaults.sh`` and ``config.sh`` in order to prevent expansion of variable 
references at the time ``var_defns.sh`` is sourced.  Double quotes may be used, but in 
that case, backslashes as well as dollar signs must be escaped, e.g. ``MY_CMD="cd 
\\\${some_dir}"``.  Since this is more cumbersome, we recommend use of single quotes.  

