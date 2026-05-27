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

#include <functional>
#include <map>
#include <memory>
#include <set>
#include <string>
#include <utility>
#include <vector>

#include "factory/factory.hpp"
#include "graphexceptions.hpp"
#include "options/options.hpp"
#include "portpolicy.hpp"
#include "runinfo.hpp"
#include "sharedstate.hpp"
#include "streamports.hpp"
#include "threadutilities.hpp"
#include "yaml-cpp/yaml.h"

// exception class for all processor related errors
GRAPHERROR(ProcessorInternalError);
GRAPHERROR(ProcessingError);
GRAPHERROR(ProcessingConfigureError);
GRAPHERROR(ProcessingCreatePortsError);
GRAPHERROR(ProcessingStreamInfoError);
GRAPHERROR(ProcessingPrepareError);
GRAPHERROR(ProcessingPreprocessingError);

void convert_name(std::string& s);
struct TimingEntry {
    uint64_t sync_cycles;
    uint64_t work_cycles;
};

namespace graph {
class ProcessorGraph;
}

class IProcessor {
    friend class ISlotIn;
    friend class graph::ProcessorGraph;

   public:  // called by anyone
    IProcessor(ThreadPriority priority = PRIORITY_HIGH) : running_(false), thread_() {
        // add test option
        add_option("test", new_test_flag_);

        // add advanced options
        add_advanced_option("thread_core", thread_core_);
        add_advanced_option("threadpriority", thread_priority_ = priority);
        add_advanced_option("buffer_sizes", requested_buffer_sizes_);
    }

    virtual ~IProcessor() { internal_Stop(); }

    // Thread-local storage to prevent contention between 256 threads
    // Initialized to nullptr; allocated only on first use
    static inline thread_local std::vector<TimingEntry>* t_metrics = nullptr;
    static constexpr size_t MAX_SAMPLES = 100000;

    // Fast, inline recording function
    inline void record_metrics(uint64_t sync, uint64_t work) noexcept {
        if (!t_metrics) [[unlikely]] {
            t_metrics = new std::vector<TimingEntry>();
            t_metrics->reserve(MAX_SAMPLES);
        }

        if (t_metrics->size() < MAX_SAMPLES) {
            t_metrics->push_back({sync, work});
        }
    }

    // Dump logic to be called in Postprocess
    void dump_benchmarks() {
        if (!t_metrics || t_metrics->empty()) return;

        std::system("mkdir -p bench");

        // Use .bin extension to distinguish from CSV
        std::string filename = "bench/bench_" + std::string(name()) + "_" +
                               std::to_string(reinterpret_cast<uintptr_t>(this)) + ".bin";

        std::ofstream f{filename, std::ios::binary};
        if (f.is_open()) {
            // Write the entire buffer in one system call
            f.write(reinterpret_cast<const char*>(t_metrics->data()),
                    t_metrics->size() * sizeof(TimingEntry));
            f.close();
        } else {
            LOG(ERROR) << "Failed to write binary to " << filename;
        }

        delete t_metrics;
        t_metrics = nullptr;
    }

    /**
     * Get processor's name.
     *
     * The processor's name is set during the graph build phase *after*
     * construction.
     */
    const std::string name() const { return name_; }

    /**
     * Get processor's class name.
     *
     * The processor's class name is set during the graph build phase
     * *after* construction.
     */
    const std::string type() const { return type_; }

    /**
     * Get number of input ports on the processor.
     */
    unsigned int n_input_ports() const { return input_ports_.size(); }

    /**
     * Get number of output ports on the processor.
     */
    unsigned int n_output_ports() const { return output_ports_.size(); }

    /**
     * Get set of all input port names.
     */
    const std::set<std::string> input_port_names() const;

    /**
     * Get set of all output port names.
     */
    const std::set<std::string> output_port_names() const;

    /**
     * Check if input port with given name exists.
     *
     * @param port The name of the port.
     */
    bool has_input_port(std::string port) { return input_ports_.count(port) == 1; }

    /**
     * Check if output port with given name exists.
     *
     * @param port The name of the port.
     */
    bool has_output_port(std::string port) { return output_ports_.count(port) == 1; }

    virtual bool issource() const { return n_input_ports() == 0; }
    virtual bool issink() const { return n_output_ports() == 0; }
    virtual bool isfilter() const { return (!issource() && !issink()); }
    virtual bool isautonomous() const { return (issource() && issink()); }

    ThreadPriority thread_priority() const { return thread_priority_(); }
    ThreadCore thread_core() const { return thread_core_(); }
    bool running() const { return running_.load(); }

