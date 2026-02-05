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

#include <algorithm>
#include <exception>
#include <iostream>
#include <regex>
#include <string>
#include <utility>
#include <vector>

#include "buildconstant.hpp"
#include "dummy_type.cpp"
#include "processorgraph.hpp"
#include "sharedstate.hpp"

using namespace graph;

std::string graph_state_string(GraphState state) {
    std::string s;
#define PROCESS_STATE(p)  \
    case (GraphState::p): \
        s = #p;           \
        break;
    switch (state) {
        PROCESS_STATE(NOGRAPH);
        PROCESS_STATE(CONSTRUCTING);
        PROCESS_STATE(PREPARING);
        PROCESS_STATE(READY);
        PROCESS_STATE(STARTING);
        PROCESS_STATE(PROCESSING);
        PROCESS_STATE(STOPPING);
        PROCESS_STATE(ERROR);
    }
#undef PROCESS_STATE
    return s;
}

std::vector<std::string> expandProcessorName(const std::string& s) {
    static const int name_group = 1;
    static const int range_group = 2;
    static const int first_range_id = 1;
    static const int end_range_id = 2;

    std::vector<std::string> result;
    int startid, endid;

    // name# or name[#, #-#]
    std::regex re("^([a-zA-Z]+(?:[ -_][a-zA-Z]+)*)[ ]*((?:\\d+)|(?:\\([\\d,\\-]+\\)))?$");

    std::smatch match;

    // match regular expression
    if (!std::regex_match(s, match, re)) {
        throw std::runtime_error("Invalid processor name: \"" + s + "\"");
    }

    // get base name
    if (!match[name_group].matched) {
        throw std::runtime_error("Invalid processor name (no base name): \"" + s + "\"");
    }

    std::string name = match[name_group].str();

    // remove trimming spaces
    name = std::regex_replace(name, std::regex("^ +| +$"), std::string(""));
    // name = std::regex_replace(name, std::regex("[ _]"), "-");
    //  parse part identifiers
    std::vector<int> identifiers;

    if (!match[range_group].matched) {
        result.push_back(name);
    } else {
        std::string range = match[range_group].str();  // Example: (1-2)
        // remove trimming spaces
        range = std::regex_replace(range, std::regex("^ +| +$"), std::string(""));

        if (range[0] == '(') {
            // match ID range vector
            // remove brackets and spaces
            range.erase(
                std::remove_if(range.begin(), range.end(),
                               [](char x) { return (x == '(' || x == ')' || std::isspace(x)); }),
                range.end());

            // split on comma
            auto id_range = split(range, ',');

            std::regex re_range("(\\d+)(?:\\-(\\d+))?");
            std::smatch match_range;

            // match start and end id of ranges
            for (const auto& q : id_range) {
                if (std::regex_match(q, match_range, re_range)) {
                    startid = stoi(match_range[first_range_id].str());
                    if (match_range[end_range_id].matched) {
                        endid = stoi(match_range[end_range_id].str());
                    } else {
                        endid = startid;
                    }
                    for (auto kk = startid; kk <= endid; kk++) {
                        result.push_back(name + std::to_string(kk));
                    }
                } else {
                    throw std::runtime_error("Invalid processor name (invalid identifiers): \"" +
                                             s + "\"");
                }
            }
        } else {
            // try to convert to int
            try {
                result.push_back(name + std::to_string(stoi(range)));
            } catch (std::invalid_argument& e) {
                throw std::runtime_error("Invalid processor name (invalid identifiers): \"" + s +
                                         "\"");
            }
        }
    }
    return result;
}
constexpr size_t n_rows = 14;

constexpr std::string_view nlxreader_options_ = R"(
advanced:
    thread_core_range: [0, 0]
