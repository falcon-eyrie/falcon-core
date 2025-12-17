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
#include <fstream>
#include <iostream>
#include <regex>
#include <utility>

#include "iprocessor.hpp"
#include "logging/log.hpp"
#include "utilities/general.hpp"

void convert_name(std::string& s) {
    if (std::regex_match(s, std::regex("^\\w(?:(?:[ -][\\w])|\\w)*$"))) {
        s = std::regex_replace(s, std::regex("[ _]"), "-");
    } else {
        throw ProcessorInternalError(s + " is not a valid name.");
    }
}

const std::set<std::string> IProcessor::input_port_names() const {
    std::set<std::string> names;
    for (auto& it : input_ports_) {
        names.insert(it.first);
    }
    return names;
}

const std::set<std::string> IProcessor::output_port_names() const {
    std::set<std::string> names;
    for (auto& it : output_ports_) {
        names.insert(it.first);
    }
    return names;
}

YAML::Node IProcessor::ExportYAML() {
    YAML::Node node;

    for (auto& it : input_ports_) {
        node["inports"][it.first] = it.second->ExportYAML();
    }

    for (auto& it : output_ports_) {
        node["outports"][it.first] = it.second->ExportYAML();
    }

    for (auto& it : shared_states_) {
        node["states"][it.first]["permission"] =
            permission_to_string(it.second->external_permission());
        if (it.second->external_permission() != Permission::NONE) {
            node["states"][it.first]["value"] = it.second->get_string();
        }
        node["states"][it.first]["description"] = it.second->description();
    }

    for (auto& it : exposed_methods_) {
        node["methods"].push_back(it.first);
    }

    return node;
}

void IProcessor::remove_option(const std::string& name) {
    options_.remove(name);
}

IPortIn* IProcessor::input_port(const PortAddress& address) {
    return input_port(address.port());
}

IPortOut* IProcessor::output_port(const PortAddress& address) {
    return output_port(address.port());
}

ISlotIn* IProcessor::input_slot(const SlotAddress& address) {
    return input_port(address.port())->slot(address.slot());
}

ISlotOut* IProcessor::output_slot(const SlotAddress& address) {
    return output_port(address.port())->slot(address.slot());
}

std::string IProcessor::default_input_port() const {
    if (input_ports_.size() != 1) {
        throw std::runtime_error("Cannot determine default input port for processor \"" + name() +
                                 "\".");
    }
    return input_ports_.begin()->first;
}

std::string IProcessor::default_output_port() const {
    if (output_ports_.size() != 1) {
        throw ProcessorInternalError("Cannot determine default output port.", name());
    }
    return output_ports_.begin()->first;
}

void IProcessor::CompleteStreamInfo() {
    for (auto& it : output_ports_) {
        for (int k = 0; k < it.second->number_of_slots(); ++k) {
            it.second->slot(k)->streaminfo().Finalize();
        }
    }
}

void IProcessor::internal_Configure(const YAML::Node& node, const GlobalContext& context) {
    YAML::Node empty_node(YAML::NodeType::Map);
    try {
        if (!node["options"]) {
            // to trigger check of required options
            options_.from_yaml(empty_node);
        } else {
            options_.from_yaml(node["options"]);
        }

        if (!node["advanced"]) {
            // to trigger check of required options
            advanced_options_.from_yaml(empty_node);
        } else {
            advanced_options_.from_yaml(node["advanced"]);
        }
    } catch (const std::runtime_error& error) {
        throw std::runtime_error(name() + ": " + error.what());
    }

    Configure(context);
}

void IProcessor::internal_CreatePorts() {
    CreatePorts();
    // set requested buffer sizes

    if (requested_buffer_sizes_.is_null()) {
        return;
    }

    for (auto& it : requested_buffer_sizes_()) {
        if (!has_output_port(it.first) || it.second < 2) {
            LOG(WARNING) << "Could not set ringbuffer size to " << it.second << " for port "
                         << name() << "." << it.first;
        } else {
            output_port(it.first)->set_buffer_size(it.second);
            LOG(INFO) << "Set ringbuffer size to " << it.second << " for port " << name() << "."
                      << it.first;
        }
    }
}

