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

#include <cstdlib>
#include <deque>
#include <exception>
#include <iostream>
#include <regex>
#include <string>

#include "buildconstant.hpp"
#include "cmdline/cmdline.h"
#include "commandhandler.hpp"
#include "commandsource.hpp"
#include "configuration.hpp"
#include "context.hpp"
#include "graphmanager.hpp"
#include "logging/customsink.hpp"
#include "logging/log.hpp"
#include "options/units.hpp"
#include "utilities/time.hpp"

using namespace std;

int main(int argc, char **argv) {

    // create a parser
    cmdline::parser parser;

    // add specified type of variable.
    // 1st argument is long name
    // 2nd argument is short name (no short name if '\0' specified)
    // 3rd argument is description
    // 4th argument is mandatory (optional. default is false)
    // 5th argument is default value  (optional. it used when mandatory is
    // false)
    parser.add<string>("config", 'c', "configuration file", false,
                       "$HOME/.config/falcon/config.yaml");
    parser.add("autostart", 'a', "auto start processing (needs graph)");
    parser.add("debug", 'd', "show debug messages");
    parser.add("noscreenlog", '\0', "disable logging to screen");
    parser.add("nocloudlog", '\0', "disable logging to cloud");
    parser.add("test", 't', "turn testing on by default");
    parser.add("version", 'v', "Show the falcon version number and exit.");
    parser.footer("[graph file] ...");
    // Run parser
    // It returns only if command line arguments are valid.
    // If arguments are invalid, a parser output error msgs then exit program.
    // If help flag ('--help' or '-?') is specified, a parser output usage
    // message then exit program.
    parser.parse_check(argc, argv);

    if (parser.exist("version")) {
        std::cout << "Falcon " << GIT_REVISION << std::endl;
        std::cout << "Last build: " << BUILD_TIMESTAMP << std::endl;
        std::cout << "Configuration: " << BUILD_TYPE << std::endl;
        std::cout << "Extensions: " << std::endl;

        std::vector<std::string> extensions = split(EXTENSIONS_BUILD, ';');
        for (auto it : extensions) {
            std::cout << it << std::endl;
        }
        return EXIT_SUCCESS;
    }
    // create default configuration
    FalconConfiguration config;

    // add custom units
    units::addUserDefinedUnit("sample", units::precise::sample_units);
    units::addUserDefinedUnit("spike", units::precise::spike_units);

    // load configuration file
    try {
        config.load(parser.get<std::string>("config"));
    } catch (std::runtime_error &e) {
        std::cout << e.what() << std::endl;
        std::cout << "Falcon terminated." << std::endl;
        return EXIT_FAILURE;
    }

    // apply command line arguments
    if (parser.exist("autostart")) {
        config.graph_autostart = true;
    }
    if (parser.exist("debug")) {
        config.debug_enabled = true;
    }
    if (parser.exist("noscreenlog")) {
        config.logging_screen_enabled = false;
    }
    if (parser.exist("nocloudlog")) {
        config.logging_cloud_enabled = false;
    }
    if (parser.exist("test")) {
        config.testing_enabled = true;
    }

    // add default URIs
    config.server_side_storage_custom["resources"] =
        config.server_side_storage_resources();
    config.server_side_storage_custom["graphs"] =
        config.server_side_storage_resources() + "/graphs";
    config.server_side_storage_custom["filters"] =
        config.server_side_storage_resources() + "/filters";
    config.server_side_storage_custom["runroot"] =
        config.server_side_storage_environment();

    GlobalContext context(config.testing_enabled(),
                          config.server_side_storage_custom());

    // set up loggers
    // file logger
    char *home = getenv("HOME");
    std::regex re("(\\$HOME|~)");
    std::string logpath = std::regex_replace(config.logging_path(), re, home);

    auto worker = g3::LogWorker::createLogWorker();
    auto defaultHandler = worker->addDefaultLogger("falcon", logpath);

    // initialize logging before creating additional loggers
    g3::initializeLogging(worker.get());
    g3::only_change_at_initialization::addLogLevel(STATE);
    g3::only_change_at_initialization::addLogLevel(UPDATE);
    g3::only_change_at_initialization::addLogLevel(ERROR);

    // enable DEBUG logging
    if (config.debug_enabled()) {
        g3::log_levels::enable(DEBUG);
    } else {
        g3::log_levels::disable(DEBUG);
    }

    // screen logger
    if (config.logging_screen_enabled()) {
        worker->addSink(std::make_unique<ScreenSink>(),
                        &ScreenSink::ReceiveLogMessage);
        LOG(INFO) << "Enabled logging to screen.";
    }
    // cloud logger
    if (config.logging_cloud_enabled()) {
        worker->addSink(std::make_unique<ZMQSink>(context.zmq(),
                                                  config.logging_cloud_port()),
                        &ZMQSink::ReceiveLogMessage);
        // wait so that any existing subscriber has a change to connect before
        // we send out first messages
        std::this_thread::sleep_for(std::chrono::milliseconds(200));
        LOG(INFO) << "Enabled logging to cloud on port "
                  << config.logging_cloud_port();
    }

    LOG(INFO) << "Logging initialized. Log file saved to " << logpath;

    // Check clock used for internal timing
    LOG_IF(WARNING, not Clock::is_steady)
        << "The clock used for timing is not steady.";

    LOG(INFO) << "Resolution of clock used for timing is "
              << 10e6 * static_cast<double>(Clock::period::num) /
                     Clock::period::den
              << " microseconds.";

    // create and start GraphManager in separate thread
    graph::GraphManager gm(context);
    gm.start();

    // create command sources
    // keyboard commands
    commands::KeyboardCommands kb;
    // cloud commands
    commands::ZMQCommands zc(context.zmq(), config.network_port());
    // command line commands
    commands::CommandLineCommands cl;

    std::string graph_file = config.graph_file();
    if (parser.rest().size() > 0) {
        graph_file = parser.rest().back();
    }

    std::deque<std::string> command;
    if (graph_file.size() > 0) {

        command.push_back("graph");
        command.push_back("build");
        command.push_back(graph_file);

        cl.AddCommand(command);

        command.clear();

        if (config.graph_autostart()) {
            command.push_back("graph");
            command.push_back("start");

            cl.AddCommand(command);

            command.clear();
        }
    }

    // set up Command handler
    commands::CommandHandler commandhandler(context);

    // add command sources to handler
    commandhandler.addSource(cl);
    commandhandler.addSource(kb);
    commandhandler.addSource(zc);

    LOG(INFO) << "Enabled keyboard commands.";
    LOG(INFO) << "Enabled cloud commands on port " << config.network_port();

    LOG(INFO) << "Falcon started successfully.";
    // start handling commands
    commandhandler.start();

    LOG(INFO) << "Falcon shutting down normally.";
    g3::internal::shutDownLogging();
    return EXIT_SUCCESS;
}