options:
    address: 0.0.0.0
    port: 5000
    batch_size: 1
    update_interval: 1
    channelmap:
        tt1: [0, 1, 2, 3]
        tt2: [4, 5, 6, 7]
        tt3: [8, 9, 10, 11]
        tt4: [12, 13, 14, 15]
        tt5: [16, 17, 18, 19]
        tt6: [20, 21, 22, 23]
        tt7: [24, 25, 26, 27]
        tt8: [28, 29, 30, 31]
        tt9: [32, 33, 34, 35]
        tt10: [36, 37, 38, 39]
        tt11: [40, 41, 42, 43]
        tt12: [44, 45, 46, 47]
        tt13: [48, 49, 50, 51]
        tt14: [52, 53, 54, 55]
        tt15: [56, 57, 58, 59]
        tt16: [60, 61, 62, 63]
        tt17: [64, 65, 66, 67]
        tt18: [68, 69, 70, 71]
        tt19: [72, 73, 74, 75]
        tt20: [76, 77, 78, 79]
        tt21: [80, 81, 82, 83]
        tt22: [84, 85, 86, 87]
        tt23: [88, 89, 90, 91]
        tt24: [92, 93, 94, 95]
        tt25: [96, 97, 98, 99]
        tt26: [100, 101, 102, 103]
        tt27: [104, 105, 106, 107]
        tt28: [108, 109, 110, 111]
        tt29: [112, 113, 114, 115]
        tt30: [116, 117, 118, 119]
        tt31: [120, 121, 122, 123]
        tt32: [124, 125, 126, 127]
)";

void ProcessorGraph::ConstructProcessorEnginesBench() {
    // 1st layer: NlxReader
    auto nlx_reader = ProcessorFactory::instance().create("NlxReader");
    nlx_reader->set_name_and_type("nlx_reader", "NlxReader");
    nlx_reader->internal_Configure(YAML::Load(std::string(nlxreader_options_)), global_context_);

    // 2nd layer : ChainProcessors with 7 MultiChannelFilter each
    auto chains = std::vector<std::unique_ptr<IProcessor>>();

    auto chain_cores = std::vector<int>{2, 4, 6, 8, 10, 12};

    for (int col = 1; col <= n_rows; ++col) {
        auto chain_processor = ProcessorFactory::instance().create("ChainProcessor");
        chain_processor->set_name_and_type("chain" + std::to_string(col), "ChainProcessor");

        auto thread_core_id = chain_cores[(col - 1) % chain_cores.size()];

        auto chain_options = std::string(
                                 "advanced:\n"
                                 "    thread_core_range: [") +
                             std::to_string(thread_core_id) + ", " + std::to_string(15) + "]\n";

        chain_processor->internal_Configure(YAML::Load(chain_options), global_context_);

        auto roman_numerals = std::vector<std::string>{"I", "II", "III", "IV", "V", "VI", "VII"};

        for (int pass = 1; pass <= 7; ++pass) {
            auto filter = ProcessorFactory::instance().create("MultiChannelFilter");
            filter->set_name_and_type("pass" + roman_numerals[pass - 1] + std::to_string(col),
                                      "MultiChannelFilter");
            filter->internal_Configure(YAML::Load("options:\n"
                                                  "    filter:\n"
                                                  "        type: fir\n"
                                                  "        description: all pass filter\n"
                                                  "        coefficients: [1]\n"),
                                       global_context_);
            filter->ExecutePrepare();
            chain_processor->insertChainProcessor(std::unique_ptr<IProcessor>(filter));
        }

        auto levelcross = ProcessorFactory::instance().create("LevelCrossingDetector");
        levelcross->set_name_and_type("levelcross" + std::to_string(col), "LevelCrossingDetector");
        levelcross->internal_Configure(YAML::Load("options:\n"
                                                  "    event: rising_edge\n"
                                                  "    threshold: 0.0\n"
                                                  "    upslope: true\n"
                                                  "    post_detect_block: 15\n"),
                                       global_context_);
        levelcross->ExecutePrepare();
        chain_processor->insertChainProcessor(std::unique_ptr<IProcessor>(levelcross));

        chains.push_back(std::unique_ptr<IProcessor>(chain_processor));
    }

    // 3th layer: EventSync
    auto event_sync = ProcessorFactory::instance().create("EventSync");
    event_sync->set_name_and_type("sync", "EventSync");
    event_sync->internal_Configure(YAML::Load("advanced:\n"
                                              "    thread_core_range: [14, 14]\n"
                                              "options:\n"
                                              "    target_event: rising_edge\n"),
                                   global_context_);

    // 4th layer: LatencyBenchmark
    auto latency_benchmark = ProcessorFactory::instance().create("LatencyBenchmark");
    latency_benchmark->set_name_and_type("bench", "LatencyBenchmark");
    latency_benchmark->internal_Configure(YAML::Load("advanced:\n"
                                                     "    thread_core_range: [15, 15]\n"),
                                          global_context_);

    processors_.try_emplace("nlx_reader", "NlxReader", std::unique_ptr<IProcessor>(nlx_reader));

    for (int i = 0; i < n_rows; ++i) {
        processors_.try_emplace("chain" + std::to_string(i + 1), "ChainProcessor",
                                std::move(chains[i]));
    }

    processors_.try_emplace("sync", "EventSync", std::unique_ptr<IProcessor>(event_sync));
    processors_.try_emplace("bench", "LatencyBenchmark",
                            std::unique_ptr<IProcessor>(latency_benchmark));
}

