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
#include <vector>

#include "commandsource.hpp"
#include "context.hpp"

namespace commands {

class CommandHandler {
  public:
    CommandHandler(GlobalContext &context) { global_context_ = &context; }

    /**
     * Add a source to receive commands from it (example: cloud/zmq, command
     * line, keyboard)
     *
     * @param source class defining the source of commands derived from
     * CommandSource
     */
    void addSource(CommandSource &source) { sources_.push_back(&source); }

    /**
     * Receive commands and delegate to the graph thread in case of a graph
     * command or handle it directly
     *
     * @param command
     * @param reply  buffer for the answer from the graph socket
     * @return if falcon should be safely (closing all threads) terminated
     */
    bool HandleCommand(std::deque<std::string> &command,
                       std::deque<std::string> &reply);
    /**
     * Send commands to the graph thread via it graph socket
     *
     * @param command keyword send to the graph thread
     * @param reply  buffer for the answer from the graph socket
     * @return always false - no command to the graph can terminate the main
     * thread
     */
    bool DelegateGraphCommand(std::deque<std::string> &command,
                              std::deque<std::string> &reply);

    /**
     * Manage sub-command for the resources command
     *
     * @param sub-command keyword
     * @param reply  buffer for the answer from the graph socket
     * @return always false - no resources command can terminate the main thread
     */
    bool DelegateResourcesCommand(std::deque<std::string> &command,
                                  std::deque<std::string> &reply);

    /**
     * Once start is launched the main thread is busy only listening, processing
     * and replying to messages coming from listed sources
     */
    void start();

  private:
    typedef std::vector<CommandSource *> VectSources;
    VectSources sources_;
    GlobalContext *global_context_;
    zmq::socket_t *graph_socket_;
};
} // namespace commands
