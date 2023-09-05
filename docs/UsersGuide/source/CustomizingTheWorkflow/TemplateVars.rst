.. _TemplateVars:

======================
Template Variables
======================

The SRW App's experiment configuration system supports the use of template variables
in ``config_defaults.yaml`` and ``config.yaml``. A template variable is an experiment configuration variable that contains references to values of other variables. 
These references are **not** set to the values of the referenced variables (or "expanded") when the experiment's variable definitions file (``var_defns.sh``) is generated or sourced.
Instead, they are expanded and evaluated **at run time** when bash's
``eval`` command is used on the template. 

Generic Example
==================

As an example, consider a hypothetical template variable named ``MY_CMD`` that is defined in ``config_defaults.yaml``
(or redefined by the user in ``config.yaml``) as follows:

   .. code-block:: console

      MY_CMD: 'cd ${some_dir}'

Here, ``some_dir`` may be another experiment variable defined in ``var_defns.sh`` or a
local variable defined in a script or function that will evaluate the template. 
It is important to use single quotes on the right-hand side of the definition above;
otherwise, bash will try to evaluate ``${some_dir}`` when constructing ``var_defns.sh``,
which may result in an error and/or unexpected behavior (e.g., if ``${some_dir}`` 
is not yet defined). The experiment generation system will define ``MY_CMD`` in 
``var_defns.sh`` in exactly the same way as in ``config_defaults.yaml`` and/or 
``config.yaml``, e.g., ``MY_CMD: 'cd ${some_dir}'``. Then the following code snippet 
in a script or function will evaluate the contents of ``MY_CMD`` using a locally-set 
value of ``some_dir``:

   .. code-block:: none
      
      ...
      . var_defns.sh       # Source the experiment's variable definition file (assuming
                           # it is in the current directory). This defines the MY_CMD
                           # template variable (in addition to other variables).
      ...
      some_dir="20200715"  # Set the local variable some_dir.
      ...
      eval ${MY_CMD}       # Use eval to evaluate the contents of MY_CMD. The value of
                           # some_dir specified in this file a few lines above is substituted
                           # for ${some_dir} in MY_CMD before MY_CMD is evaluated.

Graphics Plotting Example
============================

When attempting to generate graphics plots from a forecast, users have the option to 
produce difference plots from two experiments that are on the same domain and 
available for the same cycle starting date/time and forecast hours. 
To generate difference plots, users must use the template variable ``COMOUT_REF`` 
to indicate where the :term:`GRIB2` files from post-processing are located. 

In *community* mode (i.e., when ``RUN_ENVIR: "community"``), this directory will 
take the form ``/path/to/expt_dirs/expt_name/$PDY$cyc/postprd``, where ``$PDY`` refers 
to the cycle date in YYYYMMDD format, and ``$cyc`` refers to the starting hour of the cycle. 
(These variables are set in previous tasks based on the value of ``DATE_FIRST_CYCL``.)
Given two experiments, ``expt1`` and ``expt2``, users can generate difference plots by 
setting ``COMOUT_REF`` in the ``expt2`` configuration file (``config.yaml``) as follows:

.. code-block:: console

   COMOUT_REF: '${EXPT_BASEDIR}/expt1/${PDY}${cyc}/postprd'

The ``expt2`` workflow already knows where to find its own post-processed output, so 
``COMOUT_REF`` should point to post-processed output for the other experiment (``expt1``). 

In *nco* mode, this directory should be set to the location of the first experiment's 
``COMOUT`` directory (``${COMOUT}`` in the example below) and end with ``${PDY}/${cyc}``. 
For example:

.. code-block:: console

   COMOUT_REF: '${COMOUT}/${PDY}/${cyc}/'

