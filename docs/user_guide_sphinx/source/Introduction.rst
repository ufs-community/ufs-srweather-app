.. _introduction:
.. include:: prolog.inc 

------------
Introduction
------------

This document contains the Finite-Volume Cubed-Sphere Standalone Regional (FV3SAR) Model User's Guide. It provides an overview of the FV3SAR, the fundamentals of obtaining, building and running the FV3SAR. There is also a description of the FV3SAR community workflow and its components. 

For the latest version of the released code, please visit the `FV3SAR DTC Website <http://www.dtcenter.org/>`_

Please send questions and comments to the help desk: `xxx-help@ucar.edu`

This document and the annual releases are made available through a community effort jointly led by the Developmental Testbed Center (DTC) and the National Centers for Environmental Prediction (NCEP) Environmental Modeling Center (EMC), in collaboration with other developers. To help sustain this effort, we recommend for those who use the community release, the  helpdesk, the User's Guide, and other DTC services, please refer to this community effort in their work and publications. 


How To Use This Document
------------------------

This table describes the type changes and symbols used in this guide.

+------------------------+------------------------------+---------------------------------------+
| **Typeface or Symbol** |  **Meaning**                 |  **Example**                          |
+========================+==============================+=======================================+
| ``AaBbCc123``          | The names of commands,       | Edit your ``.bashrc`` |br|            |
|                        | files, and directories; |br| | Use ``ls -a`` to list all files. |br| |
|                        | on-screen computer output    | ``host$ You have mail!``              |
+------------------------+------------------------------+---------------------------------------+
| :mod:`AaBbCc123`       | What you type contrasted     | ``host$`` :mod:`su`                   |
|                        | with on-screen computer      |                                       |
|                        | output                       |                                       |
+------------------------+------------------------------+---------------------------------------+
| ``%``                  | Command-line prompt          | ``% cd $TOP_DIR``                     |
+------------------------+------------------------------+---------------------------------------+

Following these typefaces and conventions, shell commands, code examples, namelist varialbes, etc.
will be presented in this style:

.. code-block:: console

   % mkdir ${TOP_DIR}
