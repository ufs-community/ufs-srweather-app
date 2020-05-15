# This is the main cmake file for ufs-srweather-app.
#
# Ed Hartnett 5/14/20

# This will use any cmake between 3.1 and 3.15, prefering later
# versions with updated policies.
cmake_minimum_required(VERSION 3.1...3.15)
if (${CMAKE_VERSION} VERSION_LESS 3.12)
  cmake_policy(VERSION ${CMAKE_MAJOR_VERSION}.${CMAKE_MINOR_VERSION})
endif()

# set the project name
project(ufs-srweather-app VERSION 1.0)

#Add custom CMake Module
SET(CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake/"
  CACHE INTERNAL "Location of our custom CMake modules.")

# A function used to create autotools-style 'yes/no' definitions.
# If a variable is set, it 'yes' is returned. Otherwise, 'no' is
# returned.
#
# Also creates a version of the ret_val prepended with 'NC',
# when feature is true, which is used to generate netcdf_meta.h.
FUNCTION(is_disabled feature ret_val)
  IF(${feature})
    SET(${ret_val} "no" PARENT_SCOPE)
  ELSE()
    SET(${ret_val} "yes" PARENT_SCOPE)
    SET("NC_${ret_val}" 1 PARENT_SCOPE)
  ENDIF(${feature})
ENDFUNCTION()

# A function used to create autotools-style 'yes/no' definitions.
# If a variable is set, it 'yes' is returned. Otherwise, 'no' is
# returned.
#
# Also creates a version of the ret_val prepended with 'NC',
# when feature is true, which is used to generate netcdf_meta.h.
FUNCTION(is_enabled feature ret_val)
  IF(${feature})
    SET(${ret_val} "yes" PARENT_SCOPE)
    SET("NC_${ret_val}" 1 PARENT_SCOPE)
  ELSE()
    SET(${ret_val} "no" PARENT_SCOPE)
    SET("NC_${ret_val}" 0 PARENT_SCOPE)
  ENDIF(${feature})
ENDFUNCTION()

# Find netCDF.
#include(FindNetCDF)
#find_package (NetCDF REQUIRED)

#include_directories("${NETCDF_INCLUDES}")

# Create a config.h.
#configure_file(config.h.cmake.in config.h)

# Turn on testing.
enable_testing()
include(CTest)

# Build in this subdirectory.
#add_subdirectory(src)

#####
# Configure and print the ufs-srweather-app.settings file.
#####

# Set variables to mirror those used by autoconf.
# This way we don't need to maintain two separate template
# files.
SET(host_cpu "${cpu}")
SET(host_vendor "${osname}")
SET(host_os "${osrel}")
SET(abs_top_builddir "${CMAKE_CURRENT_BINARY_DIR}")
SET(abs_top_srcdir "${CMAKE_CURRENT_SOURCE_DIR}")

SET(CC_VERSION "${CMAKE_C_COMPILER}")

# Build *FLAGS for ufs-srweather-app.settings.
SET(CFLAGS "${CMAKE_C_FLAGS} ${CMAKE_C_FLAGS_${CMAKE_BUILD_TYPE}}")
SET(CPPFLAGS "${CMAKE_CPP_FLAGS} ${CMAKE_CPP_FLAGS_${CMAKE_BUILD_TYPE}}")
SET(LDFLAGS "${CMAKE_SHARED_LINKER_FLAGS} ${CMAKE_SHARED_LINKER_FLAGS_${CMAKE_BUILD_TYPE}}")

is_disabled(BUILD_SHARED_LIBS enable_static)
is_enabled(BUILD_SHARED_LIBS enable_shared)

is_enabled(ENABLE_V2_API HAS_NC2)
is_enabled(ENABLE_NETCDF_4 HAS_NC4)
is_enabled(ENABLE_HDF4 HAS_HDF4)
is_enabled(ENABLE_NETCDF_4 HAS_HDF5)
is_enabled(USE_SZIP HAS_SZLIB)
is_enabled(USE_SZIP HAS_SZLIB_WRITE)
is_enabled(STATUS_PNETCDF HAS_PNETCDF)
is_enabled(STATUS_PARALLEL HAS_PARALLEL)
is_enabled(ENABLE_PARALLEL4 HAS_PARALLEL4)
is_enabled(ENABLE_DAP HAS_DAP)
is_enabled(ENABLE_DAP HAS_DAP2)
is_enabled(ENABLE_DAP4 HAS_DAP4)
is_enabled(ENABLE_BYTERANGE HAS_BYTERANGE)
is_enabled(ENABLE_DISKLESS HAS_DISKLESS)
is_enabled(USE_MMAP HAS_MMAP)
is_enabled(JNA HAS_JNA)
is_enabled(ENABLE_ZERO_LENGTH_COORD_BOUND RELAX_COORD_BOUND)
is_enabled(USE_CDF5 HAS_CDF5)
is_enabled(ENABLE_ERANGE_FILL HAS_ERANGE_FILL)
is_enabled(HAVE_H5Z_SZIP HAS_SZLIB)
is_enabled(HDF5_HAS_PAR_FILTERS HAS_PAR_FILTERS)

# Generate file from template.
CONFIGURE_FILE("${CMAKE_CURRENT_SOURCE_DIR}/ufs-srweather-app.settings.in"
  "${CMAKE_CURRENT_BINARY_DIR}/ufs-srweather-app.settings"
  @ONLY)

# Read in settings file, print out.
# Avoid using system-specific calls so that this
# might also work on Windows.
FILE(READ "${CMAKE_CURRENT_BINARY_DIR}/ufs-srweather-app.settings"
  UFS-SRWEATHER-APP_SETTINGS)
MESSAGE(${UFS-SRWEATHER-APP_SETTINGS})

# Install ufs-srweather-app.settings file into same location
# as the libraries.
INSTALL(FILES "${netCDF_BINARY_DIR}/ufs-srweather-app.settings"
  DESTINATION include
  COMPONENT libraries)

#####
# End ufs-srweather-app.settings section.
#####
