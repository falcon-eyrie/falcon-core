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

#include <iostream>
#include <list>
#include <regex>
#include <string>
#include <utility>

#include "connectionparser.hpp"
#include "utilities/string.hpp"

ConnectionRule parseConnectionRule(std::string rulestring) {
    // rule
    // <specifier>:<name><id>.<specifier>:<name><id>.<specifier>:<name><id>
    // specifier is one of f (processor), p (port) or s (slot)
    // name is any character in [a-zA-Z_]
    // id is either: number or list of ranges (e.g. [1, 4-8, 10])

    static const int type_specifier = 1;
    static const int name_group = 2;
    static const int range_group = 3;
    static const int first_range_id = 1;
    static const int end_range_id = 2;

    ConnectionRule rule;
    SingleConnectionRule single_rules[2];

    std::string expr("^(?:(f|p|s)\\:)?([a-zA-Z]*(?:[ -_][a-zA-Z]+)*)[ "
                     "]*((?:\\d+)|(?:\\([\\d,\\-]+\\)))?$");
    std::regex re(expr);
    std::smatch match;

    int startid;
    int endid;
    int current_rule_part = 0;
    int current_connection_part;

    // split on "="
    auto rule_parts = split(rulestring, '=');

    if (rule_parts.size() != 2 || rule_parts[0].length() == 0 ||
        rule_parts[1].length() == 0) {
        throw std::runtime_error(
            "Error parsing connection rule. Use the following pattern: "
            "[upstream] = [downstream].");
    }

    for (auto &rule_part : rule_parts) {
        rule_part = std::regex_replace(rule_part, std::regex("^ +| +$"),
                                       std::string(""));
        // split on "."
        auto connection_parts = split(rule_part, '.');

        if (connection_parts.size() > 3) {
            throw std::runtime_error(
                "Error parsing connection rule. "
                "Port/slot address can have at most 3 parts "
                "(given: " +
                rule_part + ").");
        }

        current_connection_part = 0;

        std::list<NodePart> available_specifiers{PROCESSOR, PORT, SLOT};
        NodePart specifier;

        for (auto &connection_part : connection_parts) {
            // match regular expression
            if (!std::regex_match(connection_part, match, re)) {
                throw std::runtime_error("Error parsing connection rule. "
                                         "Cannot parse part of address: " +
                                         connection_part + ".");
            }
            // parse part specifier

            if (!match[type_specifier].matched) {

                // get next available specifier
                specifier = available_specifiers.front();

                available_specifiers.pop_front();

            } else {
                // check if specifier is available
                std::string type_spec = match[type_specifier].str();

                if (type_spec == "f") {
                    specifier = PROCESSOR;
                } else if (type_spec == "p") {
                    specifier = PORT;
                } else {
                    specifier = SLOT;
                }

                auto it = std::find(available_specifiers.begin(),
                                    available_specifiers.end(), specifier);
                if (it == available_specifiers.end()) {
                    throw std::runtime_error("Error parsing connection rule. "
                                             "Duplicate address specifier.");
                }

                available_specifiers.remove(specifier);
            }

            // parse part name

            if (!match[name_group].matched && specifier != SLOT) {
                throw std::runtime_error("Error parsing connection rule. "
                                         "Invalid processor or port name: " +
                                         connection_part + ".");
            }

            std::string name = match[name_group].str();

            // parse part identifiers
            std::vector<int> identifiers;
            if (!match[range_group].matched) {
                // match all or default
                if (specifier == SLOT) {
                    identifiers.push_back(-1);
                } else {
                    identifiers.push_back(MATCH_NONE);
                }
            } else {
                std::string range = match[range_group].str();

                if (range[0] == '(') {
                    // match ID range vector
                    // remove brackets and spaces
                    range.erase(std::remove_if(range.begin(), range.end(),
                                               [](char x) {
                                                   return (x == '(' ||
                                                           x == ')' ||
                                                           std::isspace(x));
                                               }),
                                range.end());

                    // split on comma
                    auto id_range = split(range, ',');

                    std::regex re_range("(\\d+)(?:\\-(\\d+))?");
                    std::smatch match_range;

                    // match start and end id of ranges
                    for (const auto &q : id_range) {
                        if (std::regex_match(q, match_range, re_range)) {
                            startid = stoi(match_range[first_range_id].str());
                            if (match_range[end_range_id].matched) {
                                endid = stoi(match_range[end_range_id].str());
                            } else {
                                endid = startid;
                            }
                            for (auto kk = startid; kk <= endid; kk++) {
                                identifiers.push_back(kk);
                            }
                        } else {
                            throw std::runtime_error(
                                "Error parsing connection rule. "
                                "Cannot parse range: " +
                                q + ".");
                        }
                    }
                } else {
                    // try to convert to int
                    try {
                        identifiers.push_back(stoi(range));
                    } catch (std::invalid_argument &e) {
                        throw std::runtime_error(
                            "Error parsing connection rule. "
                            "Cannot parse range: " +
                            range + ".");
                    }
                }
            }

            if (specifier == PORT) {
                name = std::regex_replace(name, std::regex("[ _]"), "-");
            }
            // construct ConnectionPart and add to SingleConnectionRule
            single_rules[current_rule_part][current_connection_part] =
                std::make_tuple(specifier, name, identifiers);

            current_connection_part++;
        }

        // TODO: complete missing ConnectionParts of SingleConnectionRule
        // go through available specifiers
        for (auto &k : available_specifiers) {
            if (k == PROCESSOR) {
                throw std::runtime_error("Error parsing connection rule. "
                                         "No processor specified");
            } else if (k == PORT) {
                single_rules[current_rule_part][current_connection_part] =
                    std::make_tuple(PORT, std::string(""),
                                    std::vector<int>(1, MATCH_NONE));
            } else if (k == SLOT) {
                single_rules[current_rule_part][current_connection_part] =
                    std::make_tuple(SLOT, std::string(""),
                                    std::vector<int>(1, -1));
            }
            current_connection_part++;
        }
        current_rule_part++;
    }

    // construct ConnectionRule from both SingleConnectionRules
    rule = std::make_pair(single_rules[0], single_rules[1]);

    return rule;
}

