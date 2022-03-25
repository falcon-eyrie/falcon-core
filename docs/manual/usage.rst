.. _usage:

Launch Falcon from command line
===============================

Command-line
------------

.. code-block:: bash

   falcon graph.yaml

.. code-block:: bash

    usage: falcon [options] ... [graph file] ...
    options:
    -c, --config         configuration file (string [=$HOME/.falcon/config.yaml])
    -a, --autostart      auto start processing (needs graph)
    -d, --debug          show debug messages
        --noscreenlog    disable logging to screen
        --nocloudlog     disable logging to cloud
    -t, --test           turn testing on by default
    -v, --version        Show the falcon version number and exit.
    -?, --help           print this message

A configuration file can be used to specify automatically this options + others used to affine the control in the whole system.
Check out the :ref:`manual-configuration`.

.. note:: The option specified in command line are prioritized against the options specified in the config file.

Control commands with a Falcon running graph
--------------------------------------------

Keyboard commands
.................

=== ========================================
key action
=== ========================================
q   quit
i   info
r   start processing graph (run)
t   start processing in test mode
s   stop processing graph
k   stop processing and quit (kill)
y   display the current graph in yaml format
d   request documentation
=== ========================================

Falcon-client gui
.................

The graph is also controllable from a (remote) client. See this section for more details : :ref:`generic_client`
Commands are send from the client via zmq communication. See :ref:`zmq_command`

