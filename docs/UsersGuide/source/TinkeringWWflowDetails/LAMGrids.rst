.. _LAMGrids:

=================================================================================
Limited Area Model (:term:`LAM`) Grids:  Predefined and User-Generated Options
=================================================================================
In order to set up the workflow and generate an experiment with the SRW Application, the user
must choose between various predefined :term:`FV3`-:term:`LAM` grids or generate a user-defined grid.
At this time, full support is only provided to those using one of the four predefined
grids supported in the v2.1.0 release, but other predefined grids are available (see :numref:`Section %s <PredefGrid>` for more detail). Preliminary information is also provided at the end of this chapter describing how users can leverage the SRW App workflow scripts to generate their own user-defined grid. Currently, this feature is not fully supported and is "use at your own risk."

Predefined Grids
=================
The SRW App v2.1.0 release includes four predefined limited area model (:term:`LAM`) grids. To select a supported predefined grid, the ``PREDEF_GRID_NAME`` variable within the ``task_run_fcst:`` section of the ``config.yaml`` script must be set to one of the following four options:

* ``RRFS_CONUS_3km``
* ``RRFS_CONUS_13km``
* ``RRFS_CONUS_25km``
* ``SUBCONUS_Ind_3km``

These four options are provided for flexibility related to compute resources and supported physics options. Other predefined grids are listed :ref:`here <PredefGrid>`. The high-resolution 3-km :term:`CONUS` grid generally requires more compute power and works well with three of the five supported physics suites (see :numref:`Table %s <GridPhysicsCombos>`). Low-resolution grids (i.e., 13-km and 25-km domains) require less compute power and should generally be used with the other supported physics suites: ``FV3_GFS_v16`` and ``FV3_RAP``. 

.. _GridPhysicsCombos:

.. table:: Preferred grid and physics combinations for supported domains & physics suites

   +-------------------+------------------+
   | Grid              | Physics Suite(s) |
   +===================+==================+
   | RRFS_CONUS_3km    | FV3_RRFS_v1beta  |
   |                   |                  |
   |                   | FV3_HRRR         |
   |                   |                  |
   |                   | FV3_WoFS         |
   +-------------------+------------------+
   | SUBCONUS_Ind_3km  | FV3_RRFS_v1beta  |
   |                   |                  |
   |                   | FV3_HRRR         |
   |                   |                  |
   |                   | FV3_WoFS         |
   +-------------------+------------------+
   | RRFS_CONUS_13km   | FV3_GFS_v16      |
   |                   |                  |
   |                   | FV3_RAP          |
   +-------------------+------------------+
   | RRFS_CONUS_25km   | FV3_GFS_v16      |
   |                   |                  |
   |                   | FV3_RAP          |
   +-------------------+------------------+

In theory, it is possible to run any of the supported physics suites with any of the predefined grids, but the results will be more accurate and meaningful with appropriate grid/physics pairings. 

The predefined :term:`CONUS` grids follow the naming convention (e.g., RRFS_CONUS_*km) of the prototype 3-km continental United States (CONUS) grid being tested for the Rapid Refresh Forecast System (:term:`RRFS`). The RRFS will be a convection-allowing, hourly-cycled, :term:`FV3`-:term:`LAM`-based ensemble planned for operational implementation in 2024. All four supported grids were created to fit completely within the High Resolution Rapid Refresh (`HRRR <https://rapidrefresh.noaa.gov/hrrr/>`_) domain to allow for use of HRRR data to initialize the SRW App. 

Predefined 3-km CONUS Grid
-----------------------------

The 3-km CONUS domain is ideal for running the ``FV3_RRFS_v1beta`` physics suite, since this suite definition file (:term:`SDF`) was specifically created for convection-allowing scales and is the precursor to the operational physics suite that will be used in the RRFS. The 3-km domain can also be used with the ``FV3_HRRR`` and ``FV3_WoFS`` physics suites, which likewise do not include convective parameterizations. In fact, the ``FV3_WoFS`` physics suite is configured to run at 3-km *or less* and could therefore run with even higher-resolution user-defined domains if desired. However, the ``FV3_GFS_v16`` and ``FV3_RAP`` suites generally should *not* be used with the 3-km domain because the cumulus physics used in those physics suites is not configured to run at the 3-km resolution. 

.. _RRFS_CONUS_3km:

.. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/RRFS_CONUS_3km.sphr.native_wrtcmp.png
   :alt: Map of the continental United States 3 kilometer domain. The computational grid boundaries appear in red and the write-component grid appears just inside the computational grid boundaries in blue. 

   *The boundary of the RRFS_CONUS_3km computational grid (red) and corresponding write-component grid (blue).*

