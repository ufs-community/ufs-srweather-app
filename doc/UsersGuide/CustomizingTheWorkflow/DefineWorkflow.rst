.. _DefineWorkflow:

=============================
Defining an SRW App Workflow
=============================

Many predefined workflows with optional variants exist within the Short-Range Weather Application, but the Application also includes the ability to define a new workflow from scratch. This functionality allows users to add tasks to the workflow to meet their scientific exploration needs.

Rocoto is the primary workflow manager software used by the UFS SRW App. Rocoto workflows are defined in an XML file (``FV3LAM_wflow.xml``) based on parameters set during experiment generation. The SRW Rocoto XML is built using the UW Tools Rocoto Tool. Reference its documentation `here <https://uwtools.readthedocs.io/en/main/sections/user_guide/yaml/rocoto.html>`__. For more information about Rocoto, check out its `documentation here <http://christopherwharrop.github.io/rocoto/>`_.

Order of Precedence
===================
There is a specific order of precedence imposed when the SRW App loads configuration files.

#. Load ``config_defaults.yaml`` file.
#. Load the user’s ``config.yaml`` file.
#. Load the ``default_workflow.yaml`` file.
#. Call the ``dereference`` method to fill in templates.
#. Load all files from the ``taskgroups:`` entry from the user’s config or from the default if not overridden. This is achieved with a call to the ``dereference()`` method on the UWConfig object.
#. Add the contents of the files to the ``task:`` section.
#. Update the existing workflow configuration with any user-specified entries (removing the ones that are that the UW-supported ``!remove`` tag).
#. Incorporate other default configuration settings from machine files, constants, etc. into the default configuration dictionary in memory.
#. Apply all user settings last to take highest precedence.
#. Call ``dereference()`` to render templates that are available.
   NOTE: This is the one that is likely to trip up any settings that ``setup.py`` will make. References to other defaults that get changed during the course of validation may be rendered here earlier than desired.

At this point, validation and updates for many other configuration settings will be made for a variety of sections. Once complete, ``dereference()`` is called again to ensure values have the appropriate highest-priority user settings.

Just before the ``rocoto:`` section is written to its own file in the experiment directory, ``clean_rocoto_dict()`` is called on that section to remove invalid dictionaries, i.e., metatasks with no tasks, tasks with no associated commands, etc.

The ``rocoto:`` section is not included in the ``var_defns.yaml`` since that file is used primarily to store settings needed at run-time. 

