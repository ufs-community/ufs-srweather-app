.. _Quickstart:

==========
Quickstart
==========
To build and run the UFS Short-Range Weather Application, the user must get the workflow scripts,
and source code for the UFS_UTILS pre-processor, the UFS Weather Model, and the Unified
Post Processor (:term:`UPP`).  Obtaining the source code is simplified by the use of *manage_externals*,
which allows the user to clone an umbrella repository and all of the necessary sub-repositories.
The steps described in this chapter assume that the necessary software/operating system
requirements and libraries described in :numref:`Section %s <SystemRequirements>` are built
and available as modules on your machine.

.. _ObtainingCode:

Obtaining the Source Code
=========================
The necessary source code is publicly available on github.  To clone the latest version of the code:

.. code-block:: console

   git clone https://github.com/ufs-community/ufs-srweather-app.git
   cd ufs-srweather-app
   git checkout master
   ./manage_externals/checkout_externals

This steps will create a directory called ``ufs-srweather-app`` and check out the ``master`` branch.
``manage_externals/checkout_externals`` command will clone the additional repositories needed by the workflow.
The ``checkout_externals`` script uses the configuration file ``Externals.cfg`` in the top level directory
and will clone the pre-processor source code, the :term:`UFS` :term:`Weather Model`, and :term:`UPP` source
code into the appropriate directories under your regional_workflow directory.

Building the Source Code
========================
Build the preprocessing utilities, forecast model, and post-processor as follows:

.. code-block:: console

   cd ufs-srweather-app/src
   ./build_all.sh >& build.out &

This will likely take ~30 minutes.  Log files will be written in the ``ufs-srweather-app/src/logs`` directory.
When the build completes, you should see the following executables in the ``ufs-srweather-app/exec`` directory:

.. code-block:: console

   chgres_cube.exe
   filter_topo
   fregrid
   fregrid_parallel
   global_equiv_resol
   make_hgrid
   make_hgrid_parallel
   make_solo_mosaic
   mosaic_file
   ncep_post
   orog.x
   regional_grid
   sfc_climo_gen
   shave.x

These are the pre- and post-processing executables.  The forecast executable ``fv3.exe`` resides in
``ufs-srweather-app/src/ufs_weather_model/tests`` and is built, by default, with the Common Community
Physics Package (:term:`CCPP`).  For more information on the CCPP, see
`here <https://ccpp-techdoc.readthedocs.io/en/v4.0/>`_ enabled. 
For more information on the UFS Weather Model build options, see 
https://ufs-weather-model.readthedocs.io/en/latest/CompilingCodeWithoutApp.html.

.. note::

   You must first complete the build steps before proceeding to the workflow generation and run steps below.
