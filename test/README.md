# Build test for the UFS Short-Range Weather App

## Description

This script builds the executables for the UFS Short-Range Weather Application (SRW App)
for the current code in the users ufs-srweather-app directory.  It consists of the following steps:

* Build all of the executables for the supported compilers on the given machine

* Check for the existence of all executables

* Print out a PASS/FAIL message

Currently, the following configurations are supported:

Machine     | Cheyenne    | Hera   | Jet    | Orion  | wcoss_cray  | wcoss_dell_p3  |
------------| ------------|--------|--------|--------|-------------|----------------|
Compiler(s) | Intel, GNU  | Intel  | Intel  | Intel  | Intel       | Intel          |

The CMake build is done in the ``build_${compiler}`` directory.
The executables for each build are installed under the ``bin_${compiler}`` directory.

NOTE:  To run the regional workflow using these executables, the ``EXECDIR`` variable in the
``${SR_WX_APP_TOP_DIR}/regional_workflow/ush/setup.sh`` file must be set to the
appropiate directory, for example:  ``EXECDIR="${SR_WX_APP_TOP_DIR}/bin_intel/bin"``,
where ``${SR_WX_APP_TOP_DIR}`` is the top-level directory of the cloned ufs-srweather-app repository.

## Usage

To run the tests, specify the machine name on the command line, for example:

On cheyenne:

```
cd test
./build.sh cheyenne >& build.out &
```

Check the ``${SR_WX_APP_TOP_DIR}/test/build_test$PID.out`` file for PASS/FAIL.
