cmake_minimum_required(VERSION 2.8)
enable_language(CXX)

project(test)

include_directories("../lib")
include_directories("../falcon")
include_directories(".")
include_directories(${CMAKE_BINARY_DIR}/falcon)
cmake_policy(SET CMP0079 NEW)

add_library(gmain t_main.cpp)
target_link_libraries(gmain gtest gmock)

MESSAGE("Add test: Core_test")
add_executable(core_test graph_parser_test.cpp )
target_link_libraries(core_test gmain falconlib)
        
add_test(NAME core_test COMMAND core_test)

