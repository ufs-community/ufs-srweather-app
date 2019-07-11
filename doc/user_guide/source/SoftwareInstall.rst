.. _SoftwareInstall:

****************************************
How to Install the Regional FV3 Software
****************************************

#. Create a top-level directory (aka base directory) in which to clone the FV3SAR workflow
   repository.  In these instructions, we will assume that the shell variable ``BASEDIR`` contains
   the full path to this directory.  Then the base directory can be created as follows:

   .. code-block:: console

      mkdir $BASEDIR

#. Clone the ``regional_workflow`` repository (currently hosted on Github) within ``BASEDIR`` and
   check out the ``community_develop`` branch:

   .. code-block:: console

      cd $BASEDIR
      git clone git@github.com:NOAA-EMC/regional_workflow

   or

   .. code-block:: console

      git clone https://${GITHUBUSER}@github.com/NOAA-EMC/regional_workflow
      cd regional_workflow
      git checkout community_develop

An example of including comments from a script:

This describes the machine and queue parameters:

.. literalinclude:: ../../../ush/config_defaults.sh
   :start-after: mach_doc_start
   :end-before: mach_doc_end

This describes the contents of the directories:

.. literalinclude:: ../../../ush/config_defaults.sh
   :start-after: dir_doc_start
   :end-before: dir_doc_end


