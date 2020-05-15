# This is the main cmake file for ufs-srweather-app.
#
# Ed Hartnett 5/14/20

# This will use any cmake between 3.1 and 3.15, prefering later
# versions with updated policies.
cmake_minimum_required(VERSION 3.1...3.15)
if (${CMAKE_VERSION} VERSION_LESS 3.12)
  cmake_policy(VERSION ${CMAKE_MAJOR_VERSION}.${CMAKE_MINOR_VERSION})
endif()

# Set the project name and version.
project(ufs-srweather-app VERSION 1.0)

# Set extended version info.
SET(SRWA_VERSION_MAJOR 1)
SET(SRWA_VERSION_MINOR 0)
SET(SRWA_VERSION_PATCH 0)
SET(SRWA_VERSION_NOTE "-development")
SET(SRWA_VERSION ${SRWA_VERSION_MAJOR}.${SRWA_VERSION_MINOR}.${SRWA_VERSION_PATCH}${SRWA_VERSION_NOTE})

#Add custom CMake Module
SET(CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake/"
  CACHE INTERNAL "Location of our custom CMake modules.")

# A function used to create autotools-style 'yes/no' definitions.
# If a variable is set, it 'yes' is returned. Otherwise, 'no' is
# returned.
#
# Also creates a version of the ret_val prepended with 'NC',
# when feature is true, which is used to generate ufs_srweather_app_meta.h.
FUNCTION(is_disabled feature ret_val)
  IF(${feature})
    SET(${ret_val} "no" PARENT_SCOPE)
  ELSE()
    SET(${ret_val} "yes" PARENT_SCOPE)
    SET("SRWA_${ret_val}" 1 PARENT_SCOPE)
  ENDIF(${feature})
ENDFUNCTION()

# A function used to create autotools-style 'yes/no' definitions.
# If a variable is set, it 'yes' is returned. Otherwise, 'no' is
# returned.
#
# Also creates a version of the ret_val prepended with 'NC',
# when feature is true, which is used to generate ufs_srweather_app_meta.h.
FUNCTION(is_enabled feature ret_val)
  IF(${feature})
    SET(${ret_val} "yes" PARENT_SCOPE)
    SET("SRWA_${ret_val}" 1 PARENT_SCOPE)
  ELSE()
    SET(${ret_val} "no" PARENT_SCOPE)
    SET("SRWA_${ret_val}" 0 PARENT_SCOPE)
  ENDIF(${feature})
ENDFUNCTION()

# Turn on testing.
enable_testing()
include(CTest)

# Build in this subdirectory.
#add_subdirectory(src)

#####
# Configure and print the ufs-srweather-app.settings file.
#####

# Set variables.
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

# Determine output yes/no values.
is_disabled(BUILD_SHARED_LIBS enable_static)
is_enabled(BUILD_SHARED_LIBS enable_shared)
is_enabled(STATUS_PARALLEL HAS_PARALLEL)

# Generate file from template.
CONFIGURE_FILE("${CMAKE_CURRENT_SOURCE_DIR}/ufs_srweather_app.settings.in"
  "${CMAKE_CURRENT_BINARY_DIR}/ufs_srweather_app.settings"
  @ONLY)

# Read in settings file, print out.
# Avoid using system-specific calls so that this
# might also work on Windows.
FILE(READ "${CMAKE_CURRENT_BINARY_DIR}/ufs_srweather_app.settings"
  UFS-SRWEATHER-APP_SETTINGS)
MESSAGE(${UFS-SRWEATHER-APP_SETTINGS})

# Install ufs_srweather_app.settings file into same location
# as the app.
INSTALL(FILES "${CMAKE_BINARY_DIR}/ufs_srweather_app.settings"
  DESTINATION bin)

#####
# Create 'ufs_srweather_app_meta.h' include file.
#####
configure_file(
  ufs_srweather_app_meta.h.in
  ufs_srweather_app_meta.h @ONLY)

FILE(COPY "${CMAKE_CURRENT_BINARY_DIR}/ufs_srweather_app_meta.h" DESTINATION include)

