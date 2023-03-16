.. _AQM:

=====================================
Air Quality Modeling (Online-CMAQ)
=====================================

The standard SRW App distribution uses the uncoupled version of the UFS Weather Model (atmosphere-only). However, users have the option to use a coupled version of the SRW App that includes the standard distribution (atmospheric model) plus the Air Quality Model (AQM).

The AQM is a UFS Application that dynamically couples the Community Multiscale Air Quality (:term:`CMAQ`) model with the UFS Weather Model through the :term:`NUOPC` Layer to simulate temporal and spatial variations of atmospheric compositions (e.g., ozone and aerosol compositions). The CMAQ model, treated as a column chemistry model, updates concentrations of chemical species (e.g., ozone and aerosol compositions) at each integration time step. The transport terms (e.g., :term:`advection` and diffusion) of all chemical species are handled by the UFS Weather Model as tracers.

Quick Start Guide (Online-CMAQ)
==================================

Clone the ``develop`` branch of the authoritative SRW App repository:

.. code-block:: console

   git clone -b develop https://github.com/ufs-community/ufs-srweather-app
   cd ufs-srweather-app

Note that the latest hash of the ``develop`` branch might not be tested with the sample scripts of Online-CMAQ. To check out the stable (verified) version for Online-CMAQ, users can check out the following hash:

.. code-block:: console

   git checkout ff6f103

This will check out the following hashes of the external components, which are specified in ``ufs-srweather-app/Externals.cfg`` (as of 03/08/2023):

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

Users may replace the hashes above with different ones if they prefer. For example, users can comment out the hash line and uncomment the branch line with a new ``repo_url`` address to use a different branch for development. 

.. code-block:: console

   repo_url = https://github.com/chan-hoo/ufs-weather-model
   branch = feature/for_example
   #hash = e051e0e

Note that the repository URL has been changed to check out code from a user's personal ``ufs-weather-model`` fork rather than the authoritative UFS community repository. 

Check out the external components:

.. code-block:: console

   ./manage_externals/checkout_externals

Build Online-CMAQ:

.. code-block:: console

   ./devbuild.sh -p=[machine] -a=ATMAQ

where ``[machine]`` is ``hera``, or ``wcoss2``.

Set up the user-specific configuration:

.. code-block:: console

   cd ush
   cp config.aqm.community.yaml (or config.aqm.nco.realtime.yaml) config.yaml

Note that additional sample scripts can be found in Chan-Hoo's GitHub repo for online-cmaq.

Set the following parameters in config.yaml for the automatic initial-submission and re-submission by cron:

.. code-block:: console

   workflow:
     USE_CRON_TO_RELAUNCH: true
     CRON_RELAUNCH_INTVL_MNTS: 3

This means that cron will submit the launch script every 3 minutes. Note that you should create your crontab with ``crontab -e`` first if this is your first time to use cron.

Load the python environment for the workflow:

.. code-block:: console

   # On WCOSS2:
   source ../versions/run.ver.wcoss2
   # On all systems (including WCOSS2):
   module use ../modulefiles
   module load wflow_[machine]
   conda activate regional_workflow

where ``[machine]`` is ``hera`` or ``wcoss2``.

Generate the workflow:

.. code-block:: console

   python3 generate_FV3LAM_wflow.py

Run the workflow only if ``USE_CRON_TO_RELAUNCH: true`` was not set in ``config.yaml`` (see Step 5 for the automatic resubmission by cron):

.. code-block:: console

   cd [EXPT_BASEDIR]/[EXPT_SUBDIR]
   ./launch_FV3LAM_wflow.sh

Repeat the launch command until you have SUCCESS or FAILURE on your terminal window.

References
UFS SRW App Users' Guide for the develop branch of the UFS SRW App (Chan-Hoo Jeon, NOAA/NCEP/EMC).
