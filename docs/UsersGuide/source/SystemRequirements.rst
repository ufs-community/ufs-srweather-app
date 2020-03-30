.. _SystemRequirements:

===================
System Requirements
===================
The UFS Short-Range Weather Application is supported on the NOAA HPC Hera and NCAR
Supercomputer Cheyenne.  Intel and GNU are the currently supported
compilers for building the pre-processing utilities, the UFS Weather Model,
and the Unified Post Processor (:term:`UPP`).

Software/Operating System Requirements
======================================
The following are the external system and software requirements for installing and
running all tasks in the UFS Short-Range Weather Application. 

* UNIX style operating system
* Fortran compiler with support for Fortran 2003 (Intel or GNU compiler)
* python = 2.7
* perl 5
* git client (1.8 or greater)
* C compiler
* MPI
* netCDF
* HDF5
* pnetCDF
* `NCEPLIBS <https://github.com/NOAA-EMC/NCEPLIBS>`_
* `NCEPLIBS-external <https://github.com/NOAA-EMC/NCEPLIBS-external>`_ (includes ESMF)
* CMake 3.15 or newer
* Rocoto Workflow Management System (1.3.1)

NCEP Libraries
==============
A number of the :term:`NCEP` (National Center for Environmental Prediction) production
libraries are necessary for building and running the pre-processing utilities,
the :term:`UFS` :term:`Weather Model` and :term:`UPP`.  These libraries are not part of the
UFS Short-Range Weather Application source code distribution.  If they are not already installed on
your computer platform, you may have to clone the source code from the
`github repository <https://github.com/NOAA-EMC/NCEPLIBS>`_ and follow the build instructions
in the `wiki page <https://github.com/NOAA-EMC/NCEPLIBS/wiki/Cloning-and-Compiling-NCEPLIBS>`_.
Note that these libraries must be built with the same compiler used to build the pre-processing utilities,
the UFS Weather Model and the UPP.
