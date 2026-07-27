cmake_minimum_required(VERSION 3.16)


# Export compile commands for VS Code IntelliSense
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_CXX_STANDARD 26)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)


# Prevents re-downloading dependencies every time the build folder is deleted
set(FETCHCONTENT_BASE_DIR "${CMAKE_HOME_DIRECTORY}/.cache" CACHE PATH "")


if(CMAKE_BUILD_TYPE STREQUAL "Debug")
	message(STATUS "Debug build")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O0 -g -Wall -Wextra -Wunused -pthread")
elseif(CMAKE_BUILD_TYPE STREQUAL "Profile")
	message(STATUS "Profile build")
   	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O3 -g -fno-omit-frame-pointer -Wall -Wextra -Wunused -pthread")
else()
	message(STATUS "Release build")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O3 -Wall -Wextra -Wunused -pthread")
endif()

set(CMAKE_SHARED_LIBRARY_LINK_CXX_FLAGS "")

project (rootproject)

ENABLE_LANGUAGE(CXX)

set(_build_version "unknown")
find_package(Git)
if(GIT_FOUND)
    execute_process(COMMAND ${GIT_EXECUTABLE} describe --tags
                    WORKING_DIRECTORY "${local_dir}"
                    OUTPUT_VARIABLE _build_version
                    ERROR_QUIET
                    OUTPUT_STRIP_TRAILING_WHITESPACE
                    )
endif()
string(TIMESTAMP _time_stamp)


cmake_policy(SET CMP0135 NEW)
include(FetchContent)

FetchContent_Declare(
    flatbuffers
    URL "https://github.com/google/flatbuffers/archive/refs/tags/v25.12.19-2026-02-06-03fffb2.zip"
)

FetchContent_Declare(
		yaml-cpp
		URL "https://github.com/jbeder/yaml-cpp/archive/refs/tags/yaml-cpp-0.9.0.zip"
)

FetchContent_Declare(
		cppzmq
		URL "https://github.com/zeromq/cppzmq/archive/refs/tags/v4.11.0.zip"
)

FetchContent_Declare(
	g3log
	URL "https://github.com/KjellKod/g3log/archive/refs/tags/2.6.zip"
)

FetchContent_Declare(
	units
	GIT_REPOSITORY https://github.com/LLNL/units.git
	GIT_SHALLOW OFF
	# The fix is not released yet, therefore we need to fetch a specific commit
	# rather than downloading the source code as zip file
	GIT_TAG c5610c81fb9285abef1217145365ac6532b6f0cc
)

if(CMAKE_BUILD_TYPE STREQUAL "Debug")
        set(CMAKE_INSTALL_PREFIX ${CMAKE_CURRENT_BINARY_DIR})
endif()

set(FLATBUFFERS_BUILD_FLATC ON CACHE INTERNAL "Enable the build of the flatbuffers compiler")
set(FLATBUFFERS_BUILD_TESTS OFF CACHE INTERNAL "Enable tests from flatbuffers lib.")
set(FLATBUFFERS_BUILD_FLATHASH OFF CACHE INTERNAL "Enable the build of flathash")
set(FLATBUFFERS_ENABLE_PCH OFF CACHE INTERNAL
       "Enable precompile headers support for 'flatbuffers' and 'flatc'. \"
        Only work if CMake support 'target_precompile_headers'. \"
        Only work if CMake supports 'target_precompile_headers'. \"
        This can speed up compilation time."
       )

FetchContent_MakeAvailable(flatbuffers)

include_directories(BEFORE SYSTEM "${flatbuffers_SOURCE_DIR}/include")


set(YAML_CPP_BUILD_TESTS OFF CACHE BOOL "disable yaml tests")
message(STATUS "Populating yaml-cpp...")
FetchContent_MakeAvailable(yaml-cpp)
message(STATUS "Done.")


include_directories(BEFORE SYSTEM "${yaml-cpp_SOURCE_DIR}/include")
target_link_libraries(${YAMLCPP} yaml-cpp)

FetchContent_GetProperties(cppzmq)
if(NOT cppzmq_POPULATED)
	message(STATUS "Populating zmq-cpp...")
	FetchContent_MakeAvailable(cppzmq)
	# Add here options for cppzmq building
	set(CPPZMQ_BUILD_TESTS OFF CACHE BOOL "Whether or not to build the tests")
	message(STATUS "Done.")
endif()

include_directories(BEFORE SYSTEM "${cppzmq_SOURCE_DIR}")
target_link_libraries(${ZMQ} cppzmq)

FetchContent_GetProperties(units)
if(NOT units_POPULATED)
	message(STATUS "Populating LLNL units...")
	FetchContent_MakeAvailable(units)
	set(USE_LIBCXX OFF CACHE INTERNAL "")
	set(UNITS_HEADER_ONLY OFF CACHE INTERNAL "")
	set(UNITS_ENABLE_TESTS OFF CACHE BOOL "Whether or not to build the tests")
	set(UNITS_INSTALL OFF CACHE INTERNAL "")
	set(UNITS_BUILD_OBJECT_LIBRARY OFF CACHE INTERNAL "")
	set(UNITS_BUILD_STATIC_LIBRARY ON CACHE INTERNAL "")
	set(UNITS_BUILD_SHARED_LIBRARY OFF CACHE INTERNAL "")
	set(UNITS_BUILD_WEBSERVER OFF CACHE INTERNAL "")
	message(STATUS "Done.")
endif()

include_directories(BEFORE SYSTEM "${units_SOURCE_DIR}")
# Temporarily disabled
# target_link_libraries(${UNITS} units::units)

message(STATUS "Populating g3log...")
set(ADD_G3LOG_UNIT_TEST OFF CACHE INTERNAL "")
set(ADD_FATAL_EXAMPLE OFF CACHE INTERNAL "")
set(ADD_G3LOG_BENCH_PERFORMANCE OFF CACHE INTERNAL "")
set(USE_DYNAMIC_LOGGING_LEVELS ON CACHE INTERNAL "")
set(INSTALL_G3LOG OFF CACHE INTERNAL "")
set(G3_SHARED_LIB OFF CACHE INTERNAL "")
FetchContent_MakeAvailable(g3log)
message(STATUS "Done.")
FetchContent_GetProperties(g3log)


include_directories(BEFORE SYSTEM "${g3log_SOURCE_DIR}/src")
include_directories(BEFORE SYSTEM "${g3log_BINARY_DIR}/include")
target_link_libraries(${LOGGER} g3log)


## External extensions ##

SET(EXTENSION_PATHS "")
SET(INSTALLED_EXTENSIONS "")

message(STATUS "Checking for extensions.")

include(scripts/cmake/ParseExtensions.cmake)

## External extensions ##
add_subdirectory(lib)
add_subdirectory(falcon)
