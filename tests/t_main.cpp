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


#include <regex>
#include "gtest/gtest.h"
#include "cmdline/cmdline.h"
#include "logging/log.hpp"
#include "logging/customsink.hpp"

using namespace std;

int main(int argc, char** argv) {
  cmdline::parser parser;
  parser.add<string>("logpath", 'l', "logging path of the test", false, "$HOME/log");
  parser.add("noscreenlog", '\0', "disable logging to screen");
  parser.parse_check(argc, argv);

  char *home = getenv("HOME");
  std::regex re("(\\$HOME|~)");
  std::string logpath =  std::regex_replace(parser.get<std::string>("logpath"), re, home);
  auto worker = g3::LogWorker::createLogWorker();
  auto defaultHandler = worker->addDefaultLogger("falcon", logpath);

  // initialize logging before creating additional loggers
  g3::initializeLogging(worker.get());

  // enable DEBUG logging
  g3::log_levels::set(DEBUG, true);
  if (!parser.exist("noscreenlog")) {
      worker->addSink(std::make_unique<ScreenSink>(),
                      &ScreenSink::ReceiveLogMessage);
  }

  ::testing::InitGoogleTest(&argc, argv);
  return RUN_ALL_TESTS();

}
