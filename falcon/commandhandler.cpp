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
#include <deque>
#include <regex>
#include <unistd.h>

#include "buildconstant.hpp"
#include "commandhandler.hpp"
#include "utilities/filesystem.hpp"
#include "utilities/zmqutil.hpp"
#include "yaml-cpp/yaml.h"

using namespace commands;

bool CommandHandler::DelegateGraphCommand(std::deque<std::string> &command,
                                          std::deque<std::string> &reply) {
    // delegate
    s_send_multi(*graph_socket_, command);
    // get reply
    reply = s_blocking_recv_multi(*graph_socket_);

    return false;
}

bool CommandHandler::DelegateResourcesCommand(std::deque<std::string> &command,
                                              std::deque<std::string> &reply) {

    std::string resources_type;

    if (command[0] == "list") {

        if (command.size() == 2)
            resources_type = command[1] + "://";
        else
            resources_type = "resources://";

        try {
            std::string resource_path =
                global_context_->resolve_path(resources_type);
            std::vector<std::string> list_files =
                getAllFilesInDir(resource_path);
            for (auto const &file : list_files) {
                reply.push_back(std::regex_replace(
                    file, std::regex(resource_path), resources_type));
            }

        } catch (YAML::BadFile &e) {
            reply.push_back("ERR");
            reply.push_back("Unknown resources type requested \"" +
                            resources_type + "\".");
            return false;
        }

    } else if (command[0] == "graphs") {
        try {
            std::string graph_path = global_context_->resolve_path(command[1]);
            YAML::Node node;
            node["falcon"]["version"] = "1.0.0";
            node["graph"] = YAML::LoadFile(graph_path);
            YAML::Emitter out;
            out << node;
            reply.push_back(std::string(out.c_str()));
        } catch (YAML::BadFile &e) {
            reply.push_back("ERR");
            reply.push_back("Invalid graph file");
        }
    } else {
        // error
        reply.push_back("ERR");
        reply.push_back("Unknown resources command \"" + command[0] + "\".");
    }
    return false;
}

bool CommandHandler::HandleCommand(std::deque<std::string> &command,
                                   std::deque<std::string> &reply) {
    bool finished = false;

    std::deque<std::string> local_command;
    std::deque<std::string> local_reply;

    if (command.empty()) {
        return finished;
    }
    if (command[0] == "graph") {
        // delegate
        command.pop_front();
        finished = DelegateGraphCommand(command, reply);
    } else if (command[0] == "resources") {
        command.pop_front();
        finished = DelegateResourcesCommand(command, reply);
    } else if (command[0] == "documentation") {
        local_command.push_back("documentation");
        finished = DelegateGraphCommand(local_command, reply);
    } else if (command[0] == "test") {
        if (command.size() > 1) {
            if (command[1] == "true" || command[1] == "on") {
                global_context_->set_test(true);
                reply.push_back("OK");
            } else if (command[1] == "false" || command[1] == "off") {
                global_context_->set_test(false);
                reply.push_back("OK");
            } else {
                reply.push_back("ERR");
                reply.push_back("Invalid argument for test command");
            }
        } else {
            // toggle test flag
            global_context_->set_test(!global_context_->test());
            reply.push_back("OK");
        }
    } else if (command[0] == "quit" || command[0] == "kill") {
        local_command.push_back("state");
        DelegateGraphCommand(local_command, local_reply);

        if (local_reply[0] == "PROCESSING" && command[0] == "quit") {
            // error
            reply.push_back("ERR");
            reply.push_back("Cannot quit while graph is processing.");
        } else {
            if (local_reply[0] == "PROCESSING") {
                local_command.back() = "stop";
                DelegateGraphCommand(local_command, local_reply);
            }
            local_command.back() = "destroy";
            DelegateGraphCommand(local_command, local_reply);
            reply.push_back("OK");
            finished = true;
        }
    } else if (command[0] == "info") {
        local_command.push_back("state");
        DelegateGraphCommand(local_command, local_reply);

        YAML::Emitter out;
        out << YAML::BeginMap;
        out << YAML::Key << "Falcon version" << YAML::Value << GIT_REVISION;
        out << YAML::Key << "run_environment_root" << YAML::Value
            << global_context_->storage_context("runroot");
        out << YAML::Key << "resource_root" << YAML::Value
            << global_context_->storage_context("resources");
        out << YAML::Key << "graph_state" << YAML::Value << local_reply[0];
        out << YAML::Key << "default_test_flag" << YAML::Value
            << global_context_->test();

        reply.push_back(std::string(out.c_str()));
    } else {
        // error
        reply.push_back("ERR");
        reply.push_back("Unknown command \"" + command[0] + "\".");
    }
    return finished;
}

void CommandHandler::start() {
    if (sources_.size() == 0) {
        return;
    }

    // connect to graph thread
    // construct socket here, so that it is automatically destructed when this
    // function ends
    zmq::socket_t socket(global_context_->zmq(), ZMQ_REQ);
    socket.connect("inproc://graph");

    // save pointer to socket, so that DelegateGraphCommand can use it
    graph_socket_ = &socket;

    bool finished = false;
    std::deque<std::string> command;
    std::deque<std::string> reply;

    while (!finished) {
        usleep(100000); // 0.1 second

        // iterate through sources
        for (auto &it : sources_) {
            // retrieve command
            command.clear();

            if (it->getcommand(command)) {
                reply.clear();
                finished = HandleCommand(command, reply);
                it->sendreply(command, reply);
            }

            if (finished) {
                break;
            }
        }
    }

    graph_socket_ = nullptr;
}
