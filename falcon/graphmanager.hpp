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

#include <deque>
#include <string>
#include <thread>

#include "context.hpp"
#include "processorgraph.hpp"

namespace graph {

class GraphManager {
  public:
    GraphManager(GlobalContext &context);
    ~GraphManager() { stop(); }

    void stop() {
        terminate_ = true;
        thread_.join();
    }

    void start() {
        terminate_ = false;
        thread_ = std::thread(&GraphManager::Run, this);
    }
    bool terminated() const { return terminate_; }

  private:
    std::thread thread_;

    void Run();
    bool terminate_ = false;
    GlobalContext *global_context_;

    void HandleCommand(std::string command, std::deque<std::string> &extra,
                       std::deque<std::string> &reply);
    void ParseGraph(YAML::Node &node);

    ProcessorGraph graph_;
};
} // namespace graph
