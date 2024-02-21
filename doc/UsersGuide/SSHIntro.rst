:orphan:

.. _SSHIntro:

======================================
Introduction to SSH & Data Transfer
======================================

.. attention:: 

   Note that all port numbers, IP addresses, and SSH keys included in this chapter are placeholders and do not refer to known systems. They are used purely for illustrative purposes, and users should modify the commands to correspond to their actual systems. 

A Secure SHell (SSH) tunnel creates an encrypted connection between two computer systems. This secure connection allows users to access and use a remote system via the command line on their local machine. SSH connections can also be used to transfer data securely between two systems. Many HPC platforms, including NOAA :srw-wiki:`Level 1 systems <Supported-Platforms-and-Compilers>`, are accessed via SSH from the user's own computer. 

.. attention:: 

   Note that the instructions on this page assume that users are working on a UNIX-like system (i.e., Linux or MacOS). They may not work as-is on Windows systems, but users can adapt them for Windows or use a tool such as Cygwin, which enables the use of UNIX-like commands on Windows. Users may also consider installing a virtual machine such as VirtualBox. 

.. _CreateSSH:

Creating an SSH Tunnel
============================

Create an SSH Key
--------------------

To generate an SSH key, open a terminal window and run:  

.. code-block:: console
      
   ssh-keygen -t rsa

Hit enter three times to accept defaults, or if customization is desired:

   * Enter the file in which to save the key (for example: ``~/.ssh/id_rsa``)
   * Enter passphrase (empty for no passphrase)
   * Enter same passphrase again

To see the SSH public key contents, run: 

.. code-block:: console

   cat id_rsa.pub

SSH Into a Remote Machine
----------------------------

This process differs somewhat from system to system. However, this section provides general guidance. 

Create/Edit an SSH Configuration File (``~/.ssh/config``)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

If it exists, the SSH ``config`` file is located in the hidden ``.ssh`` directory. If it does not exist, opening it will create the file. In a terminal window, run:

.. code-block:: console

   vi ~/.ssh/config

Press ``i`` to edit the file, and add an entry in the following format: 

.. code-block:: console

   Host <name_of_your_choice>
     Hostname <host_name_or_IP_address>
     User <Username>
     IdentityFile ~/.ssh/<key_name>

When finished, hit the ``esc`` key and type ``:wq`` to write the data to the file and quit the file editor.

.. note::

   The ``IdentityFile`` line is not required unless the user has multiple SSH keys. However, there is no harm in adding it. 

Concretely, a user logging into an AWS cluster might enter something similar to the following. 

.. code-block:: console

   Host aws
     Hostname 50.60.700.80
     User Jane.Doe
     IdentityFile ~/.ssh/id_rsa

Users attempting to authenticate via SSH on GitHub might create the following code block instead:

.. code-block:: console
   
   Host github
     Hostname github.com
     User git
     IdentityFile ~/.ssh/id_ed25519

SSH Into the Remote System
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

To SSH into the remote system, simply run:

.. code-block:: console

   ssh <Host> 

where ``<Host>`` is the "name_of_your_choice" that was added to the ``config`` file. For example, a user logging into the AWS cluster above would type:

.. code-block:: console

   ssh aws 

This will create an SSH tunnel between the user's local system and the AWS cluster. The user will be able to work on the AWS cluster by running commands in the terminal window. 

In some cases, the user may be asked if they want to connect:

.. code-block:: console

   The authenticity of host '50.60.700.80 (50.60.700.80)' can't be established.
   ECDSA key fingerprint is SHA256:a0ABbC4cdeDEfFghi+j3kGHlO5mnIJKLMop7NOqPrQR.
   Are you sure you want to continue connecting (yes/no/[fingerprint])? 

Enter ``yes`` to continue connecting. The user is responsible for verifying that they are connecting to the correct system. 

.. _SSHDataTransfer:

Data Transfer via SSH
============================

Introduction
---------------

Users who are working on a remote cloud or HPC system may want to copy files (e.g., graphics plots) to or from their local system. Users can run the ``scp`` command in a new terminal/command prompt window to securely copy these files from their remote system to their local system or vice versa. The structure of the command is:

.. code-block:: console

   scp [OPTION] [user@]SRC_HOST:]file1 [user@]DEST_HOST:]file2

Here, ``SRC_HOST`` refers to the system where the files are currently located. ``DEST_HOST`` refers to the system that the files will be copied to. ``file1`` is the path to the file or directory to copy, and ``file2`` is the location that the file or directory should be copied to on the ``DEST_HOST`` system. 

.. _SSHDownload:

Download the Data from a Remote System to a Local System
-----------------------------------------------------------

.. note:: 

   Users should transfer data to or from non-:srw-wiki:`Level 1 <Supported-Platforms-and-Compilers>` platforms using the recommended approach for that platform. This section outlines some basic guidance, but users may need to supplement with research of their own. On Level 1 systems, users may find it helpful to refer to the `RDHPCS CommonDocs Wiki <https://rdhpcs-common-docs.rdhpcs.noaa.gov/wiki/index.php/Transferring_Data>`__.

To download data using ``scp``, users can typically adjust one of the following commands for use on their system:

.. code-block:: console

   scp username@your-IP-address:/path/to/file_or_directory_1 /path/to/file_or_directory_2
   # OR
   scp -P 12345 username@localhost:/path/to/file_or_directory_1 path/to/file_or_directory_2

To copy an entire directory, use ``scp -r`` instead of ``scp``. 

Users who know the IP address of their remote system can use the first command. For example: 

.. code-block:: console

   scp Jane.Doe@10.20.300.40:/contrib/Jane.Doe/expt_dirs/test_community/2019061518/postprd/*.png /Users/janedoe/plots

This command will copy all files ending in ``.png`` from the remote ``test_community/2019061518/postprd/`` experiment subdirectory into Jane Doe's local ``plots`` directory. 

Users who know their ``localhost`` port number should use the second command and, if requested, enter the password to the remote system. For example:

.. code-block:: console

   scp -P 3355 Jane.Doe@localhost:/lustre/Jane.Doe/expt_dirs/test_community/2019061518/postprd/*.png .

This command will copy all files ending in ``.png`` from the ``test_community/2019061518/postprd/`` experiment subdirectory on a remote HPC system into Jane Doe's present working directory (``.``). 

.. attention:: 

   Note that all port numbers, IP addresses, and SSH keys included in this chapter are placeholders and do not refer to known systems. They are used purely for illustrative purposes, and users should modify the commands to correspond to their actual systems. 