void ProcessorGraph::ParseConnectionRulesBench() {
    // connect nlx out to chain in
    for (int i = 1; i <= n_rows; ++i) {
        connections_.push_back(
            std::make_pair(SlotAddress("nlx_reader", "tt" + std::to_string(i), 0),

                           SlotAddress("chain" + std::to_string(i), "input", 0)));
    }

    // connect chain out to eventsync in
    for (int i = 1; i <= n_rows; ++i) {
        connections_.push_back(std::make_pair(SlotAddress("chain" + std::to_string(i), "output", 0),
                                              SlotAddress("sync", "events", i - 1)));
    }

    // connect sync out to benchmark in
    connections_.push_back(
        std::make_pair(SlotAddress("sync", "events", 0), SlotAddress("bench", "data", 0)));
}

void ProcessorGraph::ConstructProcessorEngines(const YAML::Node& node) {
    for (const auto& entry : node) {
        const auto raw_key = entry.first.as<std::string>();
        const auto& processor_node = entry.second;

        const auto names = expandProcessorName(raw_key);

        if (!processor_node["class"]) [[unlikely]] {
            throw InvalidProcessorError(
                std::format("No class specified for processor {}", raw_key));
        }

        const auto proc_class = processor_node["class"].as<std::string>();

        for (const auto& name : names) {
            auto [it, inserted] = processors_.try_emplace(name, proc_class, nullptr);
            auto& [existing_class, existing_ptr] = it->second;

            if (inserted) {
                try {
                    existing_ptr.reset(ProcessorFactory::instance().create(proc_class));
                } catch (const factory::UnknownClass&) {
                    throw InvalidProcessorError(std::format(
                        "Cannot create processor {} of unknown class {}.", name, proc_class));
                }

                existing_ptr->set_name_and_type(name, proc_class);
                existing_ptr->internal_Configure(processor_node, global_context_);
                LOG(DEBUG) << std::format("Constructed {}({}).", name, proc_class);

            } else {
                if (existing_class != proc_class) [[unlikely]] {
                    throw InvalidProcessorError(std::format("Class mismatch for {}: {} vs {}.",
                                                            name, existing_class, proc_class));
                }
                existing_ptr->internal_Configure(processor_node, global_context_);
            }
        }
    }
}

void ParseConnectionRules(const YAML::Node& node, StreamConnections& connections) {
    for (YAML::const_iterator it = node.begin(); it != node.end(); ++it) {
        expandConnectionRule(parseConnectionRule(it->as<std::string>()), connections);
        LOG(DEBUG) << "Parsed connection rule " << it->as<std::string>();
    }
}

ProcessorGraph::ProcessorGraph(GlobalContext& context)
    : global_context_(context), terminate_signal_(false) {
    LOG(STATE) << state_string();
    // log list of registered processors
    std::vector<std::string> processors = ProcessorFactory::instance().listEntries();
    for (const auto& item : processors) {
        documentation_[item] = LoadProcessorDoc(item);
        if (documentation_[item].IsMap() && documentation_[item]["Description"]) {
            LOG(INFO) << "Registered processor " << item << " - "
                      << documentation_[item]["Description"];
        } else {
            LOG(INFO) << "Registered processor " << item;
        }
    }
}

YAML::Node LoadProcessorDoc(std::string processor) {
    std::transform(processor.begin(), processor.end(), processor.begin(), ::tolower);
    std::string filename = DOC_PATH + processor + "/doc.yaml";
    YAML::Node node;
    try {
        return YAML::LoadFile(filename);
    } catch (YAML::BadFile& e) {
        return YAML::Load("No available documentation.\n");
    } catch (YAML::ParserException& e) {
        LOG(DEBUG) << processor << " - " << e.what();
        return YAML::Load("Error when parsing this documentation.\n");
    }
}

