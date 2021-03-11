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

#include "options/units.hpp"
#include "gtest/gtest.h"
#include "processorgraph.hpp"
#include "connectionparser.hpp"

namespace {

TEST(expandProcessorName, DefaultName) {

  std::vector<std::string> result = expandProcessorName("processor");
  EXPECT_EQ(result[0], "processor");
  EXPECT_EQ(result.size(), 1);
}

TEST(expandProcessorName, PartNameWithUnderscore) {

  std::vector<std::string> result = expandProcessorName("processor_name");
  EXPECT_EQ(result[0], "processor-name");
  EXPECT_EQ(result.size(), 1);

 // std::vector<std::string> result2 = expandProcessorName("processor_name (1-2)");
 // EXPECT_EQ(result[0], "processor-name1");
 // EXPECT_EQ(result[1], "processor-name2");
 // EXPECT_EQ(result.size(), 2);
}

TEST(expandProcessorName, PartNameWithSpace) {

  std::vector<std::string> result = expandProcessorName("processor name");
  EXPECT_EQ(result[0], "processor-name");
  EXPECT_EQ(result.size(), 1);

/*  std::vector<std::string> result2 = expandProcessorName("processor name (1-2)");
  EXPECT_EQ(result[0], "processor-name1");
  EXPECT_EQ(result[1], "processor-name2");
  EXPECT_EQ(result.size(), 2);*/
}

TEST(expandProcessorName, PartNameWithDash) {

  std::vector<std::string> result = expandProcessorName("processor-name");
  EXPECT_EQ(result[0], "processor-name");
  EXPECT_EQ(result.size(), 1);

 /* std::vector<std::string> result2 = expandProcessorName("processor-name (1-2)");
  EXPECT_EQ(result[0], "processor-name1");
  EXPECT_EQ(result[1], "processor-name2");
  EXPECT_EQ(result.size(), 2);*/
}

TEST(ParseConnectionRules, classicRule) {
  ConnectionRule rules = parseConnectionRule("source.hp=ripple_filter.data");
  //EXPECT_EQ(printSingleConnectionRule(rules.first), "0source.1hp.2");
  //EXPECT_EQ(printSingleConnectionRule(rules.second), "0ripple-filter.1data.2");
}

TEST(ParseConnectionRules, ExpandRule) {
  ConnectionRule rules = parseConnectionRule("ripple_filter.data = p:data.f:detector_sink");
  //EXPECT_EQ(printSingleConnectionRule(rules.first), "0ripple_filter.1data.2");
  //EXPECT_EQ(printSingleConnectionRule(rules.second), "0detector_sink.1data.2");
}


} // namespace
