// ---------------------------------------------------------------------
// This file is part of falcon-core.
//
// Copyright (C) 2015, 2016, 2017 Neuro-Electronics Research Flanders
//
// Falcon-server is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Falcon-server is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with falcon-core. If not, see <http://www.gnu.org/licenses/>.
// ---------------------------------------------------------------------

#pragma once

#include <atomic>
#include <chrono>
#include <condition_variable>
#include <cstdio>
#include <ctime>
#include <functional>
#include <map>
#include <memory>
#include <mutex>
#include <set>
#include <string>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>
#include <utility>
#include <vector>
#include <zmq.hpp>

#include "factory/factory.hpp"
#include "graphexceptions.hpp"
#include "options/options.hpp"
#include "sharedstate.hpp"
#include "t_streamports.hpp"
#include "test_utilities.hpp"
#include "yaml-cpp/yaml.h"

// exception class for all processor related errors
GRAPHERROR(ProcessorInternalError);
GRAPHERROR(ProcessingError);
GRAPHERROR(ProcessingConfigureError);
GRAPHERROR(ProcessingCreatePortsError);
GRAPHERROR(ProcessingStreamInfoError);
GRAPHERROR(ProcessingPrepareError);
GRAPHERROR(ProcessingPreprocessingError);
GRAPHERROR(TestError);

typedef int16_t ThreadPriority;

const ThreadPriority PRIORITY_NONE = -1;
const ThreadPriority PRIORITY_LOW = 0;
const ThreadPriority PRIORITY_MEDIUM = 50;
const ThreadPriority PRIORITY_HIGH = 100;


class IProcessor {
  friend class ISlotIn;

public: // called by anyone
  IProcessor(ThreadPriority priority = PRIORITY_NONE) {}

  const std::string name() const { return name_; }
  const std::string type() const { return type_; }
  unsigned int n_input_ports() const { return input_ports_.size(); }
  unsigned int n_output_ports() const { return output_ports_.size(); }

  virtual bool issource() const { return n_input_ports() == 0; }
  virtual bool issink() const { return n_output_ports() == 0; }
  virtual bool isfilter() const { return (!issource() && !issink()); }
  virtual bool isautonomous() const { return (issource() && issink()); }

public:
  void load_fake_options(const YAML::Node &node) {
    YAML::Node empty_node(YAML::NodeType::Map);

    if (!node["options"]) {
      // to trigger check of required options
      options_.from_yaml(empty_node);
    } else {
      options_.from_yaml(node["options"]);
    }
  }

protected:
  std::map<std::string, std::shared_ptr<std::ostream>> streams_;
  std::vector<TimePoint> test_source_timestamps_;

  /* this methods creates a file whose access key is filename and whose
  fullpath is prefix.filename.extension*/
  void create_file(std::string prefix, std::string variable_name,
                   std::string extension = "bin"){};

  void prepare_latency_test(ProcessingContext &context){};
  void save_source_timestamps_to_disk(std::uint64_t n_timestamps){};

protected: // callable by derived processors, but not others
  template <typename TValue>
  void add_option(std::string name, TValue &value, std::string description = "",
                  bool required = false) {
    options_.add(name, value, description, required);
  }

  template <typename DATATYPE>
  PortOut<DATATYPE> *
  create_output_port(std::string name,
                     const typename DATATYPE::Capabilities &capabilities,
                     const typename DATATYPE::Parameters &parameters,
                     const PortOutPolicy &policy) {
    if (name.size() == 0) {
      name = DATATYPE::dataname();
    }

    if (output_ports_.count(name) == 1) {
      throw std::runtime_error("Output port name \"" + name +
                               "\" is invalid or already exists.");
    }

    output_ports_[name] = std::move(std::unique_ptr<IPortOut>(
        (IPortOut *)new PortOut<DATATYPE>(this, PortAddress(this->name(), name),
                                          capabilities, parameters, policy)));

    return ((PortOut<DATATYPE> *)output_ports_[name].get());
  }

