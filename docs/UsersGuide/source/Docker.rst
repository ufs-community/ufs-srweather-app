.. _Docker:

*************
Run in Docker
*************

This document explains how to run the SRW public release, version 1,
in a Docker container. We will run twice: once by building a Docker
image complete with the application, and a second time building the
application manually within a pre-existing Docker image.

* :ref:`Docker_GetDocker`

* :ref:`Docker_DownloadTheFiles`

* :ref:`Docker_CreatingTheDockerImage`

* :ref:`Docker_StartTheWorkflow`

* :ref:`Docker_MonitorTheWorkflow`

* :ref:`Docker_WhereIsMyOutput`

* :ref:`Docker_ChangingTheCode`

.. note::
   If you find that :ref:`Docker_CreatingTheDockerImage` is too hard, then
   manually compile and run instead. It may be easier for you. To do
   that, you would read the sections in this order instead:

   * :ref:`Docker_GetDocker`

   * :ref:`Docker_DownloadTheFiles`

   * :ref:`Docker_ChangingTheCode` (the last section in this document)

   * :ref:`Docker_StartTheWorkflow`

   * :ref:`Docker_MonitorTheWorkflow`

   * :ref:`Docker_WhereIsMyOutput`

.. _Docker_GetDocker:
   
Get Docker
##########

Security Risks
**************

Containerization technologies such as Docker are security risks unless
they are used correctly. Before using Docker on a production
environment, or any other situation where the security of your machine
is critical, make sure you plan accordingly:

https://docs.docker.com/engine/security/security/

These containers were built and tested in a virtual machine to fully
isolate Docker from the host. If your machine has hardware
virtualization support, that is an excellent option. Cloud computing
providers also use virtualization. Running inside a cloud provider's
container service is another option.

Install Docker
**************

Before you can follow any of these instructions, you need to install
the Docker Engine. The method depends on your platform. To get the
official Docker releases, go to their Release Channels. Otherwise,
your operating system's package repository may have Docker. It's
likely called "docker" or "docker.io"

If you want the most recent version of Docker, full instructions for
all platforms Docker supports are here:

* https://docs.docker.com/engine/install/

Relevant pages for Ubuntu and RedHat/CentOS:

* UBUNTU: https://docs.docker.com/engine/install/ubuntu/
* REDHAT/CENTOS: https://docs.docker.com/engine/install/centos/
* Optional post-install steps: https://docs.docker.com/engine/install/linux-postinstall/

.. _Docker_DownloadTheFiles:

Download The Files
##################

You need to download seven files.

Most of the compressed files are available in three forms:

1. ``.tar.xz`` -- xz files for Linux. These are the smallest files. If
   you have xz on your computer, download this one. (On unix, run
   ``xz --version`` to see if xz is installed.)

2. ``.7z`` -- 7zip files for Windows. They use the same compression
   algorithm as xz, so they're about the same size.

3. ``.tar.gz`` -- For unix users who are stuck without xz, download these.

Most files have md5sums next to them, so you can verify the
download. They're named like so:

- For this file: ``20210224-ubuntu18-nceplibs.gz``

- The md5sum is: ``20210224-ubuntu18-nceplibs.gz.md5``

7zip has its own verification system, so you don't need to check the
md5sum. Just tell 7zip to verify the archive.

The files:

- The container. If you download the 7z, you'll need to extract the
  file inside. Others can be given to Docker directly, if it
  understands the compression algorithm. These each contain a
  compressed tar file. No *not* untar the file; the tar file *is* the
  container. Download ONE of:

  - https://ufs-data.s3.amazonaws.com/public_release/ufs-srweather-app-v1.0.0/docker/20210224-ubuntu18-nceplibs.xz

  - https://ufs-data.s3.amazonaws.com/public_release/ufs-srweather-app-v1.0.0/docker/20210224-ubuntu18-nceplibs.7z

  - https://ufs-data.s3.amazonaws.com/public_release/ufs-srweather-app-v1.0.0/docker/20210224-ubuntu18-nceplibs.gz

- ``config.sh`` https://ufs-data.s3.amazonaws.com/public_release/ufs-srweather-app-v1.0.0/docker/config.sh

- ``run_all.sh`` https://ufs-data.s3.amazonaws.com/public_release/ufs-srweather-app-v1.0.0/docker/run_all.sh

