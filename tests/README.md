# Build test for the UFS Short-Range Weather App

## Description

This script builds the executables for the UFS Short-Range Weather Application (SRW App)
for the current code in the users ufs-srweather-app directory.  It consists of the following steps:

* Build all of the executables for the supported compilers on the given machine

* Check for the existence of all executables

* Print out a PASS/FAIL message

Currently, the following configurations are supported:

Machine     | Cheyenne    | Hera   | Jet    | Orion  | wcoss2  |
------------| ------------|--------|--------|--------|---------|
Compiler(s) | Intel, GNU  | Intel  | Intel  | Intel  | Intel   |

The CMake build is done in the ``build_${compiler}`` directory.
The executables for each build are installed under the ``bin_${compiler}`` directory.

NOTE:  To run the regional workflow using these executables, the ``EXECDIR`` variable in the
``${HOMEdir}/ush/setup.py`` file must be set to the
appropiate directory, for example:  ``EXECDIR="${HOMEdir}/bin_intel/bin"``,
where ``${HOMEdir}`` is the top-level directory of the cloned ufs-srweather-app repository.

## Usage

To run the tests, specify the machine name on the command line, for example:

On cheyenne:

```
cd test
./build.sh cheyenne >& build.out &
```

Check the ``${HOMEdir}/test/build_test$PID.out`` file for PASS/FAIL.
