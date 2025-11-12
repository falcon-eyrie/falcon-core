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
#include <unistd.h>

#include "graphmanager.hpp"
#include "logging/log.hpp"
#include "utilities/general.hpp"
#include "utilities/zmqutil.hpp"

using namespace graph;

GraphManager::GraphManager(GlobalContext &context)
    : global_context_(&context), graph_(context) {}

void GraphManager::HandleCommand(std::string command,
                                 std::deque<std::string> &extra,
                                 std::deque<std::string> &reply) {
    if (command == "build") {
        if (extra.size() < 1) {
            throw std::runtime_error("Missing YAML graph definition.");
        }
        YAML::Node node = YAML::Load(extra[0]);

        if (!node.IsMap()) {
            std::string file = node.as<std::string>();
            file = global_context_->resolve_path(file, "graphs");
            try {
                node = YAML::LoadFile(file);
            } catch (YAML::BadFile &e) {
                throw std::runtime_error(
                    "Cannot open YAML graph definition file " + file +
                    ". Check if file actually exists.");
            }
        }
        ParseGraph(node);
        // save YAML to global_context_.resolve_path( "graphs://_last_graph" )
        std::ofstream fout(
            global_context_->resolve_path("graphs://_last_graph.yaml"));
        fout << node;

    } else if (command == "destroy") {
        graph_.Destroy();
    } else if (command == "start" || command == "test") {
        std::string run_env = extra.size() > 0 ? extra[0] : "";
        std::string destination = extra.size() > 1 ? extra[1] : "";
        std::string source = extra.size() > 2 ? extra[2] : "";
        graph_.StartProcessing(run_env, destination, source,
                               command == "test" || global_context_->test());
    } else if (command == "stop") {
        graph_.StopProcessing();
    } else if (command == "state") {
        reply.push_back(graph_.state_string());
    } else if (command == "update") {
        if (extra.size() > 0) {
            YAML::Node node = YAML::Load(extra[0]);
            graph_.Update(node);
            YAML::Emitter out;
            out << node;
            reply.push_back(std::string(out.c_str()));
        }
    } else if (command == "retrieve") {
        if (extra.size() > 0) {
            YAML::Node node = YAML::Load(extra[0]);
            graph_.Retrieve(node);
            YAML::Emitter out;
            out << node;
            reply.push_back(std::string(out.c_str()));
        }
    } else if (command == "apply") {
        if (extra.size() > 0) {
            YAML::Node node = YAML::Load(extra[0]);
            graph_.Apply(node);
            YAML::Emitter out;
            out << node;
            reply.push_back(std::string(out.c_str()));
        }
    } else if (command == "documentation") {
        YAML::Node docs = graph_.GetProcessorDocumentation();
        YAML::Emitter out;
        out << docs;
        reply.push_back(std::string(out.c_str()));
    } else if (command == "yaml") {
        reply.push_back(graph_.ExportYAML());
    } else {
        throw std::runtime_error("Unknown graph command \"" + command + "\".");
    }
}

void GraphManager::ParseGraph(YAML::Node &node) {
    if (node["graph"]) {
        if (node["processors"]) {
            LOG(WARNING)
                << "Detected mixed use of old and new style graph definition."
                   " Only the new style graph definition will be used and "
                   "top-level "
                   "processors, connections"
                   " and states maps will be ignored.";
        }

        if (!node["graph"].IsMap()) {
            std::string graph_template_path =
                global_context_->resolve_path(node["graph"].as<std::string>());
            try {
                node["graph"] = YAML::LoadFile(graph_template_path);
            } catch (YAML::BadFile &e) {
                throw std::runtime_error(
                    "Cannot open YAML graph template definition file " +
                    graph_template_path + ". Check if file actually exists.");
            }
        }

        if (node["options"]) {
            YAML::Node options_node;
            if (!node["options"].IsMap()) {
                std::string graph_options_path = global_context_->resolve_path(
                    node["options"].as<std::string>());

                try {
                    options_node = YAML::LoadFile(graph_options_path);
                } catch (YAML::BadFile &e) {
                    throw std::runtime_error(
                        "Cannot open YAML graph options definition file " +
                        graph_options_path +
                        ". Check if file actually exists.");
                }

            } else {
                options_node = node["options"];
            }

            for (YAML::const_iterator it = options_node.begin();
                 it != options_node.end(); ++it) {
                std::string processor_name = it->first.as<std::string>();
                if (!node["graph"]["processors"][processor_name]) {
                    throw std::runtime_error("Mismatch between the options "
                                             "graph and the template graph.");
                }

                for (YAML::const_iterator options_type_it = it->second.begin();
                     options_type_it != it->second.end(); ++options_type_it) {
                    for (YAML::const_iterator options_it =
                             options_type_it->second.begin();
                         options_it != options_type_it->second.end();
                         ++options_it) {
                        std::string processor_option_name =
                            options_it->first.as<std::string>();
                        node["graph"]["processors"][processor_name]
                            [options_type_it->first.as<std::string>()]
                            [processor_option_name] = options_it->second;
                    }
                }
            }
        }
        graph_.Build(node["graph"]);
    } else if (node["processors"]) {
        LOG(WARNING)
            << "The graph definition seems to have the server-side format. "
               "Consider to use a user-side format to override options.";
        graph_.Build(node);
    } else {
        throw std::runtime_error("Invalid graph description.");
    }
}

void GraphManager::Run() {
    // initialize
    zmq::socket_t socket(global_context_->zmq(), ZMQ_REP);
    socket.bind("inproc://graph");

    zmq_frames request;
    zmq_frames reply;

    while (!terminated()) {
        // sleep a bit, since we are continuously polling
        usleep(1000); // 1 msec

        // process commands
        request.clear();
        if (s_nonblocking_recv_multi(socket, request)) {
            // handle command

            reply.clear();

            std::string command = request[0];
            request.pop_front();

            LOG(DEBUG) << "GraphManager received command \"" << command << "\"";

            try {
                HandleCommand(command, request, reply);

                if (reply.size() == 0) {
                    reply.push_back("OK");
                }
            } catch (GraphException &e) {
                if (e.isFatal()) {
                    reply.push_back("ERR");
                } else {
                    reply.push_back("WARN");
                }
                reply.push_back(e.gettype());
                reply.push_back(e.what());

                LOG(ERROR) << "Error handling command: " << command
                           << " Error type: " << e.gettype()
                           << "  Error: " << e.what();
            } catch (std::exception &e) {
                reply.push_back("ERR");
                reply.push_back("exception");
                reply.push_back(e.what());

                LOG(ERROR) << "Error handling command: " << command
                           << " Error: " << e.what();
            } catch (...) {
                reply.push_back("ERR");
                reply.push_back("Unknown");
                reply.push_back("Unknown error.");

                LOG(ERROR) << "Error handling command: " << command;
            }

            // reply
            s_send_multi(socket, reply);

            LOG(DEBUG) << "GraphManager replied to command \"" << command
                       << "\" with \""
                       << join(reply.begin(), reply.end(), std::string(" | "))
                       << "\"";
        }

        // check if graph processing was terminated by a processor
        // or if all processors are done and waiting to be killed
        if (graph_.done()) {
            LOG(DEBUG) << "Processing is done.";
            graph_.StopProcessing();
        }
    }

    // finish
}