- ``ufs-srweather-app-Dockerfile`` https://ufs-data.s3.amazonaws.com/public_release/ufs-srweather-app-v1.0.0/docker/ufs-srweather-app-Dockerfile

- ``fix_files.tar.xz`` Download ONE of:

  - https://ufs-data.s3.amazonaws.com/public_release/ufs-srweather-app-v1.0.0/docker/fix_files.tar.xz

  - https://ufs-data.s3.amazonaws.com/public_release/ufs-srweather-app-v1.0.0/docker/fix_files.7z

  - https://ufs-data.s3.amazonaws.com/public_release/ufs-srweather-app-v1.0.0/docker/fix_files.tar.gz

- Native Earth files. These are only available as ``.tar.gz`` files.
  Download ONE of:

  - https://ftp.emc.ncep.noaa.gov/EIB/UFS/SRW/v1p0/natural_earth/natural_earth_ufs-srw-release-v1.0.0.tar.gz

  - https://ufs-data.s3.amazonaws.com/public_release/ufs-srweather-app-v1.0.0/natural_earth/natural_earth_ufs-srw-release-v1.0.0.tar.gz

- Model input data. You have two options.

  1. Download just the test case in this tutorial. ONE of:

     - https://ufs-data.s3.amazonaws.com/public_release/ufs-srweather-app-v1.0.0/docker/model_data_fv3gfs_2019061500.tar.xz

     - https://ufs-data.s3.amazonaws.com/public_release/ufs-srweather-app-v1.0.0/docker/model_data_fv3gfs_2019061500.7z

     - https://ufs-data.s3.amazonaws.com/public_release/ufs-srweather-app-v1.0.0/docker/model_data_fv3gfs_2019061500.tar.gz

  2. Download all four test cases. These are only available in
     ``.tar.gz`` files. Download ONE of:

       - https://ftp.emc.ncep.noaa.gov/EIB/UFS/SRW/v1p0/simple_test_case/gst_model_data.tar.gz

       - https://ufs-data.s3.amazonaws.com/public_release/ufs-srweather-app-v1.0.0/ic/gst_model_data.tar.gz

.. _Docker_CreatingTheDockerImage:

Create the Docker Image
#######################

1. Put all seven files you downloaded in one directory.

2. If you have a large machine, with 12 logical cpus or more, you
   should switch to the 12 core setup by editing ``config.sh``. The
   default is for four (4) logical cpus. Near the bottom of ``config.sh``
   you will see these lines::

        # Twelve (12) core machines
        RUN_CMD_UTILS="mpirun -np 12"
        RUN_CMD_POST="mpirun -np 12"
        
        # Comment out the next five lines if you want the 12 core settings
        # Four (4) core machines
        LAYOUT_X="1"
        LAYOUT_Y="3"
        RUN_CMD_UTILS="mpirun -np 4"
        RUN_CMD_POST="mpirun -np 4"

   To run the 12 core version, comment out the last four lines, which
   set the ``$LAYOUT_X``, ``$LAYOUT_Y``, ``$RUN_CMD_UTILS``, and
   ``$RUN_CMD_POST`` variables.

3. LOW MEMORY MACHINES - The workflow uses more than 16 GB of memory
   (RAM), on top of the memory your OS and other applications use. If
   you don't have significantly more than 16 GB of RAM, then use the 4
   core config, but reduce the utilities to one MPI rank. Do that by
   putting this at the end of ``config.sh``::

       RUN_CMD_UTILS="mpirun -np 1"

   The utilities will take a long time to run if you do that, but the
   memory usage will be lower.


4. Import the docker container. This command is for a unix console; if
   you're using a graphical Docker wrapper, substitute with the
   appropriate actions::

       docker import 20210224-ubuntu18-nceplibs.xz import-nceplibs-20210219

   .. note::
      
      If your machine cannot handle the ``.xz`` files, then try
      decompressing the file first. If you can't decompress it, download
      the ``.7z`` file with 7zip, or the ``.gz`` file and decompress that. On
      Windows, the ``.7z`` file is your best bet if you have 7zip
      installed.

5. Update the ``FROM`` line at the top of ``ufs-srweather-app-Dockerfile``
   to match your imported name::

     FROM import-nceplibs-20210219

6. In the same file, change the ``git clone`` command to match your desired branch and repository::

     git clone --branch ufs-v1.0.1 https://github.com/ufs-community/ufs-srweather-app.git /usr/local/src/ufs-srweather-app