  template <typename DATATYPE>
  PortOut<DATATYPE> *
  create_output_port(const typename DATATYPE::Capabilities &capabilities,
                     const typename DATATYPE::Parameters &parameters,
                     const PortOutPolicy &policy) {
    return create_output_port<DATATYPE>(DATATYPE::dataname(), capabilities,
                                        parameters, policy);
  }

  template <typename DATATYPE>
  PortIn<DATATYPE> *
  create_input_port(std::string name,
                    const typename DATATYPE::Capabilities &capabilities,
                    const PortInPolicy &policy) {
    if (name.size() == 0) {
      name = DATATYPE::dataname();
    }

    if (input_ports_.count(name) == 1) {
      throw std::runtime_error("Input port name \"" + name +
                               "\" is invalid or already exists.");
    }

    input_ports_[name] =
        std::move(std::unique_ptr<IPortIn>((IPortIn *)new PortIn<DATATYPE>(
            this, PortAddress(this->name(), name), capabilities, policy)));

    return ((PortIn<DATATYPE> *)input_ports_[name].get());
  }

  template <typename DATATYPE>
  void fake_connection_input_port(std::string name,
                                  const typename DATATYPE::Capabilities &capabilities,
                                  const typename DATATYPE::Parameters &parameters,
                                  const PortOutPolicy &policy){

    if(input_ports_.count(name) == 0){
      throw TestError("The input port you are trying to connect to a fake output "
                      "port does not exist");
    }
    PortIn<DATATYPE>* port_in = ((PortIn<DATATYPE> *)input_ports_[name].get());
    auto fake_connected_port= new PortOut<DATATYPE>(this, PortAddress(this->name(), name),
                                                                              capabilities, parameters, policy);

    for(int i=0; i< fake_connected_port->number_of_slots(); i++){
      if(i > port_in->maximal_number_of_slots()){
        throw TestError("Too many slots specified in the fake output port to be connected "
                        "to this input port.");
      }

      if(i > port_in->number_of_slots()-1){
        port_in->NewSlot(1);
      }

      port_in->slot(i)->Connect(fake_connected_port->slot(i));
    }

  }
  template <typename DATATYPE>
  PortIn<DATATYPE> *
  create_input_port(const typename DATATYPE::Capabilities &capabilities,
                    const PortInPolicy &policy) {
    return create_input_port<DATATYPE>(DATATYPE::dataname(), capabilities,
                                       policy);
  }

  IPortIn *input_port(std::string port) { return input_ports_.at(port).get(); }
  IPortOut *output_port(std::string port) {
    return output_ports_.at(port).get();
  }

  ISlotIn *input_slot(const SlotAddress &address) {
    return input_port(address.port())->slot(address.slot());
  };

  ISlotOut *output_slot(const SlotAddress &address) {
    return output_port(address.port())->slot(address.slot());
  }

  template <typename T>
  StaticState<T> *create_static_state(std::string state, T default_value,
                                      bool shared = true,
                                      Permission external = Permission::WRITE,
                                      std::string description = "") {
    if (shared) {
      return ((StaticState<T> *)create_readable_shared_state<T>(
          state, default_value, Permission::READ, external, description));
    } else {
      return ((StaticState<T> *)create_readable_shared_state<T>(
          state, default_value, Permission::NONE, external, description));
    }
  }

  template <typename T>
  ProducerState<T> *create_producer_state(
      std::string state, T default_value, bool cooperative = false,
      Permission external = Permission::READ, std::string description = "") {
    if (cooperative) {
      return ((ProducerState<T> *)create_writable_shared_state<T>(
          state, default_value, Permission::WRITE, external, description));
    } else {
      return ((ProducerState<T> *)create_writable_shared_state<T>(
          state, default_value, Permission::NONE, external, description));
    }
  }

  template <typename T>
  BroadcasterState<T> *
  create_broadcaster_state(std::string state, T default_value,
                           Permission external = Permission::NONE,
                           std::string description = "") {
    return ((BroadcasterState<T> *)create_writable_shared_state<T>(
        state, default_value, Permission::READ, external, description));
  }

