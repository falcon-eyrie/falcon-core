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
#include <sstream>
#include <sys/stat.h>

#include "string.hpp"

bool path_exists(const std::string &name) {
    struct stat buffer;
    return (stat(name.c_str(), &buffer) == 0);
}

std::vector<std::string> &split(const std::string &s, char delim,
                                std::vector<std::string> &elems) {
    std::stringstream ss(s);
    std::string item;
    while (std::getline(ss, item, delim)) {
        if (item.length() > 0) {
            elems.push_back(item);
        }
    }
    return elems;
}

std::vector<std::string> split(const std::string &s, char delim) {
    std::vector<std::string> elems;
    split(s, delim, elems);
    return elems;
}

std::string
resolve_server_path(std::string p,
                    const std::map<std::string, std::string> &contexts,
                    std::string default_context) {
    // regular expression: "^(\w+)://+([/_[:alnum:]])$"
    std::string expr("^(\\w+)://+([/_.[:alnum:]]*)$");
    std::regex re(expr);
    std::smatch match;

    if (p.size() > 0 &&
        (p[0] == '/' ||
         p[0] == '.')) { // absolute path or realtive to current directory
        return p;
    }

    if (!std::regex_match(p, match, re)) {
        // no context, prepend default context
        if (default_context == "") {
            throw std::runtime_error(
                std::string("No default storage context available. ") +
                "Make sure that filepaths listed in the options do NOT contain "
                "dashes (-)" +
                " and that the default values of the string options are not "
                "parsed " +
                "with context.resolve_path.");
        }

        if (contexts.count(default_context) != 1) {
            throw std::runtime_error("No storage context \"" + default_context +
                                     "\" exists.");
        }

        p = contexts.at(default_context) + "/" + p;
        return p;
    }

    if (contexts.count(match[1].str()) != 1) {
        throw std::runtime_error("No storage context \"" + match[1].str() +
                                 "\" exists.");
    }

    p = contexts.at(match[1].str()) + "/" + match[2].str();

    return p;
}

std::string extract_path_to_folder(std::string path_to_file) {
    // build paths to subfolders and check if all created paths exist
    auto path_to_folder = path_to_file;
    // pix_folder = repo://tests/data/bifurcated_maze/encoding_models/TT_I_
    while (path_to_folder.back() != '/') {
        path_to_folder.pop_back();
    } // pix_folder = repo://tests/data/bifurcated_maze/encoding_models/
    return path_to_folder;
}

std::string complete_path(std::string file_path, std::string processor_name,
                          std::string extension) {
    auto path_len = file_path.size();

    if (path_len > 4) {
        auto dotted_extension = extension;
        if (extension.front() != '.') {
            dotted_extension = "." + extension;
        }

        if ((file_path.compare(path_len - 4, 4, dotted_extension) != 0)) {
            if (isdigit(processor_name[processor_name.size() - 2])) {
                file_path.push_back(processor_name[processor_name.size() - 2]);
            }
            if (isdigit(processor_name.back())) {
                file_path.push_back(processor_name.back());
            }
            file_path.append(dotted_extension);
        }
    }
    return file_path;
}