7. Build a new docker container, with the compiled model and
   workflow. This command is for a unix console; if you're using a
   graphical Docker wrapper, substitute with the appropriate actions::

       docker build -t ufs-srweather-app-20210219 -f ufs-srweather-app-Dockerfile .

8. Pick a directory to store the workflow output, and make that
   directory on your host machine. Choose a directory on the container
   with a linux-friendly directory path. That means no whitespace or
   special characters::

       export HOST_TEMP_DIR="/home/example_home_directory/ufs"
       export DOCKER_TEMP_DIR=/tmp/docker
       mkdir $HOST_TEMP_DIR

   Those commands are for bash; if you are using a different method
   (like Finder, Explorer or tcsh), then substitute with the
   appropriate actions.

9. Decompress the two data archives into your ``$HOST_TEMP_DIR``. This
   command is for a bash console; if you're using something else,
   substitute it with the appropriate actions::

       cd "$HOST_TEMP_DIR"
       unxz -c /path/to/model_data_fv3gfs_2019061500.tar.xz | tar -xf -
       unxz -c /path/to/fix_files.tar.xz | tar -xf -

   .. note::
      
      If your machine cannot handle the ``.xz`` files, then try the
      ``.7z`` with 7zip, or the ``.gz`` gzipped files instead. The ``.7z`` is
      your best bet on Windows, if you have 7zip installed.

10. Check ``$HOST_TEMP_DIR`` and make sure you see these four directories:

  - ``fix_am``
  - ``fix_orog``
  - ``fix_sfc_climo``
  - ``model_data``

11. There should be a ``$HOST_TEMP_DIR/model_data/FV3GFS/2019061500`` directory.


.. _Docker_StartTheWorkflow:

Start the Workflow
##################

1. Start a docker container from the image you just built::

       docker run --mount "type=bind,source=${HOST_TEMP_DIR},target=${DOCKER_TEMP_DIR}" -it ufs-srweather-app-20210219 bash --login

2. You should see a bash root shell that looks something like this::

       [root@e9de7d681604 /]#

3. Set the ``$DOCKER_TEMP_DIR`` variable again. This time, it is in the
   container::

       export DOCKER_TEMP_DIR=/tmp/retest

   IMPORTANT: The ``$DOCKER_TEMP_DIR`` inside the container *must* match
   the ``$DOCKER_TEMP_DIR`` outside the container.

4. Go to the regional workflow ush directory::

       cd /usr/local/src/ufs-srweather-app/regional_workflow/ush

5. Generate the workflow::

       ./generate_FV3LAM_wflow.sh

6. When it finishes, you should see this::

        ========================================================================
        ========================================================================
        
        Workflow generation completed.
        
        ========================================================================
        ========================================================================
        
        The experiment directory is:
        
          > EXPTDIR="/tmp/retest/experiment/test_CONUS_25km_GFSv15p2"

7. Go to the wrappers directory::

        cd wrappers/

8. Run the workflow in the background, so you can monitor the log files::

        ./run_all.sh > run_all.log 2>&1 &

9. You should see this message, which means the job is running. The
   second number will vary; it is the process id assigned by the
   operating system::

        [1] 24737


.. _Docker_MonitorTheWorkflow:

Monitor the Workflow
####################

This section explains several ways to monitor the workflow. If you
don't want to monitor it in detail, just wait for the workflow to end
by typing::

    wait %1

When that returns, view the last 10 lines of the log file to see if it
succeeded::

    tail run_all.log

You will see the final job, the post, finish its 48th hour::

    ========================================================================
    Post-processing for forecast hour 048 completed successfully.
    
    Exiting script:  "exregional_run_post.sh"
    In directory:    "/usr/local/src/ufs-srweather-app/regional_workflow/scripts"
    ========================================================================
    + print_info_msg '
    ========================================================================
    Exiting script:  "JREGIONAL_RUN_POST"
    In directory:    "/usr/local/src/ufs-srweather-app/regional_workflow/jobs"
    ========================================================================'
    
    ========================================================================
    Exiting script:  "JREGIONAL_RUN_POST"
    In directory:    "/usr/local/src/ufs-srweather-app/regional_workflow/jobs"
    ========================================================================
    + (( i++  ))
    + (( i<=48 ))

Monitor Main Log File with ``tail``
***********************************

The ``run_all.log`` will log what wrappers are run, and the last 20 lines
of each wrapper's log file:
::

        tail run_all.log

