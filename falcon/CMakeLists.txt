cmake_minimum_required(VERSION 2.8)
ENABLE_LANGUAGE(CXX)

MACRO(SUBDIRLIST result curdir)
    FILE(GLOB children RELATIVE ${curdir} ${curdir}/*)
    SET(dirlist "")
    FOREACH (child ${children})
        IF (IS_DIRECTORY ${curdir}/${child})
            LIST(APPEND dirlist ${child})
        ENDIF ()
    ENDFOREACH ()
    SET(${result} ${dirlist})
ENDMACRO()

project(falcon)

set(PLATFORM_LINK_LIBRARIES rt dl)

MESSAGE("${CMAKE_BUILD_TYPE}")

add_definitions(-DG2_DYNAMIC_LOGGING)
# Create a resource path
Set(BUILD_RESOURCES_PATH ${rootproject_BINARY_DIR})
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    Set(RESOURCES_PATH ${rootproject_BINARY_DIR} CACHE STRING "")
else()
    Set(RESOURCES_PATH ${CMAKE_INSTALL_PREFIX}/share CACHE STRING "")
endif()
mark_as_advanced(RESOURCES_PATH)

configure_file(configuration.hpp.in configuration.hpp)


# list of source files

include_directories("../resources")
include_directories("../lib")
include_directories(".")
include_directories(${CMAKE_CURRENT_BINARY_DIR})

add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/datatype_generated.h
    DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/datatype.fbs
    COMMAND flatc --cpp ${CMAKE_CURRENT_SOURCE_DIR}/datatype.fbs
)

add_custom_target(datatypebuffer DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/datatype_generated.h)

set(_processor_doc_path ${CMAKE_CURRENT_BINARY_DIR}/processors/)
configure_file(buildconstant.hpp.in buildconstant.hpp @ONLY)
file(GLOB sources *.cpp)

add_executable(falcon "main.cpp")

import_extensions() 
import_tools()

# here we have to use --whole-archive linker option, otherwise the data type and processor libs are not
# linked at all because none of their exported symbols are explicitly used in falcon. Same is true for (part of)
# the disruptor and utilities libraries

SET(WHOLELIBS -Wl,--whole-archive logging units-static utilities options disruptor context ${DATATYPE_LIBS} ${PROCESSOR_LIBS} -Wl,--no-whole-archive)

list(REMOVE_ITEM sources "${falcon_SOURCE_DIR}/main.cpp")
add_library(falconlib OBJECT ${sources})

target_compile_definitions(falconlib PUBLIC TESTING=0)
target_link_libraries(falconlib yaml-cpp flatbuffers zmq rt dl ${WHOLELIBS})
target_link_libraries(falcon falconlib)
install(TARGETS falcon CONFIGURATIONS Release RUNTIME DESTINATION bin)

import_resources()

