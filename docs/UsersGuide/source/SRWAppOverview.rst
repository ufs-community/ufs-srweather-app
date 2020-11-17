.. _SRWAppOverview:

========================================
Short-Range Weather Application Overview
========================================

Building the Executables for the Application
============================================
When the build completes, you should see the following pre- and post-processing executables in the
``ufs-srweather-app/bin`` directory which are described in :numref:`Table %s <exec_description>`.

.. _exec_description:

.. table::  Names and descriptions of the executables produced by the build step and used by the SRW App.

   +------------------------+---------------------------------------------------------------------------------+
   | **Executable Name**    | **Description**                                                                 |
   +========================+=================================================================================+
   | chgres_cube            | Reads in raw external model (global or regional) and surface climatology data   |
   |                        | to create initial conditions for the UFS Weather Model                          |
   +------------------------+---------------------------------------------------------------------------------+
   | filter_topo            | Filters topography based on resolution                                          |
   +------------------------+---------------------------------------------------------------------------------+
   | global_equiv_resol     | Calculates the regional grid’s global uniform cubed-sphere grid equivalent      |
   |                        | resolution                                                                      |
   +------------------------+---------------------------------------------------------------------------------+
   | make_hgrid             | Creates GFDL horizontal grid files                                              |
   +------------------------+---------------------------------------------------------------------------------+

.. _RunUsingStandaloneScripts:

Run Workflow Using Stand-alone Scripts
============================================
