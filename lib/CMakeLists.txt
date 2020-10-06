add_subdirectory( utilities )
add_subdirectory( options )
add_subdirectory( logging )
add_subdirectory( context )
# disruptor library
add_library( disruptor disruptor/claim_strategy.cpp disruptor/wait_strategy.cpp disruptor/sequence.cpp)


