======================================
Installation using graphical installer
======================================

GUI install
-----------

You just want to run falcon with a set of selected extensions and you don't want to look at the code ? This part is for you.
In parallel, we developed a cmake-client python gui to automatically create an installation of Falcon.

.. code-block:: console

    conda env create KloostermanLab/falcon
    conda activate falcon
    fklab-build --gui false --path https://bitbucket.org/kloostermannerflab/falcon-core.git \
            --version 1.3.0  \
            --build_options DCMAKE_INSTALL_PREFIX="$HOME/opt/falcon-core"

You can read the readme file in the `fklab-cmake-gui <https://bitbucket.org/kloostermannerflab/fklab-cmake-gui>`_
repository for more information on how the gui is working.

Information specific to the build of falcon asked in the app :

- repository path: https://bitbucket.org/kloostermannerflab/falcon-core.git (the ssh path is also possible)
- (latest) version :
    + 1.3.0 => latest stable version
    + develop

A grid with available extensions will be display. You can add your own extensions if needed but note that falcon-core does
not contains any extensions.
If you want to use the core extensions, you need to have the "falcon-fklab-extension" selected.
The extensions are stored in this `repository <https://bitbucket.org/kloostermannerflab/falcon-fklab-extensions>`_.

This step is optional and will allow falcon to more finely control CPU core utilization.

.. code-block:: console

    sudo setcap 'cap_sys_nice=pe' `which falcon`

Once, the app has been installed (without errors) you can continue to the section :ref:`usage`.

Python install
--------------

You can also used the fklab-build tool to build the app in fast mode without using the gui.

.. code-block::

    fklab-build --gui false --build_options DCMAKE_INSTALL_PREFIX="$HOME/opt/falcon-core"

Cmake options are available to `configure <https://cmake.org/cmake/help/latest/manual/cmake.1.html>`_ the build.
It can be added with the argument ``--build_options OPTIONS`` (without - before D)

Troubleshoots
-------------

All dependencies should be automatically installed but in case an error occurs with cmake or with the zmq library,
you can install them yourself before clean the build in the app and launched again the installation

- **CMAKE**

The build system is based on CMake (minimum version 3.11).
Last version of CMake are available through pip.

.. code-block:: console

    pip install cmake

- **zeromq**

.. code-block:: console

    sudo apt-get install libzmq3-dev