    YAML::Node ExportYAML();

    void checkNonvoluntaryContextSwitches();

   protected:
    std::map<std::string, std::shared_ptr<std::ostream>> streams_;
    std::vector<TimePoint> test_source_timestamps_;

    /* this methods creates a file whose access key is filename and whose
    fullpath is prefix.filename.extension*/
    void create_file(const std::string& prefix, const std::string& variable_name,
                     const std::string& extension = "bin");

    void prepare_latency_test(ProcessingContext& context);
    void save_source_timestamps_to_disk(std::uint64_t n_timestamps);

   protected:  // callable by derived processors, but not others
    /**
     * Add an option to the processor.
     *
     * A static state can only be read by the owning processor. If `shared`
     * is true, then the state can be read by other processors as well
     * (if their states are connected). Otherwise, a non-shared static state is
     * created that is not accessible from other processors. The main use of
     * static states is to expose the state value to clients by
     * setting the `external` permissions to `Permission::READ` or
     * `Permission::WRITE`.
     *
     * @tparam TValue The type of the option value.
     *
     * @param name The name of the option that is unique within the processor.
     * @param value A reference to the linked Value object (should be derived
     * from ValueBase).
     * @param description A brief description of the option.
     * @param required Makes it a required option that clients need to specify
     * in the graph definition
     *
     */
    template <typename TValue>
    void add_option(std::string name, TValue& value, std::string description = "",
                    bool required = false) {
        options_.add(name, value, description, required);
    }

    /**
     * Remove an existing processor option.
     *
     * @param name The name of the existing option.
     *
     */
    void remove_option(const std::string& name);

    /**
     * Create an data output port on the processor.
     *
     * @tparam DATATYPE The type of data that will be streamed through the port.
     *
     * @param parameters The data type specific parameters of the port.
     * @param policy The output port policy.
     *
     * @returns An observing pointer to the output port.
     */
    template <typename DATATYPE>
    PortOut<DATATYPE>* create_output_port(std::string name,
                                          const typename DATATYPE::Parameters& parameters,
                                          const PortOutPolicy& policy) {
        if (name.size() == 0) {
            name = DATATYPE::dataname();
        }
        convert_name(name);
        if (output_ports_.count(name) == 1) {
            throw std::runtime_error("Output port name \"" + name +
                                     "\" is invalid or already exists.");
        }

        output_ports_[name] = std::move(std::unique_ptr<IPortOut>((IPortOut*) new PortOut<DATATYPE>(
            this, PortAddress(this->name(), name), parameters, policy)));

        return ((PortOut<DATATYPE>*) output_ports_[name].get());
    }

    /**
     * Create an output port on the processor.
     *
     * The port name is set to the default data type name.
     *
     * @overload
     */
    template <typename DATATYPE>
    PortOut<DATATYPE>* create_output_port(const typename DATATYPE::Parameters& parameters,
                                          const PortOutPolicy& policy) {
        return create_output_port<DATATYPE>(DATATYPE::dataname(), parameters, policy);
    }

    /**
     * Create an data input port on the processor.
     *
     * @tparam DATATYPE The type of data that will be streamed through the port.
     *
     * @param capabilities The data type specific capabilities of the port.
     * @param policy The input port policy.
     *
     * @returns An observing pointer to the input port.
     */
    template <typename DATATYPE>

    PortIn<DATATYPE>* create_input_port(std::string name,
                                        const typename DATATYPE::Capabilities& capabilities,
                                        const PortInPolicy& policy) {
        if (name.size() == 0) {
            name = DATATYPE::dataname();
        }
        convert_name(name);
        if (input_ports_.count(name) == 1) {
            throw std::runtime_error("Input port name \"" + name +
                                     "\" is invalid or already exists.");
        }

        input_ports_[name] = std::move(std::unique_ptr<IPortIn>((IPortIn*) new PortIn<DATATYPE>(
            this, PortAddress(this->name(), name), capabilities, policy)));

        return ((PortIn<DATATYPE>*) input_ports_[name].get());
    }

    /**
     * Create an input port on the processor.
     *
     * The port name is set to the default data type name.
     *
     * @overload
     */
    template <typename DATATYPE>
    PortIn<DATATYPE>* create_input_port(const typename DATATYPE::Capabilities& capabilities,
                                        const PortInPolicy& policy) {
        return create_input_port<DATATYPE>(DATATYPE::dataname(), capabilities, policy);
    }

