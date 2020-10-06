add_library(utilities keyboard.cpp general.cpp zmqutil.cpp time.cpp
        string.cpp math_numeric.cpp configuration.cpp filesystem.cpp serialization.cpp)

target_link_libraries(utilities zmq)
# modified from https://stackoverflow.com/a/55783677
if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
    if (CMAKE_CXX_COMPILER_VERSION VERSION_LESS 7.4)
        message(FATAL_ERROR "You are on an extremely old version of GCC. Please update your compiler to at least GCC 5.4, preferably latest")
    elseif (CMAKE_CXX_COMPILER_VERSION VERSION_LESS 9.0)
        message(WARNING "Older version of GCC detected. Using Legacy C++ support for std::filesystem")
        target_link_libraries(utilities stdc++fs)
    endif ()
endif ()
