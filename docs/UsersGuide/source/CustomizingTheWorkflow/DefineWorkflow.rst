.. _DefineWorkflow:

=============================
Defining an SRW App Workflow
=============================

Many predefined workflows with optional variants exist within the Short-Range Weather Application, but the Application also includes the ability to define a new workflow from scratch. This functionality allows users to add tasks to the workflow to meet their scientific exploration needs.

Rocoto is the primary workflow manager software used by the UFS SRW App. Rocoto workflows are defined in an XML file (``FV3LAM_wflow.xml``) based on parameters set during experiment generation. This section explains how the Rocoto XML is built using a Jinja2 template (`Jinja docs here <https://jinja.palletsprojects.com/en/3.1.x/templates/>`__) and structured YAML files. The YAML follows the requirements in the `Rocoto documentation <http://christopherwharrop.github.io/rocoto/>`__ with a few exceptions or additions outlined in this documentation.

The Jinja2 Template
===================

In previous versions of the SRW Application, the Jinja2 template to create the Rocoto XML was tightly coupled to specific configuration settings of the SRW App. It was built from a limited, pre-defined set of specific tasks, defining switches for those tasks to be included or not in the rendered XML.

Now, the Jinja2 template is entirely agnostic to SRW Application decisions and has been developed to wrap the features of Rocoto in an extensible, configurable format.


The ``rocoto`` section of ``config.yaml``
==========================================
The structured YAML file that defines the Rocoto XML is meant to reflect the sections required by any Rocoto XML. That structure looks like this, with some example values filled in:

.. code-block:: console

   rocoto:
     attrs:
       realtime: F
       scheduler: slurm
       cyclethrottle: 5
       corethrottle:
       taskthrottle:
     cycledefs:
       groupname:
         - !startstopfreq ['2022102000', ‘2023102018’, ‘06:00:00’]
       groupname2:
         - !startstopfreq ['2022102000', ‘2023102018’, ‘24:00:00’]
         - !startstopfreq ['2022102006', ‘2023102018’, ‘24:00:00’]
     entities:
        foo: 1
        bar: “/some/path”
     log: ""
     tasks:
       taskgroups: '{{ ["parm/wflow/prep.yaml", "parm/wflow/coldstart.yaml", "parm/wflow/post.yaml"]|include }}'
       task_*:
       metatask_*:

Under the Rocoto section, several subentries are required. They are described here using similar language as in the Rocoto documentation.

``attrs``: Any of the attributes to the ``workflow`` tag in Rocoto. This is meant to contain a nested dictionary defining any of the Rocoto-supported attributes, where the key is the name of the attribute, and the value is what Rocoto expects.

``cycledefs``: A dictionary in which each key defines a group name for a ``cycledef`` tag; the key’s value is a list of acceptable ``cycledef`` formatted strings. The PyYAML constructor ``!startstopfreq`` has been included here to help with the automated construction of a tag of that nature. The preferred option for the SRW App is to use the “start, stop, step” method.

``entities``: A dictionary in which each key defines the name of a Rocoto entity and its value. These variables are referenceable throughout the workflow with the ``&foo;`` notation.

``log``: The path to the log file. This corresponds to the ``<log>`` tag.

``tasks``: This section is where the defined tasks and metatasks are created. This is the main portion of the workflow that will most commonly differ from experiment to experiment with different configurations.

In addition to the structured YAML itself, the SRW App enables additional functionality when defining a YAML file. Often, PyYAML features are introduced and documented `here <https://pyyaml.org/wiki/PyYAMLDocumentation>`__. In the above example, the ``!startstopfreq`` is an example of a PyYAML constructor. Supported constructors will be outlined :ref:`below <YAMLconstructors>`. There are also examples of using PyYAML anchors and aliases in the definition of groups of tasks in the SRW App. Please see `this documentation <https://pyyaml.org/wiki/PyYAMLDocumentation>`__ for the behavior of PyYAML anchors and aliases.

The use of Jinja2 templates inside the values of entries allows for the reference to other keys, mathematical operations, Jinja2 control structures, and the use of user-defined filters. Here, the ``include`` filter in the ``taskgroups`` entry is a user-defined filter. The supported filters are described in a section :ref:`below <J2filters>`.

.. _tasks:

The ``tasks`` Subsection
========================

