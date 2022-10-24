
==============================
Installation from docker image
==============================


A docker image to run falcon has been created. It enables the use of falcon on windows.

You need docker installed on your computer and for windows a linux for windows kernel running in background is advised
to handle correctly the multithread.

- https://docs.docker.com/desktop/install/windows-install/
- https://learn.microsoft.com/fr-fr/windows/wsl/

.. code-block:: console

    docker pull marinechaput/falcon:develop # for develop version with open ephys reader (for neuropixels)
    docker run -v /local/path:/root/log  -p 3335:3335 -p 5993:5993 -p 5555:5555 -p 5556:5556 -p 7777:7777  marinechaput/falcon:develop


The last command can be used as any falcon command with the usual option to add directly a graph or to connect a falcon client
directly on it.




