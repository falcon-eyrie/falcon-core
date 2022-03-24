
========================
Installation from source
========================

The building of the falcon app is based on cmake and fetch_dependency to manage libraries and extensions. The plugin
can be specified by modifying the extensions.txt file at the root of falcon_core.

Download
--------

Download the latest source from https://bitbucket.org/kloostermannerflab/falcon-core/downloads/?tab=downloads.

Dependencies
------------

- **CMAKE**

The build system is based on CMake (minimum version 3.11).
Last version of CMake are available through pip.

.. code-block:: console

    pip install cmake

- **zeromq**

.. code-block:: console

    sudo apt-get install libzmq3-dev

- **g++-5 (or upper)**

G++ v.5 or upper is needed in order to have all libraries of the C++11 standard.
In order to install it type in a terminal:

.. code-block:: console

    sudo apt-get install g++


- **External libraries included in source tree** (just for information, you don't need to do anything normally)

    + cmdline (header only library)
    + disruptor
    + yaml-cpp : https://github.com/jbeder/yaml-cpp.git
    + cppzmq : https://github.com/zeromq/cppzmq.git
    + g3log : https://github.com/KjellKod/g3log.git
    + unit : https://github.com/LLNL/units.git

Build instructions
------------------

Compiling falcon has only been tested with GNU g++ compiler. You should use version 5 or upper.
The falcon-core repository does not contains any extensions. You will have to add, at least, the core extension to the extensions.txt.

*How extensions are found and added to build ?*

Extensions are added through the FetchContent feature of CMake. It allows to link in the Falcon CMake
the different git repository (or local folder) containing the extension. This extension needs to contain at least CMake.
This solution allows to use a specific version of an extension by adding a tag version in the option.

The CmakeList.txt will read the extensions.txt file described below :

.. code-block::

    enable , extension name , extension path , extension version (optional)
    1 , extensions , https://bitbucket.org/kloostermannerflab/falcon-fklab-extensions, 1.3.0

(latest) version for the falcon-fklab-extensions (followed the falcon-core release tag) :

- 1.3.0 => latest stable version
- develop

Enable can be 3 different values : 0 (not build)/ 1 (build)/ dev (develop mode)

The build mode will import the repository in the commit state (when not specified, the commit is the last one on the master head).
The dev mode will build the repository in its actual local state.

Command line build
..................

#. Select first the falcon-core version
.. code-block:: console

    git checkout 1.3.0 # latest stable version merged on the master branch
    git checkout develop # Contains the processors extensions to work with neuropixels data
    git checkout develop # Contains latest development of falcon-core

#. Verify your extensions file.
   It should contains at least the falcon-fklab-extensions with the matching version chosen in falcon-core
   For more information on how to integrate third party extension to the build, refer to the build system documentation.

#. Choose your build type :
    - Debug build
        .. code-block:: console

            mkdir build
            cd build
            cmake .. -DCMAKE_BUILD_TYPE=Debug  # set the resource folder in the build folder + activate debug mode
            make

            cd falcon
            sudo setcap 'cap_sys_nice=pe' ./falcon

        Check that you can run falcon correctly

        .. code-block:: console

            ./falcon --help  # Show the help mode
            ./falcon         # Display all processors available in this build and wait to send a graph from cloud command
            ./falcon [graph_file] # Build the graph and wait a command to run


    - Installation build
        .. code-block:: console

            mkdir build
            cd build
            cmake .. -DCMAKE_INSTALL_PREFIX="$HOME/opt/falcon-core"  # set the install and the resource folder in the path of your choice
            make install

            # Add the installation path in your $PATH if not already the case
            sudo setcap 'cap_sys_nice=pe' falcon # The last step is optional and will allow falcon to more finely control CPU core utilization.

        Check that you can run falcon correctly

        .. code-block:: console

            falcon --help  # Show the help mode
            falcon         # Display all processors available in this build and wait to send a graph from cloud command
            falcon [graph_file] # Build the graph and wait a command to run

