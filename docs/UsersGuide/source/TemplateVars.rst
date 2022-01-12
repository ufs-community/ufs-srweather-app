.. _TemplateVars:

==============================================================
Using Template Variables in the Experiment Configuration Files
==============================================================
The SRW App's experiment configuration system supports the use of template variables
in ``config_defaults.sh`` and ``config.sh``.  A template variable --- or, more briefly,
a "template" --- is an experiment configuration variable that contains in its definition
references to values of other variables.  If the template is defined properly as
described below (in particular, with single quotes), then these references will **not**
be expanded (i.e. set to the values of the referenced variables) at the time the
experiment's variable definitions file (``var_defns.sh``) is generated or sourced.
Instead, they will be expanded and evaluated **at run time**, i.e. whenever bash's
``eval`` built-in command is used on the template.  The script or function that will
evaluate the template must first source ``var_defns.sh`` (to define the template and
possibly also variables referenced by it), then ensure that any variables referenced
by the template that are not already defined in ``var_defns.sh`` get defined locally,
and only then call ``eval`` to evaluate the template.

As an example, consider a template named ``MY_CMD`` that is defined in ``config_defaults.sh``
(or redefined by the user in ``config.sh``) as follows:

   .. code-block:: none

     MY_CMD='cd ${some_dir}'

Here, ``some_dir`` may be an experiment variable defined in ``var_defns.sh`` or a
local variable defined in a script or function that will evaluate the template.  Note
that it is important to use single quotes on the right-hand side of the definition above;
otherwise, bash will try to evaluate ``${some_dir}`` when constructing ``var_defns.sh``,
which may result in an error and/or unexpected behavior (e.g. if ``${some_dir}`` is not
yet defined).  The experiment generation system will define ``MY_CMD`` in ``var_defns.sh``
in exactly the same way as in ``config_defaults.sh`` and/or ``config.sh``, e.g.
``MY_CMD='cd ${some_dir}'``.  Then the following code snippet in a script or function
will evaluate the contents of ``MY_CMD`` using a locally-set value of ``some_dir``:

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

