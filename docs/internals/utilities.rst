Utilities
=========

Options
-------

The options library provides classes and functions for the validation of values and the conversion of values to and from YAML.

At the basis is the Value class that is derived from the ValueBase class.
The Value class is templated and acts as a container for a value of certain type.
For example, ``Value<double>`` will hold a double value.

The get or set the contained object, use:

.. code-block:: cpp

    Value<double> v{0.};  // initialize value to 0.
    v.get_value();  // retrieve value
    v();  // retrieve value
    v.set_value(1.);  // set value
    v = 1.;  // set value


- Available validators: inrange, clamped, squared, multiplied, notempty
- Predefined values type: Bool, Double, Int, ConstrainedValue, ClampedValue

Example: keep (ordered) list of options.

.. code-block:: cpp

    Double a{1.5, inrange<double>(0.,2.)};
    Bool b;

    // note that the option will store a reference to the value
    // and so the values need to live for as long as the optionlist is used
    optionlist.add("value", a);
    optionlist.add("nested/enabled", b);

    // adding another option with the same name is an error
    //Bool c;
    //optionlist.add("value", c);

    // set value from yaml
    c.from_yaml(YAML::Load("false"));

    // set options from yaml
    optionlist.from_yaml(YAML::Load("{value: 1.0, nested: {enabled: true}}"));

    // convert value to yaml
    c.to_yaml();

    // convert options to yaml with custom error handler
    optionlist.to_yaml(error_handler)

    // save to yaml file
    optionlist.save_yaml("test.yaml", error_handler);


**Use of options in falcon processors**


#. Declare values as class members in the header file
    .. code-block:: cpp

      options::String option1_{"default_value", options::notempty<std::string>()};
      options::Bool option2_{true};

#. Add options in constructor.
    .. code-block:: cpp

      add_option("option1 name", option1_, "description of the option");
      add_option("option2 name", option2_, "description of the option");

#. Internally, falcon will parse the processor options and set the values.
    .. code-block:: cpp

      if(option2_())    // option 2 is a boolean
        LOG(INFO) << option1_() ;   // option 1 is a string

.. doxygennamespace:: options
   :undoc-members:
   :members:

Factory
-------

.. doxygennamespace:: factory
   :undoc-members:
   :members:
