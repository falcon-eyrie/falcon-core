Configuration system
====================

Configuration base class is defined in the utilities library.

-----

.. doxygenclass:: Configuration
   :undoc-members:
   :members:

-----

The FalconConfiguration class is derived from it and specify every available options in the config yaml loaded.
To add a new options, edit the falcon/configuration.cpp and the falcon/configuration.hpp.in files. A rebuild from clean
version is needed after that because the falcon/configuration.hpp is generated at build time.


The path of the config yaml is define by default in the main.cpp (as `$HOME/.config/falcon/config.yaml`) but can be changed
with the option `falcon -c new/path/config.yaml`.