``taskgroups``: This entry is not a standard Rocoto entry. It defines a set of files that will be included to build a workflow from predefined groups of tasks. The supported groups are included under ``parm/wflow`` for the SRW App, but the paths can point to any location on your local disk. The resulting order of the tasks will be in the same order as defined in this list. The syntax for the “include” is included as a Jinja2 filter.

``task_*``: This is a section header to add a task. The task name will be whatever the section key has defined after the first underscore. For example, ``task_run_fcst`` will be named ``run_fcst`` in the resulting workflow. More information about defining a task is included :ref:`below <defining_tasks>`.

``metatask_*``: This is a section header to add a metatask. The metatask name will be whatever the section key has defined after the first underscore. For example ``metatask_run_ensemble`` will be named ``run_ensemble`` in the resulting workflow. More information about defining a metatask is included :ref:`below <defining_metatasks>`.

.. _defining_tasks:

Defining a Task
===============
Each task supports any of the tags that are defined in the Rocoto documentation. Here’s an example of a task:

.. code-block:: console

   task_make_grid:
     account: '&ACCOUNT;'
     command: '&LOAD_MODULES_RUN_TASK_FP; "make_grid"
     attrs:
       cycledefs: at_start
       maxtries: '2'
     envars: &default_envars
       GLOBAL_VAR_DEFNS_FP: '&GLOBAL_VAR_DEFNS_FP;'
       USHdir: '&USHdir;'
       PDY: !cycstr "@Y@m@d"
       cyc: !cycstr "@H"
       subcyc: !cycstr "@M"
       LOGDIR: !cycstr "&LOGDIR;"
       nprocs: '{{ parent.nnodes * parent.ppn }}'
     native: '{{ platform.SCHED_NATIVE_CMD }}'
     nodes: '{{ nnodes }}:ppn={{ ppn }}'
     nnodes: 1
     nodesize: "&NCORES_PER_NODE;"
     ppn: 24
     partition: '{% if platform.get("PARTITION_DEFAULT") %}&PARTITION_DEFAULT;{% else %}None{% endif %}'
     queue: '&QUEUE_DEFAULT;'
     walltime: 00:20:00
     dependency:


The following sections are constructs of the interface, while all others are direct translations to tags available in Rocoto. Any tag that allows for attributes to the XML tag will take an ``attrs`` nested dictionary entry.

``attrs``: Any of the attributes to the task tag in Rocoto. This is meant to be a subdictionary defining any of the Rocoto-supported attributes, where the key is the name of the attribute, and the value is what Rocoto expects. Attributes might include any combination of the following: cycledefs, maxtries, throttle, or final.

``envars``: A dictionary of keys that map to variable names that will be exported for the job. These will show up as the set of ``<envar>`` tags in the XML. The value will be the value of the defined variable when it is exported.


If the ``command`` entry is not provided, the task won’t show up in the resulting workflow.

Defining Dependencies
=====================

The dependency entry will be an arbitrarily deep nested dictionary of key, value pairs. Each level represents entries that must come below it in priority. This is especially relevant for logic files. If an “and” tag must apply to multiple dependencies, those dependencies are all included as a nested dictionary of dependencies.

Because we are representing these entries as a dictionary, which requires hashable keys (no repeats at the same level), some tags may need to be differentiated where XML may not differentiate at all. In these instances, it is best practice to name them something descriptive. For example, you might have multiple “or” dependencies at the same level that could be named “or_files_exist” and “or_task_ran”. This style can be adopted whether or not differentiation is needed. 

The ``text`` entry on some dependencies is for those dependency tags that need the information to come between two flags, as in a data dependency.

Otherwise, all dependencies follow the same naming conventions as defined in Rocoto with ``attrs`` dictionaries included to define any of the tag attributes that may be accepted by Rocoto.

Here is an example of a complex dependency that relies on logic, task dependencies, and data dependencies:

.. code-block:: console

      dependency:
        and:
          or_get_obs: # Ensure get_obs task is complete if it's turned on
            not:
              taskvalid:
                attrs:
                  task: get_obs_mrms
            and:
              taskvalid:
                attrs:
                  task: get_obs_mrms
              taskdep:
                attrs:
                  task: get_obs_mrms
          or_do_post: &post_files_exist
            and_run_post: # If post was meant to run, wait on the whole post metatask
              taskvalid:
                attrs:
                  task: run_post_mem#mem#_f000
              metataskdep:
                attrs:
                  metatask: run_ens_post
            and_inline_post: # If inline post ran, wait on the forecast task to complete
              not:
                taskvalid:
                  attrs:
                    task: run_post_mem#mem#_f000
              taskdep:
                attrs:
                  task: run_fcst_mem#mem#

