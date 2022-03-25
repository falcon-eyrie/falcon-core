*****************
Developer's guide
*****************

Code organization and style guide
=================================

Falcon core is containing the core code to create and run the graph, as well as the logging system.
The falcon folder is containing core code to create and run the graph.

The lib folder is serving as an interface between external processors and falcon:

- cmdline - imported external lib
- disruptor - imported external lib
- factory
- logging
- options
- utilities

All processors, datatype and lib specific to one set of processors needs to be packaged in a separate extension repository.

Style guide
===========

When developing Falcon, thanks to enforce the cpplint coding style.


System overview
===============


.. toctree::
   :maxdepth: 3
   :glob:

   internals/command_system
   internals/config_system
   internals/logging_system
   internals/graph_system
   internals/utilities
