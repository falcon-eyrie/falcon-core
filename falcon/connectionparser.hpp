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

#include <memory>
#include <string>
#include <tuple>
#include <utility>
#include <vector>

#include "connections.hpp"
#include "utilities/general.hpp"

#define MATCH_NONE -1

typedef std::vector<std::pair<SlotAddress, SlotAddress>> StreamConnections;

enum NodePart { PROCESSOR = 0, PORT, SLOT };

typedef std::tuple<NodePart, std::string, std::vector<int>> ConnectionPart;
typedef std::array<ConnectionPart, 3> SingleConnectionRule;
typedef std::pair<SingleConnectionRule, SingleConnectionRule> ConnectionRule;
typedef std::vector<ConnectionRule> ConnectionRules;

ConnectionRule parseConnectionRule(std::string rulestring);
std::vector<SlotAddress> expandSingleConnectionRule(SingleConnectionRule rule);
void expandConnectionRule(ConnectionRule rule, StreamConnections &connections);

void printConnectionPart(const ConnectionPart &part);
void printSingleConnectionRule(const SingleConnectionRule &rule);
void printConnectionRule(const ConnectionRule &rule);
void printConnectionList(const StreamConnections &connections);
