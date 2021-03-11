cmake_minimum_required (VERSION 3.11)
ENABLE_LANGUAGE(CXX)

if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O0 -g -Wall -Wunused -std=c++17 -pthread -D_GLIBCXX_USE_NANOSLEEP")
else()
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O3 -Wall -Wunused -std=c++17 -pthread -D_GLIBCXX_USE_NANOSLEEP")
endif()

set(CMAKE_SHARED_LIBRARY_LINK_CXX_FLAGS "")

project (rootproject)

message(STATUS ${CMAKE_INSTALL_PREFIX}) 

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

############################
# Add the basic libraries
# to read on the use of fetch content :
# https://android.googlesource.com/platform/external/cmake/+/refs/heads/upstream-release/Modules/FetchContent.cmake
############################

include(FetchContent)

FetchContent_Declare(
    flatbuffers
    GIT_REPOSITORY "https://github.com/google/flatbuffers"
    GIT_TAG        v2.0.0
)

FetchContent_Declare(
		yaml-cpp
		GIT_REPOSITORY https://github.com/jbeder/yaml-cpp.git
		GIT_SHALLOW	ON
		GIT_TAG yaml-cpp-0.6.3
	)

FetchContent_Declare(
		cppzmq
		GIT_REPOSITORY https://github.com/zeromq/cppzmq.git
		GIT_SHALLOW	ON
		GIT_TAG v4.7.1
	)

FetchContent_Declare(
	units
	GIT_REPOSITORY https://github.com/LLNL/units.git
	GIT_SHALLOW ON
	GIT_TAG v0.4.0
)

FetchContent_Declare(
	g3log
	GIT_REPOSITORY https://github.com/KjellKod/g3log.git
	GIT_SHALLOW ON
	GIT_TAG 1.3.3
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
	FetchContent_Populate(cppzmq)
	# Add here options for cppzmq building
	set(CPPZMQ_BUILD_TESTS OFF CACHE BOOL "Whether or not to build the tests")
	add_subdirectory(${cppzmq_SOURCE_DIR} ${cppzmq_BINARY_DIR})
	message(STATUS "Done.")
endif()

include_directories(BEFORE SYSTEM "${cppzmq_SOURCE_DIR}")
target_link_libraries(${ZMQ} cppzmq)

FetchContent_GetProperties(units)
if(NOT units_POPULATED)
	message(STATUS "Populating LLNL units...")
	FetchContent_Populate(units)
	# Add here options for units building
	set(CMAKE_CXX_STANDARD 17)
	set(USE_LIBCXX OFF CACHE INTERNAL "")
	set(UNITS_HEADER_ONLY OFF CACHE INTERNAL "")
	set(UNITS_ENABLE_TESTS OFF CACHE BOOL "Whether or not to build the tests")
	set(UNITS_INSTALL OFF CACHE INTERNAL "")
	set(UNITS_BUILD_OBJECT_LIBRARY OFF CACHE INTERNAL "")
	set(UNITS_BUILD_STATIC_LIBRARY ON CACHE INTERNAL "")
	set(UNITS_BUILD_SHARED_LIBRARY OFF CACHE INTERNAL "")
	set(UNITS_BUILD_WEBSERVER OFF CACHE INTERNAL "")
	add_subdirectory(${units_SOURCE_DIR} ${units_BINARY_DIR})
	message(STATUS "Done.")
endif()

include_directories(BEFORE SYSTEM "${units_SOURCE_DIR}")
target_link_libraries(${UNITS} units-static)

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
target_link_libraries(${LOGGER} g3logger)

## External extensions ## 

SET(EXTENSION_PATHS "")
SET(INSTALLED_EXTENSIONS "")

message(STATUS "Checking for extensions.")

if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/extensions.txt")
	
	message(STATUS "Found extensions.txt")

	file(STRINGS "${CMAKE_CURRENT_SOURCE_DIR}/extensions.txt" extensions)

	# remove header row
	list(REMOVE_AT extensions 0)

	list(LENGTH extensions nextensions)

	message(STATUS "Found ${nextensions} extensions.")

	foreach(ext ${extensions})
		
		# convert from comma separated string to list
		string(REPLACE " " "" ext ${ext})
		string(REPLACE "," ";" ext ${ext})
		list(LENGTH ext nitems)

		# we need at least enabled, name and path
		if (nitems LESS 3)
			continue()
		endif()

		# only add enabled extensions
		list(GET ext 0 ext_enabled)
		list(GET ext 1 ext_name)
		list(GET ext 2 ext_path)

		if(ext_enabled)
			if(ext_name IN_LIST INSTALLED_EXTENSIONS)
				message(STATUS "Skip duplicate. Extension ${ext_name} already installed")
				continue()
			endif()

			if(ext_enabled STREQUAL "dev")
				string(TOUPPER ${ext_name} ext_name_upper)
				SET(FETCHCONTENT_SOURCE_DIR_${ext_name_upper} ${ext_path})
				message(STATUS "Adding ${ext_name} in development mode.")
			endif()

			# check if optional version is given
			if (nitems GREATER_EQUAL 4)	
				list(GET ext 3 ext_version)
				FetchContent_Declare(
					${ext_name}
					GIT_REPOSITORY ${ext_path}
					GIT_SHALLOW	ON
					GIT_TAG ${ext_version}
				)
				message(STATUS "Declared ${ext_name} (version ${ext_version}) at ${ext_path}.")
			else()
				FetchContent_Declare(
					${ext_name}
					GIT_REPOSITORY ${ext_path}
					GIT_SHALLOW	ON
				)
				message(STATUS "Declared ${ext_name} at ${ext_path}.")
				set(ext_version "master-branch")
			endif()
			
			# populate
			FetchContent_GetProperties(${ext_name})
			if(NOT ${ext_name}_POPULATED)
				message(STATUS "Populating ${ext_name} ...")
				FetchContent_Populate(${ext_name})
				add_subdirectory(${${ext_name}_SOURCE_DIR} ${${ext_name}_BINARY_DIR})
				message(STATUS "Done.")
			endif()

			include_directories(BEFORE SYSTEM "${${ext_name}_SOURCE_DIR}" ${${ext_name}_BINARY_DIR}/include)

			if(ext_enabled STREQUAL "dev")
				list(APPEND _extension_names "${ext_name} - ${ext_path} - dev")
			else()
				list(APPEND _extension_names "${ext_name} - ${ext_path} - ${ext_version}")
			endif()
			
			# add to list of extensions
			list(APPEND EXTENSION_PATHS ${${ext_name}_SOURCE_DIR})

			# add to installed extensions
			list(APPEND INSTALLED_EXTENSIONS ${ext_name})
		
		else()
			message(STATUS "Extension ${ext_name} is not enabled. Skipped.")
		endif()

	endforeach()
else()
	message(STATUS "No extensions found.")
endif()


add_subdirectory(lib)
add_subdirectory(falcon)

MESSAGE("Build TEST")
include(CTest)
enable_testing()

FetchContent_Declare(
		googletest
		GIT_REPOSITORY https://github.com/google/googletest.git
		GIT_TAG        release-1.10.0
)

FetchContent_MakeAvailable(googletest)

add_subdirectory(tests)


