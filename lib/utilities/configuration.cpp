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
#include <regex>
#include <stdexcept>
#include <string>

#include "yaml-cpp/yaml.h"

#include "configuration.hpp"
#include "filesystem.hpp"

void Configuration::load(std::string filename) {
    auto p = parse_file(filename);

    try {
        YAML::Node node;
        node = YAML::LoadFile(p.string());
        options_.from_yaml(node, {}, false);
        std::cout << "Default configuration loaded from " << p.string() << std::endl;
    } catch (YAML::BadFile& e) { // config file does not exist, save default configuration
        try {
            // create parent path if it doesn't exist
            parse_directory(p.parent_path().string(), true, true);
            // save default config
            save(p.string());
            std::cout << "Default configuration saved to " << p.string() << "." << std::endl;
        } catch (std::runtime_error& e) {
            std::cout << "Warning: could not save configuration file: " << e.what() << std::endl;
        }
    }
}

void Configuration::save(std::string filename) {
    options_.save_yaml(filename);
}
