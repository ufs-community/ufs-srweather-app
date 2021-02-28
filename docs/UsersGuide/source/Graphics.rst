.. _Graphics:

===================
Graphics Generation
===================
Two Python plotting scripts are provided to generate plots from the FV3-LAM post-processed GRIB2
output over the CONUS for a number of variables, including:

* 2-m temperature
* 2-m dew point temperature
* 10-m winds
* 500 hPa heights, winds, and vorticity
* 250 hPa winds
* Accumulated precipitation
* Composite reflectivity
* Surface-based CAPE/CIN
* Max/Min 2-5 km updraft helicity
* Sea level pressure (SLP)

The Python scripts are located under ``ufs-srweather-app/regional_workflow/ush/Python``.
The script ``plot_allvars.py`` plots the output from a single cycle within an experiment, while 
the script ``plot_allvars_diff.py`` plots the difference between the same cycle from two different
experiments (e.g. the experiments may differ in some aspect such as the physics suite used). If 
plotting the difference, the two experiments must be on the same domain and available for 
the same cycle starting date/time and forecast hours. 

The Python scripts require a cycle starting date/time in YYYYMMDDHH format, a starting forecast 
hour, an ending forecast hour, a forecast hour increment, the paths to one or two experiment directories,
and a path to the directory where the Cartopy Natural Earth shape files are located.
The full set of Cartopy shape files can be downloaded at https://www.naturalearthdata.com/downloads/. 
For convenience, the small subset of files required for these Python scripts can be obtained from the 
`EMC ftp data repository <https://ftp.emc.ncep.noaa.gov/EIB/UFS/SRW/v1p0/natural_earth/natural_earth_ufs-srw-release-v1.0.0.tar.gz>`_ 
or from `AWS cloud storage <https://ufs-data.s3.amazonaws.com/public_release/ufs-srweather-app-v1.0.0/natural_earth/natural_earth_ufs-srw-release-v1.0.0.tar.gz>`_.  
In addition, the Cartopy shape files are available on a number of Level 1 platforms in the following 
locations:

On Cheyenne:

.. code-block:: console

   /glade/p/ral/jntp/UFS_SRW_app/tools/NaturalEarth

On Hera:

.. code-block:: console

   /scratch2/NCEPDEV/fv3-cam/Chan-hoo.Jeon/tools/NaturalEarth

On Jet:
 
.. code-block:: console
 
   /lfs4/BMC/wrfruc/FV3-LAM/NaturalEarth

On Orion: 

.. code-block:: console

   /home/chjeon/tools/NaturalEarth

On Gaea:

.. code-block:: console

   /lustre/f2/pdata/esrl/gsd/ufs/NaturalEarth

The medium scale (1:50m) cultural and physical shapefiles are used to create coastlines and other 
geopolitical borders on the map. Cartopy provides the ‘background_img()’ method to add background 
images in a convenient way.  The default scale (resolution) of background attributes in the Python 
scripts is 1:50m Natural Earth I with Shaded Relief and Water, which should be sufficient for most 
regional applications. 

The appropriate environment must be loaded to run the scripts, which require Python 3 with
the ``scipy``, ``matplotlib``, ``pygrib``, ``cartopy``, and ``pillow`` packages. This Python environment has already 
been set up on Level 1 platforms and can be activated as follows:

On Cheyenne:

.. code-block:: console

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

   module use -a /apps/contrib/miniconda3-noaa-gsl/modulefiles
   module load miniconda3
   conda activate pygraf

.. note::

   If using one of the batch submission scripts described below, the user does not need to 
   manually load an environment because the scripts perform this task.

Before generating plots, it is convenient to change location to the directory containing the plotting
scripts:

.. code-block:: console

   cd ufs-srweather-app/regional_workflow/ush/Python

To generate plots for a single cycle, the ``plot_allvars.py`` script must be called with the 
following six command line arguments:

#. Cycle date/time (``CDATE``) in YYYYMMDDHH format
#. Starting forecast hour
#. Ending forecast hour 
#. Forecast hour increment
#. The top level of the experiment directory ``EXPTDIR`` containing the post-processed data.  The script will look for the data files in the directory ``EXPTDIR/CDATE/postprd``.
#. The base directory ``CARTOPY_DIR`` of the cartopy shapefiles.  The script will look for the shape files (``*.shp``) in the directory ``CARTOPY_DIR/shapefiles/natural_earth/cultural``.

An example of plotting output from a cycle generated using the sample experiment/workflow 
configuration in the ``config.community.sh`` script (which uses the GFSv15p2 suite definition file)
is as follows: 

.. code-block:: console

   python plot_allvars.py 2019061500 6 48 6 /path-to/expt_dirs/test_CONUS_25km_GFSv15p2 /path-to/NaturalEarth