The boundary of the ``RRFS_CONUS_3km`` domain is shown in :numref:`Figure %s <RRFS_CONUS_3km>` (in red), and the boundary of the :ref:`write-component grid <WriteComp>` sits just inside the computational domain (in blue). This extra grid is required because the post-processing utility (:term:`UPP`) is unable to process data on the native FV3 gnomonic grid (in red). Therefore, model data are interpolated to a Lambert conformal grid (the write component grid) in order for the UPP to read in and correctly process the data.

.. note::
   While it is possible to initialize the FV3-LAM with coarser external model data when using the ``RRFS_CONUS_3km`` domain, it is generally advised to use external model data (such as HRRR or RAP data) that has a resolution similar to that of the native FV3-LAM (predefined) grid.


Predefined SUBCONUS Grid Over Indianapolis
--------------------------------------------

.. _SUBCONUS_Ind_3km:

.. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/SUBCONUS_Ind_3km.png
   :alt: Map of Indiana and portions of the surrounding states. The map shows the boundaries of the continental United States sub-grid centered over Indianapolis. The computational grid boundaries appear in red and the write-component grid appears just inside the computational grid boundaries in blue. 

   *The boundary of the SUBCONUS_Ind_3km computational grid (red) and corresponding write-component grid (blue).*

The ``SUBCONUS_Ind_3km`` grid covers only a small section of the :term:`CONUS` centered over Indianapolis. Like the ``RRFS_CONUS_3km`` grid, it is ideally paired with the ``FV3_RRFS_v1beta``, ``FV3_HRRR``, or ``FV3_WoFS`` physics suites, since these are all convection-allowing physics suites designed to work well on high-resolution grids. 

Predefined 13-km Grid
------------------------

.. _RRFS_CONUS_13km:

.. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/RRFS_CONUS_13km.sphr.native_wrtcmp.png
   :alt: Map of the continental United States 13 kilometer domain. The computational grid boundaries appear in red and the write-component grid appears just inside the computational grid boundaries in blue. 

   *The boundary of the RRFS_CONUS_13km computational grid (red) and corresponding write-component grid (blue).*

The ``RRFS_CONUS_13km`` grid (:numref:`Fig. %s <RRFS_CONUS_13km>`) covers the full :term:`CONUS`. This grid is meant to be run with the ``FV3_GFS_v16`` or ``FV3_RAP`` physics suites. These suites use convective :term:`parameterizations`, whereas the other supported suites do not. Convective parameterizations are necessary for low-resolution grids because convection occurs on scales smaller than 25-km and 13-km. 

Predefined 25-km Grid
------------------------

.. _RRFS_CONUS_25km:

.. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/RRFS_CONUS_25km.sphr.native_wrtcmp.png
   :alt: Map of the continental United States 25 kilometer domain. The computational grid boundaries appear in red and the write-component grid appears just inside the computational grid boundaries in blue. 

   *The boundary of the RRFS_CONUS_25km computational grid (red) and corresponding write-component grid (blue).*

The final predefined :term:`CONUS` grid (:numref:`Fig. %s <RRFS_CONUS_25km>`) uses a 25-km resolution and
is meant mostly for quick testing to ensure functionality prior to using a higher-resolution domain.
However, for users who would like to use the 25-km domain for research, the ``FV3_GFS_v16`` :term:`SDF` is recommended for the reasons mentioned :ref:`above <RRFS_CONUS_13km>`. 

Ultimately, the choice of grid is experiment-dependent and resource-dependent. For example, a user may wish to use the ``FV3_GFS_v16`` physics suite, which uses cumulus physics that are not configured to run at the 3-km resolution. In this case, the 13-km or 25-km domain options are better suited to the experiment. Users will also have fewer computational constraints when running with the 13-km and 25-km domains, so depending on the resources available, certain grids may be better options than others. 

.. _UserDefinedGrid:

Creating User-Generated Grids
===============================
While the four supported predefined grids are ideal for users just starting
out with the SRW App, more advanced users may wish to create their own predefined grid for testing over
a different region and/or with a different resolution. Creating a user-defined grid requires
knowledge of how the SRW App workflow functions. In particular, it is important to understand the set of
scripts that handle the workflow and experiment generation (see :numref:`Figure %s <WorkflowGeneration>` and :numref:`Figure %s <WorkflowTasksFig>`). It is also important to note that user-defined grids are not a supported feature of the current release; however, information is being provided for the benefit of the FV3-LAM community.

With those caveats in mind, this section provides instructions for adding a new predefined grid to the FV3-LAM
workflow that will be generated using the "ESGgrid" method (i.e., using the ``regional_esg_grid`` code
in the `UFS_UTILS <https://github.com/ufs-community/UFS_UTILS>`__ repository, where ESG stands for "Extended Schmidt Gnomonic"). We assume here that the grid to be generated covers a domain that (1) does not contain either of the poles and (2) does not cross the -180 deg --> +180 deg discontinuity in longitude near the international date line. More information on the ESG grid is available `here <https://github.com/ufs-community/ufs-srweather-app/wiki/Purser_UIFCW_2023.pdf>`__. Instructions for domains that do not have these restrictions will be provided in a future release.  

