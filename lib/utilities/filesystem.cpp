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

#include "filesystem.hpp"

#include <iostream>
#include <regex>

std::string expand_home(const std::string &x) {
    char *home = getenv("HOME");
    if (home != NULL) {
        std::regex re("(\\$HOME|~)");
        auto y = std::regex_replace(x, re, home);
        return y;
    } else {
        return x;
    }
}

fs::path parse_directory(const std::string &x, bool exists, bool create) {
    fs::path p{expand_home(x)};
    // p = fs::absolute(p);

    if (fs::exists(p)) {
        if (!fs::is_directory(p)) {
            throw std::runtime_error("Not a valid directory: " + p.string());
        }
    } else if (exists) {
        if (create) {
            if (!fs::create_directories(p)) {
                throw std::runtime_error("Could not create directory: " +
                                         p.string());
            }
        } else {
            throw std::runtime_error("Directory does not exist: " + p.string());
        }
    }
    return p;
}

fs::path parse_file(const std::string &x, bool exists) {
    fs::path p{expand_home(x)};
    // p = fs::absolute(p);

    if (fs::exists(p)) {
        if (!fs::is_regular_file(p)) {
            throw std::runtime_error("Not a valid file: " + p.string());
        }
    } else if (exists) {
        throw std::runtime_error("Not an existing file: " + p.string());
    }
    return p;
}

std::vector<std::string> getAllFilesInDir(const std::string &dirPath) {

    std::vector<std::string> listOfFiles;

    if (fs::exists(dirPath) && fs::is_directory(dirPath)) {

        fs::recursive_directory_iterator iter(dirPath);
        fs::recursive_directory_iterator end;

        while (iter != end) {

            if (fs::is_regular_file(iter->path())) {

                listOfFiles.push_back(iter->path().string());
            }
            std::error_code ec;
            iter.increment(ec);
            if (ec) {
                throw std::runtime_error(
                    "Error While Accessing : " + iter->path().string() +
                    " :: " + ec.message());
            }
        }
    }
    return listOfFiles;
}