YAML::Node ProcessorGraph::GetProcessorDocumentation() {
    return documentation_;
}

std::string ProcessorGraph::state_string() const {
    return graph_state_string(state_);
}

IProcessor* ProcessorGraph::LookUpProcessor(const std::string& name) {
    if (processors_.count(name) == 0) {
        throw InvalidProcessorError("Processor \"" + name + "\" not found.");
    }
    return processors_[name].second.get();
}

std::vector<std::pair<std::string, std::shared_ptr<IState>>> ProcessorGraph::LookUpStates(
    const std::vector<std::string>& state_addresses) {
    std::vector<std::pair<std::string, std::shared_ptr<IState>>> states;

    for (auto& state_address : state_addresses) {
        // parse processor.state name
        std::vector<std::string> address = split(state_address, '.');

        if (address.size() != 2) {
            throw InvalidGraphError("Error parsing state address \"" + state_address + "\"");
        }

        // expand processor part of address
        auto expanded_processor = expandProcessorName(address[0]);

        for (auto& itv : expanded_processor) {
            IProcessor* processor = LookUpProcessor(itv);
            auto state = processor->shared_state(address[1]);  // fix error message when this fails

            states.push_back(std::make_pair(itv + "." + address[1], state));
        }
    }
    return states;
}

void ProcessorGraph::BuildSharedStates(const YAML::Node& node) {
    // states:
    //     - [processor.state, processor.state, ...]
    //     - group-name:
    //         permission: xxx
    //         description: xxx
    //         states: [...]
    //     - group-name: [...]

    std::vector<std::pair<std::string, std::shared_ptr<IState>>> states;
    std::string alias;
    Permission permission;
    std::string description;
    int group_index = 0;

    // loop through items in sequence:
    for (YAML::const_iterator link = node.begin(); link != node.end(); ++link) {
        ++group_index;

        description = "";
        permission = Permission::WRITE;

        if (link->IsSequence()) {
            alias = "alias_" + std::to_string(group_index);
            states = LookUpStates(link->as<std::vector<std::string>>());
        } else if (link->IsMap() && link->size() == 1 && link->begin()->second.IsSequence()) {
            alias = link->begin()->first.as<std::string>();
            states = LookUpStates(link->begin()->second.as<std::vector<std::string>>());
        } else if (link->IsMap() && link->size() == 1 && link->begin()->second.IsMap()) {
            alias = link->begin()->first.as<std::string>();
            description = link->begin()->second["description"].as<std::string>("");
            permission = permission_from_string(
                link->begin()->second["permission"].as<std::string>("unspecified"));
            states = LookUpStates(link->begin()->second["states"].as<std::vector<std::string>>());
        } else {
            throw InvalidGraphError("Error parsing linked state request.");
        }

        shared_state_map_.AddAlias(alias, permission, description);
        for (auto const& state : states) {
            shared_state_map_.ShareState(alias, state.first, state.second);
            LOG(DEBUG) << "Successfully linked state " << state.first << " to alias " << alias;
        }
    }
}

void ProcessorGraph::CreateConnection(SlotAddress& out, SlotAddress& in) {
    // get ProcessorEngine for output and input
    IProcessor *processor_out, *processor_in;
    try {
        processor_out = this->processors_.at(out.processor()).second.get();
    } catch (std::out_of_range& e) {
        throw std::out_of_range("Unknown processor \"" + out.processor() + "\"");
    }

    out.set_processor_class(processor_out->type());

    try {
        processor_in = this->processors_.at(in.processor()).second.get();
    } catch (std::out_of_range& e) {
        throw std::out_of_range("Unknown processor \"" + in.processor() + "\"");
    }

    in.set_processor_class(processor_in->type());

    // let engine prepare connections ( get default port, check port, reserve
    // slot, update address )
    processor_out->internal_PrepareConnectionOut(out);
    processor_in->internal_PrepareConnectionIn(in);

    // connect in to out, connect out to in
    processor_in->internal_ConnectIn(in, processor_out, out);

    try {
        processor_out->internal_ConnectOut(out, processor_in, in);
    } catch (...) {
        // internal error
        // in_connector_->Disconnect();
        throw std::runtime_error("Internal error: cannot connect to output slot");
    }
}

