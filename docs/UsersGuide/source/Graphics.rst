.. _Graphics:

===================
Graphics Generation
===================
Two Python plotting scripts are provided to generate plots from the :term:`FV3`-:term:`LAM` post-processed :term:`GRIB2`
output over the :term:`CONUS` for a number of variables, including:

* 2-m temperature
* 2-m dew point temperature
* 10-m winds
* 500 hPa heights, winds, and vorticity
* 250 hPa winds
* Accumulated precipitation
* Composite reflectivity
* Surface-based :term:`CAPE`/:term:`CIN`
* Max/Min 2-5 km updraft helicity
* Sea level pressure (SLP)

The Python scripts are located under ``ufs-srweather-app/regional_workflow/ush/Python``.
The script ``plot_allvars.py`` plots the output from a single cycle within an experiment, while 
the script ``plot_allvars_diff.py`` plots the difference between the same cycle from two different
experiments (e.g., the experiments may differ in some aspect such as the physics suite used). If 
plotting the difference, the two experiments must be on the same domain and available for 
the same cycle starting date/time and forecast hours. 

Loading the Environment
==========================

To use the plotting scripts, the appropriate environment must be loaded. The scripts require Python 3 with the ``scipy``, ``matplotlib``, ``pygrib``, ``cartopy``, and ``pillow`` packages. This Python environment has already been set up on Level 1 platforms and can be activated as follows:

On Cheyenne:

.. code-block:: console

   module load ncarenv
   ncar_pylib /glade/p/ral/jntp/UFS_SRW_app/ncar_pylib/python_graphics

On Hera and Jet:

.. code-block:: console

   module use -a /contrib/miniconda3/modulefiles
   module load miniconda3
   conda activate pygraf

On Orion:

.. code-block:: console

   module use -a /apps/contrib/miniconda3-noaa-gsl/modulefiles
   module load miniconda3
   conda activate pygraf

On Gaea:

.. code-block:: console

   module use /lustre/f2/pdata/esrl/gsd/contrib/modulefiles
   module load miniconda3/4.8.3-regional-workflow

On NOAA Cloud:

.. code-block:: console

   module use /contrib/GST/miniconda3/modulefiles
   module load miniconda3/4.10.3
   conda activate regional_workflow

.. note::

   If using one of the batch submission scripts described :ref:`below <Batch>`, the user does not need to manually load an environment because the scripts perform this task.

.. _Cartopy:

Cartopy Shapefiles
=======================

The Python plotting scripts also require a path to the directory where the Cartopy Natural Earth shapefiles are located. The medium scale (1:50m) cultural and physical shapefiles are used to create coastlines and other geopolitical borders on the map. Cartopy provides the 'background_img()' method to add background images in a convenient way. The default scale (resolution) of background attributes in the Python scripts is 1:50m Natural Earth I with Shaded Relief and Water, which should be sufficient for most regional applications. 

The full set of Cartopy shapefiles can be downloaded `here <https://www.naturalearthdata.com/downloads/>`__. For convenience, the small subset of files required for these Python scripts can be obtained from the `SRW Data Bucket <https://noaa-ufs-srw-pds.s3.amazonaws.com/NaturalEarth/NaturalEarth.tgz>`__. They are also available on all `Level 1 <https://github.com/ufs-community/ufs-srweather-app/wiki/Supported-Platforms-and-Compilers>`__ platforms in the following locations:

On Cheyenne:

.. code-block:: console

   /glade/p/ral/jntp/UFS_SRW_App/v2p0/NaturalEarth

On Hera:

.. code-block:: console

   /scratch2/BMC/det/UFS_SRW_App/v2p0/NaturalEarth

On Jet:
 
.. code-block:: console
 
   /mnt/lfs4/BMC/wrfruc/UFS_SRW_App/v2p0/NaturalEarth

On Orion: 

.. code-block:: console

   /work/noaa/fv3-cam/UFS_SRW_App/v2p0/NaturalEarth

On Gaea:

.. code-block:: console

   /lustre/f2/pdata/ncep/UFS_SRW_App/v2p0/NaturalEarth

On NOAA Cloud:

.. code-block:: console

   /contrib/EPIC/UFS_SRW_App/v2p0/NaturalEarth


Running the Plotting Scripts
======================================

Before generating plots, it is helpful to change location to the directory containing the plotting
scripts:

.. code-block:: console

   cd ufs-srweather-app/regional_workflow/ush/Python

Plotting Output from One Experiment
--------------------------------------

To generate plots for a single cycle, the ``plot_allvars.py`` script must be called with the 
following command line arguments:

#. Cycle date/time (``CDATE``) in YYYYMMDDHH format
#. Starting forecast hour
#. Ending forecast hour
#. Forecast hour increment
#. The top level of the experiment directory ``$EXPTDIR`` containing the post-processed data. The script will look for the data files in the directory ``$EXPTDIR/CDATE/postprd``.
#. The base directory ``CARTOPY_DIR`` of the cartopy shapefiles. The script will look for the shapefiles (``*.shp``) in the directory ``$CARTOPY_DIR/shapefiles/natural_earth/cultural``.
#. The name ``POST_OUTPUT_DOMAIN_NAME`` of the native grid used in the forecast

.. note::
   If a forecast starts at 18h, this is considered the 0th forecast hour, so "starting forecast hour" should be 0, not 18. 

An example of plotting output from a cycle generated using the sample experiment/workflow 
configuration in the ``config.community.sh`` script (which uses the GFSv16 suite definition file)
is as follows: 

.. code-block:: console

   python plot_allvars.py 2019061500 0 12 6 /path-to/expt_dirs/test_CONUS_25km_GFSv16 /path-to/NaturalEarth RRFS_CONUS_25km

