Users who are working on the cloud or on an HPC cluster may want to copy the ``.png`` files onto their local system to view in their preferred image viewer. Detailed instructions are available in the :ref:`Introduction to SSH & Data Transfer <SSHDataTransfer>`.

In summary, users can run the ``scp`` command in a new terminal/command prompt window to securely copy files from a remote system to their local system if an SSH tunnel is already established between the local system and the remote system. Users can adjust one of the following commands for their system:

.. code-block:: console

   scp username@your-IP-address:/path/to/source_file_or_directory /path/to/destination_file_or_directory
   # OR
   scp -P 12345 username@localhost:/path/to/source_file_or_directory /path/to/destination_file_or_directory

Users would need to modify ``username``, ``your-IP-address``, ``-P 12345``, and the file paths to reflect their systems' information. See the :ref:`Introduction to SSH & Data Transfer <SSHDataTransfer>` for example commands. 