void ProcessorGraph::Build(const YAML::Node& node) {
    if (state_ != GraphState::NOGRAPH) {
        throw InvalidStateError("A graph has already been built. Destroy old graph first.");
    }

    if (!node["processors"] || !node["processors"].IsMap()) {
        throw InvalidGraphError("No processors found in graph definition.");
    }

    set_state(GraphState::CONSTRUCTING);

    try {
        ConstructProcessorEngines(node["processors"]);
        LOG(INFO) << "Constructed and configured all processors";
        // ConstructProcessorEnginesBench();
        // LOG(INFO) << "Constructed and configured static benchmark processors";

        for (auto& it : this->processors_) {
            it.second.second->internal_CreatePorts();
            LOG(DEBUG) << "Created ports for processor " << it.first;
        }
        LOG(INFO) << "All ports have been created.";

        if (node["connections"] && node["connections"].IsSequence()) {
            ParseConnectionRules(node["connections"], connections_);
            LOG(INFO) << "Parsed all connection rules.";
            // ParseConnectionRulesBench();
            // LOG(INFO) << "Constructed static benchmark connections.";

            for (auto& it : connections_) {
                CreateConnection(it.first, it.second);
                LOG(DEBUG) << "Established connection " << it.first.string(true) << "->"
                           << it.second.string(true);
            }
            LOG(INFO) << "All connections have been established.";
        }

        if (node["states"] && node["states"].IsSequence()) {
            BuildSharedStates(node["states"]);
            LOG(INFO) << "Linked all shared states.";
        }
    } catch (...) {
        Destroy();
        throw;
    }

    try {
        // negiotiate connections
        for (auto& it : this->processors_) {
            it.second.second->internal_NegotiateConnections();
            LOG(DEBUG) << "Negotiated data streams for processor " << it.first;
        }
        LOG(INFO) << "All data streams have been negotiated.";

        // build ringbuffers
        for (auto& it : this->processors_) {
            it.second.second->internal_CreateRingBuffers();
            LOG(DEBUG) << "Constructed ring buffer for processor " << it.first;
        }
    } catch (...) {
        Destroy();
        throw;
    }

    set_state(GraphState::PREPARING);

    // prepare processors
    try {
        for (auto& it : this->processors_) {
            it.second.second->Prepare(global_context_);
            LOG(DEBUG) << "Successfully prepared processor " << it.first;
        }
        LOG(INFO) << "All processors have been prepared.";
    } catch (...) {
        Destroy();
        throw;
    }

    yaml_ = node;
    LOG(INFO) << "Graph was successfully constructed.";
    set_state(GraphState::READY);
}

void ProcessorGraph::Destroy() {
    // can only destroy graph if state is CONSTRUCTING, PREPARING or READY
    if (state_ == GraphState::PROCESSING || state_ == GraphState::STARTING ||
        state_ == GraphState::STOPPING) {
        throw InvalidStateError("Cannot destroy graph while processing.");
    } else if (state_ == GraphState::NOGRAPH) {
        // nothing to destroy
        return;
    }

    if (state_ != GraphState::CONSTRUCTING) {
        // unprepare processors
        for (auto& it : this->processors_) {
            try {
                it.second.second->Unprepare(global_context_);
                LOG(DEBUG) << "Successfully unprepared processor " << it.first;
            } catch (...) {
                connections_.clear();
                processors_.clear();
                set_state(GraphState::NOGRAPH);
                throw InvalidGraphError(
                    "Error while unpreparing processors. Forced destruction of "
                    "graph. "
                    "Possible corruption of internal state.");
            }
        }
    }

    // destroy connections and processors
    shared_state_map_.clear();  // will unlink all states and remove groups
    connections_.clear();
    processors_.clear();  // will destroy processors and all their ports/states

    yaml_ = YAML::Null;
    LOG(INFO) << "Graph has been destroyed.";
    set_state(GraphState::NOGRAPH);
}