The output files (in ``.png`` format) will be located in the directory ``$EXPTDIR/CDATE/postprd``,
where in this case ``$EXPTDIR`` is ``/path-to/expt_dirs/test_CONUS_25km_GFSv16`` and ``$CDATE`` 
is ``2019061518``.

Plotting Differences from Two Experiments
--------------------------------------------

To generate difference plots, the ``plot_allvars_diff.py`` script must be called with the following 
command line arguments:

#. Cycle date/time (``CDATE``) in YYYYMMDDHH format
#. Starting forecast hour
#. Ending forecast hour 
#. Forecast hour increment
#. The top level of the first experiment directory ``$EXPTDIR1`` containing the first set of post-processed data. The script will look for the data files in the directory ``$EXPTDIR1/CDATE/postprd``.
#. The top level of the second experiment directory ``$EXPTDIR2`` containing the second set of post-processed data. The script will look for the data files in the directory ``$EXPTDIR2/CDATE/postprd``.
#. The base directory ``CARTOPY_DIR`` of the cartopy shapefiles. The script will look for the shapefiles (``*.shp``) in the directory ``$CARTOPY_DIR/shapefiles/natural_earth/cultural``.
#. The name ``POST_OUTPUT_DOMAIN_NAME`` of the native grid used in the forecasts (this must be the same for the two forecasts)

An example of plotting differences from two experiments for the same date and predefined domain where one uses the "FV3_GFS_v16" suite definition file (SDF) and one using the "FV3_RRFS_v1beta" SDF is as follows:

.. code-block:: console

   python plot_allvars_diff.py 2019061518 0 12 6 /path-to/expt_dirs1/test_CONUS_3km_GFSv16 /path-to/expt_dirs2/test_CONUS_3km_RRFSv1beta /path-to/NaturalEarth RRFS_CONUS_25km

In this case, the output ``.png`` files will be located in the directory ``$EXPTDIR1/CDATE/postprd``.

.. _Batch:

Submitting Plotting Scripts Through a Batch System
======================================================

If users plan to create plots of multiple forecast lead times and forecast variables, then they may need to submit the Python scripts to the batch system. Sample scripts are provided for use on a platform such as Hera that uses the Slurm job scheduler: ``sq_job.sh`` and ``sq_job_diff.sh``. Equivalent sample scripts are provided for use on a platform such as Cheyenne that uses PBS as the job scheduler: ``qsub_job.sh`` and ``qsub_job_diff.sh``. Examples of these scripts are located under ``ufs-srweather-app/regional_workflow/ush/Python`` and can be used as a starting point to create a batch script for the user's specific platform/job scheduler. 

At a minimum, the account should be set appropriately prior to job submission:

.. code-block:: console

   #SBATCH --account=<account_name>

Depending on the platform, users may also need to adjust the settings to use the correct Python environment and path to the shapefiles.

When working with these batch scripts, several environment variables must be set prior to submission.
If plotting output from a single cycle, the variables to set are ``$HOMErrfs`` and ``$EXPTDIR``.
If the user's login shell is bash, these variables can be set as follows:

.. code-block:: console

   export HOMErrfs=/path-to/ufs-srweather-app/regional_workflow
   export EXPTDIR=/path-to/experiment/directory

If the user's login shell is csh/tcsh, they can be set as follows:

.. code-block:: console

   setenv HOMErrfs /path-to/ufs-srweather-app/regional_workflow
   setenv EXPTDIR /path-to/experiment/directory

If plotting the difference between the same cycle from two different experiments, the variables 
to set are ``$HOMErrfs``, ``$EXPTDIR1``, and ``$EXPTDIR2``. If the user's login shell 
is bash, these variables can be set as follows:

.. code-block:: console

   export HOMErrfs=/path-to/ufs-srweather-app/regional_workflow
   export EXPTDIR1=/path-to/experiment/directory1
   export EXPTDIR2=/path-to/experiment/directory2

If the user's login shell is csh/tcsh, they can be set as follows:

.. code-block:: console

   setenv HOMErrfs /path-to/ufs-srweather-app/regional_workflow
   setenv EXPTDIR1 /path-to/experiment/directory1
   setenv EXPTDIR2 /path-to/experiment/directory2

In addition, the variables ``CDATE``, ``FCST_START``, ``FCST_END``, and ``FCST_INC`` in the batch 
scripts can be modified depending on the user's needs. By default, ``CDATE`` is set as follows 
in the batch scripts:

.. code-block:: console

   export CDATE=${DATE_FIRST_CYCL}${CYCL_HRS}

This sets ``CDATE`` to the first cycle in the set of cycles that the experiment has run. If the
experiment contains multiple cycles and the user wants to plot output from a cycle other than 
the very first one, ``CDATE`` in the batch scripts will have to be set to the specific YYYYMMDDHH
value for that cycle. Also, to plot hourly forecast output, ``FCST_INC`` should be set to 1; to 
plot only a subset of the output hours, ``FCST_START``, ``FCST_END``, and ``FCST_INC`` must be 
set accordingly. For example, to generate plots for every 3rd forecast hour starting with forecast hour 6 and ending with the last forecast hour, use: 

.. code-block:: console

   export FCST_START=6
   export FCST_END=${FCST_LEN_HRS}
   export FCST_INC=3

The scripts must be submitted using the command appropriate for the job scheduler on the user's platform. For example, on Hera, ``sq_job.sh`` can be submitted as follows:

.. code-block:: console

   sbatch sq_job.sh

On Cheyenne, ``qsub_job.sh`` can be submitted as follows:

.. code-block:: console

   qsub qsub_job.sh
