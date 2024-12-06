.. _UFS_FIRE:

=========================================
Community Fire Behavior Module (UFS FIRE)
=========================================

The `Community Fire Behavior Model (CFBM) <https://ral.ucar.edu/model/community-fire-behavior-model>`_ is a wildland fire model coupled to the UFS Atmospheric Model. The capability to run this code is now available in the UFS Short-Range Weather App for easy use by the community. The `fire_behavior repository <https://github.com/NCAR/fire_behavior>`_ is a :term:`submodule` of the UFS Weather Model (WM), coupled through the :term:`NUOPC` Layer to provide direct feedback between the simulated atmosphere and the simulated fire. More information about the CFBM can be found in the :fire-ug:`CFBM Users Guide <>`.

The biggest difference between the UFS FIRE capability and other modes of the UFS SRW is that a special build flag is required to build the coupled fire behavior code, as described in the instructions below. Aside from that, the need for additional input files, and some fire-specific config settings, configuring and running an experiment is the same as any other use of SRW.


.. note::

   Although this chapter is the primary documentation resource for running the UFS FIRE configuration, users may need to refer to :numref:`Chapter %s <BuildSRW>` and :numref:`Chapter %s <RunSRW>` for additional information on building and running the SRW App, respectively. 

Quick Start Guide (UFS FIRE)
=====================================

Download the Code
-------------------

Clone the |branch| branch of the authoritative SRW App repository:

.. code-block:: console

   git clone -b develop https://github.com/ufs-community/ufs-srweather-app
   cd ufs-srweather-app

Checkout Externals
---------------------

Users must run the ``checkout_externals`` script to collect (or "check out") the individual components of the SRW App from their respective GitHub repositories.

.. code-block:: console

   ./manage_externals/checkout_externals

Build the SRW App with Fire Behavior Enabled
--------------------------------------------

To build the SRW with fire behavior code, use the following command:

.. code-block:: console

   ./devbuild.sh -p=<machine> -a=ATMF

where ``<machine>`` is ``hera``, ``derecho``, or any other Tier 1 platform. The ``-a`` argument indicates the configuration/version of the application to build; in this case, the atmosphere-fire coupling (ATMF).

If UFS FIRE builds correctly, users should see the standard executables listed in :numref:`Table %s <ExecDescription>`. There are no additional files expected, since the CFBM is coupled to the UFS weather model via the same ``ufs_model`` executable.

Load the |wflow_env| Environment
--------------------------------------------

Load the appropriate modules for the workflow:

.. code-block:: console

   module use /path/to/ufs-srweather-app/modulefiles
   module load wflow_<machine>

where ``<machine>`` is ``hera``, ``derecho``, or any other Tier 1 platform. 

If the console outputs a message, the user should run the commands specified in the message. For example, if the output says: 

.. code-block:: console

   Please do the following to activate conda:
       > conda activate srw_app

then the user should run |activate|. Otherwise, the user can continue with configuring the workflow. 

.. _FIREConfig:

Configure Experiment
---------------------------

Users will need to configure their experiment by setting parameters in the ``config.yaml`` file. To start, users can copy an example experiment setting into ``config.yaml``:

.. code-block:: console

   cd ush
   cp config.fire.yaml config.yaml 
   
Users will need to change the ``MACHINE`` and ``ACCOUNT`` variables in ``config.yaml`` to match their system. They may also wish to adjust other experiment settings, especially under the ``fire:`` section, described in further detail below. For more information on other configuration settings, see :numref:`Section %s <ConfigWorkflow>`.

Activating the fire behavior module is done by setting ``UFS_FIRE: True`` in the ``fire:`` section of your ``config.yaml`` file. If this variable is not specified or set to false, a normal atmospheric simulation will be run, without fire settings.

.. code-block:: console

   fire:
     UFS_FIRE: True

The fire module has the ability to print out additional messages to the log file for debugging; to enable additional log output (which may slow down the integration considerably, especially at higher levels) set ``FIRE_PRINT_MSG`` > 0

.. code-block:: console
   
   fire:
     FIRE_PRINT_MSG: 1

Additional boundary conditions file
-----------------------------------
The CFBM, as an independent, coupled component, runs separately from the atmospheric component of the weather model, requires an additional input file (``geo_em.d01.nc``) that contains fire-specific boundary conditions such as fuel properties. On Level 1 systems, users can find an example file in the usual :ref:`input data locations <Data>` under ``LOCATION``. Users can also download the data required for the community experiment from the `UFS SRW App Data Bucket <https://noaa-ufs-srw-pds.s3.amazonaws.com/index.html#develop-20240618/input_model_data/fire>`__.


