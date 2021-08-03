cmake_minimum_required(VERSION 2.8)
enable_language(CXX)

project(test)
add_definitions(-DG2_DYNAMIC_LOGGING)


include_directories("../lib")
include_directories("../falcon")
include_directories(".")

include_directories(${CMAKE_BINARY_DIR}/falcon)
include_directories(${CMAKE_CURRENT_BINARY_DIR})
cmake_policy(SET CMP0079 NEW)

add_library(gmain t_main.cpp)
target_link_libraries(gmain gtest gmock)

if(TESTING)

   import_extensions() 
   
   add_library(falconlib OBJECT "../falcon/sharedstate.cpp" "../falcon/graphexceptions.hpp" "../falcon/streaminfo.cpp"
		"../falcon/serializer.cpp" "../falcon/iprocessor.hpp" "../falcon/idata.hpp")

   add_subdirectory(testing)
   SET(WHOLELIBS -Wl,--whole-archive logging units-static utilities options disruptor ${DATATYPE_LIBS} ${PROCESSOR_LIBS} -Wl,--no-whole-archive)
   SET(TESTLIBS -Wl,--whole-archive fakeclass  -Wl,--no-whole-archive)
   target_link_libraries(falconlib yaml-cpp zmq rt dl ${WHOLELIBS} ${TESTLIBS})
   foreach( proc_test ${PROCESSOR_TEST})
	MESSAGE("Add test: ${proc_test}")
	target_link_libraries(${proc_test} gmain falconlib)
	add_test(NAME ${proc_test}  COMMAND proc_test)
   endforeach()
else()

   MESSAGE("Add test: Core_test")
   add_executable(core_test graph_parser_test.cpp )
   target_link_libraries(core_test gmain falconlib)
   add_test(NAME core_test COMMAND core_test)
endif()

