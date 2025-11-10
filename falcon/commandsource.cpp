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

#include "commandsource.hpp"
#include "utilities/general.hpp"
#include "utilities/keyboard.hpp"
#include "utilities/zmqutil.hpp"
#include <cstdlib>
#include <iostream>
#include <string>

using namespace commands;

void CommandLineCommands::AddCommand(std::deque<std::string> command) {
    queued_commands_.push_back(command);
}

bool CommandLineCommands::getcommand(std::deque<std::string> &command) {
    if (queued_commands_.size() == 0) {
        return false;
    }

    command = queued_commands_[0];
    queued_commands_.pop_front();

    std::cout << "\ncommand line command: ";

    for (auto &it : command) {
        std::cout << it << " ";
    }

    return true;
}

bool CommandLineCommands::sendreply(const std::deque<std::string> &command,
                                    std::deque<std::string> &reply) {
    if (reply.size() == 0 || reply[0] == "OK") {
        return true;
    }

    std::cout << std::endl
              << join(reply.begin(), reply.end(), std::string(" "))
              << std::flush;

    return true;
}

KeyboardCommands::KeyboardCommands() {
    s_catch_sigint_signal(); // Install Ctrl-C signal handler
    nonblock(1);
}

KeyboardCommands::~KeyboardCommands() { nonblock(0); }

bool KeyboardCommands::getcommand(std::deque<std::string> &command) {
    int hit;
    char c;

    hit = kbhit();

    // check it was CTRL-C
    if (s_interrupted) {
        command.push_back("kill");
        return true;
    }

    if (hit != 0) {
        // get key
        c = getchar();

        // parse command
        if (c == 'q' || c == 'Q') {
            command.push_back("quit");
        } else if (c == 'd' || c == 'D') {
            command.push_back("documentation");
        } else if (c == 'i' || c == 'I') {
            command.push_back("info");
        } else if (c == 'r' || c == 'R') {
            command.push_back("graph");
            command.push_back("start");
        } else if (c == 't' || c == 'T') {
            command.push_back("graph");
            command.push_back("test");
        } else if (c == 's' || c == 'S') {
            command.push_back("graph");
            command.push_back("stop");
        } else if (c == 'k' || c == 'K') {
            command.push_back("kill");
        } else if (c == 'y' || c == 'Y') {
            command.push_back("graph");
            command.push_back("yaml");
        } else {
            return false;
        }
        std::cout << "\nkey command: ";

        for (auto &it : command) {
            std::cout << it << " ";
        }
        return true;
    }
    return false;
}

bool KeyboardCommands::sendreply(const std::deque<std::string> &command,
                                 std::deque<std::string> &reply) {
    if (reply.size() == 0 || reply[0] == "OK") {
        return true;
    }

    std::cout << std::endl
              << join(reply.begin(), reply.end(), std::string(" "))
              << std::flush;

    return true;
}

ZMQCommands::ZMQCommands(zmq::context_t &context, int port) {
    socket = new zmq::socket_t(context, ZMQ_REP);
    char buffer[15];
    snprintf(buffer, 14, "tcp://*:%d", port);
    socket->bind(buffer);
}

ZMQCommands::~ZMQCommands() { delete socket; }

bool ZMQCommands::getcommand(std::deque<std::string> &command) {
    return s_nonblocking_recv_multi(*socket, command);
}

bool ZMQCommands::sendreply(const std::deque<std::string> &command,
                            std::deque<std::string> &reply) {
    return s_send_multi(*socket, reply);
}
