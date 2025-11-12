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

#include "utilities/keyboard.hpp"
#include <cstring>
#include <deque>
#include <string>
#include <zmq.hpp>

namespace commands {

class CommandSource {
  public:
    virtual bool getcommand(std::deque<std::string> &command) { return false; }
    virtual bool sendreply(const std::deque<std::string> &command,
                           std::deque<std::string> &reply) {
        return false;
    }
};

class CommandLineCommands : public CommandSource {
  public:
    void AddCommand(std::deque<std::string> command);
    bool getcommand(std::deque<std::string> &command);
    bool sendreply(const std::deque<std::string> &command,
                   std::deque<std::string> &reply);

  protected:
    std::deque<std::deque<std::string>> queued_commands_;
};

class KeyboardCommands : public CommandSource {
  public:
    KeyboardCommands();
    ~KeyboardCommands();

    bool getcommand(std::deque<std::string> &command);
    bool sendreply(const std::deque<std::string> &command,
                   std::deque<std::string> &reply);
};

class ZMQCommands : public CommandSource {
  public:
    zmq::socket_t *socket;

    ZMQCommands(zmq::context_t &context, int port);
    ~ZMQCommands();

    bool getcommand(std::deque<std::string> &command);
    bool sendreply(const std::deque<std::string> &command,
                   std::deque<std::string> &reply);
};
} // namespace commands