void ProcessorGraph::StartProcessing(const std::string& run_group_id, const std::string& run_id,
                                     const std::string& template_id, bool test_flag) {
    // start processing only if state is READY

    if (state_ == GraphState::READY) {
        run_context_.reset(new RunContext(global_context_, terminate_signal_, run_group_id, run_id,
                                          template_id, test_flag));

        set_state(GraphState::STARTING);

        // prepare all processors for processing
        // (i.e. flush buffers)
        for (auto& it : this->processors_) {
            it.second.second->internal_PrepareProcessing();
            LOG(DEBUG) << "Prepared data stream ports of processor " << it.first;
        }
        LOG(INFO) << "Prepared all data stream ports for processing.";

        try {
            // loop through all processors
            for (auto& it : this->processors_) {
                it.second.second->internal_Start(*run_context_);
                LOG(DEBUG) << "Started thread for processor " << it.first;
            }
            LOG(INFO) << "Started all processors.";
        } catch (...) {
            StopProcessing();
            throw;
        }

        // wait until all processors are in running state
        while (!all_processors_running()) {
            if (run_context_->terminated()) {
                // processor terminated during preparation or preprocessing
                // other processors need to be unlocked still
                break;
            }
        }

        // all processors have either passed the preprocessing step
        // or have terminated with error, which will be dealt with in
        // graphmanager::run let's signal everyone to GO
        {
            std::unique_lock<std::mutex> lock(run_context_->mutex);
            run_context_->go_signal = true;
            run_context_->go_condition.notify_all();
        }

        set_state(GraphState::PROCESSING);

    } else if (state_ == GraphState::NOGRAPH || state_ == GraphState::CONSTRUCTING ||
               state_ == GraphState::PREPARING) {
        throw InvalidStateError("Graph is not yet assembled.");
    }
}

void ProcessorGraph::StopProcessing() {
    if (state_ == GraphState::PROCESSING || state_ == GraphState::STARTING) {
        set_state(GraphState::STOPPING);

        if (run_context_->error()) {
            LOG(ERROR) << "Processing terminated with error. " << run_context_->error_message();
        }

        // signal stop
        run_context_->Terminate();

        // alert waiting processors
        for (auto& it : this->processors_) {
            it.second.second->internal_Alert();
        }
        // join processor threads
        for (auto& it : this->processors_) {
            it.second.second->internal_Stop();
        }

        LOG(INFO) << "Stopped all processors.";
        LOG(INFO) << "Graph was processing for " << std::to_string(run_context_->seconds())
                  << " seconds";

        run_context_.reset();
        terminate_signal_.store(false);

        set_state(GraphState::READY);

    } else if (state_ == GraphState::NOGRAPH || state_ == GraphState::CONSTRUCTING ||
               state_ == GraphState::PREPARING) {
        throw InvalidStateError("Graph is not yet assembled.");
    } else {  // READY, STOPPING
              // pass
    }
}

void ProcessorGraph::Update(YAML::Node& node) {
    // YAML
    // shared-state: value
    // processor: {state: value}

    // make sure node is a map
    if (!node.IsMap()) {
        throw InvalidProcessorError("No valid map with states found.");
    }

    // loop through all keys
    for (YAML::iterator it = node.begin(); it != node.end(); ++it) {
        std::string key = it->first.as<std::string>();

        if (it->second.IsMap()) {
            // find corresponding processor engine
            if (processors_.count(key) == 0) {
                LOG(ERROR) << "No processor named " << key;
                continue;
            }

            IProcessor* processor = processors_[key].second.get();

            // loop through states
            for (YAML::iterator it2 = it->second.begin(); it2 != it->second.end(); ++it2) {
                try {
                    auto state_name = it2->first.as<std::string>();
                    auto state_value = it2->second.as<std::string>();

                    auto pstate = processor->shared_state(state_name);

                    // check if externally settable??
                    if (pstate->external_permission() == Permission::WRITE) {
                        // set from string
                        it2->second = pstate->set_string(state_value);
                    } else {
                        throw std::runtime_error((std::ostringstream{}
                                                  << "Shared state " << state_name
                                                  << " on processor " << key
                                                  << " can not be controlled externally.")
                                                     .str());
                    }
                    LOG(UPDATE) << "State " << key << "." << state_name << " set to "
                                << state_value;
                } catch (std::exception& e) {
                    it2->second = false;
                    LOG(ERROR) << "Unable to update state value: " << e.what();
                }
            }
        } else {  // key points to shared state alias
            try {
                auto state_value = it->second.as<std::string>();
                it->second = shared_state_map_.UpdateAlias(key, state_value);
                LOG(UPDATE) << "Alias state " << key << " set to " << state_value;
            } catch (std::exception& e) {
                it->second = false;
                LOG(ERROR) << "Unable to update state value: " << e.what();
            }
        }
    }
}