The output files (in .png format) will be located in the directory ``EXPTDIR/CDATE/postprd``,
where in this case ``EXPTDIR`` is ``/path-to/expt_dirs/test_CONUS_25km_GFSv15p2`` and ``CDATE`` 
is ``2019061500``.

To generate difference plots, the ``plot_allvars_diff.py`` script must be called with the following 
seven command line arguments:

#. Cycle date/time (``CDATE``) in YYYYMMDDHH format
#. Starting forecast hour
#. Ending forecast hour 
#. Forecast hour increment
#. The top level of the first experiment directory ``EXPTDIR1`` containing the first set of post-processed data.  The script will look for the data files in the directory ``EXPTDIR1/CDATE/postprd``.
#. The top level of the first experiment directory ``EXPTDIR2`` containing the second set of post-processed data.  The script will look for the data files in the directory ``EXPTDIR2/CDATE/postprd``.
#. The base directory ``CARTOPY_DIR`` of the cartopy shapefiles.  The script will look for the shape files (``*.shp``) in the directory ``CARTOPY_DIR/shapefiles/natural_earth/cultural``.

In this case, the output png files will be located in the directory ``EXPTDIR1/CDATE/postprd``.


If the Python scripts are being used to create plots of multiple forecast lead times and forecast
variables, then they should be submitted to the batch system using either something like the ``sq_job.sh``
or ``sq_job_diff.sh`` script (for a platform such as Hera that uses the slurm 
job scheduler) or the ``qsub_job.sh`` or ``qsub_job_diff.sh`` script (for a platform such as 
Cheyenne that uses PBS or PBS Pro as the job scheduler).  Examples of these scripts are located under 
``ufs-srweather-app/regional_workflow/ush/Python`` and can be used as a starting point to create a batch script 
for your platform/job scheduler of use. The scripts must be submitted using the command appropriate 
for the job scheduler used on your platform.  For example, on Hera, 
``sq_job.sh`` can be submitted as follows:

.. code-block:: console

   sbatch sq_job.sh

On Cheyenne, ``qsub_job.sh`` can be submitted as follows:

.. code-block:: console

   qsub qsub_job.sh

When using these batch scripts, several environment variables must be set prior to submission.
If plotting output from a single cycle, the variables to set are ``HOMErrfs`` and ``EXPTDIR``.
In this case, if the user's login shell is csh/tcsh, these variables can be set as follows:

.. code-block:: console

   setenv HOMErrfs /path-to/ufs-srweather-app/regional_workflow
   setenv EXPTDIR /path-to/experiment/directory

If the user's login shell is bash, they can be set as follows:

.. code-block:: console

   export HOMErrfs=/path-to/ufs-srweather-app/regional_workflow
   export EXPTDIR=/path-to/experiment/directory

If plotting the difference between the same cycle from two different experiments, the variables 
to set are ``HOMErrfs``, ``EXPTDIR1``. and ``EXPTDIR2``.  In this case, if the user's login shell 
is csh/tcsh, these variables can be set as follows:

.. code-block:: console

   setenv HOMErrfs /path-to/ufs-srweather-app/regional_workflow
   setenv EXPTDIR1 /path-to/experiment/directory1
   setenv EXPTDIR2 /path-to/experiment/directory2

If the user's login shell is bash, they can be set as follows:

.. code-block:: console

   export HOMErrfs=/path-to/ufs-srweather-app/regional_workflow
   export EXPTDIR1=/path-to/experiment/directory1
   export EXPTDIR2=/path-to/experiment/directory2

In addition, the variables ``CDATE``, ``FCST_START``, ``FCST_END``, and ``FCST_INC`` in the batch 
scripts can be modified depending on the user's needs.  By default, ``CDATE`` is set as follows 
in the batch scripts:

.. code-block:: console

   export CDATE=${DATE_FIRST_CYCL}${CYCL_HRS}

This sets ``CDATE`` to the first cycle in the set of cycles that the experiment has run.  If the
experiment contains multiple cycles and the user wants to plot output from a cycle other than 
the very first one, ``CDATE`` in the batch scripts will have to be set to the specific YYYYMMDDHH
value for that cycle.  Also, to plot hourly forecast output, ``FCST_INC`` should be set to 1; to 
plot only a subset of the output hours, ``FCST_START``, ``FCST_END``, and ``FCST_INC`` must be 
set accordingly, e.g. to generate plots for every 6th forecast hour starting with forecast hour 6
and ending with the last forecast hour, use 

.. code-block:: console

   export FCST_START=6
   export FCST_END=${FCST_LEN_HRS}
   export FCST_INC=6
