.. _extend_data_type:

Create new data type
====================

The data streams that flow from processor to processor consist of data packets
that carry the data of interest (the payload), a source timestamp
(when the data packet was generated) and (optionally) a hardware timestamp
(original timestamp of the external hardware that generated the data).
Each input and output port on processor nodes only handles dedicated types of data.
For example, some processors operate on arrays of analog data.

Data types in Falcon form a hierarchy from generic to specific. At the top of
the hierarchy is the most generic data type "IData" that is the base for all
other data types. As long as the data type of an input port is the same or
more generic than the data type of the upstream output port, a connection can
be made. Thus, a processor node with an input port that expects the most
generic IData type, can handle incoming data streams of any other type.

Input ports may specify additional requirements for the incoming data. For example,
an input port could indicate that it only supports multi-channel analog data with
exactly 4 channels. An upstream processor with an output port that serves multi-channel
data packets with fewer or more channels will thus not be compatible.


#. **Design your datatype**
    - decide on a unique name for the data type class: The name should be camel case and end in “Type”.
      Examples: EventType, SignalType. Below, we will use “DataType”

    - decide on the parent data type of your new data type. The base of all data types is AnyType. Then, include the appropriate
      header of the parent data type. Here we use AnyType, which is defined in idata.hpp

    .. code-block:: cpp

        #include <idata.hpp>
        #include “yaml-cpp/yaml.h”  // include the yaml.h header for the data-to-YAML serialization


#. **Create the structure**
    To avoid clashes in class names, we use a data type unique namespace. Replace “DataType” with your chosen data type class name.

    .. code-block:: cpp

        namespace nsDataType {

            using ParentType = AnyType;  // set the parent data type

            struct Parameters { ... }
            class Data : public IData<Data,ParentType> { ...}
            class Capabilities {...}


        } // end namespace

    The data type class is a convenient type that collects the data type specific Parameters, Capabilities and Data classes.

    .. code-block:: cpp

        using DataType = DefineType<
          nsEventType::Data, AnyType, true,
          nsEventType::Capabilities, nsEventType::Parameters
          >;

#. **Define the Parameters structure**
    It is the  a container for parameters that are used to initialize data objects.

    .. code-block:: cpp

        struct Parameters {

          // constructor(s) to initialize parameter values
          Parameters(...) {}

          // define the data type specific parameters (replace with your own parameters)
          int x;
          double y;
        };

#. **Define the Data class**
    The Data class represents the data objects that will be streamed between output and input ports.
    It inherits from the Data class of the parent data type. There is a certain number of methods from the parent
    to specialized as well as adding assessor/setter to define the specific behavior of your datatype.

    .. code-block:: cpp

        class Data : public IData<Data,ParentType> {

         using BaseClass = IData<Data,ParentType>;

         public:

          // constructors to create data objects at least a constructor that takes a Parameters object is required
          // other constructors may be defined for convenience

          Data(...);
          Data(const Parameters& parameters);
          Parameters parameters() const {return Parameters(...);};


          // defines two static methods that return labels for the data type and the data objects.
          // These labels are used (among other things) in log and error messages.
          static const std::string static_datatype() { return “custom type”; };
          static const std::string static_dataname() { return “data”;  };

          // optional: overload the virtual ClearData method to  clear the data inside the data object
          void ClearData() override;

          // define your own API to read/write the data methods below are just an example
          int x() const;
          double y() const;
          void set_x(int x);
          void set_y(double y);

          // implement serialization methods

          void SerializeBinary(std::ostream &stream, Serialization::Format format = Serialization::Format::FULL) const override;
          void SerializeYAML(YAML::Node &node, Serialization::Format format = Serialization::Format::FULL) const override;
          void SerializeFlatBuffer(flexbuffers::Builder& fbb) override;
          void YAMLDescription(YAML::Node &node, Serialization::Format format = Serialization::Format::FULL) const override;

         // define your data
         protected:
          int x_;
          double y_;

        };

#. **Define the Capabilities class**
    The purpose of the Capabilities class is to provide validation of incoming data objects against the capabilities
    of the receiving input slot. If no capabilities need to be implemented, you can do:

    .. code-block:: cpp

        using Capabilities = ParentType::Capabilities

    You are free (but not required) to inherit from the parent data type Capabilities class if that makes sense
    (e.g., to extend the validation in the new data type)

    .. code-block:: cpp

        class Capabilities {

        public:

          // define constructor(s) to set capabilities
          Capabilities(...);

          // define validation method if validation fails, the method should throw an exception with a useful message
          template <class T> void Validate(const Data<T> & prototype) {{
            // implement your validation of the prototype data object here
          }
        };

.. note:: For more info, checkout the API reference of the AnyDataType class and its structures.