You'll see something like this::

        Running all steps.
        Will log to /tmp/retest/log
        + '[' -d /tmp/retest/log ']'
        + mkdir /tmp/retest/log
        + export OMP_NUM_THREADS=1
        + OMP_NUM_THREADS=1
        + ulimit -s unlimited
        + export EXPTDIR=/tmp/retest/experiment/test_CONUS_25km_GFSv15p2
        + EXPTDIR=/tmp/retest/experiment/test_CONUS_25km_GFSv15p2
        + nohup ./run_get_ics.sh

As the workflow progresses, the file will get longer.



Listing Log Files by Time
*************************

Each step has its own log file. This will list log files for each step::

        ls -ltr --full-time $DOCKER_TEMP_DIR/log/

That command will print something like this::

        total 8796
        -rw-r--r-- 1 root root   17510 2021-02-19 17:50:06.774014595 +0000 get_ics.log
        -rw-r--r-- 1 root root   18788 2021-02-19 17:50:10.518036577 +0000 get_lbcs.log
        -rw-r--r-- 1 root root   48747 2021-02-19 17:50:16.586072208 +0000 make_grid.log
        -rw-r--r-- 1 root root   30292 2021-02-19 17:50:58.298017510 +0000 make_orog.log
        -rw-r--r-- 1 root root  153713 2021-02-19 17:55:23.869799673 +0000 make_sfc_climo.log
        -rw-r--r-- 1 root root 8421423 2021-02-19 17:56:11.053830057 +0000 make_ics.log
        -rw-r--r-- 1 root root  299635 2021-02-19 17:57:36.689925955 +0000 make_lbcs.log




Viewing Each Step's Log File
****************************

As the workflow progresses, more files will appear. You can examine
the end of a log file with ``tail``::

    tail $DOCKER_TEMP_DIR/log/get_ics.log

That will print something like::

    generating initial conditions and surface fields for the FV3 forecast!!!
    
    Exiting script:  "exregional_get_extrn_mdl_files.sh"
    In directory:    "/usr/local/src/ufs-srweather-app/regional_workflow/scripts"
    ========================================================================
    
    ========================================================================
    Exiting script:  "JREGIONAL_GET_EXTRN_MDL_FILES"
    In directory:    "/usr/local/src/ufs-srweather-app/regional_workflow/jobs"
    ========================================================================


Monitor a Log File with ``tail -f``
***********************************

As a job proceeds, the log file will update. You can see the file as
it updates continuously using the ``-f`` flag to tail. This is only
meaningful for the newest log files; for jobs that have finished, ``tail -f``
is equivalent to ``tail``.

In my case, the make_lbcs is the job currently running. I know that
because it is the last file listed by the ``ls -ltr --full-time``
command::

    tail -f $DOCKER_TEMP_DIR/log/make_lbcs.log

Press ``Control-C`` to exit ``tail -f`` when you're done monitoring the
file. The ``tail -f`` command will not exit on its own.


View a Snapshot With ``less``
*****************************

You can view a snapshot of all of the log file using ``less``::

    less $DOCKER_TEMP_DIR/log/make_lbcs.log

Press ``q`` to exit ``less``


Monitor the Post and Graphics
*****************************

The graphics are generated last, after the post. Both the post and the
graphics put their output in this directory::

    $DOCKER_TEMP_DIR/experiment/test_CONUS_25km_GFSv15p2/2019061500/postprd

The post produces ``*.grib2`` files, and the graphics scripts make
``*.png`` files.


Is it Done?
***********

To check if the workflow finished, look at the end of the run_all.log file:
::

    tail run_all.log

After the last job finishes, the graphics, you will see a message like this::

    Done.
   
    The model ran here:
       $DOCKER_TEMP_DIR/experiment/test_CONUS_25km_GFSv15p2/2019061500
   
    GRIB2 files and plots are in the postprd subdirectory:
       $DOCKER_TEMP_DIR/experiment/test_CONUS_25km_GFSv15p2/2019061500/postprd
   
    Enjoy.

The ``$DOCKER_TEMP_DIR`` will be replaced with whatever directory you chose.

.. _Docker_WhereIsMyOutput:

Where is my Output?
###################

1. First, confirm the workflow has finished. See the end of the
   previous section for how to do this.

