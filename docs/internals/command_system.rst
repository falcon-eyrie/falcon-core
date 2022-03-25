Command system
==============

There are three command sources types:

- command line : send command from the internal falcon processing
- keyboard : send command via `keyboard shortcut <../manual/usage.html>`_
- cloud : send `command <../ui/interaction.html>`_ via zmq network

The namespace "commands" is used to contain the command system logic. Each sources derived from CommandSource and
are added in the CommandHandler during the setup part of the main.

-----

.. doxygenclass:: commands::CommandSource
   :protected-members:
   :undoc-members:
   :members:

-----

Commands are requested (serially) from sources and handled by CommandHandler class in main thread.
Graph commands are forwarded to GraphManager and handled in graph thread.
Replies are sent to the original requester of the command.

-----

.. doxygenclass:: commands::CommandHandler
   :protected-members:
   :undoc-members:
   :members:

-----
