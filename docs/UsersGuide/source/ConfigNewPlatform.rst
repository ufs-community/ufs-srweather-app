.. _ConfigNewPlatform:

===========================
Configfuring a New Platform
===========================

Software/Operating System Requirements
======================================
The following are the external system and software requirements for installing and
running all tasks in the UFS SRW Application. 

* UNIX style operating system
* Fortran compiler with support for Fortran 2003
* Python = 2.7 or 3, jinja2, yaml and f90nml
* Perl 5
* Git client (1.8 or greater)
* C compiler
* MPI
* netCDF
* HDF5
* `NCEPLIBS <https://github.com/NOAA-EMC/NCEPLIBS>`_
* `NCEPLIBS-external <https://github.com/NOAA-EMC/NCEPLIBS-external>`_ (includes ESMF)
* CMake 3.15 or newer
* Rocoto Workflow Management System (1.3.1)

.. note::

   :term:`NCEPLIBS` and :term:`NCEPLIBS-external` reside in separate GitHub repositories and are not
   part of the UFS SRW App repository.  These third-party libraries are necessary for building and
   running the pre-processing utilities, the :term:`UFS` :term:`Weather Model` and :term:`UPP`.
   If they are not already installed on your computer platform, you will have to clone the source code from the
   github repositories `NCEPLIBS-external <https://github.com/NOAA-EMC/NCEPLIBS-external>`_ and
   `NCEPLIBS <https://github.com/NOAA-EMC/NCEPLIBS>`_ and follow the build instructions
   in the `NCEPLIBS-external wiki page <https://github.com/NOAA-EMC/NCEPLIBS-external/wiki>`_.
   These libraries must be built with the same compiler used to build the pre-processing utilities,
   the UFS Weather Model and the UPP.  The libraries in NCEPLIBS-external must be built *before* the libraries
   in NCEPLIBS.

Generic MacOS or Linux Platforms
================================
