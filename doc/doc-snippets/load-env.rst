.. code-block:: console

   source /path/to/ufs-srweather-app/etc/lmod-setup.sh <platform>
   module use /path/to/ufs-srweather-app/modulefiles
   module load wflow_<platform>

where ``<platform>`` is a valid, lowercased machine name (see ``MACHINE`` in :numref:`Section %s <user>` for valid values), and ``/path/to/`` is replaced by the actual path to the ``ufs-srweather-app``. 