Instructions on how to create this file for your own experiment can be found in the :fire-ug:`CFBM Users Guide <Configuration.html#configuring-a-domain-with-the-wrf-pre-processing-system-wps>`.

Once the file is acquired/created, you will need to specify its location in your ``config.yaml`` file with the setting ``FIRE_INPUT_DIR``.

.. code-block:: console

   fire:
     FIRE_INPUT_DIR: /directory/containing/geo_em/file



Specifying a fire ignition
---------------------------

The CFBM simulates fires by specifying an "ignition" that will then propogate based on the atmospheric conditions and the specified settings. An ignition can either be a "point ignition" (i.e. a disk of fire some specified radius around a single location), or a straight line linear ignition specified by a start and end location and a specified "radius" (width). The ignition can start at the beginning of your simulation, or at some time later as specified. The CFBM can support up to 5 different fire ignitions at different places and times in a given simulation.

The CFBM settings are controlled by the :term:`namelist` file ``namelist.fire``. The available settings in this file are described in the :fire-ug:`CFBM Users Guide <Configuration.html#namelist-configuration>`, and an example file can be found under ``parm/namelist.fire``. However, there is no need to manually provide or edit this file, as the SRW workflow will create the fire namelist using the user settings in ``config.yaml``. The fire-specific options in SRW are documented in :numref:`Section %s <fire-parameters>`.

Example fire configuration
---------------------------

Here is one example of settings that can be specified for a UFS FIRE simulation:

.. code-block:: console

   fire:
     UFS_FIRE: True
     FIRE_INPUT_DIR: /home/fire_input
     DT_FIRE: 0.5
     OUTPUT_DT_FIRE: 1800
     FIRE_NUM_IGNITIONS: 1
     FIRE_IGNITION_ROS: 0.05
     FIRE_IGNITION_START_LAT: 40.609
     FIRE_IGNITION_START_LON: -105.879
     FIRE_IGNITION_END_LAT: 40.609
     FIRE_IGNITION_END_LON: -105.879
     FIRE_IGNITION_RADIUS: 250
     FIRE_IGNITION_START_TIME: 6480
     FIRE_IGNITION_END_TIME: 7000

In this case, a single fire (``FIRE_NUM_IGNITIONS: 1``) of radius 250 meters (``FIRE_IGNITION_RADIUS: 250``) is ignited at latitude 40.609˚N (``FIRE_IGNITION_START_LAT: 40.609``), 105.879˚W (``FIRE_IGNITION_START_LON: -105.879``) 6480 seconds after the start of the simulation (``FIRE_IGNITION_START_TIME: 6480``) with a rate of spread specified as 0.05 m/s (``FIRE_IGNITION_ROS: 0.05``). This "ignition" ends 7000 seconds after the start of the simulation (``FIRE_IGNITION_END_TIME: 7000``), after which the fire behavior is completely governed by the physics of the fire behavior model (integrated every 0.5 seconds as specified by ``OUTPUT_DT_FIRE``), the input fuel conditions, and the simulated atmospheric conditions.

The CFBM creates output files in :term:`netCDF` format, with the naming scheme ``fire_output_YYYY-MM-DD_hh:mm:ss.nc``. In this case the output files are written every 30 minutes (``OUTPUT_DT_FIRE: 1800``).

.. note::

  Any of the settings under :fire-ug:`the &fire section of the namelist <Configuration.html#fire>` can be specified in the SRW App ``config.yaml`` file under the ``fire:`` section, not just the settings described above. However, any additional settings from ``namelist.fire`` will need to be added to ``config_defaults.yaml`` first; otherwise the check for valid SRW options will fail.

To specify multiple fire ignitions (``FIRE_NUM_IGNITIONS > 1``), the above settings will need to be specified as a list, with one entry per ignition. See :numref:`Section %s <fire-parameters>` for more details. 


Generate the Workflow
------------------------

Generate the workflow:

.. code-block:: console

   ./generate_FV3LAM_wflow.py

Run the Workflow
------------------

If ``USE_CRON_TO_RELAUNCH`` is set to true in ``config.yaml``, the workflow will run automatically. If it was set to false, users must submit the workflow manually from the experiment directory:

.. code-block:: console

   cd ${EXPT_BASEDIR}/${EXPT_SUBDIR}
   ./launch_FV3LAM_wflow.sh