2. Make sure there are no jobs running by running the ``jobs`` command::

       jobs

   If there are still jobs running, you'll see something like this::

       [1]+  Running                 ./run_all.sh > run_all.log 2>&1

   That means the workflow is not, in fact, done.

3. Once the workflow is done, exit the shell by running ``exit``

4. Back on the host machine, look in ``$HOST_TEMP_DIR`` and you'll see
   seven directories:

   - ``experiment``
   - ``fix_am``
   - ``fix_orog``
   - ``fix_sfc_climo``
   - ``log``
   - ``model_data``
   - ``native_earth``

5. Go down a few levels into
``$HOST_TEMP_DIR/experiment/test_CONUS_25km_GFSv15p2/2019061500/`` and
you will see a great many files:

   - ``dynf001.nc`` through ``dynf048.nc`` - these are model output dynamics variables
   - ``phyf001.nc`` through ``phyf048.nc`` - these are model output physics variables
   - ``INPUT/`` - model input state
   - ``postprd/*.grib2`` - post-processed files with many diagnostics, in GRIB2 format
   - ``postprd/*.png`` - graphics generated from the GRIB2 files
   - ``for_ICS`` - initial conditions from FV3 GFS
   - ``for_LBCS`` - boundary conditions from FV3 GFS


.. _Docker_ChangingTheCode:

Changing the Code
#################

To do actual development, you want to compile manually instead of
using the ``ufs-srweather-app-Dockerfile``. There is extensive
guidance elsewhere in this documentation on how to modify and run the
model. To do this inside Docker, you need to build the model manually.

1. Pick a directory on the host machine that will contain your source code::

       export HOST_SRC_DIR="/path/to/directory/for/source/code"

2. Copy the ``config.sh`` and ``run_all.sh`` into there::

       cd "$HOST_SRC_DIR"
       cp /path/to/config.sh .
       cp /path/to/run_all.sh .

3. Change the core count in ``config.sh`` if you want to, as described earlier::

        # Twelve (12) core machines
        RUN_CMD_UTILS="mpirun -np 12"
        RUN_CMD_POST="mpirun -np 12"
        
        # Comment out the next five lines if you want the 12 core settings
        # Four (4) core machines
        LAYOUT_X="1"
        LAYOUT_Y="3"
        RUN_CMD_UTILS="mpirun -np 4"
        RUN_CMD_POST="mpirun -np 4"

4. Clone the repository in the source directory on the host::

       git clone -b release/public-v1 https://github.com/ufs-community/ufs-srweather-app.git ufs-srweather-app

5. Edit the source code until it makes you gleeful. Once it reaches
   your ideal, it's time to compile.

6. Start a shell off of the imported ``import-nceplibs-20210219``. This
   shell must run inside a login shell to get the ``module`` command, so
   you need the ``--login`` option to bash::

       docker run --mount "type=bind,source=$HOST_TEMP_DIR,target=$DOCKER_TEMP_DIR" --mount "type=bind,source=$HOST_SRC_DIR,target=/usr/local/src" -it import-nceplibs-20210219 /bin/bash --login

7. Run the commands in the last directive of ``ufs-srweather-app-Dockerfile``::

       module load cmake
       module load gcc
       module load NCEPLIBS/2.0.0
       module use /usr/local/modules
       module load esmf/8.0.0
       module load jasper/1.900.1
       module load libjpeg/9.1.0
       module load netcdf/4.7.4
       module load libpng/1.6.35
       module load jasper/1.900.1
       module list
       export CMAKE_C_COMPILER=mpicc
       export CMAKE_CXX_COMPILER=mpicxx
       export CMAKE_Fortran_COMPILER=mpif90
       export CMAKE_Platform=linux.intel
       cd /usr/local/src/ufs-srweather-app
       mkdir build
       cd build
       # This line determines how many processors you have.
       # If you want to specify a number of threads, then remove the nprocs=
       # line and specify "-j5" or your favorite number in the make line.
       nprocs=$( grep -E 'processor[[:space:]]*:' /proc/cpuinfo|wc -l )
       cmake -DCMAKE_VERBOSE_MAKEFILE:BOOL=ON -DCMAKE_INSTALL_PREFIX=
         -DCMAKE_PREFIX_PATH=/usr/local .. 2>&1 | tee log.cmake
       make "-j$nprocs" VERBOSE=1 2>&1 | tee log.make

8. If the code compiled, run the model based on the instructions as discussed in the :ref:`Docker_StartTheWorkflow` section.