void ProcessorGraph::Retrieve(YAML::Node& node) {
    // YAML
    // processor:
    //    state: <null>

    // make sure node is a map
    if (!node.IsMap()) {
        throw InvalidProcessorError("No valid map with states found.");
    }

    // loop through all keys
    for (YAML::iterator it = node.begin(); it != node.end(); ++it) {
        std::string key = it->first.as<std::string>();

        if (it->second.IsMap()) {
            // find corresponding processor engine
            if (processors_.count(key) == 0) {
                LOG(ERROR) << "No processor named " << key;
                continue;
            }

            IProcessor* processor = processors_[key].second.get();

            // loop through states
            for (YAML::iterator it2 = it->second.begin(); it2 != it->second.end(); ++it2) {
                try {
                    auto state_name = it2->first.as<std::string>();

                    auto pstate = processor->shared_state(state_name);
                    if (pstate->external_permission() != Permission::NONE) {
                        it2->second = pstate->get_string();
                    } else {
                        throw std::runtime_error((std::ostringstream{}
                                                  << "Shared state " << state_name
                                                  << " on processor " << key
                                                  << " can not be read externally.")
                                                     .str());
                    }
                } catch (std::exception& e) {
                    it2->second = YAML::Null;
                    LOG(ERROR) << "Unable to retrieve state value: " << e.what();
                }
            }
        } else {  // key points to shared state alias
            try {
                it->second = shared_state_map_.RetrieveAlias(key);
            } catch (std::exception& e) {
                it->second = YAML::Null;
                LOG(ERROR) << "Unable to retrieve state value: " << e.what();
            }
        }
    }
}

void ProcessorGraph::Apply(YAML::Node& node) {
    // YAML
    // falcon:
    //   version: 1.0
    // graph:
    //      processor:
    //       method:
    //          parameter: value

    if (!node.IsMap()) {
        throw InvalidProcessorError("No processors found in method definition.");
    }
    // loop through all processors, make sure value is another map
    for (YAML::iterator it = node.begin(); it != node.end(); ++it) {
        std::string processor_name = it->first.as<std::string>();

        if (!it->second.IsMap()) {
            LOG(ERROR) << "Invalid method definition for processor " << processor_name;
            continue;
        }
        // find corresponding processor engine
        if (processors_.count(processor_name) == 0) {
            LOG(ERROR) << "In method definition: no processor named " << processor_name;
            continue;
        }

        IProcessor* processor = processors_[processor_name].second.get();

        // loop through all states
        for (YAML::iterator it2 = it->second.begin(); it2 != it->second.end(); ++it2) {
            try {
                it2->second =
                    processor->internal_ApplyMethod(it2->first.as<std::string>(), it2->second);
            } catch (std::exception& e) {
                it2->second = YAML::Null;
                LOG(ERROR) << "Unable to apply method: " << e.what();
            }
        }
    }
}

std::string ProcessorGraph::ExportYAML() {
    std::string s = "";
    YAML::Node node;
    YAML::Emitter out;
    node["falcon"]["version"] = 1.0;
    if (state_ != GraphState::NOGRAPH) {
        for (YAML::const_iterator it = yaml_["processors"].begin(); it != yaml_["processors"].end();
             ++it) {
            std::vector<std::string> processor_list =
                expandProcessorName(it->first.as<std::string>());

            for (auto& name : processor_list) {
                node["graph"]["processors"][name] = this->processors_[name].second->ExportYAML();
                node["graph"]["processors"][name]["class"] = this->processors_[name].first;

                if (yaml_["processors"][it->first]["options"]) {
                    node["graph"]["processors"][name]["options"] =
                        yaml_["processors"][it->first]["options"];
                }

                if (yaml_["processors"][it->first]["advanced"]) {
                    node["graph"]["processors"][name]["advanced"] =
                        yaml_["processors"][it->first]["advanced"];
                }
            }
        }

        for (auto& it : this->connections_) {
            node["graph"]["connections"].push_back(it.first.string() + "=" + it.second.string());
        }

        node["graph"]["states"] = shared_state_map_.ExportYAML();

        out << node;
        s = out.c_str();
    }
    return s;
}