Repeat the launch command regularly until a SUCCESS or FAILURE message appears on the terminal window. See :numref:`Section %s <DirParams>` for more on the ``${EXPT_BASEDIR}`` and ``${EXPT_SUBDIR}`` variables. 

Users may check experiment status from the experiment directory with either of the following commands: 

.. code-block:: console

   # Check the experiment status (for cron jobs)
   rocotostat -w FV3LAM_wflow.xml -d FV3LAM_wflow.db -v 10

   # Check the experiment status and relaunch the workflow (for manual jobs)
   ./launch_FV3LAM_wflow.sh; tail -n 40 log.launch_FV3LAM_wflow

.. _FIRESuccess:

Experiment Output
--------------------

The workflow run is complete when all tasks display a "SUCCEEDED" message. If everything goes smoothly, users will eventually see a workflow status table similar to the following: 

.. code-block:: console

          CYCLE                    TASK                       JOBID               STATE         EXIT STATUS     TRIES      DURATION
   ================================================================================================================================
   202008131800               make_grid                     6498125           SUCCEEDED                   0         1          70.0
   202008131800               make_orog                     6498145           SUCCEEDED                   0         1          87.0
   202008131800          make_sfc_climo                     6498172           SUCCEEDED                   0         1          90.0
   202008131800           get_extrn_ics                     6498126           SUCCEEDED                   0         1          46.0
   202008131800          get_extrn_lbcs                     6498127           SUCCEEDED                   0         1          46.0
   202008131800         make_ics_mem000                     6498202           SUCCEEDED                   0         1          91.0
   202008131800        make_lbcs_mem000                     6498203           SUCCEEDED                   0         1         106.0
   202008131800         run_fcst_mem000                     6498309           SUCCEEDED                   0         1        1032.0
   202008131800    run_post_mem000_f000                     6498336           SUCCEEDED                   0         1          75.0
   202008131800    run_post_mem000_f001                     6498387           SUCCEEDED                   0         1          76.0
   202008131800    run_post_mem000_f002                     6498408           SUCCEEDED                   0         1          75.0
   202008131800    run_post_mem000_f003                     6498409           SUCCEEDED                   0         1          75.0
   202008131800    run_post_mem000_f004                     6498432           SUCCEEDED                   0         1          64.0
   202008131800    run_post_mem000_f005                     6498433           SUCCEEDED                   0         1          77.0
   202008131800    run_post_mem000_f006                     6498435           SUCCEEDED                   0         1          74.0
   202008131800    integration_test_mem000                     6498434           SUCCEEDED                   0         1          27.0

In addition to the standard UFS and UPP output described elsewhere in this users guide, the UFS_FIRE runs produce additional output files :ref:`described above <FIREConfig>`:

.. code-block:: console

   $ cd /path/to/expt_dir/experiment
   $ ls 2020081318/fire_output*
   fire_output_2020-08-13_18:00:00.nc  fire_output_2020-08-13_19:30:00.nc  fire_output_2020-08-13_21:00:00.nc  fire_output_2020-08-13_22:30:00.nc
   fire_output_2020-08-13_18:30:00.nc  fire_output_2020-08-13_20:00:00.nc  fire_output_2020-08-13_21:30:00.nc  fire_output_2020-08-13_23:00:00.nc
   fire_output_2020-08-13_19:00:00.nc  fire_output_2020-08-13_20:30:00.nc  fire_output_2020-08-13_22:00:00.nc  fire_output_2020-08-13_23:30:00.nc

These files contain output directly from the fire model (hence why they are at a greater frequency), including variables such as the fire perimeter and area, smoke emitted, and fuel percentage burnt. 

.. image:: https://github.com/ufs-community/ufs-srweather-app/wiki/FIRE/ncview.emis_smoke_trim.png
   :alt: Image of the simulated fire area from an example run
   :align: center

.. _FIRE-WE2E:


WE2E Tests for FIRE
=======================

Build the app for FIRE:

.. code-block:: console

  ./devbuild.sh -p=hera -a=ATMF


Run the WE2E tests:

.. code-block:: console

   $ cd /path/to/ufs-srweather-app/tests/WE2E
   $ ./run_WE2E_tests.py -t my_tests.txt -m hera -a gsd-fv3 -q -t fire

You can also run each test individually if needed:

   $ ./run_WE2E_tests.py -t my_tests.txt -m hera -a gsd-fv3 -q -t UFS_FIRE_one-way-coupled
   $ ./run_WE2E_tests.py -t my_tests.txt -m hera -a gsd-fv3 -q -t UFS_FIRE_multifire_one-way-coupled 