void IProcessor::internal_PrepareConnectionIn(SlotAddress& address) {
    if (address.processor() != name()) {
        throw std::runtime_error("Internal error: processor name does not match address.");
    }

    // get default port if needed
    if (address.port() == "") {
        address.set_port(default_input_port());
    }

    // test if port exists
    if (!has_input_port(address.port())) {
        throw std::out_of_range("Unknown input port \"" + address.processor() + "." +
                                address.port() + "\".");
    }

    // test if slot is valid and create new slot if needed
    int slot = input_port(address)->ReserveSlot(address.slot());

    // and update slot in address
    if (slot < 0) {
        throw std::out_of_range("Unable to reserve slot \"" + std::to_string(address.slot()) +
                                "\" for input port \"" + address.processor() + "." +
                                address.port() + "\".");
    }

    address.set_slot(slot);
    address.set_port_datatype(input_port(address)->datatype());
}

void IProcessor::internal_PrepareConnectionOut(SlotAddress& address) {
    if (address.processor() != name()) {
        throw std::runtime_error("Internal error: processor name does not match address.");
    }

    // get default port if needed
    if (address.port() == "") {
        address.set_port(default_output_port());
    }

    // test if port exists
    if (!has_output_port(address.port())) {
        throw std::out_of_range("Unknown output port \"" + address.port() + "\" on processor \"" +
                                address.processor() + "\".");
    }

    // test if slot is valid and create new one if necessary
    int slot = output_port(address)->ReserveSlot(address.slot());

    // and update slot in address
    if (slot < 0) {
        throw std::out_of_range("Unable to reserve slot \"" + std::to_string(address.slot()) +
                                "\" for output port \"" + address.processor() + "." +
                                address.port() + "\".");
    }

    address.set_slot(slot);
    address.set_port_datatype(output_port(address)->datatype());
}

void IProcessor::internal_ConnectIn(const SlotAddress& address, IProcessor* upstream,
                                    const SlotAddress& upstream_address) {
    input_port(address)->Connect(address.slot(), upstream->output_slot(upstream_address));
}

void IProcessor::internal_ConnectOut(const SlotAddress& address, IProcessor* downstream,
                                     const SlotAddress& downstream_address) {
    output_port(address)->Connect(address.slot(), downstream->input_slot(downstream_address));
}

void IProcessor::internal_NegotiateConnections() {
    if (!negotiated_) {
        // check if all input slots are connected
        for (auto& it : input_ports_) {
            for (int k = 0; k < it.second->number_of_slots(); ++k) {
                if (!it.second->slot(k)->connected()) {
                    throw ProcessorInternalError("input slot \"" + it.first + "." +
                                                     std::to_string(k) + "\" is not connected.",
                                                 name());
                }

                try {
                    it.second->slot(k)->Validate();
                } catch (std::exception& e) {
                    throw ProcessorInternalError(
                        std::string("Incompatible data stream ") +
                            it.second->slot(k)->upstream_address().string(false) + " -> " +
                            it.second->slot(k)->address().string(false) + " (" + e.what() + ")",
                        name());
                }
            }
        }

        for (auto& it : output_ports_) {
            for (int k = 0; k < it.second->number_of_slots(); ++k) {
                if (!it.second->slot(k)->connected()) {
                    LOG(WARNING) << name() << ": output slot \"" << it.first + "."
                                 << std::to_string(k) << "\" is not connected.";
                }
            }
        }

        CompleteStreamInfo();

        // OK, so let's finalize right here, locking streaminfo forever after
        // this also requires that set_stream_rate and set_parameters check &
        // respect the lock
        for (auto& it : output_ports_) {
            for (int k = 0; k < it.second->number_of_slots(); ++k) {
                it.second->slot(k)->streaminfo().Finalize();
            }
        }

        negotiated_ = true;
    }
}

void IProcessor::internal_CreateRingBuffers() {
    for (auto& it : output_ports_) {
        it.second->CreateRingBuffers();
    }
}

void IProcessor::internal_PrepareProcessing() {
    for (auto& it : input_ports_) {
        it.second->PrepareProcessing();
    }

    // reset all output slot cursors to 0
    for (auto& it : output_ports_) {
        it.second->PrepareProcessing();
    }
}

