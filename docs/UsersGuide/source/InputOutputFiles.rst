.. _InputOutputFiles:

======================
Input and Output Files
======================
This chapter provides an overview of the input and output files needed by the components
of the UFS SRW Application (:term:`UFS_UTILS`, the UFS :term:`Weather Model`, and :term:`UPP`).
Links to more detailed documentation for each of the components are provided.

Input Files
===========
The SRW Application requires numerous input files to run: static datasets (fix files
containing climatological information, terrain and land use data), initial and boundary
conditions files, and model configuration files (such as namelists).

Initial and Boundary Condition Files
------------------------------------
The external model files needed for initializing the runs can be obtained in a number of
ways, including: pulled directly from `NOMADS <https://nomads.ncep.noaa.gov/pub/data/nccf/com/>`_;
limited data availability), pulled from the NOAA HPSS during the workflow execution (requires
user access), or obtained and staged by the user from a different source. The data format for
these files can be :term:`GRIB2` or :term:`NEMSIO`. More information on downloading and staging
the external model data can be found in TODO Section 7.3.3-7.3.4. Once staged,
the end-to-end application will run the system and write output files to disk.

Pre-processing (UFS_UTILS)
--------------------------
When a user runs the SRW Application as described in the quickstart guide
:numref:`Section %s <Quickstart>`, input data for the pre-processing utilities is linked
from a location on disk to your experiment directory by the workflow generation step. The
pre-processing utilities use many different datasets to create grids, and to generate model
input datasets from the external model files.  A detailed description of the input files
for the pre-processing utilities can be found `here 
<https://ufs-utils.readthedocs.io/en/ufs-v1.0.0/chgres_cube.html#program-inputs-and-outputs>`_.

UFS Weather Model
-----------------
The input files for the weather model include both static (fixed) files and grid and date
specific files (terrain, initial conditions, boundary conditions, etc). The static fix files
must be staged by the user unless you are running on a pre-configured platform, in which case
you can link to the existing copy on that machine. See TODO section 7.3.1
for more information. The static, grid, and date specific files are linked in the experiment
directory by the workflow scripts. An extensive description of the input files for the weather
model can be found in the `UFS Weather Model User's Guide <https://ufs-weather-model.readthedocs.io/en/ufs-v2.0.0/>`_.
The namelists and configuration files for the SRW Application are created from templates by the
workflow, as described in :numref:`Section %s <WorkflowTemplates>`.

Unified Post Processor (UPP)
----------------------------
Documentation for the UPP input files can be found in the `UPP User's Guide
<https://upp.readthedocs.io/en/ufs-v2.0.0/InputsOutputs.html>`_.

.. _WorkflowTemplates:

Workflow
--------
The SRW Application uses a series of template files, combined with user selected settings,
to create the required namelists and parameter files needed by the Application. These
templates can be reviewed to see what defaults are being used, and where configuration parameters
are assigned from the ``config.sh`` file.

List of Template Files
^^^^^^^^^^^^^^^^^^^^^^
The template files for the SRW Application are located in ``regional_workflow/ush/templates``
and are shown in :numref:`Table %s <TemplateFiles>`.

.. _TemplateFiles:

.. table::  Template files for a regional workflow.

   +-----------------------------+-------------------------------------------------------------+
   | **File Name**               | **Description**                                             |
   +=============================+=============================================================+
   | data_table                  | Cycle-independent file that the forecast model reads in at  |
   |                             | the start of each forecast. It is an empty file. No need to |
   |                             | change.                                                     |
   +-----------------------------+-------------------------------------------------------------+
   | data_table_[CCPP]           | File specifying the output fields of the forecast model.    |
   |                             | A different diag_table may be configured for different      |
   |                             | CCPP suites.                                                |
   +-----------------------------+-------------------------------------------------------------+
   | field_table_[CCPP]          | Cycle-independent file that the forecast model reads in at  |
   |                             | the start of each forecast. It specifies the scalars that   |
   |                             | the forecast model will advect.  A different field_table    |
   |                             | may be needed for different CCPP suites.                    |
   +-----------------------------+-------------------------------------------------------------+
   | FV3.input.yml               | YAML configuration file containing the forecast model’s     |
   |                             | namelist settings for various physics suites. The values    |
   |                             | specified in this file update the corresponding values in   |
   |                             | the ``input.nml`` file. This file may be modified for the   |
   |                             | specific namelist options of your experiment.               |
   +-----------------------------+-------------------------------------------------------------+
   | FV3LAM_wflow.xml            | Rocoto XML file to run the workflow. It is filled in using  |
   |                             | the ``fill_template.py`` python script that is called in    |
   |                             | the ``generate_workflow.sh``.                               |
   +-----------------------------+-------------------------------------------------------------+
   | input.nml.FV3               | Namelist file of the weather model.                         |
   +-----------------------------+-------------------------------------------------------------+
   | model_configure             | Settings and configurations for the NUOPC/ESMF main         |
   |                             | component.                                                  |
   +-----------------------------+-------------------------------------------------------------+
   | nems.configure              | NEMS (NOAA Environmental Modeling System) configuration     |
   |                             | file, no need to change because it is an atmosphere-only    |
   |                             | model in the SRW Application.                               |
   +-----------------------------+-------------------------------------------------------------+
   | regional_grid.nml           | Namelist settings for the code that generates an ESG grid.  |
   +-----------------------------+-------------------------------------------------------------+
   | README.xml_templating.md    | Instruction of Rocoto XML templating with Jinja.            |
   +-----------------------------+-------------------------------------------------------------+

Additional information related to the ``diag_table_[CCPP]``, ``field_table_[CCPP]``, ``input.nml.FV3``,
``model_conigure``, and ``nems.configure`` can be found in the `UFS Weather Model User's Guide
<https://ufs-weather-model.readthedocs.io/en/ufs-v2.0.0/InputsOutputs.html#input-files>`_,
while information on the ``regional_grid.nml`` can be found in the UFS_UTILS User’s Guide
<TODO add link>.

Migratory Route of the Input Files in the Workflow
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
:numref:`Figure %s <MigratoryRoute>` shows how the case-specific input files in the
``ufs-srweather-app/regional_workflow/ush/templates/`` directory flow to the experiment directory.
The value of ``CCPP_PHYS_SUITE`` is specified in the configuration file ``config.sh``. The template
input files corresponding to ``CCPP_PHYS_SUITE``, such as ``field_table`` and ``nems_configure``, are
copied to the experiment directory ``EXPTDIR`` and the namelist file of the weather model ``input.nml``
is created from the ``input.nml.FV3`` and ``FV3.input.yml`` files by running the script ``generate_FV3LAM_wflow.sh``.
While running the task ‘RUN_FCST’ in the regional workflow as shown in :numref:`Figure %s <WorkflowTasksFig>`,
the ``field_table``, ``nems.configure``, and ``input.nml`` files, located in ``EXPTDIR`` are linked to the
cycle directory ``CYCLE_DIR/``, and ``diag_table`` and ``model_configure`` are copied from the ``templates``
directory. Finally, these files are updated with the variables specified in ``var_defn.sh``.

.. _MigratoryRoute:

.. figure:: _static/FV3LAM_wflow_input_path.png

    *Migratory route of input files*

