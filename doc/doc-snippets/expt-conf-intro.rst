Navigate to the ``ufs-srweather-app/ush`` directory. The default (or "control") configuration for this experiment is based on the ``config.community.yaml`` file in that directory. Users can copy this file into ``config.yaml`` if they have not already done so:

.. code-block:: console

   cd /path/to/ufs-srweather-app/ush
   cp config.community.yaml config.yaml

Users can save the location of the ``ush`` directory in an environment variable (``$USH``). This makes it easier to navigate between directories later. For example:

.. code-block:: console

   export USH=/path/to/ufs-srweather-app/ush

Users should substitute ``/path/to/ufs-srweather-app/ush`` with the actual path on their system. As long as a user remains logged into their system, they can run ``cd $USH``, and it will take them to the ``ush`` directory. The variable will need to be reset for each login session. 