The steps to add such a grid to the workflow are as follows:

#. Choose the name of the grid. For the purposes of this documentation, the grid will be called "NEW_GRID".

#. Add NEW_GRID to the array ``valid_vals_PREDEF_GRID_NAME`` in the ``ufs-srweather-app/ush/valid_param_vals.yaml`` file.

#. In ``ufs-srweather-app/ush/predef_grid_params.yaml``, add a stanza describing the parameters for NEW_GRID. An example of such a stanza is given :ref:`below <NewGridExample>`. For descriptions of the variables that need to be set, see Sections :numref:`%s <ESGgrid>` and :numref:`%s <FcstConfigParams>`.

To run a forecast experiment on NEW_GRID, start with a workflow configuration file for a successful experiment (e.g., ``config.community.yaml``, located in the ``ufs-srweather-app/ush`` subdirectory), and change the line for ``PREDEF_GRID_NAME`` in the ``task_run_fcst:`` section to ``NEW_GRID``:

.. code-block:: console

   PREDEF_GRID_NAME: "NEW_GRID"

Then, load the regional workflow python environment, specify the other experiment parameters in ``config.community.yaml``, and generate a new experiment/workflow using the ``generate_FV3LAM_wflow.py`` script (see :numref:`Chapter %s <RunSRW>` for details).

Code Example
---------------

The following is an example of a code stanza for "NEW_GRID" to be added to ``predef_grid_params.yaml``:

.. _NewGridExample:

.. code-block:: console

   #
   #---------------------------------------------------------------------
   #
   #  Stanza for NEW_GRID. This grid covers [description of the
   #  domain] with ~[size]-km cells.
   #
   #---------------------------------------------------------------------
   
   "NEW_GRID":
   
   #  The method used to generate the grid. This example is specifically for the "ESGgrid" method.

      GRID_GEN_METHOD: "ESGgrid"
   
   #  ESGgrid parameters:

      ESGgrid_LON_CTR: -97.5
      ESGgrid_LAT_CTR: 38.5
      ESGgrid_DELX: 25000.0
      ESGgrid_DELY: 25000.0
      ESGgrid_NX: 200
      ESGgrid_NY: 112
      ESGgrid_PAZI: 0.0
      ESGgrid_WIDE_HALO_WIDTH: 6

   #  Forecast configuration parameters:

      DT_ATMOS: 40
      LAYOUT_X: 5
      LAYOUT_Y: 2
      BLOCKSIZE: 40

   #  Parameters for the write-component (aka "quilting") grid. 

      QUILTING:
         WRTCMP_write_groups: 1
         WRTCMP_write_tasks_per_group: 2
         WRTCMP_output_grid: "lambert_conformal"
         WRTCMP_cen_lon: -97.5
         WRTCMP_cen_lat: 38.5
         WRTCMP_lon_lwr_left: -121.12455072
         WRTCMP_lat_lwr_left: 23.89394570

   #  Parameters required for the Lambert conformal grid mapping.

         WRTCMP_stdlat1: 38.5
         WRTCMP_stdlat2: 38.5
         WRTCMP_nx: 197
         WRTCMP_ny: 107
         WRTCMP_dx: 25000.0
         WRTCMP_dy: 25000.0

.. note:: 
   The process above explains how to create a new *predefined* grid, which can be used more than once. If a user prefers to create a custom grid for one-time use, the variables above can instead be specified in ``config.yaml``, and ``PREDEF_GRID_NAME`` can be set to a null string. In this case, it is not necessary to modify ``valid_param_vals.yaml`` or ``predef_grid_params.yaml``. Users can view an example configuration file for a custom grid `here <https://github.com/ufs-community/ufs-srweather-app/blob/develop/tests/WE2E/test_configs/wflow_features/config.custom_ESGgrid.yaml>`__.

.. _VerticalLevels:

Changing the Number of Vertical Levels
========================================

The four supported predefined grids included with the SRW App have 127 vertical levels. However, advanced users may wish to vary the number of vertical levels in the grids they are using, whether these be the predefined grids or a user-generated grid. Varying the number of vertical layers requires
knowledge of how the SRW App interfaces with the Weather Model and preprocessing utilities. It is also important to note that user-defined vertical layers are not a supported feature at present; information is being provided for the benefit of the FV3-LAM community. With those caveats in mind, this section provides instructions for modifying the number of vertical levels on a regional grid. 

.. COMMENT: What are ak and bk?!?!

Find ``ak``/``bk``
--------------------