Notice the use of a PyYAML anchor under the ``or_do_post`` section. If other tasks need this same section of the dependency, it can be included like this to reduce the extensive replication:

.. code-block:: console

   dependency:
     or_do_post:
       <<: *post_files_exist
     datadep:
       text: "&CCPA_OBS_DIR;"

The use of ``#mem#`` here is a Rocoto construct that identifies this task as a part of a metatask that is looping over ensemble members (more on metatasks below).

.. _defining_metatasks:

Defining a Metatask
===================

A metatask groups together similar tasks and allows for the definition over entries defined by ``var`` tags. To define a metatask, the ``var`` entry with a nested dictionary of keys representing the names of the metatask variables and values indicating the list of values for each iteration is required. 

Multiple var entries may be included, but each entry must have the same number of items.

The metatask section must include at least one entry defining another metatask or a task.

Here’s an example of a metatask section (without the task definition):

.. code-block:: console

   metatask_run_ensemble:
     var:
       mem: '{% if global.DO_ENSEMBLE  %}{%- for m in range(1, global.NUM_ENS_MEMBERS+1) -%}{{ "%03d "%m }}{%- endfor -%} {% else %}{{ "000"|string }}{% endif %}'
     task_make_ics_mem#mem#:

This metatask will be named “run_ensemble” and will loop over all ensemble members or just the deterministic member (“000”) if no ensemble of forecasts is meant to run.

The ``var`` section defines the metatask variables, here only “mem”. The name of the task represents that variable using ``#mem#`` to indicate that the resulting task name might be ``make_ics_mem000`` if only a deterministic forecast is configured to run.

When the task or the metatask is referenced in a dependency later on, do not include the ``task_`` or ``metatask_`` portions of the name. The reference to ``#mem#`` can be included if the dependency is included in a metatask that defines the variable, e.g., ``make_ics_mem#mem#``. Otherwise, you can reference a task that includes the value of the metatask var, e.g., ``make_ics_mem000``. More on this distinction is included in the Rocoto documentation.

.. _J2filters:

SRW-Defined Jinja2 Filters Used by YAML Interface
=================================================

``include()`` – given a list of files to other YAML files, load their contents as a nested dictionary under the entry.

.. _YAMLconstructors:

SRW-Defined PyYAML Constructors Used by YAML Interface
======================================================

``!cycstr`` - Returns a ``<cyclestring>`` element for use in Rocoto. It does not support the “offset” attribute.

``!startstopfreq`` – Creates a Rocoto XML-formatted string given a start, stop, and freq value in a list.

Order of Precedence
===================
There is a specific order of precedence imposed when the SRW App loads configuration files.

#. Load ``config_defaults.yaml`` file.
#. Load the user’s ``config.yaml`` file.
#. Load the ``default_workflow.yaml`` file.

   * At this point, all anchors and references will be resolved.
   * All PyYAML constructors will also be called for the data provided in that entry.
#. Call ``update_dict`` function to remove any null entries from default tasks using the PyYAML anchors.
#. Load all files from the ``taskgroups:`` entry from the user’s config or from the default if not overridden. This is achieved with a call to the ``extend_yaml()`` function.
#. Add the contents of the files to the ``task:`` section.
#. Update the existing workflow configuration with any user-specified entries (removing the ones that are null entries).
#. Add a ``jobname:`` entry to every task in the workflow definition section.
#. Incorporate other default configuration settings from machine files, constants, etc. into the default configuration dictionary in memory.
#. Apply all user settings last to take highest precedence.
#. Call ``extend_yaml()`` to render templates that are available.
   NOTE: This is the one that is likely to trip up any settings that ``setup.py`` will make. References to other defaults that get changed during the course of validation may be rendered here earlier than desired.

At this point, validation and updates for many other configuration settings will be made for a variety of sections. Once complete, ``extend_yaml()`` is called repeatedly, stopping only when  all possible Jinja2-templated values have been rendered.

Just before the ``rocoto:`` section is written to its own file in the experiment directory, ``clean_rocoto_dict()`` is called on that section to remove invalid dictionaries, i.e., metatasks with no tasks, tasks with no associated commands, etc.

The ``rocoto:`` section is not included in the ``var_defns.sh`` since that file is used primarily to store settings needed at run-time. 

