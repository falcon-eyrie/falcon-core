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

#include <cstring>
#include <exception>
#include <map>
#include <memory>
#include <string>
#include <utility>
#include <vector>

#include "connectionparser.hpp"
#include "graphexceptions.hpp"
#include "iprocessor.hpp"
#include "logging/log.hpp"
#include "runinfo.hpp"
#include "yaml-cpp/yaml.h"

/**
 * Get processor's documentation.
 *
 * The processor's doc is reading from the doc.yaml file placed in the processor
 *folder. if not existing, it will return a default value: "No documentation
 *found"
 *
 *@param processor string name of the processor targeted
 *@return documentation
 */
YAML::Node LoadProcessorDoc(std::string processor);

namespace graph {

enum class GraphState {
    NOGRAPH,
    CONSTRUCTING,
    PREPARING,
    READY,
    STARTING,
    PROCESSING,
    STOPPING,
    ERROR
};

class ProcessorGraph {
  public:
    ProcessorGraph(GlobalContext &context);

    bool terminated() { return terminate_signal_.load(); }

    bool done() {
        // graph is done, if it has terminated or PROCESSING and no processor is
        // running
        if (state_ != GraphState::PROCESSING) {
            return false;
        }

        if (terminated()) {
            LOG(DEBUG) << "done: terminated=true.";
            return true;
        }

        return !any_processor_running();
    }

    bool all_processors_running() {
        for (auto &it : processors_) {
            if (!it.second.second->running()) {
                return false;
            }
        }
        return true;
    }
    bool any_processor_running() {
        for (auto &it : processors_) {
            if (it.second.second->running()) {
                return true;
            }
        }
        return false;
    }

    /**
     * Construct processors listed in the graph yaml description.
     *
     * Looping through the graph description to find every processor, expanded
     *their name, create their instance and run the internal configuration for
     *each.
     *
     *@param node graph description
     */
    void ConstructProcessorEngines(const YAML::Node &node);

    /**
     * Give the documentation of either all registered processor or only
     * processors used in the running graph
     */
    YAML::Node GetProcessorDocumentation();

    /**
     * Build the graph
     *
     *Construct all processors, parse and create connections between them and
     *create shared state.
     *@param node graph description
     */
    void Build(const YAML::Node &node);
    void Destroy();
    void StartProcessing(std::string run_group_id, std::string run_id,
                         std::string template_id, bool test_flag);
    void StopProcessing();
    /**
     *Update processor's shared state with input from the user
     *
     *@param node graph description
     */
    void Update(YAML::Node &node);
    /**
     *Retrieve the state value for all shared state name given in the yaml node.
     *
     *@param node shared state description
     */
    void Retrieve(YAML::Node &node);
    /**
     *Apply exposed methods with parameters given in the yaml node
     *
     *@param node exposed method description
     */
    void Apply(YAML::Node &node);

    std::string ExportYAML();

    const GraphState state() const { return state_; }
    std::string state_string() const;
    void set_state(GraphState state) {
        state_ = state;
        LOG(STATE) << state_string();
    }

    const ProcessorMap &processors() const { return processors_; }
    const StreamConnections &connections() const { return connections_; }

    IProcessor *LookUpProcessor(std::string name);
    std::vector<std::pair<std::string, std::shared_ptr<IState>>>
    LookUpStates(std::vector<std::string> state_addresses);

    void BuildSharedStates(const YAML::Node &node);

  protected:
    void CreateConnection(SlotAddress &out, SlotAddress &in);

  private:
    YAML::Node yaml_;
    YAML::Node documentation_;

    GlobalContext &global_context_;

    ProcessorMap processors_;
    StreamConnections connections_;

    SharedStateMap shared_state_map_;

    GraphState state_ = GraphState::NOGRAPH;

    std::unique_ptr<RunContext> run_context_;
    std::atomic<bool> terminate_signal_;
};

} // namespace graph
