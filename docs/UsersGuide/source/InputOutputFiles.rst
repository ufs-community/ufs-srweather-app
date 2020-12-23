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
while information on the ``regional_grid.nml`` can be found in the `UFS_UTILS User’s Guide
<https://ufs-utils.readthedocs.io/en/ufs-v2.0.0/index.html>`_.

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

Output Files
============

The location of the output files written to disk is defined by the experiment directory,
``EXPTDIR/YYYYMMDDHH``, as set in ``config.sh``. 

Initial and boundary condition files
------------------------------------
The external model data used by *chgres_cube* (as part of the pre-processing utilities) are located
in the experiment run directory under ``EXPTDIR/YYYYMMDDHH/{EXTRN_MDL_NAME_ICS/LBCS}``.

Pre-processing (UFS_UTILS)
--------------------------
The files output by the pre-processing utilities reside in the ``INPUT`` directory under the
experiment run directory ``EXPTDIR/YYYYMMDDHH/INPUT`` and consist of the following:

* ``C403_grid.tile7.halo3.nc``
* ``gfs_bndy.tile7.000.nc``
* ``gfs_bndy.tile7.006.nc``
* ``gfs_ctrl.nc``
* ``gfs_data.nc -> gfs_data.tile7.halo0.nc``
* ``grid_spec.nc -> ../../grid/C403_mosaic.halo3.nc``
* ``grid.tile7.halo4.nc -> ../../grid/C403_grid.tile7.halo4.nc``
* ``oro_data.nc -> ../../orog/C403_oro_data.tile7.halo0.nc``
* ``sfc_data.nc -> sfc_data.tile7.halo0.nc``

These output files are used as inputs for the UFS weather model, and are described in the `Users Guide 
<https://ufs-weather-model.readthedocs.io/en/ufs-v2.0.0/InputsOutputs.html#grid-description-and-initial-condition-files>`_.

UFS Weather Model
-----------------
As mentioned previously, the workflow can be run in ‘community’ or ‘nco’ mode, which determines
the location and names of the output files.  In addition to this option, output can also be in
netCDF or nemsio format.  The output file format is set in the ``model_configure`` files using the
``output_file`` variable.  At this time, due to limitations in the post-processing component, only netCDF
format output is recommended for the SRW application.

.. note::
   In summary, the fully supported options for this release include running in ‘community’ mode with netCDF format output files.

In this case, the netCDF output files are written to the ``EXPTDIR/YYYYMMDDHH`` directory. The bases of
the file names are specified in the input file ``model_configure`` and are set to the following in the SRW Application:

* ``dynfHHH.nc``
* ``phyfHHH.nc``

Additional details may be found in the UFS Weather Model `Users Guide
<https://ufs-weather-model.readthedocs.io/en/ufs-v2.0.0/InputsOutputs.html#output-files>`_.

Unified Post Processor (UPP)
----------------------------
Documentation for the UPP output files can be found `here <https://upp.readthedocs.io/en/ufs-v2.0.0/InputsOutputs.html>`_.

For the SRW Application, the weather model netCDF output files are written to the ``EXPTDIR/YYYYMMDDHH/postprd``
directory and have the naming convention (file->linked to):

* ``BGRD3D_{YY}{JJJ}{hh}{mm}f{fhr}00 -> {domain}.t{cyc}z.bgrd3df{fhr}.tmXX.grib2``
* ``BGDAWP_{YY}{JJJ}{hh}{mm}f{fhr}00 -> {domain}.t{cyc}z.bgdawpf{fhr}.tmXX.grib2``

The default setting for the output file names uses ``rrfs`` for ``{domain}``.  This may be overridden by
the user in the ``config.sh`` settings.

If you wish to modify the fields or levels that are output from the UPP, you will need to make
modifications to file ``fv3lam.xml``, which resides in the UPP repository distributed with the UFS SRW
Application. Specifically, if the code was cloned in the directory ``ufs-srweather-app``, the file will be
located in ``ufs-srweather-app/src/EMC_post/parm``.

.. note::
   This process requires advanced knowledge of which fields can be output for the UFS Weather Model.

Use the directions in the `UPP User's Guide <https://upp.readthedocs.io/en/ufs-v2.0.0/InputsOutputs.html#control-file>`_
for details on how to make modifications to the ``fv3lam.xml`` file and for remaking the flat text file that
the UPP reads, which is called ``postxconfig-NT-fv3lam.txt`` (default).

Once you have created the new flat text file reflecting your changes, you will need to modify your
``config.sh`` to point the workflow to the new text file. In your ``config.sh``, set the following:

.. code-block:: console

   USE_CUSTOM_POST_CONFIG_FILE=”TRUE”
   CUSTOM_POST_CONFIG_PATH=”/path/to/custom/postxconfig-NT-fv3lam.txt”

which tells the workflow to use the custom file located in the user-defined path. The path should
include the filename. If this is set to true and the file path is not found, then an error will occur
when trying to generate the SRW Application workflow.

You may then start your case workflow as usual and the UPP will use the new flat ``*.txt`` file.

