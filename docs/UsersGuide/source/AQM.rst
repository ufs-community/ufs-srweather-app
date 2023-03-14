.. _AQM:

=====================================
Air Quality Modeling (Online-CMAQ)
=====================================

This chapter walks users through experiment configuration options for various severe weather events. It assumes that users have already (1) :ref:`built the SRW App <BuildSRW>` successfully and (2) run the out-of-the-box case contained in ``config.community.yaml`` (and copied to ``config.yaml`` in :numref:`Step %s <QuickBuildRun>` or :numref:`Step %s <UserSpecificConfig>`) to completion. 


The standard SRW App distribution uses the uncoupled version of the UFS Weather Model (atmosphere-only). However, users have the option to use a coupled version of the SRW App that includes the standard distribution (atmospheric model) plus the Air Quality Model (AQM).

The AQM is a UFS Application that dynamically couples the Community Multiscale Air Quality (CMAQ) model with the UFS Weather Model through the :term:`NUOPC` Layer to simulate temporal and spatial variations of atmospheric compositions (e.g., ozone and aerosol compositions). The CMAQ model, treated as a column chemistry model, updates concentrations of chemical species (e.g., ozone and aerosol compositions) at each integration time step. The transport terms (e.g., :term:`advection` and diffusion) of all chemical species are handled by the UFS Weather Model as tracers.

Quick Start Guide (Online-CMAQ)
==================================

Clone the ``develop`` branch of the authoritative repository:

.. code-block:: console

   git clone -b develop https://github.com/ufs-community/ufs-srweather-app
   cd ufs-srweather-app

Note that the latest hash of the develop branch might not be tested with the sample scripts of Online-CMAQ. Therefore, if you want to check out the stable (verified) version for Online-CMAQ, you can check out the following hash:

.. code-block:: console

   git checkout ff6f103

Check the hashes of the external components in ``ufs-srweather-app/Externals.cfg``. This will check out the following hashes of the external components that are specified in ``Externals.cfg`` (as of 03/08/2023):

.. table:: Externals for AQM

   +--------------------+--------------+
   | Component	         | Hash         |
   +====================+==============+
   | UFS_UTILS	         | ca9bed8      |
   +--------------------+--------------+
   | ufs-weather-model	| e051e0e      |
   +--------------------+--------------+
   | UPP	               | 2b2c84a      |
   +--------------------+--------------+
   | NEXUS	            | 3842818      |
   +--------------------+--------------+
   | AQM-utils	         | e078c70      |
   +--------------------+--------------+

Replace the above hashes if you want to check out different ones.
If you want to use another branch for development, you can comment out the hash line and uncomment the branch line with a new ``repo_url`` address. For example:

.. code-block:: console

   repo_url = https://github.com/chan-hoo/ufs-weather-model
   branch = feature/for_example
   #hash = e051e0e

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