std::vector<SlotAddress> expandSingleConnectionRule(SingleConnectionRule rule) {
    std::array<int, 3> index;
    std::array<std::string, 3> names;
    int idx;
    std::array<int, 3> tmp;
    std::string processor;
    std::string port;
    int slot = -1;

    std::vector<SlotAddress> cpoints;

    for (int i = 0; i < 3; i++) {
        idx = std::get<0>(rule[i]);
        index[i] = idx;
        names[i] = std::get<1>(rule[i]);
    }

    for (auto a : std::get<2>(rule[0])) {
        for (auto b : std::get<2>(rule[1])) {
            for (auto c : std::get<2>(rule[2])) {
                tmp[0] = a;
                tmp[1] = b;
                tmp[2] = c;

                for (int d = 0; d < 3; d++) {

                    if (index[d] == 0) { // processor
                        if (tmp[d] == MATCH_NONE) {
                            processor = names[d];
                        } else {
                            processor = names[d] + std::to_string(tmp[d]);
                        }
                    } else if (index[d] == 1) { // port
                        if (tmp[d] == MATCH_NONE) {
                            port = names[d];
                        } else {
                            port = names[d] + std::to_string(tmp[d]);
                        }
                    } else { // slot
                        slot = tmp[d];
                    }
                }

                cpoints.push_back(SlotAddress(processor, port, slot));
            }
        }
    }
    return cpoints;
}

void expandConnectionRule(ConnectionRule rule, StreamConnections &connections) {
    // for output SingleConnectionRule
    auto out = rule.first;
    auto out_points = expandSingleConnectionRule(out);

    // for input SingleConnectionRule
    auto in = rule.second;
    auto in_points = expandSingleConnectionRule(in);

    if (out_points.size() != 1 && out_points.size() != in_points.size()) {
        throw std::runtime_error(
            "Invalid connection rule: number of outputs and "
            "inputs does not match.");
    }

    if (out_points.size() == 1) {
        for (int i = 0; i < (int)in_points.size(); i++) {
            connections.push_back(std::make_pair(out_points[0], in_points[i]));
        }
    } else {
        for (int i = 0; i < (int)out_points.size(); i++) {
            connections.push_back(std::make_pair(out_points[i], in_points[i]));
        }
    }
}

void printConnectionPart(const ConnectionPart &part) {
    std::cout << std::get<0>(part);
    std::cout << std::get<1>(part);

    auto v = std::get<2>(part);

    if (v.size() > 0 && v[0] >= 0) {
        std::cout << "[";
        for (auto &it : v) {
            std::cout << it << ", ";
        }
        std::cout << "]";
    }
}

void printSingleConnectionRule(const SingleConnectionRule &rule) {
    for (int i = 0; i < 3; i++) {
        printConnectionPart(rule[i]);
        if (i < 2) {
            std::cout << ".";
        }
    }
}

void printConnectionRule(const ConnectionRule &rule) {
    printSingleConnectionRule(rule.first);
    std::cout << " = ";
    printSingleConnectionRule(rule.second);
    std::cout << std::endl;
}

void printConnectionList(const StreamConnections &connections) {
    for (auto &it : connections) {
        std::cout << it.first.string() << "=" << it.second.string()
                  << std::endl;
    }
}