Users will need to determine ``ak`` and ``bk`` values, which are used to define the vertical levels. The UFS_UTILS ``vcoord_gen`` tool can be used to generate ``ak`` and ``bk`` values, although users may choose a different tool if they prefer. The program will output a text file containing ``ak`` and ``bk`` values, which will be used by ``chgres_cube`` in the ``make_ics_*`` and ``make_lbcs_*`` tasks to generate the initial and lateral boundary conditions from the external data. 

Documentation for ``vcoord_gen`` is available `here <https://noaa-emcufs-utils.readthedocs.io/en/latest/ufs_utils.html#vcoord-gen>`__. Users can find and run the UFS_UTILS ``vcoord_gen`` tool in their ``ufs-srweather-app/sorc/UFS_UTILS`` directory. The program outputs a text file containing the ``ak`` and ``bk`` values. 

.. COMMENT: Do users need to link the fix dirs and build all? Or can they just run a script?
   UFS_UTILS Instructions:
   git clone https://github.com/ufs-community/UFS_UTILS.git
   cd UFS_UTILS/fix
   ./link_fixdirs.sh emc hera
   cd ..
   ./build_all.sh

Configure the SRW App
-----------------------

Modify ``input.nml.FV3``
^^^^^^^^^^^^^^^^^^^^^^^^^^

The FV3 namelist file, ``input.nml.FV3``, is located in ``ufs-srweather-app/parm``. Users will need to update the ``npz`` and ``levp`` variables in this file. For ``n`` vertical levels, users should set ``npz=n`` and ``levp=n+1``. For example, if a user who wants 51 vertical levels would set ``npz`` and ``levp`` as follows: 

.. code-block:: console
   
   &fv_core_nml
      npz = 51

   &external_ic_nml
      levp = 52

Additionally, check that ``external_eta = .true.``.

.. note::

   Keep in mind that levels and layers are not the same. For ``n``` vertical *layers*, set ``npz=n-1`` and ``levp=n``. 

Modify the ``vcoord_gen`` Output File
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

An example ``vcoord_gen`` output file with the ``ak``/``bk`` of 51 *layers* in HRRR:

.. COMMENT: So there are 52 levels? But it outputs the number of layers? 

.. code-block:: console 

     2    51
       0.000  1.00000000
     100.489  0.99703511
     301.301  0.99110699
     652.193  0.98073807
    1252.141  0.96297859
    2048.934  0.93933066
    3039.804  0.90982196
    4172.131  0.87595869
    5345.312  0.84070688
    6654.616  0.80115384
    8095.872  0.75734128
    9664.085  0.70931915
   11353.200  0.65714800
   13155.709  0.60090291
   15061.961  0.54068039
   17058.872  0.47661128
   19127.360  0.40888640
   21196.533  0.33919467
   22957.824  0.27748176
   24425.977  0.22311023
   25594.002  0.17614998
   26490.401  0.13504199
   27092.278  0.10011322
   27389.473  0.07117127
   27374.474  0.04789926
   27047.652  0.03009748
   26431.278  0.01734722
   25569.228  0.00891572
   24456.118  0.00368082
   23317.667  0.00124733
   22039.819  0.00020781
   20678.800  0.00000000
   19297.000  0.00000000
   17915.200  0.00000000
   16533.400  0.00000000
   15151.600  0.00000000
   13769.800  0.00000000
   12388.000  0.00000000
   11006.200  0.00000000
    9624.400  0.00000000
    8438.600  0.00000000
    7566.400  0.00000000
    6762.800  0.00000000
    6008.200  0.00000000
    5302.600  0.00000000
    4655.800  0.00000000
    4048.200  0.00000000
    3479.800  0.00000000
    2950.600  0.00000000
    2460.600  0.00000000
    2000.000  0.00000000

In the SRW App, the ``chgres_cube`` utility performs the vertical level conversion in the ``make_ics_*`` and ``make_lbcs_*`` tasks, so some additional changes to the ``vcoord_gen`` output file are required.

The first line needs to be changed to:

.. code-block:: console 

   2     52

And one more line needs to be added at the bottom of the text file:

.. code-block:: console 

   0   0

Modify ``config.yaml``
^^^^^^^^^^^^^^^^^^^^^^^^

To use the text file produced by ``vcoord_gen`` in the SRW App, users need to set the ``VCOORD_FILE`` variable in their ``config.yaml`` file. Normally, this file is named ``global_hyblev.l65.txt`` and is located in the ``fix_am`` directory, but users should adjust the path and name of the file to suit their system. For example, in ``config.yaml``, set: 

.. code-block:: console

   task_make_ics:
      VCOORD_FILE: /Users/Jane.Smith/data/fix_am/global_hyblev.l75.txt
   task_make_lbcs:
      VCOORD_FILE: /Users/Jane.Smith/data/fix_am/global_hyblev.l75.txt

