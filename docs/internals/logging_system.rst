Logging system
==============


Falcon's logging system is based on the
`g3log <https://github.com/KjellKod/g3log>`_ library - version 1.3.3,
which is fetch from the repository at build time.

The logging library is used to provide information about the internal
state and operation to the user (or developer). There are a number of
different types of log messages (i.e "log levels") defined, each with
their own format and usage pattern as listed below:

:DEBUG: debug info
:INFO: general info
:WARNING: general warning
:FATAL: run-time errors info from falcon and other fatal errors info before killing the software.

:STATE: log the state of the graph
:UPDATE: update info on the run-time processor parameters
:ERROR: error info specific to the falcon process

The actual implementation is in the falcon lib logging with the custom sinks and new logging levels.
To log messages in the code, one needs to include the *logging/log.hpp* header file and then do for example:

.. code-block:: cpp

    LOG(INFO) << "my informative message";

    LOG_IF(DEBUG, condition) << "If [true], then this text will be logged";

Log level for falcon can be added in the logging/g3loglevels. Other log levels specifics to an extension can be added
in the extension repository in a similar way.

In Falcon, three destinations ("sinks") for log messages are defined.

- log messages are always saved to a log file. The path of this file is set using the *logging.path* configuration option (see :ref:`manual-configuration`).
- log messages are displayed is the terminal in which Falcon was started (but only if the *logging.screen.enabled* configuration option is set to true).
- log messages are broadcast to clients using a ZMQ publisher network socket (if the *logging.cloud.enabled* configuration option is true).
  The network port is configurable (see :ref:`manual-configuration`). The format of these logs is a multipart message with 3 or 4 parts:

  + Log level (kind)
  + datetime
  + what - actual log message
  + (optional) where: often for an error, gives the location in the code where the log error occurred.

This custom sink are developed in logging/customsink.hpp.

Here is an example in Python how to receive log messages broadcast to port 5556 on the local computer:

.. code-block:: python

    import zmq

    context = zmq.Context()
    socket = context.socket( zmq.SUB )

    socket.connect( "tcp://localhost:5556" )

    socket.setsockopt(zmq.SUBSCRIBE, "")

    while True:
        message = socket.recv_multipart()
        message = [c if isinstance(c, str) else c.decode("utf-8") for c in message]  # Decode the multi-part message

        # Message parsing step
        event = dict(
            kind=message[0].lower(),
            when=datetime.datetime.strptime(message[1], "%Y/%m/%d %H:%M:%S %f"),
            what=message[2],
        )
        if len(message) > 3:
            event["where"] = message[3]

        print(event)


**Logging library**


The logging library in the lib folder is used to configurate the g3log lib used in background.
It is separated in two config parts :

- custom Log levels: STATE, UPDATE and ERRORS
- custom sinks

-----

.. doxygenclass:: ZMQSink
   :undoc-members:
   :members:

.. doxygenclass:: ScreenSink
   :undoc-members:
   :members:

-----