    /**
     * Retrieve observing pointer to input port.
     *
     * @param port The name of the input port.
     */
    IPortIn* input_port(std::string port) { return input_ports_.at(port).get(); }

    /**
     * Retrieve observing pointer to output port.
     *
     * @param port The name of the output port.
     */
    IPortOut* output_port(std::string port) { return output_ports_.at(port).get(); }

    /**
     * Retrieve observing pointer to input port.
     *
     * @param port The address of the input port.
     */
    IPortIn* input_port(const PortAddress& address);

    /**
     * Retrieve observing pointer to output port.
     *
     * @param port The address of the output port.
     */
    IPortOut* output_port(const PortAddress& address);

    /**
     * Retrieve observing pointer to input slot.
     *
     * @param port The address of the input slot.
     */
    ISlotIn* input_slot(const SlotAddress& address);

    /**
     * Retrieve observing pointer to output slot.
     *
     * @param port The address of the output slot.
     */
    ISlotOut* output_slot(const SlotAddress& address);

    /*self – peers – external

    static variable: value is not changed by self or others
    R – N – N (static variable) -> not very useful
    R – N – R (externally observed static variable)
    R – R – N (static shared observable)
    R – R – R (externally observed static shared observable)
    R – N – W (externally controlled static variable)
    R – R – W (externally controlled shared static variable)
    isolated producer: value is changed by self only
    W – N – N (isolated producer) -> not very useful
    W – N – R (externally observed isolated producer)
    W – N – W (bi-directional channel)
    co-operative producer: self and others change the value
    W – W – N (co-operative producer)
    W – W – R (externally observed co-operative producer)
    W – W – W (externally controlled co-operative producer)
    follower: value is changed by others, self only reads
    R – W – N (follower)
    R – W – R (externally observed follower)
    R – W – W (externally controlled follower)
    broadcaster: self changes the value, others follow
    W – R – N (broadcaster)
    W – R – R (externally observed broadcaster)
    W – R – W (externally controlled broadcaster)

    */

    /**
     * Create a static state on the processor.
     *
     * A static state can only be read by the owning processor. If `shared`
     * is true, then the state can be read by other processors as well
     * (if their states are connected). Otherwise, a non-shared static state is
     * created that is not accessible from other processors. The main use of
     * static states is to expose the state value to clients by
     * setting the `external` permissions to `Permission::READ` or
     * `Permission::WRITE`.
     *
     * @tparam T The type of the state value.
     *
     * @param state The name of the state that is unique within the processor.
     * @param default_value The initial value of the state.
     * @param cooperative Creates a cooperative or isolated producer state.
     * @param external The external read/write permissions.
     * @param description A brief description of the state's purpose.
     *
     * @returns An observing pointer to the static state.
     *
     */
    template <typename T>
    StaticState<T>* create_static_state(std::string state, T default_value, bool shared = true,
                                        Permission external = Permission::WRITE,
                                        std::string description = "") {
        if (shared) {
            return ((StaticState<T>*) create_readable_shared_state<T>(
                state, default_value, Permission::READ, external, description));
        } else {
            return ((StaticState<T>*) create_readable_shared_state<T>(
                state, default_value, Permission::NONE, external, description));
        }
    }

    /**
     * Create a producer state on the processor.
     *
     * A producer state can be written by the owning processor. If `cooperative`
     * is true, then the state can be written to by other processors as well
     * (if their states are connected). Otherwise, an isolated producer is
     * created that is not accessible from other processors. The main use of
     * isolated producers is to expose the state value to clients by setting the
     * `external` permissions to `Permission::READ` or `Permission::WRITE`.
     *
     * @tparam T The type of the state value.
     *
     * @param state The name of the state that is unique within the processor.
     * @param default_value The initial value of the state.
     * @param cooperative Creates a cooperative or isolated producer state.
     * @param external The external read/write permissions.
     * @param description A brief description of the state's purpose.
     *
     * @returns An observing pointer to the producer state.
     *
     */
    template <typename T>
    ProducerState<T>* create_producer_state(std::string state, T default_value,
                                            bool cooperative = false,
                                            Permission external = Permission::READ,
                                            std::string description = "") {
        if (cooperative) {
            return ((ProducerState<T>*) create_writable_shared_state<T>(
                state, default_value, Permission::WRITE, external, description));
        } else {
            return ((ProducerState<T>*) create_writable_shared_state<T>(
                state, default_value, Permission::NONE, external, description));
        }
    }

