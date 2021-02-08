.. _Graphics:

===================
Graphics Generation
===================
Two Python scripts are provided to generate plots from the FV3-LAM post-processed GRIB2
output over the CONUS for a number of variables, including:

* 2-m Temperature
* 2-m Dew Point Temperature
* 10-m Winds
* 500 hPa Heights, Winds, and Vorticity
* 250 hPa Winds
* Accumulated Precipitation
* Composite Reflectivity
* Surface-based CAPE/CIN
* Max/Min 2-5 km Updraft Helicity
* Sea level pressure (SLP)

The Python plotting scripts are located under ``ufs-srweather-app/regional_workflow/ush/Python``
directory. The ``plot_allvars.py`` script plots the output from a single run, while the ``plot_allvars_diff.py``
script plots the difference between two runs. If you are plotting the difference, the runs must be on the
same domain and available for the same forecast hours. 

The Python scripts require a cycle date and time, a starting forecast hour (HHH), an ending forecast
hour (HHH), a forecast hour increment (HHH), a path to one or two experiment directory(ies) (``EXPT_DIR_#``),
and a path to the directory where the Natural Earth shape files are located (``CARTOPY_DIR``). 

The Cartopy shape files can be downloaded at https://www.naturalearthdata.com/downloads/. The medium scale
(1:50m) cultural and physical shapefiles are used to create coastlines and other geopolitical borders
on the map. Cartopy provides the ‘background_img()’ method to add background images in a convenient way.
The default scale (resolution) of background attributes in the Python scripts is 1:50m Natural Earth I
with Shaded Relief and Water, which should be sufficient for most regional applications. 

Generate the python plots:

.. code-block:: console

   cd ufs-srweather-app/regional_workflow/ush/Python

The appropriate environment will need to be loaded to run the scripts, which require Python 3 with
the pygrib and cartopy packages. This Python environment has already been set up on Level 1 platforms,
and can be activated in the following way:

.. note::

   If you are using the batch submission scripts, the environments are set for you and you do not
   need to set them on the command line prior to running the script - see further instructions below.

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

To run the Python plotting script for a single run, six command line arguments are required, including:

#. Cycle date/time in YYYYMMDDHH format
#. Starting forecast hour in HHH format
#. Ending forecast hour in HHH format
#. Forecast hour increment in HHH format
#. ``EXPT_DIR``: Experiment directory where post-processed data are found ``EXPT_DIR/YYYYMMDDHH/postprd``
#. ``CARTOPY_DIR``:  Base directory of cartopy shapefiles with a file structure of ``CARTOPY_DIR/shapefiles/natural_earth/cultural/*.shp``


To run the differencing Python plotting script, seven command line arguments are required, including:

#. Cycle date/time in YYYYMMDDHH format
#. Starting forecast hour in HHH format
#. Ending forecast hour in HHH format
#. Forecast hour increment in HHH format
#. ``EXPT_DIR_1``: Experiment directory #1 where post-processed data are found ``EXPT_DIR/YYYYMMDDHH/postprd``
#. ``EXPT_DIR_2``: Experiment directory #2 where post-processed data are found ``EXPT_DIR/YYYYMMDDHH/postprd``
#. ``CARTOPY_DIR``:  Base directory of cartopy shapefiles with a file structure of ``CARTOPY_DIR/shapefiles/natural_earth/cultural/*.shp``


An example for plotting output from the default config.sh settings (using the GFSv15p2 suite definition file)
is as follows: 

.. code-block:: console

   python plot_allvars.py 2019061500 6 48 6 /path-to/expt_dirs/test_CONUS_25km_GFSv15p2 /path-to/NaturalEarth

The Cartopy shape files are available for use on on a number of Tier 1 platforms in the following locations:

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


If the Python scripts are being used to create plots of multiple forecast lead times and forecast
variables, then they should be submitted through the batch system using one of the following scripts.
 
On Hera, Jet, Orion, Gaea: 

.. code-block:: console

   sbatch sq_job.sh

On Cheyenne:

.. code-block:: console

   qsub qsub_job.sh

If the batch script is being used, multiple environment variables (``HOMErrfs`` and ``EXPTDIR(#)``)
need to be set prior to submitting the script:

For a single run:

.. code-block:: console

   setenv HOMErrfs /path-to/ufs-srweather-app/regional_workflow
   setenv EXPTDIR /path-to/EXPTDIR
   -or- 
   export HOMErrfs=/path-to/ufs-srweather-app/regional_workflow
   export EXPTDIR=/path-to/EXPTDIR

For differencing two runs:

.. code-block:: console

   setenv HOMErrfs /path-to/ufs-srweather-app/regional_workflow
   setenv EXPTDIR1 /path-to/EXPTDIR1
   setenv EXPTDIR2 /path-to/EXPTDIR2
   -or-
   export HOMErrfs=/path-to/ufs-srweather-app/regional_workflow
   export EXPTDIR1=/path-to/EXPTDIR1
   export EXPTDIR2=/path-to/EXPTDIR2

In addition, the following variables can be modified in the batch script depending on your
needs (for example, if you want to plot hourly forecast output, ``FCST_INC`` should be set to 1;
if you just want to plot a subset of your model output you can set the ``FCST_START/END/INC`` accordingly):

.. code-block:: console

   export CDATE=${DATE_FIRST_CYCL}${CYCL_HRS}
   export FCST_START=6
   export FCST_END=${FCST_LEN_HRS}
   export FCST_INC=6

The output files (.png format) will be located in the experiment directory (``EXPT_DIR``) under the
``YYYYMMDDHH/postprd`` directory.


