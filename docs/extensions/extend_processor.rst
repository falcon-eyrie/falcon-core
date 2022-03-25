Create new processor
====================

Setup for the new processor
---------------------------

Add in your repository a newprocessor folder.

.. code-block::

    extension_repo
       L processors
            L newprocessor
                L newprocessor.cpp
                  newprocessor.hpp
                  doc.yaml
                  CMakeLists.txt

            L otherprocessors

CMakeLists.txt should contains at least :

.. code-block::

    add_library(newprocessor "newprocessor.cpp")
    target_link_libraries(newprocessor lib1 lib2)  # target libs available are the one from the lib folder in a parent extension,
                                                   # from the lib folder or from the lib folder in falcon-core

Develop a processor class
-------------------------

.. note::

     The example code given here is for the cpp file

The new processor class needs to derive from the IProcessor class.

Two important inputs are :

- const YAML: Node &node : The description from the graph of the node with the different parameters related to the processor
- Context : There is a GlobalContext and a ProcessingContext structure available to be use in the class. (see context documentation)

Virtual methods from the IProcessor class are available to be override:

-   *Class constructor* : Add options object to the options processor engine.

    .. code-block:: C++

        ExampleProcessor::ExampleProcessor(): IProcessor() {
            add_option("option 1", options1_, "This option can be modify in the graph file with the keyword: option 1");
            add_option("option 2", options2_, "This option can be modify in the graph file with the keyword: option 2");
        }


-   *Configure( const GlobalContext& context)* : The graph (yaml file) describe the node
    with some parameters specific to the processor. These options are loaded internally between the creation of the processor
    and the call of this method. It is the time to do additional configurations based on the options (log in, derive some variables
    from it ... etc.).

    .. code-block:: console

        void ExampleProcessor::Configure( const GlobalContext& context) {
            if(options1_() > 3){
                LOG(INFO) << "The option 1 is under 3" ;
            }

            useful_var_ = options1_() - options2_();
        }

-   *CreatePorts()* : This part make use of the internal available methods from Iprocessor (see the API documentation)
    for creating input port (*create_input_port*), shared states, and output port (*create_output_port*).

    .. code-block:: C++

        void FalconProcessor::CreatePorts() {
          data_in_port_ =
              create_input_port("data", AnyDataType(), PortInPolicy(SlotRange(m, n)));

          other_data_in_port_ = create_input_port("other_data", AnyDataType(),
                                                  PortInPolicy(SlotRange(m, n)));

          data_out_port_ =
              create_output_port("data", AnyDataType(), PortOutPolicy(SlotRange(m, n)));

          other_data_out_port_ = create_output_port("other_data", AnyDataType(),
                                                    PortOutPolicy(SlotRange(m, n)));

        }

-   *CompleteStreamInfo()* set extra information for output datastream and parameters specific to the datatype, check additional conditions as
    for example same numbers of input / output slot if there are related

-   *Prepare(GlobalContext& context)* : prepare state of the node aka connecting server ... etc.

-   *Unprepare(GlobalContext& context)* : undo the prepare method

-   *Preprocess(ProcessingContext& context)* : pre-process state of the note aka clear states
    The Preprocess part is synchronized between processor. So, all processor will wait for that others finished this part.
    At the difference of prepare step, it is done in their own thread.

-   *Process(ProcessingContext& context)* : process state of the node : for loop while the context does not send a terminated signal

    #. **Retrieve pointers to next data packet(s).**
        Use RetrieveData, RetrieveDataN or RetrieveDataAll to retrieve respectively one data packet, N data packets
        or all available data packets. By default, these methods will block until enough data is available.
        If a time-out has been set and there is still not enough data available after time is up, these methods will either
        return no data or the cached last data packet (if caching was enabled).

    #. **Use the retrieved data.**
        .. warning:: Do not overwrite or alter the data, as other read cursors may still need to access the same data.

    #. **Release the data packets and move ahead read cursor.**
        Always use the ReleaseData method after you are done with the retrieved data packets, so that the data packets can be reused.

    #. **Process data**

    #. **Claim data packets for writing.**
        Use ClaimData or ClaimDataN to claim respectively one or N data packets.These methods will always block until enough
        positions on the ring buffer are available for writing. If needed,the data packets can be cleared automatically
        so that any previous data is removed.

    #. **Write new data to the data packets.**
        Don’t forget to update the timestamps as well.

    #.  **Publish the data to the ring buffer using the the PublishData() method.**
        Always pair a call to one of the ClaimData methods with a call to PublishData to properly advance the write cursor
        and make the new data available for readers.


    .. code-block:: C++

        void ExampleProcessor::Process(ProcessingContext &context) {
          AnyData *data_in = nullptr;
          AnyData *data_out = nullptr;
          T1 temp1 = 0;

          while (!context.terminated()) {
            if (!data_in_port_->slot(0)->RetrieveData(data_in)) {
              break;
            }

            // place this carefully!
            data_in_port_->slot(0)->ReleaseData();

            // clearing will take an extra operation, don't clear if you are going to
            // overwrite
            data_out = data_out_port_->slot(0)->ClaimData(true);
            data_out->set_hardware_timestamp(data_in->hardware_timestamp());
            data_out->set_source_timestamp();
            data_out_port_->slot(0)->PublishData();
          }
        }

-   *Postprocess(ProcessingContext& context)* : post-process state of the node aka log info, clean up and close communication

-   *TestPrepare(ProcessingContext& context)* : use in case of integration test

-   *TestFinalize(ProcessingContext& context)* : use in case of integration test


Finally, don't forget to add your processor in the namespace by using

.. code-block:: C++

    REGISTERPROCESSOR(ProcessorName)


.. admonition:: To look before starting to develop a new processor

    - `logging system <../internals/logging_system.html>`_
    - `graph system <../internals/graph_system.html>`_


Create the internal documentation of your processor
---------------------------------------------------

The documentation of your processor will need to specify what it is doing, its inputs and outputs but also how to describe it in
the graph definition yaml file (available options ...etc.).

To do this "doc.yaml" need to be added next to the .cpp with these entrees:

.. code-block:: yaml

    Description: short description

    Long description: long description (e.g. explanation of algorithm)

    Input ports:
      - name: name
        type: MultiChannelType
        slots: # or [#, #]
        description: description

    Output ports: ... same as input ports ...

    Options:
      - &options1                               #this option is also used as a shared state
        name: name
        type: double
        default: ...
        description: ...

    Methods:
      - name: name
        arguments:
          - name: default value
          - ...
        returns: ...
        description: ...

    States:
      static:
        - name: name
          type: double
          initial value: ...
          shared: true/false
          external access: read or write or none
          description: ...

      producer:
        - name: name
          type: double
          initial value: ...
          cooperative: true/false
          external access: read or write or none
          description: ...

      broadcaster:
        - name: name
          type: double
          initial value: ...
          external access: read or write or none
          description: ...

      follower:
        - name: name
          type: double
          initial value: ...
          external access: read or write or none
          description: ...

        - options: *options1                      #when the shared state was originally an option,
          external access: read or write or none  #the structure change a little to reuse the yaml option spec

To correctly build the documentation, this file needs to be in yaml format.