    /**
     * Create a broadcaster state on the processor.
     *
     * A broadcaster state can be written by the owning processor and can only
     * be read by other processors (if their states are connected).
     * If `external` permissions are set to `Permission::READ` or
     * `Permission::WRITE`, then the state value can also accessed by clients.
     *
     * @tparam T The type of the state value.
     *
     * @param state The name of the state that is unique within the processor.
     * @param default_value The initial value of the state.
     * @param external The external read/write permissions.
     * @param description A brief description of the state's purpose.
     *
     * @returns An observing pointer to the broadcaster state.
     *
     */
    template <typename T>
    BroadcasterState<T>* create_broadcaster_state(std::string state, T default_value,
                                                  Permission external = Permission::NONE,
                                                  std::string description = "") {
        return ((BroadcasterState<T>*) create_writable_shared_state<T>(
            state, default_value, Permission::READ, external, description));
    }

    /**
     * Create a follower state on the processor.
     *
     * A follower state can only be read the owning processor and can be written
     * to by other processors (if their states are connected). The initial value
     * of the state is only used if the state is not connected to any other
     * state. If `external` permissions are set to `Permission::READ` or
     * `Permission::WRITE`, then the state value can also accessed by clients.
     *
     * @tparam T The type of the state value.
     *
     * @param state The name of the state that is unique within the processor.
     * @param default_value The initial value of the state.
     * @param external The external read/write permissions.
     * @param description A brief description of the state's purpose.
     *
     * @returns An observing pointer to the follower state.
     *
     */
    template <typename T>
    FollowerState<T>* create_follower_state(std::string state, T default_value,
                                            Permission external = Permission::NONE,
                                            std::string description = "") {
        return ((FollowerState<T>*) create_readable_shared_state<T>(
            state, default_value, Permission::WRITE, external, description));
    }

    /**
     * Create a readable shared state on the processor.
     *
     * A readable state can only be read the owning processor. Access
     * permissions for other processors (if their states are linked) and clients
     * can be set by the `peers` and `external` parameters.
     *
     * @tparam T The type of the state value.
     *
     * @param state The name of the state that is unique within the processor.
     * @param default_value The initial value of the state.
     * @param peers The state access permissions for other processors.
     * @param external The external read/write permissions.
     * @param description A brief description of the state's purpose.
     *
     * @returns An observing pointer to the readable state.
     *
     */
    template <typename T>
    ReadableState<T>* create_readable_shared_state(std::string state, T default_value,
                                                   Permission peers = Permission::WRITE,
                                                   Permission external = Permission::NONE,
                                                   std::string description = "") {
        if (shared_states_.count(state) == 1) {
            throw ProcessorInternalError(
                "Shared state \"" + state + "\" is invalid or already exists.", name());
        }

        shared_states_[state] = std::move(std::unique_ptr<IState>(
            (IState*) new ReadableState<T>(default_value, description, peers, external)));

        return ((ReadableState<T>*) shared_states_[state].get());
    }

    /**
     * Create a writable shared state on the processor.
     *
     * A writable state can be written to by the owning processor. Access
     * permissions for other processors (if their states are linked) and clients
     * can be set by the `peers` and `external` parameters.
     *
     * @tparam T The type of the state value.
     *
     * @param state The name of the state that is unique within the processor.
     * @param default_value The initial value of the state.
     * @param peers The state access permissions for other processors.
     * @param external The external read/write permissions.
     * @param description A brief description of the state's purpose.
     *
     * @returns An observing pointer to the writable state.
     *
     */
    template <typename T>
    WritableState<T>* create_writable_shared_state(std::string state, T default_value,
                                                   Permission peers = Permission::READ,
                                                   Permission external = Permission::NONE,
                                                   std::string description = "") {
        if (shared_states_.count(state) == 1) {
            throw ProcessorInternalError(
                "Shared state \"" + state + "\" is invalid or already exists.", name());
        }

        shared_states_[state] = std::move(std::unique_ptr<IState>(
            (IState*) new WritableState<T>(default_value, description, peers, external)));
        return ((WritableState<T>*) shared_states_[state].get());
    }

    /**
     * Retrieve a pointer to a state.
     *
     * @param state The name of the state.
     */
    std::shared_ptr<IState> shared_state(std::string state) {
        if (this->shared_states_.count(state) == 0) {
            throw ProcessorInternalError("Shared state \"" + state + "\" does not exist.", name());
        }
        return shared_states_[state];
    }

    template <class T>
    void expose_method(std::string methodname, YAML::Node (T::*method)(const YAML::Node&)) {
        if (exposed_methods_.count(methodname) == 1) {
            throw ProcessorInternalError(
                "Exposed method \"" + methodname + "\" is invalid or already exists.", name());
        }
        exposed_methods_[methodname] =
            std::bind(method, static_cast<T*>(this), std::placeholders::_1);
    }

