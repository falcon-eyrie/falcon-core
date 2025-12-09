add_library( logging log.hpp customsink.cpp)
target_link_libraries(logging g3log)