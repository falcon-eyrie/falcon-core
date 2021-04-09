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
   
  std::vector<std::string> result2 = expandProcessorName("processor_name (1-2)");
  EXPECT_EQ(result2[0], "processor-name1");
  EXPECT_EQ(result2[1], "processor-name2");
  EXPECT_EQ(result2.size(), 2);
}

TEST(expandProcessorName, PartNameWithSpace) {

  std::vector<std::string> result = expandProcessorName("processor name");
  EXPECT_EQ(result[0], "processor-name");
  EXPECT_EQ(result.size(), 1);

  std::vector<std::string> result2 = expandProcessorName("processor name (1-2)");
  EXPECT_EQ(result2[0], "processor-name1");
  EXPECT_EQ(result2[1], "processor-name2");
  EXPECT_EQ(result2.size(), 2);
}

TEST(expandProcessorName, PartNameWithDash) {

  std::vector<std::string> result = expandProcessorName("processor-name");
  EXPECT_EQ(result[0], "processor-name");
  EXPECT_EQ(result.size(), 1);

  std::vector<std::string> result2 = expandProcessorName("processor-name (1-2)");
  EXPECT_EQ(result2[0], "processor-name1");
  EXPECT_EQ(result2[1], "processor-name2");
  EXPECT_EQ(result2.size(), 2);
}

TEST(ParseConnectionRules, classicRule) {
  ConnectionRule rules = parseConnectionRule("source.hp.0=ripple_filter.data.1");

  // PROCESSOR PART 
  printConnectionRule(rules);
  EXPECT_EQ(std::get<1>(rules.second[0]), "ripple-filter");
  EXPECT_EQ(std::get<1>(rules.first[0]), "source");
  EXPECT_EQ(std::get<0>(rules.second[0]), 0);
  EXPECT_EQ(std::get<0>(rules.first[0]), 0);

  // PORT PART 
  
  EXPECT_EQ(std::get<1>(rules.second[1]), "data");
  EXPECT_EQ(std::get<1>(rules.first[1]), "hp");
  EXPECT_EQ(std::get<0>(rules.second[1]), 1);
  EXPECT_EQ(std::get<0>(rules.first[1]), 1);

  // SLOT PART 
  
  EXPECT_EQ(std::get<2>(rules.second[2])[0], 1);
  EXPECT_EQ(std::get<2>(rules.first[2])[0], 0);
  EXPECT_EQ(std::get<0>(rules.second[2]), 2);
  EXPECT_EQ(std::get<0>(rules.first[2]), 2);

}

TEST(ParseConnectionRules, ExpandRule) {
  ConnectionRule rules = parseConnectionRule("source.hp = f:ripple_filter.p:data.s:1");

  printConnectionRule(rules);
  EXPECT_EQ(std::get<1>(rules.second[0]), "ripple-filter");
  EXPECT_EQ(std::get<1>(rules.first[0]), "source");
  EXPECT_EQ(std::get<0>(rules.second[0]), 0);
  EXPECT_EQ(std::get<0>(rules.first[0]), 0);

  // PORT PART 
  EXPECT_EQ(std::get<1>(rules.second[1]), "data");
  EXPECT_EQ(std::get<1>(rules.first[1]), "hp");
  EXPECT_EQ(std::get<0>(rules.second[1]), 1);
  EXPECT_EQ(std::get<0>(rules.first[1]), 1);

  // SLOT PART 
  EXPECT_EQ(std::get<2>(rules.second[2])[0], 1);
  EXPECT_EQ(std::get<2>(rules.first[2])[0], -1);
  EXPECT_EQ(std::get<0>(rules.second[2]), 2);
  EXPECT_EQ(std::get<0>(rules.first[2]), 2);
}

TEST(ParseConnectionRules, DocEquivalentyRules) {
  ConnectionRule rules = parseConnectionRule("upstream.out(1-2)=downstream.in(1-2)");

  EXPECT_EQ(std::get<1>(rules.first[0]), "upstream");
  EXPECT_EQ(std::get<1>(rules.second[0]), "downstream");
  EXPECT_EQ(std::get<0>(rules.second[0]), 0);
  EXPECT_EQ(std::get<0>(rules.first[0]), 0);

  // PORT PART 
  EXPECT_EQ(std::get<1>(rules.first[1]), "out");
  EXPECT_EQ(std::get<1>(rules.second[1]), "in");
  EXPECT_EQ(std::get<0>(rules.second[1]), 1);
  EXPECT_EQ(std::get<0>(rules.first[1]), 1);
  EXPECT_EQ(std::get<2>(rules.first[1])[0], 1);
  EXPECT_EQ(std::get<2>(rules.first[1])[1], 2);
}



} // namespace