  template <typename T>
  FollowerState<T> *
  create_follower_state(std::string state, T default_value,
                        Permission external = Permission::NONE,
                        std::string description = "") {
    return ((FollowerState<T> *)create_readable_shared_state<T>(
        state, default_value, Permission::WRITE, external, description));
  }

  template <typename T>
  ReadableState<T> *create_readable_shared_state(
      std::string state, T default_value, Permission peers = Permission::WRITE,
      Permission external = Permission::NONE, std::string description = "") {

    if (shared_states_.count(state) == 1) {
      throw ProcessorInternalError("Shared state \"" + state +
                                       "\" is invalid or already exists.",
                                   name());
    }

    shared_states_[state] =
        std::move(std::unique_ptr<IState>((IState *)new ReadableState<T>(
            default_value, description, peers, external)));

    return ((ReadableState<T> *)shared_states_[state].get());
  }

  template <typename T>
  WritableState<T> *create_writable_shared_state(
      std::string state, T default_value, Permission peers = Permission::READ,
      Permission external = Permission::NONE, std::string description = "") {

    if (shared_states_.count(state) == 1) {
      throw ProcessorInternalError("Shared state \"" + state +
                                       "\" is invalid or already exists.",
                                   name());
    }

    shared_states_[state] =
        std::move(std::unique_ptr<IState>((IState *)new WritableState<T>(
            default_value, description, peers, external)));
    return ((WritableState<T> *)shared_states_[state].get());
  }

  std::shared_ptr<IState> shared_state(std::string state) {
    if (this->shared_states_.count(state) == 0) {
      throw ProcessorInternalError(
          "Shared state \"" + state + "\" does not exist.", name());
    }
    return shared_states_[state];
  }

  template <class T>
  void expose_method(std::string methodname,
                     YAML::Node (T::*method)(const YAML::Node &)) {

    if (exposed_methods_.count(methodname) == 1) {
      throw ProcessorInternalError("Exposed method \"" + methodname +
                                       "\" is invalid or already exists.",
                                   name());
    }
    exposed_methods_[methodname] =
        std::bind(method, static_cast<T *>(this), std::placeholders::_1);
  }

  std::function<YAML::Node(const YAML::Node &)> &
  exposed_method(std::string method) {
    if (this->exposed_methods_.count(method) == 0) {
      throw ProcessorInternalError(
          "Exposed method \"" + method + "\" does not exist.", name());
    }
    return exposed_methods_[method];
  }

private: // to be overridden by derived processors, callable internally
  virtual void Configure(const GlobalContext &context) {
  }
  virtual void CreatePorts() = 0;
  virtual void Preprocess(ProcessingContext &context) {}
  virtual void Process(ProcessingContext &context) = 0;
  virtual void Postprocess(ProcessingContext &context) {}
  virtual void CompleteStreamInfo() {
    for (auto &it : output_ports_) {
      for (int k = 0; k < it.second->number_of_slots(); ++k) {
        it.second->slot(k)->streaminfo().Finalize();
      }
    }
  };
  virtual void Prepare(GlobalContext &context) {}
  virtual void Unprepare(GlobalContext &context) {}

private:
  std::string name_;
  std::string type_;

  std::map<std::string, std::unique_ptr<IPortIn>> input_ports_;
  std::map<std::string, std::unique_ptr<IPortOut>> output_ports_;

  std::map<std::string, std::function<YAML::Node(const YAML::Node &)>>
      exposed_methods_;
  std::map<std::string, std::shared_ptr<IState>> shared_states_;

  // std::atomic<bool> running_;
  // std::thread thread_;

protected:
  options::OptionList options_;

//protected:   // to be overridden and callable by derived processors
// virtual std::string default_input_port(){};
// virtual std::string default_output_port(){};

};

#define REGISTERPROCESSOR(PROCESSOR)
