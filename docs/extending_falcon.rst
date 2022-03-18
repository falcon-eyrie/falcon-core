.. _overview_extensions:

****************
Extending Falcon
****************

An extension cannot be build by itself. You will need to rebuild falcon-core while adding your extension local path
in the extensions.txt in dev mode. It will automatically build falcon-core as well as your extension.

.. code-block::

    enable , extension name , extension path , extension version (optional)
    dev , your_extension_name , local/path/your/repository


.. toctree::
   :maxdepth: 1
   :glob:

   extensions/extend_processor
   extensions/extend_datatype
   extensions/tools


**Recap: How to package an extension**

Example of an extension structure :

.. code-block::

    extension_repository :
        - processors
            - processor_name
                - doc.yaml
                - processor_name.cpp
                - processor_name.hpp
                - CMakeList.txt
        - datatypes
            (similar structure to processors)
        - lib
            - Lib1
                - code
                - CMakeList.txt
            - Lib2
            - CMakeList.txt
        - resources
            - graphs
            - filters
            - others folder (can be reach in falcon via its own uri or with resources://folder_name)
        - tools

Minimal CMakeList.txt in each extension (lib, processor, datatype) :

.. code-block::

    add_library( name "name.cpp" )
    TARGET_LINK_LIBRARIES( name lib_name )

.. note::

    lib_name could be a lib added in the extension but also already present in the falcon-core or others extensions
    also present in extensions.txt

Once this is pushed online in a repository, you can remove the dev mode from your build system and install the extension
in falcon-core from a specific version (git tag, branch ... ) in the same way as the others extensions.


.. code-block::

    enable , extension name , extension path , extension version (optional)
    1 , your_extension_name , https://online/repo/path, version