void IProcessor::internal_ThreadEntry(RunContext& runcontext) {
    LOG(DEBUG) << "Entering thread for processor " << name_;

    ProcessingContext context(runcontext, name_,
                              new_test_flag_.is_null() ? runcontext.test() : new_test_flag_());

    LOG(DEBUG) << name_ << ": processor test flag set to " << context.test();

    internal_PrepareProcessing();

    try {
        TestPrepare(context);
    } catch (std::exception& e) {
        context.TerminateWithError("TestPrepare", e.what());
    }

    try {
        Preprocess(context);
    } catch (std::exception& e) {
        context.TerminateWithError("PreProcess", e.what());
    }

    running_.store(true);

    // wait for the go signal
    {
        std::unique_lock<std::mutex> lock(runcontext.mutex);
        while (!runcontext.go_signal) {
            runcontext.go_condition.wait(lock);
        }
    }

    try {
        Process(context);
    } catch (std::exception& e) {
        context.TerminateWithError("Process", e.what());
    }

    try {
        Postprocess(context);
    } catch (std::exception& e) {
        context.TerminateWithError("PostProcess", e.what());
    }

    try {
        TestFinalize(context);
    } catch (std::exception& e) {
        context.TerminateWithError("TestFinalize", e.what());
    }

    running_.store(false);

    LOG(DEBUG) << "Exiting thread for processor " << name_;
}

void IProcessor::internal_Start(RunContext& runcontext) {
    if (!running_) {
        internal_Stop();

        thread_ = std::thread(&IProcessor::internal_ThreadEntry, this, std::ref(runcontext));

        if (!set_realtime_priority(thread_.native_handle(), thread_priority())) {
            LOG(WARNING) << "Unable to set thread priority for " << name_;
        } else if (thread_priority() >= PRIORITY_LOW) {
            LOG(INFO) << "Successfully set thread priority for " << name_ << " to "
                      << thread_priority() << "%.";
        }

        if (!set_thread_core(thread_.native_handle(), thread_core())) {
            LOG(WARNING) << "Unable to pin thread for " << name_ << " to core " << thread_core();
        } else if (thread_core() >= 0) {
            LOG(INFO) << "Successfully pinned thread for " << name_ << " to core " << thread_core()
                      << ".";
        }
    }
}

void IProcessor::internal_Stop() {
    if (thread_.joinable()) thread_.join();
    LOG(DEBUG) << name() << ": thread joined";
}

void IProcessor::internal_Alert() {
    for (auto& it : output_ports_) {
        it.second->UnlockSlots();
    }
    for (auto& it : input_ports_) {
        it.second->UnlockSlots();
    }
}

YAML::Node IProcessor::internal_ApplyMethod(const std::string& name, const YAML::Node& node) {
    return exposed_method(name)(node);
}

void IProcessor::create_file(const std::string& prefix, const std::string& variable_name,
                             const std::string& extension) {
    std::string full_path = prefix + "." + variable_name + "." + extension;
    if (path_exists(full_path)) {
        throw ProcessorInternalError("Output file " + full_path + " already exists.", name());
    }

    // unique_ptr gives compilation error for unknown reasons
    auto stream = std::shared_ptr<std::ostream>(
        new std::ofstream(full_path, std::ofstream::out | std::ofstream::binary));
    if (!stream->good()) {
        throw ProcessorInternalError("Error opening output file " + full_path + ".", name());
    } else {
        LOG(INFO) << name() << ". " + full_path + " opened correctly for writing";
    }
    streams_[variable_name] = std::move(stream);
}

void IProcessor::prepare_latency_test(ProcessingContext& context) {
    auto path = context.resolve_path("test://", "test");
    create_file(path + name(), "SourceTimestamps");
    LOG(UPDATE) << name() << ". Resizing the source timestamp vector for testing ...";
    // reserve enough memory for the test
    test_source_timestamps_.resize(MAX_TEST_SAMPLING_FREQUENCY * (3600 * MAX_N_HOURS_TEST));
    LOG(INFO) << name() << ". Source timestamp vector resized with "
              << test_source_timestamps_.size() << " elements";
}

void IProcessor::save_source_timestamps_to_disk(std::uint64_t n_timestamps) {
    test_source_timestamps_.resize(n_timestamps);
    for (auto source_ts : test_source_timestamps_) {
        streams_["SourceTimestamps"]->write(reinterpret_cast<const char*>(&source_ts),
                                            sizeof(TimePoint));
    }
    LOG(INFO) << name() << ". " << test_source_timestamps_.size()
              << " source timestamps were written to disk.";
}