    std::function<YAML::Node(const YAML::Node&)>& exposed_method(std::string method) {
        if (this->exposed_methods_.count(method) == 0) {
            throw ProcessorInternalError("Exposed method \"" + method + "\" does not exist.",
                                         name());
        }
        return exposed_methods_[method];
    }

   protected:  // to be overridden and callable by derived processors
    virtual std::string default_input_port() const;
    virtual std::string default_output_port() const;

   private:  // to be overridden by derived processors, callable internally
    virtual void Configure(const GlobalContext& context) {}
    virtual void CreatePorts() = 0;
    virtual void Preprocess(ProcessingContext& context) {}
    virtual void Process(ProcessingContext& context) = 0;
    virtual void Postprocess(ProcessingContext& context) {}
    virtual void CompleteStreamInfo();
    virtual void Prepare(GlobalContext& context) {}
    virtual void Unprepare(GlobalContext& context) {}
    virtual void TestPrepare(ProcessingContext& context) {}
    virtual void TestFinalize(ProcessingContext& context) {}

   private:  // callable internally only
    void internal_Configure(const YAML::Node& node,
                            const GlobalContext& context);  // from engine
    void internal_CreatePorts();
    void internal_PrepareConnectionIn(SlotAddress& in);
    void internal_PrepareConnectionOut(SlotAddress& out);
    void internal_ConnectIn(const SlotAddress& address, IProcessor* upstream,
                            const SlotAddress& upstream_address);
    void internal_ConnectOut(const SlotAddress& address, IProcessor* downstream,
                             const SlotAddress& downstream_address);

    void internal_NegotiateConnections();

    void internal_CreateRingBuffers();
    void internal_PrepareProcessing();

    void internal_ThreadEntry(RunContext& runcontext);

    void internal_Start(RunContext& runcontext);
    void internal_Stop();

    void internal_Alert();

    YAML::Node internal_ApplyMethod(const std::string& name, const YAML::Node& node);

    void set_name_and_type(std::string name, std::string type) {
        name_ = name;
        type_ = type;
    }

    template <typename TValue>
    void add_advanced_option(std::string name, TValue& value, std::string description = "",
                             bool required = false) {
        advanced_options_.add(name, value, description, required);
    }

   private:
    std::string name_;
    std::string type_;

    std::map<std::string, std::unique_ptr<IPortIn>> input_ports_;
    std::map<std::string, std::unique_ptr<IPortOut>> output_ports_;

    std::map<std::string, std::function<YAML::Node(const YAML::Node&)>> exposed_methods_;
    std::map<std::string, std::shared_ptr<IState>> shared_states_;

    bool negotiated_ = false;
    bool prepared_ = false;

    std::atomic<bool> running_;

    std::thread thread_;

    options::Value<ThreadPriority, false> thread_priority_{
        PRIORITY_HIGH, options::inrange<ThreadPriority>(PRIORITY_NONE, PRIORITY_HIGH)};

    options::Value<ThreadCore, false> thread_core_{
        CORE_NOT_PINNED, options::inrange<ThreadCore>(
                             CORE_NOT_PINNED, (ThreadCore) sysconf(_SC_NPROCESSORS_ONLN) - 1)};

    options::NullableBool new_test_flag_;
    options::Value<std::map<std::string, int>> requested_buffer_sizes_{};

    /// @brief Count of non-voluntary context switches measured last time.
    /// It's used to calculate the increase in non-voluntary context
    /// switches to log an alert message.
    uint64_t lastNonvoluntaryContextSwitches = 0;

   protected:
    options::OptionList options_;
    options::OptionList advanced_options_;
};

typedef std::map<std::string, std::pair<std::string, std::unique_ptr<IProcessor>>> ProcessorMap;

typedef factory::ObjectFactory<IProcessor, std::string> ProcessorFactory;

template <class PROCESSOR>
class ProcessorRegistrar {
   public:
    ProcessorRegistrar(std::string name);
};

template <class PROCESSOR>
ProcessorRegistrar<PROCESSOR>::ProcessorRegistrar(std::string name) {
    ProcessorFactory::instance().registerClass(name,
                                               factory::createInstance<IProcessor, PROCESSOR>);
}

#define REGISTERPROCESSOR(PROCESSOR)                             \
    namespace {                                                  \
    static ProcessorRegistrar<PROCESSOR> _registrar(#PROCESSOR); \
    };
