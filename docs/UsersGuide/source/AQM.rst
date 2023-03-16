.. _AQM:

=====================================
Air Quality Modeling (Online-CMAQ)
=====================================

The standard SRW App distribution uses the uncoupled version of the UFS Weather Model (atmosphere-only). However, users have the option to use a coupled version of the SRW App that includes the standard distribution (atmospheric model) plus the Air Quality Model (AQM).

The AQM is a UFS Application that dynamically couples the Community Multiscale Air Quality (:term:`CMAQ`) model with the UFS Weather Model through the :term:`NUOPC` Layer to simulate temporal and spatial variations of atmospheric compositions (e.g., ozone and aerosol compositions). The CMAQ model, treated as a column chemistry model, updates concentrations of chemical species (e.g., ozone and aerosol compositions) at each integration time step. The transport terms (e.g., :term:`advection` and diffusion) of all chemical species are handled by the UFS Weather Model as tracers.

Quick Start Guide (Online-CMAQ)
==================================

Download the Code
-------------------

Clone the ``develop`` branch of the authoritative SRW App repository:

.. code-block:: console

   git clone -b develop https://github.com/ufs-community/ufs-srweather-app
   cd ufs-srweather-app

Note that the latest hash of the ``develop`` branch might not be tested with the sample scripts of Online-CMAQ. To check out the stable (verified) version for Online-CMAQ, users can check out the following hash:

.. code-block:: console

   git checkout ff6f103

This will check out the following hashes of the external components, which are specified in ``ufs-srweather-app/Externals.cfg`` (as of 03/08/2023):

.. _ExternalsAQM:

.. table:: Externals for Online-CMAQ

   +--------------------+--------------+
   | Component          | Hash         |
   +====================+==============+
   | UFS_UTILS          | ca9bed8      |
   +--------------------+--------------+
   | ufs-weather-model	| e051e0e      |
   +--------------------+--------------+
   | UPP                | 2b2c84a      |
   +--------------------+--------------+
   | NEXUS              | 3842818      |
   +--------------------+--------------+
   | AQM-utils          | e078c70      |
   +--------------------+--------------+

Users may replace the hashes above with different ones if they prefer. For example, users can comment out the hash line and uncomment the branch line with a new ``repo_url`` address to use a different branch for development. In the example below, the repository URL has been changed to check out code from a user's personal ``ufs-weather-model`` fork rather than the authoritative UFS community repository. 

.. code-block:: console

   repo_url = https://github.com/chan-hoo/ufs-weather-model
   branch = feature/for_example
   #hash = e051e0e

Checkout Externals
---------------------

The SRW App relies on a variety of components from other repositories, which are detailed in :numref:`Chapter %s <Components>` of this User’s Guide. The AQM version of the SRW pulls in the additional externals listed in :numref:`Table %s <ExternalsAQM>`. Users must run the ``checkout_externals`` script to collect (or "check out") the individual components of the SRW App (AQM version) from their respective GitHub repositories. 

.. code-block:: console

   ./manage_externals/checkout_externals

On Hera and WCOSS2, users can build the SRW App AQM binaries with the following command:

.. code-block:: console

   ./devbuild.sh -p=<machine> -a=ATMAQ

where ``<machine>`` is ``hera``, or ``wcoss2``. The ``-a`` argument indicates the configuration/version of the application to build. 

Building on other machines, including other `Level 1 <https://github.com/ufs-community/ufs-srweather-app/wiki/Supported-Platforms-and-Compilers>`__ platforms, is not currently guaranteed to work, and users may have to make adjustments to the modulefiles for their system. 

Load the ``regional_workflow`` Environment
--------------------------------------------

Load the python environment for the workflow:

.. code-block:: console

   # On WCOSS2 (do not run on other systems):
   source ../versions/run.ver.wcoss2
   # On all systems (including WCOSS2):
   module use /path/to/ufs-srweather-app/modulefiles
   module load wflow_<machine>
   conda activate regional_workflow

where ``<machine>`` is ``hera`` or ``wcoss2``. The workflow should load on other platforms listed under the ``MACHINE`` variable in :numref:`Section %s <user>`, but users will likely need to adjust other elements of the process when running on those platforms. 

.. _AQMConfig:

Configure and Experiment
---------------------------

Users will need to configure their experiment by setting parameters in the ``config.yaml`` file. To start, users can copy a default experiment setting into ``config.yaml``:

.. code-block:: console

   cd ush
   cp config.aqm.community.yaml config.yaml 
   
Users may prefer to copy the ``config.aqm.nco.realtime.yaml`` for a default "nco" mode experiment instead. 

.. note:: 
   
   Additional sample configuration files can be found in the ``online-cmaq`` branch of Chan-Hoo Jeon's (NOAA/NCEP/EMC) ``ufs-srweather-app`` repository fork on `GitHub <https://github.com/chan-hoo/ufs-srweather-app/tree/online-cmaq>`__.

Users will need to change the ``MACHINE`` and ``ACCOUNT`` variables to match their system. They may also wish to adjust other experiment settings. For more information on each task and variable, see :numref:`Chapter %s <ConfigWorkflow>`. 

Users may also wish to change :term:`cron`-related parameters in ``config.yaml``. In the ``config.aqm.community.yaml`` file, which was copied into ``config.yaml``, cron is used for the automatic initial submission and resubmission for the experiment:

.. code-block:: console

   workflow:
     USE_CRON_TO_RELAUNCH: true
     CRON_RELAUNCH_INTVL_MNTS: 3

This means that cron will submit the launch script every 3 minutes. Users may choose not to submit using cron or to submit at a different frequency. Note that users should create a crontab by running ``crontab -e`` the first time they use cron.

Generate the Workflow
------------------------

Generate the workflow:

.. code-block:: console

   ./generate_FV3LAM_wflow.py

Run the Workflow
------------------

If ``USE_CRON_TO_RELAUNCH`` is set to true in ``config.yaml`` (see :numref:`Section %s <AQMConfig>`), the workflow will run automatically. If it was set to false, users must submit the workflow manually from the experiment directory:

.. code-block:: console

   cd <EXPT_BASEDIR>/<EXPT_SUBDIR>
   ./launch_FV3LAM_wflow.sh

Repeat the launch command regularly until a SUCCESS or FAILURE message appears on the terminal window. See :numref:`Section %s <DirParams>` for more on the ``<EXPT_BASEDIR>`` and ``<EXPT_SUBDIR>`` variables. 

Users may check experiment status with either of the following commands: 

.. code-block:: console

   # Check the experiment status (best for cron jobs)
   rocotostat -w FV3LAM_wflow.xml -d FV3LAM_wflow.db -v 10
   # Check the experiment status and relaunch the workflow (for manual jobs)
   ./launch_FV3LAM_wflow.sh; tail -n 40 log.launch_FV3LAM_wflow

